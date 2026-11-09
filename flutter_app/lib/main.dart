import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

// 构建期开关：项目尚未创建 Firestore 数据库，默认关闭以保证 0 额外请求。
// 完成前置配置后用 `flutter build web --dart-define=FIRESTORE_ENABLED=true` 开启。
const bool kFirestoreEnabled =
    bool.fromEnvironment('FIRESTORE_ENABLED', defaultValue: false);

// 构建期开关：Cloud Functions 生产部署需要 Blaze 计费计划，当前项目为 Spark，
// 函数未部署。默认关闭以保证 0 额外请求；升级 Blaze 并部署函数后用
// `flutter build web --dart-define=FUNCTIONS_ENABLED=true` 开启。
const bool kFunctionsEnabled =
    bool.fromEnvironment('FUNCTIONS_ENABLED', defaultValue: false);

const String _systemInstruction = '你是「NEON PLINKO 霓虹弹珠」的官方规则助手。只回答与这个游戏相关的问题，包括：玩法步骤、9 个倍率槽（x12 / x4 / x1.5 / x0.5 / x0.25 / x0.5 / x1.5 / x4 / x12）、下注档位（10 / 25 / 50 / 100 / 250 CR）、初始 1,000 CR、目标 10,000 CR、键盘与触屏操作、最高纪录保存在浏览器 localStorage、纯娱乐且无真实货币投注。请用简体中文、简短、纯文本回答，不要使用 Markdown，不要编造未提供的信息。如果问题与游戏无关，请礼貌拒答并引导用户回到游戏。';

// 2026-11 实测可用的稳定模型；gemini-3.8-flash 当时持续高负载。
const List<String> _models = <String>[
  'gemini-3.5-flash-lite',
  'gemini-3.6-flash',
  'gemini-3.5-flash',
];

const String _mainGameUrl = 'https://neon-plinko-20261110.web.app/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NeonAiApp());
}

/// 对齐官方 quickstart-flutter / analytics 的 logEvent + setUserProperty 用法。
///
/// Firebase Web 端 Analytics 需要 measurementId（启用 Google Analytics 后才会生成）。
/// 本项目尚未启用 GA、measurementId 为空，因此这里优雅跳过初始化：
/// 不创建 FirebaseAnalytics 实例、不发起任何第三方统计请求，站点 CSP 与行为保持不变。
/// 之后在 Firebase 控制台启用 GA 并把 measurementId 填入 firebase_options.dart 即可自动生效。
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  bool get enabled =>
      (DefaultFirebaseOptions.web.measurementId ?? '').isNotEmpty;

  Future<void> init() async {
    if (!enabled) {
      debugPrint('[analytics] measurementId 为空，跳过 Analytics 初始化。');
      return;
    }
    try {
      final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      _analytics = analytics;
      await analytics.setAnalyticsCollectionEnabled(true);
      await analytics.setUserProperty(name: 'plinko_client', value: 'flutter_web');
      await analytics.logScreenView(screenName: 'ai_assistant');
      await log('app_open', parameters: <String, Object>{'platform': 'flutter_web'});
    } catch (e) {
      debugPrint('[analytics] 初始化失败：$e');
      _analytics = null;
    }
  }

  Future<void> log(String name, {Map<String, Object>? parameters}) async {
    final FirebaseAnalytics? analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('[analytics] logEvent($name) 失败：$e');
    }
  }

  Future<void> setUserId(String? id) async {
    final FirebaseAnalytics? analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('[analytics] setUserId 失败：$e');
    }
  }
}

/// 对齐官方 quickstart-flutter / authentication 的
/// authStateChanges() + signInAnonymously() + User.uid 用法。
///
/// 匿名登录不需要注册、不需要输入信息，最适合纯娱乐规则助手。
/// 项目当前尚未启用 Anonymous sign-in provider，因此按钮触发时会捕获
/// `operation-not-allowed` 并给出友好提示，AI 助手完全不受影响。
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<String> signInAnonymously() async {
    final UserCredential credential = await _auth.signInAnonymously();
    final String uid = credential.user?.uid ?? '';
    if (uid.isEmpty) throw StateError('匿名登录未返回 uid');
    await AnalyticsService.instance.setUserId(uid);
    await AnalyticsService.instance.log('login', parameters: <String, Object>{
      'method': 'anonymous',
    });
    return uid;
  }

  Future<void> signOut() async {
    await AnalyticsService.instance.setUserId(null);
    await _auth.signOut();
  }
}

