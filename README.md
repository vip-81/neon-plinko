# NEON PLINKO 霓虹弹珠

已部署到 Cloudflare Pages 的免费赛博朋克风 H5 弹珠游戏。单个 `index.html` 内含完整页面、样式、Canvas 游戏逻辑与音效，无前端框架、无 CDN、无外部图片。

- **生产地址（Canonical）**：https://neon-plinko.pages.dev/
- **GitHub Pages 镜像**：https://vip-81.github.io/neon-plinko/
- **Firebase Hosting 镜像**：https://neon-plinko-20261110.web.app/
- **Firebase AI Logic 助手页（Web）**：https://neon-plinko-20261110.web.app/ai
- **Flutter Web AI 助手**：https://neon-plinko-flutter.web.app/
- **Flutter Web 站点内的 H5 游戏**：https://neon-plinko-flutter.web.app/game/
- **React / Vite AI 助手**：https://neon-plinko-js.web.app/
- **GitHub 仓库**：https://github.com/vip-81/neon-plinko
- **Gitee 仓库**：https://gitee.com/vip882/neon-plinko
- **AtomGit 仓库**：https://atomgit.com/zzw1208/neon-plinko
- **Cloudflare Pages 项目**：`neon-plinko`
- **部署环境**：production / `main`
- **现有项目**：`neon21-casino`、`static-casino-game`、`golden-reels` 均保持原样，未被覆盖

## 文件结构

```text
.
├── index.html      # 完整游戏 + SEO/GEO 内容页（核心文件）
├── og-cover.png    # 1200 × 630 社交分享封面
├── robots.txt      # 抓取规则 + sitemap 地址
├── sitemap.xml     # 单页 sitemap
├── llms.txt        # 面向 AI 摘要与引用的结构化站点摘要
├── _headers        # Cloudflare Pages 缓存与安全响应头
├── firebase.json   # Firebase Hosting 配置（headers / cache / cleanUrls）
├── .firebaserc     # Firebase 项目与多站点 target 映射
├── ai.html         # 独立 Web AI 规则助手页（Firebase AI Logic / Gemini）
├── firebase-config.example.js  # Web 配置模板；真实 firebase-config.js 仅部署时生成
├── flutter_app/    # 独立 Flutter Web AI 助手源码 + 部署配置
├── unity_app/      # Firebase AI Logic Unity C# 源码示例（仅源码，未构建）
├── js_app/         # Firebase AI Logic React / Vite 应用源码 + 部署配置
├── 404.html        # 品牌化 404 页面（含 noindex）
├── .nojekyll       # GitHub Pages：跳过 Jekyll，原样发布静态文件
└── README.md       # 部署与维护说明
```

## 本次生产部署

页面已写入正式绝对地址：

- Canonical：`https://neon-plinko.pages.dev/`
- `og:url`、`og:image`、`twitter:image`
- JSON-LD：`WebSite`、`WebPage`、`VideoGame`、`FAQPage`
- `robots.txt` 的 Sitemap 行
- `sitemap.xml` 的 `<loc>`

Cloudflare Pages 会通过 `_headers` 为 HTML、封面和索引文件设置缓存、CSP、`X-Content-Type-Options`、`Referrer-Policy` 与 `X-Frame-Options`。

### 更新部署

在本目录执行：

```bash
npx wrangler pages deploy . --project-name neon-plinko --branch main
```

或在 Cloudflare Dashboard → Workers & Pages → `neon-plinko` → Create new deployment 中上传本目录。

### GitHub Pages 镜像部署

仓库 `vip-81/neon-plinko` 的 `main` 分支已启用 GitHub Pages（根目录发布）。推送后会自动重新构建：

```bash
git init
git add .
git commit -m "Deploy NEON PLINKO"
git branch -M main
git remote add origin https://github.com/vip-81/neon-plinko.git
git push -u origin main
```

- 镜像地址：https://vip-81.github.io/neon-plinko/
- GitHub Pages 不支持自定义响应头，`_headers` 中的 CSP 与缓存策略仅在 Cloudflare Pages 生效。
- 两个地址返回相同页面；canonical、`og:url`、JSON-LD、`sitemap.xml` 与 `robots.txt` 统一指向 Cloudflare 生产域名，避免重复索引。
- 需要把 GitHub Pages 设为主站时，将上述文件中的 `https://neon-plinko.pages.dev/` 替换为 `https://vip-81.github.io/neon-plinko/`，同步更新 `llms.txt`，然后重新部署两个平台。

