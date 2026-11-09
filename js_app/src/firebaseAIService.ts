// 对齐官方 firebase/quickstart-js → ai/ai-samples/src/services/firebaseAIService.ts
// 使用 npm `firebase ^13` 模块化 API；getAI(app) 默认即 Gemini Developer API。
import { initializeApp } from 'firebase/app';
import { getAI, getGenerativeModel } from 'firebase/ai';
import { firebaseConfig } from './firebase-config';

// 官方 App Check 骨架（本项目未强制启用，避免无 site key 时线上失效；见 README）：
// import { initializeAppCheck, ReCaptchaEnterpriseProvider } from 'firebase/app-check';
// initializeAppCheck(app, {
//   provider: new ReCaptchaEnterpriseProvider(import.meta.env.VITE_RECAPTCHA_SITE_KEY),
//   isTokenAutoRefreshEnabled: true
// });

const app = initializeApp(firebaseConfig);
const ai = getAI(app);

// 官方示例默认 gemini-3.5-flash-lite；后两个为 2026-11 实测可用的回退。
// 注意：Gemini 3.x 已弃用 temperature / topP / topK，故不再传这些参数。
export const MODELS = ['gemini-3.5-flash-lite', 'gemini-3.6-flash', 'gemini-3.5-flash'];

const SYSTEM_INSTRUCTION =
  '你是「NEON PLINKO 霓虹弹珠」的官方规则助手。只回答与这个游戏相关的问题，包括：' +
  '玩法步骤、9 个倍率槽（x12 / x4 / x1.5 / x0.5 / x0.25 / x0.5 / x1.5 / x4 / x12）、' +
  '下注档位（10 / 25 / 50 / 100 / 250 CR）、初始 1,000 CR、目标 10,000 CR、' +
  '键盘与触屏操作、最高纪录保存在浏览器 localStorage、纯娱乐且无真实货币投注。' +
  '请用简体中文、简短、纯文本回答，不要使用 Markdown，不要编造未提供的信息。' +
  '如果问题与游戏无关，请礼貌拒答并引导用户回到游戏。';

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout>;
  return Promise.race([
    promise,
    new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error('请求超时，请重试')), ms);
    })
  ]).finally(() => clearTimeout(timer));
}

/** 向 Gemini 提问，按模型列表回退，返回纯文本答案。 */
export async function askNeonPlinko(question: string): Promise<string> {
  const q = question.trim();
  if (!q) throw new Error('问题不能为空');

  let lastError = '';
  for (const modelName of MODELS) {
    try {
      const model = getGenerativeModel(ai, {
        model: modelName,
        generationConfig: { maxOutputTokens: 300 }
      });
      const result = await withTimeout(
        model.generateContent(SYSTEM_INSTRUCTION + '\n\n用户问题：' + q),
        35000
      );
      const text = (result.response.text() ?? '').trim();
      return text.length ? text : '（AI 返回了空内容，请重试）';
    } catch (e) {
      lastError = e instanceof Error ? e.message : String(e);
    }
  }

  throw new Error(
    '暂时无法连接 AI 助手。可能是模型临时高负载、App Check 未配置或免费额度不足；' +
      '已自动尝试多个稳定模型，请稍后重试。\n\n错误详情：' + lastError
  );
}
