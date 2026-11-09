# NEON PLINKO · Flutter Web AI 助手

独立 Flutter Web 应用，使用 **Firebase AI Logic**（`firebase_ai` + `firebase_core`）调用 Gemini，提供与 H5 主页相同的 NEON PLINKO 规则问答；并按官方 Analytics quickstart 接入 `firebase_analytics` 事件埋点。

- 生产地址：https://neon-plinko-flutter.web.app/
- 深链示例：`https://neon-plinko-flutter.web.app/?q=最高倍率是多少`
- Firebase 项目：`boto3-firebase-1101012838`
- Hosting 站点：`neon-plinko-flutter`
- 依赖：`firebase_core ^5.1.0`、`firebase_ai ^5.1.0`、`firebase_analytics ^13.0.1`、`firebase_auth ^7.0.1`、Flutter 3.47.9 / Dart 3.13.7

> 主游戏仍是 `../index.html` 的零依赖单文件静态站；本目录只是额外的 Flutter 客户端示例，不参与主站 SEO/GEO/Lighthouse 评分。

## 本地构建

1. 把 `lib/firebase_options.dart` 中的占位值替换为 `firebase apps:sdkconfig WEB <appId>` 输出：
   ```bash
   firebase apps:sdkconfig WEB 1:909891373707:web:93ea70d7a2a1fe5ac6a28e
   ```
2. 安装依赖并构建：
   ```bash
   flutter pub get
   flutter analyze
   flutter build web --release --base-href '/' --no-wasm-dry-run
   ```
3. 本目录的 `firebase.json` 已配置 Flutter Web 所需的 CSP（`wasm-unsafe-eval`、`fonts.gstatic.com`、Gemini 端点、Analytics 端点）与缓存策略。

## 游戏本体（/game/）

Flutter Web 站点同时承载完整的 NEON PLINKO 单文件 H5 游戏：`https://neon-plinko-flutter.web.app/game/`。

- 构建后把仓库根目录的 `index.html`、`og-cover.png` 复制到发布目录的 `game/` 子目录即可（游戏全为 inline CSS/JS + `data:` favicon，无外部请求）。
- `web/index.html` 底部的 `<a id="neon-game-launcher" href="/game/">` 是 Flutter 首页的「开始游戏」入口。
- `firebase.json` 已为 `/game/` 与 `/game/**` 配置缓存，并在 CSP 的 `img-src` 放行 `https://neon-plinko.pages.dev`。
- 游戏保持「免费、免下载、零依赖、单文件 H5」定位，未用 Dart 重写物理引擎。

## Analytics（Google Analytics for Firebase）