### Firebase Hosting 部署

复用已有 Firebase 项目 `boto3-firebase-1101012838`，并新建独立 Hosting 站点 `neon-plinko-20261110`，未覆盖该项目中已有站点：

- 站点地址：https://neon-plinko-20261110.web.app/
- 项目 ID：`boto3-firebase-1101012838`
- Site ID：`neon-plinko-20261110`
- 部署 target：`neon-plinko`（见 `.firebaserc`）
- Firebase 项目控制台：https://console.firebase.google.com/project/boto3-firebase-1101012838/overview

在 `firebase.json` 所在目录执行：

```bash
firebase target:apply hosting neon-plinko neon-plinko-20261110 --project boto3-firebase-1101012838
firebase deploy --only hosting:neon-plinko --project boto3-firebase-1101012838
```

- `firebase.json` 配置了 CSP、安全响应头、缓存策略、`cleanUrls` 与自定义 404；效果与 Cloudflare `_headers` 对齐。
- 仅上传 `index.html`、`og-cover.png`、`robots.txt`、`sitemap.xml`、`llms.txt`、`404.html` 六个文件；`_headers`、README、`.nojekyll` 与 Firebase 配置本身设为 `ignore`。
- Firebase 镜像与 Cloudflare / GitHub Pages 一样，canonical 保持 `https://neon-plinko.pages.dev/`。
- 登录使用 `gcloud auth application-default login` 生成的 ADC；Firebase CLI 会直接复用该凭据，无需单独 `firebase login`。

### Firebase AI Logic 助手页

独立页面 `ai.html` 使用 Firebase AI Logic Web SDK（13.1.0，gstatic CDN）调用 Gemini，提供游戏规则问答；主游戏 `index.html` 完全不变。

- 访问地址：https://neon-plinko-20261110.web.app/ai （`/ai.html` 会 301 到 `/ai`）
- 该页设置 `noindex, follow`，不参与主站 SEO/GEO 评分，也不纳入主站 Lighthouse。
- 仅该页放宽 CSP，允许 `www.gstatic.com`、`apis.google.com` 与 `firebasevertexai.googleapis.com`；首页仍是严格 CSP，Lighthouse 保持 100/100/100。
- 模型按 `gemini-3.5-flash-lite` → `gemini-3.6-flash` → `gemini-3.5-flash` 回退，单次请求 35 秒超时；`gemini-3.8-flash` 当前高负载，故不作为首选。
- 系统提示词限定只回答 NEON PLINKO 的玩法、倍率、下注、操作与安全说明，并拒答无关问题。
- 其他镜像（如 GitHub Pages）没有 `firebase-config.js` 时会显示「仅 Firebase 环境可用」并禁用提问，不会调用 Gemini；AI 助手的实际入口是 Firebase Hosting。

前置配置（已完成）：

- 注册 Firebase Web App：`1:909891373707:web:93ea70d7a2a1fe5ac6a28e`
- 启用 `generativelanguage.googleapis.com`、`firebasevertexai.googleapis.com`、`apikeys.googleapis.com`
- 通过 Firebase provisioning API 创建 AI Logic genai config（否则会报 `genai config not found`）
- 将公开 Firebase Web API Key 限制为仅允许 `https://neon-plinko-20261110.web.app/*`、`https://neon-plinko-20261110.firebaseapp.com/*` 与 localhost

部署时使用 `firebase-config.example.js` 作为模板生成 `firebase-config.js` 并上传到 Hosting；**真实配置不提交到公开仓库**，避免把项目标识写入源码库：

```bash
cp firebase-config.example.js firebase-config.js
# 填入 firebase apps:sdkconfig WEB <appId> 输出的值
firebase deploy --only hosting:neon-plinko --project boto3-firebase-1101012838
```

生产环境建议在 Firebase 控制台额外配置 App Check / reCAPTCHA Enterprise 强制校验；当前通过 provisioning API 初始化，未启用 App Check 强制校验，但 API Key 已做域名限制。

### Flutter Web AI 助手

按你提供的 `firebase/quickstart-flutter` 方向，另建了独立 Flutter Web 客户端（该仓库 `main` 分支当前已无 AI Logic 示例，故按官方 `firebase_ai` Dart API 实现）：