/// 对齐官方 quickstart-flutter / firestore 的
/// FirebaseFirestore.instance + collection().add() + snapshots() 用法。
///
/// 每次 AI 问答写入 `neon_plinko_ai_logs`，并用最近 5 条展示「最近提问」。
/// 项目当前 firestore.googleapis.com 为 DISABLED、数据库也未创建，因此
/// 由 kFirestoreEnabled 构建期开关默认关闭：不实例化 Firestore、不发起请求。
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  static const String collectionName = 'neon_plinko_ai_logs';

  bool get enabled => kFirestoreEnabled;

  Future<void> saveLog({
    required String question,
    required String answer,
    required String model,
    required String source,
  }) async {
    if (!enabled) return;
    try {
      await FirebaseFirestore.instance.collection(collectionName).add(<String, dynamic>{
        'question': question,
        'answer': answer,
        'model': model,
        'source': source,
        'client': 'flutter_web',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[firestore] 写入失败：$e');
    }
  }

  Stream<List<Map<String, dynamic>>> recentLogs() {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data())
              .toList(),
        );
  }

  // ---- FriendlyChat 实时聊天面板（离线可用） ----

  static const String chatCollection = 'neon_plinko_chat';
  static bool _initialized = false;

  /// 对齐 FriendlyChat 的「Offline」特性：开启时启用 Firestore 本地缓存，
  /// 断网也能展示历史消息（Flutter Web 走 IndexedDB 持久化）。
  /// 必须在首次读写前调用，且由 kFirestoreEnabled 开关保护。
  Future<void> init() async {
    if (!enabled || _initialized) return;
    try {
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      _initialized = true;
    } catch (e) {
      debugPrint('[firestore] 初始化离线缓存失败：$e');
    }
  }

  Future<void> postMessage({
    required String uid,
    required String displayName,
    required String text,
  }) async {
    if (!enabled) return;
    try {
      await FirebaseFirestore.instance.collection(chatCollection).add(<String, dynamic>{
        'uid': uid,
        'displayName': displayName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[firestore] 发送消息失败：$e');
    }
  }

  /// 对齐 FriendlyChat 的 orderBy('timestamp').snapshots() 实时列表。
  Stream<List<Map<String, dynamic>>> chatStream() {
    return FirebaseFirestore.instance
        .collection(chatCollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data())
              .toList(),
        );
  }
}

/// 对齐官方 quickstart-flutter / cloud_functions 的
/// FirebaseFunctions.instance.httpsCallable('...').call() 用法。
///
/// 调用后端 callable `neonPlinkoRules`，返回游戏规格（倍率表/下注/目标）。
/// 官方示例为 `addMessage` 字符串回显，此处改为与 NEON PLINKO 规则相关的结构化数据。
/// 项目当前为 Spark、`cloudfunctions.googleapis.com` 为 DISABLED、函数未部署，
/// 因此由 kFunctionsEnabled 构建期开关默认关闭：不实例化 Functions、不发起请求。
class FunctionsService {
  FunctionsService._();
  static final FunctionsService instance = FunctionsService._();

  static const String callableName = 'neonPlinkoRules';

  bool get enabled => kFunctionsEnabled;

  Future<Map<String, dynamic>?> fetchRules() async {
    if (!enabled) return null;
    try {
      final HttpsCallableResult<dynamic> result =
          await FirebaseFunctions.instance.httpsCallable(callableName).call();
      final Object? data = result.data;
      if (data is Map<Object?, Object?>) {
        return data.map((Object? k, Object? v) =>
            MapEntry<String, dynamic>(k.toString(), v));
      }
      return <String, dynamic>{'raw': data.toString()};
    } catch (e) {
      debugPrint('[functions] 调用失败：$e');
      return <String, dynamic>{'error': e.toString()};
    }
  }
}

