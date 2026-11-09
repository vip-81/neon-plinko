# NEON PLINKO · Flutter Web AI 助手

独立 Flutter Web 应用，使用 **Firebase AI Logic**（`firebase_ai` + `firebase_core`）调用 Gemini，提供与 H5 主页相同的 NEON PLINKO 规则问答。

- 生产地址：https://neon-plinko-flutter.web.app/
- 深链示例：`https://neon-plinko-flutter.web.app/?q=最高倍率是多少`
- Firebase 项目：`boto3-firebase-1101012838`
- Hosting 站点：`neon-plinko-flutter`
- 依赖：`firebase_core ^5.1.0`、`firebase_ai ^5.1.0`、Flutter 3.47.9 / Dart 3.13.7

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
3. 本目录的 `firebase.json` 已配置 Flutter Web 所需的 CSP（`wasm-unsafe-eval`、`fonts.gstatic.com`、Gemini 端点）与缓存策略。

## 游戏本体（/game/）

Flutter Web 站点同时承载完整的 NEON PLINKO 单文件 H5 游戏：`https://neon-plinko-flutter.web.app/game/`。

- 构建后把仓库根目录的 `index.html`、`og-cover.png` 复制到发布目录的 `game/` 子目录即可（游戏全为 inline CSS/JS + `data:` favicon，无外部请求）。
- `web/index.html` 底部的 `<a id="neon-game-launcher" href="/game/">` 是 Flutter 首页的「开始游戏」入口。
- `firebase.json` 已为 `/game/` 与 `/game/**` 配置缓存，并在 CSP 的 `img-src` 放行 `https://neon-plinko.pages.dev`。
- 游戏保持「免费、免下载、零依赖、单文件 H5」定位，未用 Dart 重写物理引擎。

## 部署

```bash
firebase target:apply hosting flutter neon-plinko-flutter --project boto3-firebase-1101012838
firebase deploy --only hosting:flutter --project boto3-firebase-1101012838
```

部署前把 `build/web` 内容复制到含 `firebase.json` 的发布目录；真实 `firebase_options.dart` 只保留在构建机，不提交到公开仓库。

## 模型回退

`gemini-3.5-flash-lite` → `gemini-3.6-flash` → `gemini-3.5-flash`，单次请求 35 秒超时。`gemini-3.8-flash` 在 2026-11 实测持续高负载，故不作为首选。
