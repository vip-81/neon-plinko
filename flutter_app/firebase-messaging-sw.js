// firebase-messaging-sw.js —— FCM Web 服务工作者骨架。
// 仅当 Cloud Messaging 构建期开关开启（FCM_ENABLED）并在 main.dart 填入 kVapidKey、
// 且在 Firebase 控制台生成 Web 推送证书后，FCM 才会加载本文件并真正接收后台推送。
// 默认部署下 FCM 关闭，本文件不会被加载，仅为启用推送时的模板。

importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging.js');

// TODO: 填入项目的 Firebase Web 配置（与 firebase_options.dart 的 web 配置一致，messagingSenderId 必填）。
// 这些不是密钥，但属于项目标识，启用前请替换为真实值。
firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
});

const messaging = firebase.messaging();

// 后台（页面不可见时）收到推送：用系统通知展示。
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] 后台消息:', payload);
  const notification = payload.notification || {};
  const title = notification.title || 'NEON PLINKO';
  const body = notification.body || '';
  if (self.registration && self.registration.showNotification) {
    self.registration.showNotification(title, { body: body });
  }
});