- 站点：https://neon-plinko-flutter.web.app/
- Firebase 项目：`boto3-firebase-1101012838`；Hosting 站点：`neon-plinko-flutter`
- 源码：`flutter_app/`，使用 `firebase_core ^5.1.0` + `firebase_ai ^5.1.0` + `firebase_analytics ^13.0.1`，Flutter 3.47.9 / Dart 3.13.7
- 功能与 Web 助手一致：系统提示词限定游戏规则、3 个稳定模型回退、35 秒超时、`?q=` 深链自动提问
- **游戏本体**：同一 Flutter Web 站点以 `/game/` 子路径托管完整单文件 H5 游戏（保持「免费、免下载、零依赖」），Flutter 首页底部有「▶ 开始游戏」入口；不重写 Canvas 物理引擎
- 实测：`/game/` 空格开局 → 投放 → x1.5 结算 38 CR；`?q=最高倍率是多少` 调用 `gemini-3.5-flash-lite` 返回 200，答案为「游戏中的最高倍率是 x12，位于最左侧和最右侧的倍率槽。」，控制台 0 错误
- 该站点单独放宽 CSP 以允许 Wasm（`'wasm-unsafe-eval'`）、`fonts.gstatic.com` 与 Gemini 端点；主游戏与 Web 助手的 CSP 不受影响
- 页面同样 `noindex`，不进入 sitemap，不参与主站评分
- 真实 `firebase_options.dart` 仅在构建目录；仓库中 `flutter_app/lib/firebase_options.dart` 为占位模板

构建与部署命令见 `flutter_app/README.md`。

#### Analytics（Google Analytics for Firebase）

