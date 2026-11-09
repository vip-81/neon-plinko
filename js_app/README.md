# NEON PLINKO · React / Vite AI 助手（Firebase AI Logic JS SDK）

按官方 [`firebase/quickstart-js`](https://github.com/firebase/quickstart-js) 的 `ai/ai-samples/src/services/firebaseAIService.ts` 结构改写的独立 Web 应用。

- 生产地址：https://neon-plinko-js.web.app/
- 深链示例：`https://neon-plinko-js.web.app/?q=最高倍率是多少`
- Firebase 项目：`boto3-firebase-1101012838` · Hosting 站点：`neon-plinko-js` · deploy target：`js`
- 技术：React 19 + TypeScript + Vite 6 + `firebase ^13`（npm 模块化 SDK，非 CDN）

> 主游戏仍是 `../index.html` 的零依赖单文件 H5；本目录是额外的 Web 客户端示例，`noindex`，不参与主站 SEO/GEO/Lighthouse 评分。

## 与官方 quickstart 的对应关系

| 官方 | 本示例 |
|---|---|
| `ai/ai-samples/src/services/firebaseAIService.ts` | `src/firebaseAIService.ts` |
| `VITE_FIREBASE_CONFIG` 注入配置 | `src/firebase-config.ts` 同样用 `import.meta.env.VITE_FIREBASE_CONFIG` |
| `getAI(app)` + `getGenerativeModel(ai, { model })` | 一致 |
| 默认 `gemini-3.5-flash-lite` | 一致，另加 `gemini-3.6-flash` / `gemini-3.5-flash` 回退与 35s 超时 |
| `initializeAppCheck(app, { provider: new ReCaptchaEnterpriseProvider(...) })` | 以注释骨架保留；**未强制启用**（无有效 site key 时会导致线上失效） |

官方明确：`temperature` / `topP` / `topK` 对 Gemini 3.x 已弃用，故本示例不传这些参数。

## 本地开发

```bash
cp .env.example .env.local   # 填入 firebase apps:sdkconfig WEB <appId> 的 JSON
npm install
npm run dev
```

## 构建与部署

配置通过环境变量注入，源码中不含任何真实项目标识：

```bash
$env:VITE_FIREBASE_CONFIG = '{"apiKey":"...","authDomain":"...","projectId":"...","appId":"...","messagingSenderId":"...","storageBucket":"..."}'
npm run build

firebase target:apply hosting js neon-plinko-js --project boto3-firebase-1101012838
firebase deploy --only hosting:js --project boto3-firebase-1101012838
```

`firebase.json` 已配置 React/Vite 产物所需的 CSP（Gemini 端点、字体、同站哈希资源）与缓存策略。

## App Check（生产建议）

官方 quickstart 使用 `ReCaptchaEnterpriseProvider`。启用前需：

1. 在 Firebase 控制台创建 reCAPTCHA Enterprise site key；
2. 取消 `src/firebaseAIService.ts` 中 `initializeAppCheck(...)` 的注释并填入 `VITE_RECAPTCHA_SITE_KEY`；
3. 在 Firebase 控制台为 AI Logic 开启强制校验。

未提供有效 site key 时请勿启用，否则所有客户端请求会被拒绝。

## 安全

- `.gitignore` 排除 `node_modules/`、`dist/`、`.env*`。
- `.env.example` 只有占位符；真实配置仅在构建期通过环境变量提供。
- Firebase Web API Key 是公开项目标识，已通过 Google API Keys API 限制为仅允许指定域名。