class NeonAiApp extends StatelessWidget {
  const NeonAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEON PLINKO AI 助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF3CAC),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF0B0720),
        ),
        scaffoldBackgroundColor: const Color(0xFF05030F),
      ),
      home: const AiAssistantPage(),
    );
  }
}

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  FirebaseAI? _ai;
  bool _busy = false;
  String _status = '正在初始化…';
  String _answer = '';
  StreamSubscription<User?>? _authSub;
  User? _authUser;
  String _authStatus = '未登录（可选）';
  bool _authBusy = false;
  Map<String, dynamic>? _functionRules;
  String _functionStatus = '未启用';
  bool _functionBusy = false;
  final TextEditingController _chatController = TextEditingController();
  String _chatError = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.init();
    if (kFirestoreEnabled) {
      // 启用时初始化 Firestore 离线缓存（必须在首次读写前）。
      FirestoreService.instance.init();
    }
    _authSub = AuthService.instance.authStateChanges().listen(
      (User? user) {
        if (!mounted) return;
        setState(() {
          _authUser = user;
          if (user != null) {
            final String short = user.uid.length >= 8 ? user.uid.substring(0, 8) : user.uid;
            _authStatus = '匿名已登录 · uid $short…';
          } else if (_authStatus.startsWith('匿名已登录')) {
            _authStatus = '已退出登录';
          }
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() => _authStatus = 'Auth 状态监听异常：$e');
      },
    );
    try {
      _ai = FirebaseAI.googleAI();
      _status = '已连接，请输入问题。';
    } catch (e) {
      _status = 'Firebase 初始化失败：$e';
    }
    final String? initialQuestion = Uri.base.queryParameters['q'];
    if (initialQuestion != null && initialQuestion.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ask(initialQuestion, source: 'deeplink'),
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously() async {
    if (_authBusy || _authUser != null) return;
    setState(() {
      _authBusy = true;
      _authStatus = '正在匿名登录…';
    });
    try {
      await AuthService.instance.signInAnonymously();
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _authStatus = '匿名登录成功';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _authStatus = e.code == 'operation-not-allowed'
            ? '项目尚未启用 Anonymous 登录提供方；AI 助手仍可正常使用。'
            : '匿名登录未成功（${e.code}）；AI 助手仍可正常使用。';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authBusy = false;
        _authStatus = '匿名登录未成功；AI 助手仍可正常使用。';
      });
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    setState(() => _authStatus = '已退出登录');
  }

  Future<void> _callRulesFunction() async {
    if (_functionBusy) return;
    setState(() {
      _functionBusy = true;
      _functionStatus = '正在调用 Cloud Function…';
      _functionRules = null;
    });
    final Map<String, dynamic>? rules = await FunctionsService.instance.fetchRules();
    if (!mounted) return;
    setState(() {
      _functionBusy = false;
      _functionRules = rules;
      if (rules == null) {
        _functionStatus = '未启用';
      } else if (rules.containsKey('error')) {
        _functionStatus = '调用失败：${rules['error']}';
      } else {
        _functionStatus = '调用成功';
      }
    });
  }

  Future<void> _postChat() async {
    final String text = _chatController.text.trim();
    if (text.isEmpty || !kFirestoreEnabled) return;
    setState(() => _chatError = '');
    await FirestoreService.instance.postMessage(
      uid: _authUser?.uid ?? 'anon',
      displayName: _authUser != null
          ? '访客${(_authUser!.uid.length >= 4 ? _authUser!.uid.substring(0, 4) : _authUser!.uid)}'
          : '匿名访客',
      text: text,
    );
    if (!mounted) return;
    _chatController.clear();
  }

  Future<void> _ask(String question, {String source = 'input'}) async {
    final FirebaseAI? ai = _ai;
    if (ai == null || _busy || question.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _answer = '';
      _status = '正在连接 Gemini，请稍候…';
    });

    await AnalyticsService.instance.log('ask_ai', parameters: <String, Object>{
      'source': source,
      'question_length': question.trim().length,
    });

    String lastError = '';
    for (final String name in _models) {
      try {
        final GenerativeModel model = ai.generativeModel(
          model: name,
          systemInstruction: Content.text(_systemInstruction),
          generationConfig: GenerationConfig(maxOutputTokens: 300),
        );
        final GenerateContentResponse response = await model
            .generateContent(<Content>[Content.text(question.trim())])
            .timeout(const Duration(seconds: 35));
        final String text = (response.text ?? '').trim();
        if (!mounted) return;
        setState(() {
          _answer = text.isEmpty ? '（AI 返回了空内容，请重试）' : text;
          _status = '回答完成。';
          _busy = false;
        });
        await AnalyticsService.instance.log('ai_response', parameters: <String, Object>{
          'status': 'ok',
          'model': name,
        });
        await FirestoreService.instance.saveLog(
          question: question.trim(),
          answer: text,
          model: name,
          source: source,
        );
        return;
      } catch (e) {
        lastError = e.toString();
      }
    }

    await AnalyticsService.instance.log('ai_response', parameters: <String, Object>{
      'status': 'error',
    });
    if (!mounted) return;
    setState(() {
      _answer = '暂时无法连接 AI 助手。可能是模型临时高负载、API Key 域名限制或免费额度不足；已自动尝试多个稳定模型，请稍后重试。\n\n错误详情：$lastError';
      _status = '请求失败。';
      _busy = false;
    });
  }

  void _submit() => _ask(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 规则助手'),
        backgroundColor: const Color(0xFF0B0720),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'NEON PLINKO',
                  style: TextStyle(
                    color: Color(0xFFFF3CAC),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'FIREBASE AI LOGIC + AUTH // FLUTTER WEB',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                const Text(
                  '只回答 NEON PLINKO 霓虹弹珠的玩法、倍率、下注、操作与规则问题。由 Gemini 生成，纯娱乐游戏，不涉及真实货币。',
                  style: TextStyle(color: Color(0xFFA8A2C8), height: 1.6),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text('向 AI 提问', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        maxLength: 500,
                        enabled: !_busy,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '例如：最高倍率是多少？怎么在手机上投放？',
                          hintStyle: const TextStyle(color: Color(0xFF7A7499)),
                          filled: true,
                          fillColor: const Color(0xFF060312),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: const Color(0xFF06030F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_busy ? '思考中…' : '询问 AI 助手'),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _chip('倍率表', 'NEON PLINKO 的 9 个倍率槽分别是什么？'),
                          _chip('操作方式', '游戏怎么开始？键盘和手机分别怎么操作？'),
                          _chip('下注与目标', '下注档位有哪些？初始筹码和胜利目标是多少？'),
                          _chip('安全说明', '这个游戏涉及真实货币或充值吗？最高纪录保存在哪里？'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(_status, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13)),
                      if (_answer.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF060312),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x33A8A2C8)),
                          ),
                          child: SelectableText(
                            _answer,
                            style: const TextStyle(color: Colors.white, height: 1.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        '问题会发送给 Google Gemini，请勿输入个人信息。AI 回答可能有误，规则以游戏主页为准。',
                        style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Firebase Authentication',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '对齐官方 quickstart 的 authStateChanges() + signInAnonymously()。匿名登录仅生成临时 uid，不需要注册或输入任何信息；未启用登录提供方时 AI 助手仍可正常使用。',
                        style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (_authBusy || _authUser != null) ? null : _signInAnonymously,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF00E5FF),
                                side: const BorderSide(color: Color(0x5500E5FF)),
                              ),
                              child: Text(_authBusy ? '登录中…' : '匿名登录'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _authUser == null ? null : _signOut,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF3CAC),
                                side: const BorderSide(color: Color(0x55FF3CAC)),
                              ),
                              child: const Text('退出登录'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_authStatus, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Cloud Firestore',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '对齐官方 quickstart 的 collection().add() + snapshots() + StreamBuilder。启用后把每次 AI 问答写入 neon_plinko_ai_logs，并展示最近 5 条提问。',
                        style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      if (!kFirestoreEnabled)
                        const Text(
                          '未启用：项目尚未创建 Firestore 数据库（firestore.googleapis.com 为 DISABLED）。AI 助手仍可正常使用，且不会产生任何 Firestore 请求。',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, height: 1.6),
                        )
                      else
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirestoreService.instance.recentLogs(),
                          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                            if (snapshot.hasError) {
                              return const Text(
                                'Firestore 读取失败：请确认已创建数据库并部署 firestore.rules。',
                                style: TextStyle(color: Color(0xFFFF3CAC), fontSize: 13),
                              );
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('正在读取最近提问…', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13));
                            }
                            final List<Map<String, dynamic>> logs = snapshot.data ?? <Map<String, dynamic>>[];
                            if (logs.isEmpty) {
                              return const Text('暂无记录', style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13));
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: logs.map((Map<String, dynamic> log) {
                                final String q = (log['question'] ?? '').toString();
                                final String a = (log['answer'] ?? '').toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '• $q → $a',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Cloud Functions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '对齐官方 quickstart 的 FirebaseFunctions.instance.httpsCallable(...).call()。后端 callable neonPlinkoRules 返回游戏规格（倍率表/下注/目标）；与官方 addMessage 回显示例同构。',
                        style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      if (!kFunctionsEnabled)
                        const Text(
                          '未启用：Cloud Functions 生产部署需要 Blaze 计费计划，当前项目为 Spark、函数未部署。AI 助手仍可正常使用，且不会产生任何 Functions 请求。',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, height: 1.6),
                        )
                      else ...<Widget>[
                        OutlinedButton(
                          onPressed: _functionBusy ? null : _callRulesFunction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00E5FF),
                            side: const BorderSide(color: Color(0x5500E5FF)),
                          ),
                          child: Text(_functionBusy ? '调用中…' : '调用 neonPlinkoRules'),
                        ),
                        const SizedBox(height: 10),
                        Text(_functionStatus, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13)),
                        if (_functionRules != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF060312),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x33A8A2C8)),
                            ),
                            child: SelectableText(
                              _functionRules!.entries
                                  .map((MapEntry<String, dynamic> e) => '${e.key}: ${e.value}')
                                  .join('\n'),
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        '实时聊天面板（FriendlyChat）',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '对齐官方 flutter/codelabs · firebase-get-to-know-flutter（FriendlyChat）的 Auth + Firestore + 离线持久化：匿名用户发消息写入 neon_plinko_chat，用 orderBy(\'createdAt\').snapshots() + StreamBuilder 实时展示；启用时开启本地缓存，断网仍可看历史。',
                        style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      if (!kFirestoreEnabled)
                        const Text(
                          '未启用：当前为构建期关闭状态（Firestore 数据库尚未创建）。AI 助手与控制台不受影响，且不会产生任何 Firestore 请求。',
                          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, height: 1.6),
                        )
                      else ...<Widget>[
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF060312),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x33A8A2C8)),
                          ),
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: FirestoreService.instance.chatStream(),
                            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                              if (snapshot.hasError) {
                                return const Text(
                                  '聊天读取失败：请确认已创建数据库并部署 firestore.rules。',
                                  style: TextStyle(color: Color(0xFFFF3CAC), fontSize: 13),
                                );
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('正在加载聊天…', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13));
                              }
                              final List<Map<String, dynamic>> msgs = snapshot.data ?? <Map<String, dynamic>>[];
                              if (msgs.isEmpty) {
                                return const Text('还没有消息，来发第一条吧～', style: TextStyle(color: Color(0xFFA8A2C8), fontSize: 13));
                              }
                              return ListView.separated(
                                reverse: true,
                                itemCount: msgs.length,
                                separatorBuilder: (BuildContext c, int i) => const SizedBox(height: 8),
                                itemBuilder: (BuildContext c, int i) {
                                  final Map<String, dynamic> m = msgs[i];
                                  final String name = (m['displayName'] ?? '匿名').toString();
                                  final String body = (m['text'] ?? '').toString();
                                  return RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                                      children: <TextSpan>[
                                        TextSpan(text: '$name：', style: const TextStyle(color: Color(0xFF00E5FF))),
                                        TextSpan(text: body),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: _authUser != null ? '说点什么…' : '请先匿名登录再发言',
                                  hintStyle: const TextStyle(color: Color(0x88A8A2C8)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0x55A8A2C8)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onSubmitted: (_) => _postChat(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _authUser == null ? null : _postChat,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF3CAC),
                                side: const BorderSide(color: Color(0x55FF3CAC)),
                              ),
                              child: const Text('发送'),
                            ),
                          ],
                        ),
                        if (_chatError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_chatError, style: const TextStyle(color: Color(0xFFFF3CAC), fontSize: 12)),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  'H5 主游戏：$_mainGameUrl',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String question) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
      backgroundColor: const Color(0x1100E5FF),
      side: const BorderSide(color: Color(0x5500E5FF)),
      onPressed: _busy ? null : () {
        _controller.text = question;
        _ask(question, source: 'suggestion');
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xEE0B0720),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x55FF3CAC)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22FF3CAC), blurRadius: 30),
        ],
      ),
      child: child,
    );
  }
}