按 [`firebase/quickstart-flutter` → `analytics/`](https://github.com/firebase/quickstart-flutter/tree/main/analytics) 的 `logEvent` / `setUserProperty` / `setAnalyticsCollectionEnabled` 用法，在 Flutter Web 应用埋入 `app_open`、`screen_view`、`ask_ai`、`ai_response` 与用户属性 `plinko_client=flutter_web`。

- **项目尚未启用 Google Analytics**：`firebase apps:sdkconfig WEB <appId>` 返回 `measurementId` 为空，Firebase 项目 `resources` 中无 `analyticsAccount` / `analyticsProperty`。
- 因此 `AnalyticsService` 优雅降级：`measurementId` 为空时跳过 `FirebaseAnalytics.instance` 初始化，**不发起任何第三方统计请求**；实测 `google-analytics` / `googletagmanager` 请求数均为 0，AI 助手仍返回 200、控制台 0 错误。
- `firebase.json` 已预先在 CSP 放行 `www.google-analytics.com`、`*.google-analytics.com`、`*.analytics.google.com`、`www.googletagmanager.com`；启用 GA 后只需把生成的 `measurementId` 填入 `flutter_app/lib/firebase_options.dart` 并重新构建，无需改业务逻辑。
- **主游戏 `index.html` 不接入 Analytics**（保持无统计脚本、`connect-src 'self'`、Lighthouse 100）。
- 同时移除了 Flutter 端已弃用的 `temperature` 参数，与官方及 JS 版实现对齐。

#### Authentication（Firebase Auth）

按 [`firebase/quickstart-flutter` → `authentication/`](https://github.com/firebase/quickstart-flutter/tree/main/authentication) 的 `authStateChanges()` / `signInAnonymously()` / `User.uid`，在 Flutter Web 应用加入 `firebase_auth ^7.0.1` 与匿名登录（官方示例为 Email/Password + `firebase_ui_auth`，此处选用无需注册的匿名方式）。

- 新增 `AuthService`：订阅 `authStateChanges()`、提供「匿名登录」/「退出登录」按钮、登录后把 uid 写入 Analytics `setUserId` 并埋 `login` 事件。
- 复验修正：`identitytoolkit admin/v2` 返回 `404 CONFIGURATION_NOT_FOUND` 只表示未启用 Identity Platform (GCIP)，**不代表经典 Firebase Auth 未启用**；线上 `accounts:signUp` 返回 200，Anonymous provider 实际可用，「匿名登录」按钮可成功拿到 uid。代码仍保留 `operation-not-allowed` 的降级分支以适配其它项目。
- `firebase.json` CSP 已预放行 `identitytoolkit.googleapis.com` / `securetoken.googleapis.com`，并增加 `frame-src` 允许 Auth 隐藏 iframe。
- 主游戏 `index.html` 不接入 Auth，保持零第三方请求与 Lighthouse 100。

#### Cloud Firestore

按 [`firebase/quickstart-flutter` → `firestore/`](https://github.com/firebase/quickstart-flutter/tree/main/firestore)（Friendly Eats）的 `collection().add()` + `snapshots()` + `StreamBuilder` 用法，在 Flutter Web 应用加入 `cloud_firestore ^7.1.0`：

- `FirestoreService` 把每次 AI 问答写入 `neon_plinko_ai_logs`（问题/回答/模型/source/时间/客户端），并展示最近 5 条提问
- 新增 `flutter_app/firestore.rules`（默认拒绝，仅该集合允许已登录用户 read/create）与 `flutter_app/firestore.indexes.json`（空索引）
- **项目尚未启用 Firestore**：`firestore.googleapis.com` 为 `DISABLED`，无数据库；Anonymous Auth provider 经复验已可用。因此用构建期开关 `FIRESTORE_ENABLED` 默认关闭：不实例化 Firestore、Firestore 数据请求 0（仅 1 个 gstatic SDK 脚本）、AI 助手与控制台不受影响；在 Firebase 控制台启用 Firestore API 并创建 `(default)` 数据库后，用 `--dart-define=FIRESTORE_ENABLED=true` 重新构建并 `firebase deploy --only firestore:rules` 即可开启
- **实时聊天面板（FriendlyChat）**：原 `flutter/friendlychat-flutter` 已 404，迁移至 `flutter/codelabs` → `firebase-get-to-know-flutter`（BSD-3-Clause）。在 Flutter Web 应用新增匿名用户实时聊天：`FirestoreService.chatStream()` 用 `orderBy('createdAt').snapshots()` + `StreamBuilder` 实时展示 `neon_plinko_chat`，开启 `FIRESTORE_ENABLED` 时启用 `Settings(persistenceEnabled: true)` 离线缓存（对齐 FriendlyChat 的 Offline 特性）；`firestore.rules` 同步新增该集合的 read/create 规则。默认构建 0 聊天请求
- **Realtime Database（参考 Trovami）**：[Trovami](https://github.com/Samaritan1011001/Trovami) 是 Flutter+Firebase 实时位置分享 App，核心用 RTDB 实时同步；**仓库无 LICENSE（保留所有权利），不复制其代码**，改用官方 `firebase_database` SDK 自行实现许可证中立的实时共享计数器（全局「投注次数」，`onValue` 监听 + `ServerValue.increment` 原子自增）。新增 `flutter_app/database.rules.json` 与 `firebase.json` 的 `database` 配置、CSP 放行 `*.firebaseio.com`；构建期开关 `RTDB_ENABLED` 默认关闭（0 次 RTDB 请求）。开启前需在控制台创建 RTDB 实例并 `firebase deploy --only database`
- 默认/开启两种构建均已通过 `flutter analyze` 与生产编译校验
- `firebase.json` CSP 已显式放行 `firestore.googleapis.com`
- 主游戏 `index.html` 不接入 Firestore，最高纪录仍在 localStorage

#### Cloud Functions

按 [`firebase/quickstart-flutter` → `cloud_functions/`](https://github.com/firebase/quickstart-flutter/tree/main/cloud_functions)（官方 V1 `addMessage` callable）的 `httpsCallable(...).call()` 用法，在 Flutter Web 应用加入 `cloud_functions ^7.0.1`：

- `FunctionsService` 调用 callable `neonPlinkoRules` 返回游戏规格（倍率表/下注/目标/操作），UI 卡片展示；后端 `flutter_app/functions/index.js` 用当前 SDK 的 v2 `onCall` 等价实现（纯静态、无密钥、通过 `node --check`）
- `flutter_app/functions/package.json` + `firebase.json` 的 `functions` codebase 配置；CSP 放行 `*.cloudfunctions.net`
- **函数未部署到生产**：官方要求 Blaze 计费计划，而项目仍为 Spark、`cloudfunctions.googleapis.com` 为 DISABLED。用构建期开关 `FUNCTIONS_ENABLED` 默认关闭：0 次 Functions 请求、AI 助手与控制台不受影响；升级 Blaze 后 `firebase deploy --only functions` 并用 `--dart-define=FUNCTIONS_ENABLED=true` 重新构建即可开启
- 关/开两种构建均通过 `flutter analyze` 与生产编译；本地可先用 `firebase emulators:start --only functions` 验证（不需要 Blaze）
- 主游戏 `index.html` 不接入 Cloud Functions

### Unity（Firebase AI Logic 快速入门）

依据 [`firebase/quickstart-unity`](https://github.com/firebase/quickstart-unity)（`master` 分支的 `firebaseai/testapp/`）新增 `unity_app/` C# 源码示例：

- 核心脚本 `unity_app/Assets/Scripts/NeonPlinkoAIHandler.cs`：`FirebaseAI.GetInstance(FirebaseAI.Backend.GoogleAI(), useLimitedUseAppCheckTokens: true)` → `GetGenerativeModel(...)` → `GenerateContentAsync(...)`，与 Web / Flutter 助手使用同一套系统提示词与模型回退
- 与 Flutter 仓库不同，这个 quickstart **确实包含** `firebaseai/` 官方示例（`UIHandler.cs` 默认模型 `gemini-3.1-flash-lite`，可切换 Google AI / Agent Platform 后端）
- **未构建、未部署**：当前环境无 Unity Editor / Firebase Unity SDK；且官方 Firebase Unity SDK 只支持 Android / iOS / tvOS / 桌面（桌面仅开发用），**WebGL 不受官方支持**（[issue #566](https://github.com/firebase/firebase-unity-sdk/issues/566)），因此没有 Unity WebGL 静态托管产物
- 浏览器端仍使用已上线的 Web 助手与 Flutter Web 助手；`unity_app/` 仅作为 Unity 客户端接入参考同步到代码仓库
- 接入步骤、平台矩阵与 App Check 配置见 `unity_app/README.md`

### React / Vite（Firebase AI Logic JS 快速入门）

依据 [`firebase/quickstart-js`](https://github.com/firebase/quickstart-js)（`master` 分支的 `ai/ai-samples/` 与 `ai-react-app/`）新建独立 Web 应用：

- 站点：https://neon-plinko-js.web.app/ ，深链 `?q=最高倍率是多少`
- Firebase 项目 `boto3-firebase-1101012838` · Hosting 站点 `neon-plinko-js` · deploy target `js`
- 源码 `js_app/`：React 19 + TypeScript + Vite 6 + npm `firebase ^13`；`src/firebaseAIService.ts` 对齐官方 `service.ts`（`initializeApp` → `getAI(app)` → `getGenerativeModel`）
- 配置通过 `VITE_FIREBASE_CONFIG` 在构建期注入，源码与仓库均不含真实项目标识；`.env.example` 只有占位符
- 不传 `temperature` / `topP` / `topK`（官方注明 Gemini 3.x 已弃用）；模型回退与 Web / Flutter 助手一致，35 秒超时
- App Check 按官方 `ReCaptchaEnterpriseProvider` 以注释骨架保留，未强制启用（无有效 site key 会拒绝全部客户端请求）
- 实测：`?q=最高倍率是多少` 调用 `gemini-3.5-flash-lite` 返回 200，页面显示「最高倍率是 x12。」，控制台 0 错误
- 站点 `noindex`，CSP 单独配置（Gemini 端点、字体、同站哈希资源），主站与其它镜像不受影响
- 构建与部署命令见 `js_app/README.md`

### 代码托管镜像

同一份源码已同步到三个公开仓库，均为零构建静态站点：

| 平台 | 仓库 | 默认分支 |
|---|---|---|
| GitHub | https://github.com/vip-81/neon-plinko | `main` |
| Gitee | https://gitee.com/vip882/neon-plinko | `master` |
| AtomGit | https://atomgit.com/zzw1208/neon-plinko | `main` |

- 三个仓库仅用于源码分发与备份；线上生产仍以 Cloudflare Pages 为 canonical。
- `.nojekyll` 为平台标记文件，内容为一个换行符，便于 Gitee / AtomGit 正确写入空标记文件。
- 更新任一仓库后，其他两个仓库需手动同步同一批文件；操作凭据使用环境变量或平台 Secrets，勿写入项目文件。

## 本地预览

任选一种静态服务器（不要直接双击 `index.html`）：

```bash
# Node.js
npx serve .

# Python 3
python -m http.server 8080

# PHP
php -S localhost:8080
```

打开 `http://localhost:8080/`。开发时可加 `?debug=1` 使用调试接口：

```js
window.__NEON_PLINKO_DEBUG__.snapshot()
window.__NEON_PLINKO_DEBUG__.start()
window.__NEON_PLINKO_DEBUG__.drop()
window.__NEON_PLINKO_DEBUG__.setBalance(5000)
window.__NEON_PLINKO_DEBUG__.finish(true)
```

正式发布若不需要调试入口，可删除 `index.html` 中 `__NEON_PLINKO_DEBUG__` 相关代码。

## SEO / GEO 实现

- 语义化 `header` / `main` / `section` / `footer`，单一 H1，完整 H2/H3 层级。
- Title、Description、Keywords、Canonical、Robots、Theme Color。
- Open Graph：类型、站点名、语言、标题、描述、URL、绝对图片、图片尺寸与 alt。
- Twitter Card：`summary_large_image`、标题、描述、绝对图片与 alt。
- JSON-LD：`WebSite` + `WebPage` + `VideoGame` + `FAQPage`。
- 页面内包含一句话摘要、游戏规格、玩法步骤、倍率表、技术特性与 FAQ，便于搜索引擎和生成式引擎提取。
- `llms.txt` 提供可直接引用的游戏事实、规则、倍率与 FAQ，并注明引用来源。
- `sitemap.xml` 与 `robots.txt` 已指向正式域名。
- Google Search Console：已通过 API 创建 URL-prefix 资源 `https://neon-plinko.pages.dev/`；因所有权尚未验证，sitemap 提交返回 403。需在 GSC 完成验证（HTML 文件 / DNS / meta 标签）后重新提交 `sitemap.xml`。
- AI 助手页为 `noindex` 辅助页，不进入 sitemap，也不作为生成式引擎的引用来源；GEO 仍以主页语义化内容、JSON-LD、FAQ 与 `llms.txt` 为准。

### 绑定自定义域名后

如果以后绑定新域名，请全局替换以下文件中的 `https://neon-plinko.pages.dev/`：

- `index.html`（canonical、OG、Twitter、JSON-LD）
- `sitemap.xml`
- `robots.txt`
- `llms.txt`

然后在 Cloudflare Pages 的 **Custom domains** 中添加域名并开启 HTTPS。建议同时在 Google Search Console / Bing Webmaster Tools 提交新的 sitemap。

## 性能与可访问性

- Lighthouse 本地桌面测试：Accessibility / Best Practices / SEO 均为 100，0 项失败。
- Firebase Hosting 生产 URL 复测：Accessibility / Best Practices / SEO 均为 100，0 项失败。
- 页面无外部字体、图片、统计或第三方脚本请求。
- `index.html` 约 132 KB；`og-cover.png` 约 0.8 MB。
- 支持键盘（方向键、空格、M）与触屏/指针操作，带 `aria-live` 状态播报。
- 支持 `prefers-reduced-motion` 与高对比度模式。
- 已在约 800 × 654 的矮屏桌面、375 px 与 320 px 宽移动布局下检查。
- 上线后仍建议在真实 iOS Safari、Android Chrome 和桌面 Firefox 上各测一局。

## 安全提示（重要）

- 项目文件不包含任何 Cloudflare、GitHub、Gitee、AtomGit、Google 或 itch.io 密钥；Firebase Web 配置只提供 `firebase-config.example.js` 模板，真实 `firebase-config.js` 只在部署目录生成。
- Firebase Web API Key 是公开的项目标识而非私密凭据，已通过 Google API Keys API 限制为仅允许指定域名；请勿把 Gemini API Key 写进前端。
- `unity_app/.gitignore` 已排除 `google-services.json`、`GoogleService-Info.plist` 与 App Check debug token；源码中均为占位符。
- `js_app/` 使用 `VITE_FIREBASE_CONFIG` 构建期注入，`.gitignore` 排除 `.env*`；仓库内无任何真实 Firebase 配置。
- 本次部署使用的凭据仅通过命令环境传递，没有写入 `index.html`、README、Git 或静态资源；Google ADC 凭据保存在用户目录 `%APPDATA%\gcloud\application_default_credentials.json`，属于本机登录态，不在项目目录内。
- 你在对话中提供的 **Cloudflare API Token、R2 Access Key / Secret Key、itch.io API Key、两个 GitHub Token、Gitee Token、AtomGit Token 均已出现在聊天记录中，请立即撤销并重新生成**。尤其是 R2 Secret Access Key、Cloudflare API Token 与 classic GitHub Token，应视为已泄露。
- 后续更新时，使用环境变量或平台 Secrets 管理，不要把密钥粘贴到对话或提交到仓库。

## 说明

页面中的品牌、文案与玩法为原创演示内容；游戏筹码仅为娱乐数值，不涉及真实货币投注。