对齐官方 [`firebase/quickstart-flutter` → `analytics/`](https://github.com/firebase/quickstart-flutter/tree/main/analytics) 的 `logEvent` / `setUserProperty` / `setAnalyticsCollectionEnabled` 用法。

`lib/main.dart` 中的 `AnalyticsService` 埋点：

| 事件 / 属性 | 触发 |
|---|---|
| `app_open` | 应用启动（参数 `platform=flutter_web`） |
| `screen_view`（`ai_assistant`） | 应用启动 |
| `ask_ai` | 提交问题（参数 `source=input\|suggestion\|deeplink`、`question_length`） |
| `ai_response` | 回答完成 / 失败（参数 `status=ok\|error`、`model`） |
| user property `plinko_client` | 固定值 `flutter_web` |

### measurementId 前提（重要）

Firebase Web 端 Analytics 需要 `measurementId`（形如 `G-XXXXXXXXXX`），它在 **Firebase 项目启用 Google Analytics 并注册 Web App 后**才会生成。当前项目 `boto3-firebase-1101012838` 尚未启用 GA，`firebase apps:sdkconfig` 返回 `measurementId` 为空。

因此 `AnalyticsService` 采用优雅降级：

- `measurementId` 为空 → **跳过** `FirebaseAnalytics.instance` 初始化，不发起任何第三方统计请求，站点 CSP 与现有行为完全不变；
- 在 Firebase 控制台启用 Google Analytics 后，重新运行 `firebase apps:sdkconfig WEB <appId>`，把生成的 `measurementId` 填入 `lib/firebase_options.dart`，重新构建即可自动开始上报，无需改业务逻辑。

`firebase.json` 的 CSP 已预先放行 `www.google-analytics.com`、`*.google-analytics.com`、`*.analytics.google.com`、`www.googletagmanager.com`，启用后无需再改部署配置。

> 主游戏 `../index.html` 明确无统计脚本、CSP `connect-src 'self'`，**不接入 Analytics**，以保持零第三方请求与 Lighthouse 100。

## Authentication（Firebase Auth）

对齐官方 [`firebase/quickstart-flutter` → `authentication/`](https://github.com/firebase/quickstart-flutter/tree/main/authentication) 的 `authStateChanges()` / `signInAnonymously()` / `User.uid` 用法；官方示例用 Email/Password + `firebase_ui_auth`，本助手改用**匿名登录**（无需注册、无需输入信息，更适合纯娱乐规则问答）。

`lib/main.dart` 中的 `AuthService`：

- 启动时订阅 `authStateChanges()`，UI 显示匿名 uid 前 8 位
- 提供「匿名登录」按钮，默认不自动请求，登录后把 uid 写入 Analytics `setUserId` 并埋 `login` 事件
- 提供「退出登录」按钮

### 登录提供方前提（重要）

Firebase 项目 `boto3-firebase-1101012838` **尚未启用 Firebase Authentication**：`identitytoolkit.googleapis.com/admin/v2/projects/.../config` 返回 `404 CONFIGURATION_NOT_FOUND`，也没有任何 sign-in provider。

因此采用优雅降级：

- 默认不发起登录请求，页面加载仍是 0 第三方请求、0 控制台错误，AI 助手照常工作；
- 点击「匿名登录」若返回 `operation-not-allowed`（provider 未启用），捕获 `FirebaseAuthException` 并显示「项目尚未启用 Anonymous 登录提供方；AI 助手仍可正常使用。」
- 在 Firebase 控制台 → Authentication → Sign-in method 启用 **Anonymous** 后，重新打开页面点击即可成功，无需改代码。

`firebase.json` 的 CSP 已预先放行 `identitytoolkit.googleapis.com`、`securetoken.googleapis.com`、`apis.google.com`，并增加 `frame-src` 允许 Firebase Auth 的隐藏 iframe（`*.firebaseapp.com` / `*.web.app` / `accounts.google.com`）。

> 主游戏 `../index.html` **不接入 Auth**（保持零第三方请求与 Lighthouse 100）。

## 部署

```bash
firebase target:apply hosting flutter neon-plinko-flutter --project boto3-firebase-1101012838
firebase deploy --only hosting:flutter --project boto3-firebase-1101012838
```

部署前把 `build/web` 内容复制到含 `firebase.json` 的发布目录；真实 `firebase_options.dart` 只保留在构建机，不提交到公开仓库。

**避免旧版 JS 缓存**：Flutter Web 的 `main.dart.js` 文件名不带内容哈希，`firebase.json` 已对 `main.dart.js` / `flutter_bootstrap.js` / `flutter.js` / `version.json` 设置 `no-cache, must-revalidate`。此外每次部署需把生成的 `flutter_bootstrap.js` 中

```js
"mainJsPath":"main.dart.js"
```

改为 `"mainJsPath":"main.dart.js?v=<serviceWorkerVersion>"`（`serviceWorkerVersion` 就在同一文件末尾）。这样浏览器会按构建版本请求新 JS，不会命中上一版缓存。

## 模型回退

`gemini-3.5-flash-lite` → `gemini-3.6-flash` → `gemini-3.5-flash`，单次请求 35 秒超时。`gemini-3.8-flash` 在 2026-11 实测持续高负载，故不作为首选；`temperature` 等 Gemini 3.x 已弃用参数不再传递。
