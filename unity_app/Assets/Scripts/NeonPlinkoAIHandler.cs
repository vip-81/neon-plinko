// Adapted from firebase/quickstart-unity (firebaseai/testapp/Assets/Firebase/Sample/FirebaseAI/UIHandler.cs)
// Original copyright 2025 Google Inc., licensed under Apache License 2.0.
// NEON PLINKO 专用改写：限定游戏规则问答、稳定模型回退、超时保护。
//
// 用法：把本脚本挂到场景中任意 GameObject，订阅 OnStatusChanged / OnAnswer / OnError，
//       或直接从 UI 按钮调用 Ask(question)。运行前请完成 README 中的 Firebase 配置。

namespace NeonPlinko
{
  using Firebase;
  using Firebase.AI;
  using Firebase.AppCheck;
  using Firebase.Extensions;
  using System;
  using System.Collections.Generic;
  using System.Threading.Tasks;
  using UnityEngine;

  [AddComponentMenu("NEON PLINKO/Firebase AI Logic Handler")]
  public sealed class NeonPlinkoAIHandler : MonoBehaviour
  {
    [Header("Gemini 模型")]
    [SerializeField] private string primaryModel = "gemini-3.5-flash-lite";
    [SerializeField] private string[] fallbackModels =
    {
      "gemini-3.6-flash",
      "gemini-3.5-flash"
    };
    [SerializeField] private int maxOutputTokens = 300;
    [SerializeField] private int timeoutMs = 35000;

    [Header("App Check（仅开发期使用 Debug Provider）")]
    [SerializeField] private bool useDebugAppCheckProvider = true;
    [SerializeField] private string appCheckDebugToken = "REPLACE_WITH_APP_CHECK_DEBUG_TOKEN";

    public event Action<string> OnStatusChanged;
    public event Action<string> OnAnswer;
    public event Action<string> OnError;

    private FirebaseAI ai;
    private bool firebaseReady;

    // 与 Web / Flutter 助手完全一致的规则边界，便于 GEO 与多端行为统一。
    private const string SystemInstruction =
      "你是「NEON PLINKO 霓虹弹珠」的官方规则助手。只回答与这个游戏相关的问题，包括：" +
      "玩法步骤、9 个倍率槽（x12 / x4 / x1.5 / x0.5 / x0.25 / x0.5 / x1.5 / x4 / x12）、" +
      "下注档位（10 / 25 / 50 / 100 / 250 CR）、初始 1,000 CR、目标 10,000 CR、" +
      "键盘与触屏操作、最高纪录保存在浏览器 localStorage、纯娱乐且无真实货币投注。" +
      "请用简体中文、简短、纯文本回答，不要使用 Markdown，不要编造未提供的信息。" +
      "如果问题与游戏无关，请礼貌拒答并引导用户回到游戏。";

    private void Start()
    {
      ConfigureAppCheck();
      FirebaseApp.CheckAndFixDependenciesAsync().ContinueWithOnMainThread(task =>
      {
        DependencyStatus status = task.Result;
        if (status != DependencyStatus.Available)
        {
          Debug.LogError("Firebase 依赖未就绪: " + status);
          OnStatusChanged?.Invoke("Firebase 初始化失败：" + status);
          return;
        }

        // GoogleAIBackend = Gemini Developer API（Spark 免费方案可用，无需 Blaze）。
        // limited-use App Check token 固定 5 分钟 TTL，不缓存。
        ai = FirebaseAI.GetInstance(
          FirebaseAI.Backend.GoogleAI(),
          useLimitedUseAppCheckTokens: true);

        firebaseReady = true;
        OnStatusChanged?.Invoke("已连接，请输入问题。");
      });
    }

    private void ConfigureAppCheck()
    {
      if (!useDebugAppCheckProvider)
      {
        // 正式发布：在调用任何其它 Firebase SDK 之前设置平台 provider，例如
        // FirebaseAppCheck.SetAppCheckProviderFactory(PlayIntegrityProviderFactory.Instance);   // Android
        // FirebaseAppCheck.SetAppCheckProviderFactory(DeviceCheckProviderFactory.Instance);     // iOS
        return;
      }

      DebugAppCheckProviderFactory.Instance.SetDebugToken(appCheckDebugToken);
      FirebaseAppCheck.SetAppCheckProviderFactory(DebugAppCheckProviderFactory.Instance);
    }

    /// <summary>
    /// 向 Gemini 提问并返回纯文本答案；按顺序尝试模型列表，任一成功即返回。
    /// </summary>
    public async Task<string> AskAsync(string question)
    {
      if (!firebaseReady || ai == null)
      {
        throw new InvalidOperationException("Firebase 尚未就绪，请等待 CheckAndFixDependenciesAsync 完成。");
      }
      if (string.IsNullOrWhiteSpace(question))
      {
        throw new ArgumentException("问题不能为空。", nameof(question));
      }

      List<string> models = new List<string> { primaryModel };
      models.AddRange(fallbackModels);
      string lastError = "";

      foreach (string modelName in models)
      {
        try
        {
          GenerativeModel model = ai.GetGenerativeModel(
            modelName: modelName,
            generationConfig: new GenerationConfig(maxOutputTokens: maxOutputTokens),
            systemInstruction: ModelContent.Text(SystemInstruction));

          Task<GenerateContentResponse> pending = model.GenerateContentAsync(question.Trim());
          Task winner = await Task.WhenAny(pending, Task.Delay(timeoutMs));
          if (winner != pending)
          {
            throw new TimeoutException("请求超时（" + timeoutMs + " ms），模型：" + modelName);
          }

          GenerateContentResponse response = await pending;
          string text = (response.Text ?? "").Trim();
          return text.Length == 0 ? "（AI 返回了空内容，请重试）" : text;
        }
        catch (Exception e)
        {
          lastError = e.Message;
          Debug.LogWarning("模型 " + modelName + " 调用失败，尝试下一个：" + lastError);
        }
      }

      throw new Exception(
        "已尝试全部模型仍无法连接 AI 助手。可能是模型高负载、App Check 未配置、" +
        "API 未启用或额度不足。\n最后错误：" + lastError);
    }

    /// <summary>供 Unity UI 按钮直接调用的 fire-and-forget 包装。</summary>
    public async void Ask(string question)
    {
      OnStatusChanged?.Invoke("正在连接 Gemini，请稍候…");
      try
      {
        string answer = await AskAsync(question);
        OnAnswer?.Invoke(answer);
        OnStatusChanged?.Invoke("回答完成。");
      }
      catch (Exception e)
      {
        OnError?.Invoke(e.Message);
        OnStatusChanged?.Invoke("请求失败。");
      }
    }
  }
}
