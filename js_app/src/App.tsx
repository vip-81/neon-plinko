import { useEffect, useRef, useState } from 'react';
import { askNeonPlinko } from './firebaseAIService';

const SUGGESTIONS = [
  { label: '倍率表', q: 'NEON PLINKO 的 9 个倍率槽分别是什么？' },
  { label: '操作方式', q: '游戏怎么开始？键盘和手机分别怎么操作？' },
  { label: '下注与目标', q: '下注档位有哪些？初始筹码和胜利目标是多少？' },
  { label: '安全说明', q: '这个游戏涉及真实货币或充值吗？最高纪录保存在哪里？' }
];

const GAME_URL = 'https://neon-plinko-20261110.web.app/game/';

export default function App() {
  const [question, setQuestion] = useState('');
  const [answer, setAnswer] = useState('');
  const [status, setStatus] = useState('正在初始化…');
  const [busy, setBusy] = useState(false);
  const autoStarted = useRef(false);

  async function ask(q: string) {
    const text = q.trim();
    if (!text || busy) return;
    setBusy(true);
    setAnswer('');
    setStatus('正在连接 Gemini，请稍候…');
    try {
      const result = await askNeonPlinko(text);
      setAnswer(result);
      setStatus('回答完成。');
    } catch (e) {
      setAnswer(e instanceof Error ? e.message : String(e));
      setStatus('请求失败。');
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    setStatus('已连接，请输入问题。');
    const initial = new URLSearchParams(window.location.search).get('q');
    if (initial && !autoStarted.current) {
      autoStarted.current = true;
      setQuestion(initial);
      void ask(initial);
    }
  }, []);

  return (
    <div className="wrap">
      <header>
        <a className="brand" href={GAME_URL}>
          <b>NEON</b> PLINKO
        </a>
        <p className="kicker">FIREBASE AI LOGIC // REACT + VITE</p>
        <h1>AI <span>规则助手</span></h1>
        <p className="lede">
          只回答 NEON PLINKO 霓虹弹珠的玩法、倍率、下注、操作与规则问题。
          由 Firebase AI Logic JS SDK 调用 Gemini 生成，纯娱乐游戏，不涉及真实货币。
        </p>
      </header>

      <main>
        <section className="card" aria-labelledby="ask-title">
          <h2 id="ask-title">向 AI 提问</h2>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void ask(question);
            }}
          >
            <label htmlFor="question">你的问题</label>
            <textarea
              id="question"
              value={question}
              maxLength={500}
              disabled={busy}
              placeholder="例如：最高倍率是多少？怎么在手机上投放？"
              onChange={(e) => setQuestion(e.target.value)}
            />
            <div className="actions">
              <button className="primary" type="submit" disabled={busy}>
                {busy ? '思考中…' : '询问 AI 助手'}
              </button>
              <a className="ghost" href={GAME_URL}>开始游戏</a>
            </div>
          </form>

          <div className="chips" aria-label="推荐问题">
            {SUGGESTIONS.map((s) => (
              <button
                key={s.label}
                type="button"
                disabled={busy}
                onClick={() => {
                  setQuestion(s.q);
                  void ask(s.q);
                }}
              >
                {s.label}
              </button>
            ))}
          </div>

          <p className="status" role="status" aria-live="polite">{status}</p>
          {answer && <div className="answer" aria-live="polite">{answer}</div>}
          <p className="note">
            本页面会把你的问题发送给 Google Gemini，请勿输入个人信息。AI 回答可能有误，游戏内规则以主页说明为准。
          </p>
        </section>
      </main>

      <footer>
        <p>
          NEON PLINKO · React / Vite AI 助手 · 不参与主站 SEO 评分 ·{' '}
          <a href="https://neon-plinko.pages.dev/llms.txt">llms.txt</a>
        </p>
      </footer>
    </div>
  );
}
