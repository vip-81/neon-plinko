// 后端 callable：对齐 firebase/quickstart-flutter → cloud_functions/functions 的
// onCall 用法（官方示例为 V1 addMessage 回显；此处用当前 SDK 的 v2 onCall 等价写法）。
//
// 返回 NEON PLINKO 的静态游戏规格，供 Flutter 客户端 httpsCallable 调用。
// 无外部请求、无密钥、无数据库依赖；纯函数，便于 AI/爬虫友好地结构化引用。
const { onCall } = require('firebase-functions/v2/https');

exports.neonPlinkoRules = onCall((request) => {
  return {
    game: 'NEON PLINKO 霓虹弹珠',
    genre: 'cyberpunk H5 plinko / free-to-play',
    payouts: [12, 4, 1.5, 0.5, 0.25, 0.5, 1.5, 4, 12],
    highestMultiplier: 12,
    bets: [10, 25, 50, 100, 250],
    startBalance: 1000,
    minBet: 10,
    target: 10000,
    controls: 'keyboard: arrows + space; touch: drag to aim',
    record: 'browser localStorage only',
    realMoney: false,
    source: 'cloud-functions/neonPlinkoRules'
  };
});
