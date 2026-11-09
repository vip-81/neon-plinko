/// <reference types="vite/client" />

// 与官方 quickstart-js / ai/ai-samples 一致：构建期通过 VITE_FIREBASE_CONFIG 注入。
// 源码中只有占位符，不写入任何真实项目标识。
const fromEnv = import.meta.env.VITE_FIREBASE_CONFIG as string | undefined;

export const firebaseConfig: Record<string, string> = fromEnv
  ? JSON.parse(fromEnv)
  : {
      apiKey: 'YOUR_API_KEY',
      authDomain: 'YOUR_AUTH_DOMAIN',
      projectId: 'YOUR_PROJECT_ID',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_SENDER_ID',
      storageBucket: 'YOUR_STORAGE_BUCKET'
    };
