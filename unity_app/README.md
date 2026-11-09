# NEON PLINKO · Firebase AI Logic（Unity C# 源码示例）

按官方快速入门 [`firebase/quickstart-unity`](https://github.com/firebase/quickstart-unity) 的 `firebaseai/testapp/` 示例改写的 **NEON PLINKO 规则助手** C# 实现。

> 本目录**仅提供源码与接入说明**：当前环境没有 Unity Editor / Firebase Unity SDK，未构建、未部署任何 Unity 产物。
> NEON PLINKO 线上主游戏仍是单文件 H5（`../index.html`），可玩版本见 https://neon-plinko-flutter.web.app/game/ 。

## 官方示例位置

- 仓库默认分支：`master`
- 示例工程：`firebaseai/testapp/`
- 关键脚本：`firebaseai/testapp/Assets/Firebase/Sample/FirebaseAI/UIHandler.cs`
- 该示例中的真实调用：
  ```csharp
  var backend = FirebaseAI.Backend.GoogleAI();
  var model = FirebaseAI.GetInstance(backend, useLimitedUseAppCheckTokens: true)
                        .GetGenerativeModel(ModelName);
  var response = await model.GenerateContentAsync(message);
  UnityEngine.Debug.Log(response.Text);
  ```

## 本示例做了什么

`Assets/Scripts/NeonPlinkoAIHandler.cs` 是一个 `MonoBehaviour`：

- 用 `FirebaseAI.Backend.GoogleAI()`（Gemini Developer API，Spark 免费方案可用，无需 Blaze）
- 通过 `ModelContent.Text(...)` 设置系统提示词，限定只回答 NEON PLINKO 玩法 / 倍率 / 下注 / 操作 / 安全说明，并拒答无关问题
- 模型按顺序回退：`gemini-3.5-flash-lite` → `gemini-3.6-flash` → `gemini-3.5-flash`（2026-11 实测稳定；`gemini-3.8-flash` 当时持续高负载）
- `GenerationConfig(maxOutputTokens: 300)` 控制回答长度；最新 Gemini 3.x/4.x 模型已不支持 `temperature` / `topK` / `topP`，故不设置
- `Task.WhenAny` + `Task.Delay(35000)` 实现 35 秒超时保护
- 暴露 `OnStatusChanged` / `OnAnswer` / `OnError` 事件与 `Ask(question)` 包装，便于绑定 UI

## 环境要求

| 项 | 要求 |
|---|---|
| Unity | 官方示例要求 2021.3+；Firebase Unity SDK 建议 2022 LTS+ |
| Firebase Unity SDK | 从 https://firebase.google.com/download/unity 下载（需 `FirebaseAI` + `FirebaseAppCheck` + `FirebaseApp` / External Dependency Manager） |
| Android | Android SDK / NDK（Play Integrity 作为 App Check provider） |
| iOS | Xcode 16.2+（Device Check / App Attest） |
| 配置文件 | Android `google-services.json`、iOS `GoogleService-Info.plist`、桌面 `google-services-desktop.json` |

## 接入步骤

1. 在 Firebase 控制台为项目 `boto3-firebase-1101012838` 注册 **Android / iOS / 桌面** 应用（注意：不是 Web 应用），下载对应配置文件放进 `Assets/`。
2. 导入 Firebase Unity SDK 的 `.unitypackage`（至少 `FirebaseApp`、`FirebaseAI`、`FirebaseAppCheck`）。
3. 启用 `generativelanguage.googleapis.com` 与 `firebasevertexai.googleapis.com`，并完成 AI Logic provisioning（否则报 `genai config not found`）。
4. 把 `NeonPlinkoAIHandler.cs` 挂到场景 GameObject；订阅事件或让按钮调用 `Ask(question)`。
5. 开发期在 Inspector 填 `appCheckDebugToken`；正式发布改用 `PlayIntegrityProviderFactory` / `DeviceCheckProviderFactory`，并关闭 Debug Provider。
6. 在 Unity Editor 中 `File > Build Settings` 选择 Android / iOS / 桌面目标运行。

## 平台限制（重要）

Firebase Unity SDK 官方支持矩阵为 **Android / iOS / tvOS / 桌面（beta，仅开发用途）**；**WebGL 不在官方支持列表**（[firebase-unity-sdk issue #566](https://github.com/firebase/firebase-unity-sdk/issues/566) 仍是未关闭的 feature request）。社区方案需借助第三方 JS 桥接（如 `FirebaseWebGL`），不属于官方路径。

因此本示例**没有**构建 Unity WebGL、也没有部署到静态托管；如需浏览器端 AI 助手，请使用已上线的：

- Web 版：https://neon-plinko-20261110.web.app/ai
- Flutter Web 版：https://neon-plinko-flutter.web.app/

## 安全说明

- 本目录**不包含**任何真实 `google-services.json` / `GoogleService-Info.plist` / App Check debug token。
- `.gitignore` 已排除 Unity 生成目录与 Firebase 配置文件，避免误提交凭据。
- `appCheckDebugToken` 字段为占位符，仅用于本地开发；生产环境不要硬编码 token。
