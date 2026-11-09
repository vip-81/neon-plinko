# NEON PLINKO 霓虹弹珠

已部署到 Cloudflare Pages 的免费赛博朋克风 H5 弹珠游戏。单个 `index.html` 内含完整页面、样式、Canvas 游戏逻辑与音效，无前端框架、无 CDN、无外部图片。

- **生产地址（Canonical）**：https://neon-plinko.pages.dev/
- **GitHub Pages 镜像**：https://vip-81.github.io/neon-plinko/
- **Firebase Hosting 镜像**：https://neon-plinko-20261110.web.app/
- **Firebase AI Logic 助手页**：https://neon-plinko-20261110.web.app/ai
- **GitHub 仓库**：https://github.com/vip-81/neon-plinko
- **Gitee 仓库**：https://gitee.com/vip882/neon-plinko
- **AtomGit 仓库**：https://atomgit.com/zzw1208/neon-plinko
- **Cloudflare Pages 项目**：`neon-plinko`
- **部署环境**：production / `main`
- **现有项目**：`neon21-casino`、`static-casino-game`、`golden-reels` 均保持原样，未被覆盖

## 文件结构

```text
.
├── index.html      # 完整游戏 + SEO/GEO 内容页（核心文件）
├── og-cover.png    # 1200 × 630 社交分享封面
├── robots.txt      # 抓取规则 + sitemap 地址
├── sitemap.xml     # 单页 sitemap
├── llms.txt        # 面向 AI 摘要与引用的结构化站点摘要
├── _headers        # Cloudflare Pages 缓存与安全响应头
├── firebase.json   # Firebase Hosting 配置（headers / cache / cleanUrls）
├── .firebaserc     # Firebase 项目与多站点 target 映射
├── ai.html         # 独立 AI 规则助手页（Firebase AI Logic / Gemini）
├── firebase-config.example.js  # Web 配置模板；真实 firebase-config.js 仅部署时生成
├── 404.html        # 品牌化 404 页面（含 noindex）
├── .nojekyll       # GitHub Pages：跳过 Jekyll，原样发布静态文件
└── README.md       # 部署与维护说明
```

## 本次生产部署

页面已写入正式绝对地址：

- Canonical：`https://neon-plinko.pages.dev/`
- `og:url`、`og:image`、`twitter:image`
- JSON-LD：`WebSite`、`WebPage`、`VideoGame`、`FAQPage`
- `robots.txt` 的 Sitemap 行
- `sitemap.xml` 的 `<loc>`

Cloudflare Pages 会通过 `_headers` 为 HTML、封面和索引文件设置缓存、CSP、`X-Content-Type-Options`、`Referrer-Policy` 与 `X-Frame-Options`。

### 更新部署

在本目录执行：

```bash
npx wrangler pages deploy . --project-name neon-plinko --branch main
```

或在 Cloudflare Dashboard → Workers & Pages → `neon-plinko` → Create new deployment 中上传本目录。

### GitHub Pages 镜像部署

仓库 `vip-81/neon-plinko` 的 `main` 分支已启用 GitHub Pages（根目录发布）。推送后会自动重新构建：

```bash
git init
git add .
git commit -m "Deploy NEON PLINKO"
git branch -M main
git remote add origin https://github.com/vip-81/neon-plinko.git
git push -u origin main
```

- 镜像地址：https://vip-81.github.io/neon-plinko/
- GitHub Pages 不支持自定义响应头，`_headers` 中的 CSP 与缓存策略仅在 Cloudflare Pages 生效。
- 两个地址返回相同页面；canonical、`og:url`、JSON-LD、`sitemap.xml` 与 `robots.txt` 统一指向 Cloudflare 生产域名，避免重复索引。
- 需要把 GitHub Pages 设为主站时，将上述文件中的 `https://neon-plinko.pages.dev/` 替换为 `https://vip-81.github.io/neon-plinko/`，同步更新 `llms.txt`，然后重新部署两个平台。

### Firebase Hosting 部署

复用已有 Firebase 项目 `boto3-firebase-1101012838`，并新建独立 Hosting 站点 `neon-plinko-20261110`，未覆盖该项目中已有站点：

- 站点地址：https://neon-plinko-20261110.web.app/
- 项目 ID：`boto3-firebase-1101012838`
- Site ID：`neon-plinko-20261110`
- 部署 target：`neon-plinko`（见 `.firebaserc`）
- Firebase 项目控制台：https://console.firebase.google.com/project/boto3-firebase-1101012838/overview

在 `firebase.json` 所在目录执行：

```bash
firebase target:apply hosting neon-plinko neon-plinko-20261110 --project boto3-firebase-1101012838
firebase deploy --only hosting:neon-plinko --project boto3-firebase-1101012838
```

- `firebase.json` 配置了 CSP、安全响应头、缓存策略、`cleanUrls` 与自定义 404；效果与 Cloudflare `_headers` 对齐。
- 仅上传 `index.html`、`og-cover.png`、`robots.txt`、`sitemap.xml`、`llms.txt`、`404.html` 六个文件；`_headers`、README、`.nojekyll` 与 Firebase 配置本身设为 `ignore`。
- Firebase 镜像与 Cloudflare / GitHub Pages 一样，canonical 保持 `https://neon-plinko.pages.dev/`。
- 登录使用 `gcloud auth application-default login` 生成的 ADC；Firebase CLI 会直接复用该凭据，无需单独 `firebase login`。

### Firebase AI Logic 助手页

独立页面 `ai.html` 使用 Firebase AI Logic Web SDK（13.1.0，gstatic CDN）调用 Gemini，提供游戏规则问答；主游戏 `index.html` 完全不变。

- 访问地址：https://neon-plinko-20261110.web.app/ai （`/ai.html` 会 301 到 `/ai`）
- 该页设置 `noindex, follow`，不参与主站 SEO/GEO 评分，也不纳入主站 Lighthouse。
- 仅该页放宽 CSP，允许 `www.gstatic.com`、`apis.google.com` 与 `firebasevertexai.googleapis.com`；首页仍是严格 CSP，Lighthouse 保持 100/100/100。
- 模型按 `gemini-3.5-flash-lite` → `gemini-3.6-flash` → `gemini-3.5-flash` 回退，单次请求 35 秒超时；`gemini-3.8-flash` 当前高负载，故不作为首选。
- 系统提示词限定只回答 NEON PLINKO 的玩法、倍率、下注、操作与安全说明，并拒答无关问题。
- 其他镜像（如 GitHub Pages）没有 `firebase-config.js` 时会显示「仅 Firebase 环境可用」并禁用提问，不会调用 Gemini；AI 助手的实际入口是 Firebase Hosting。

前置配置（已完成）：

- 注册 Firebase Web App：`1:909891373707:web:93ea70d7a2a1fe5ac6a28e`
- 启用 `generativelanguage.googleapis.com`、`firebasevertexai.googleapis.com`、`apikeys.googleapis.com`
- 通过 Firebase provisioning API 创建 AI Logic genai config（否则会报 `genai config not found`）
- 将公开 Firebase Web API Key 限制为仅允许 `https://neon-plinko-20261110.web.app/*`、`https://neon-plinko-20261110.firebaseapp.com/*` 与 localhost

部署时使用 `firebase-config.example.js` 作为模板生成 `firebase-config.js` 并上传到 Hosting；**真实配置不提交到公开仓库**，避免把项目标识写入源码库：

```bash
cp firebase-config.example.js firebase-config.js
# 填入 firebase apps:sdkconfig WEB <appId> 输出的值
firebase deploy --only hosting:neon-plinko --project boto3-firebase-1101012838
```

生产环境建议在 Firebase 控制台额外配置 App Check / reCAPTCHA Enterprise 强制校验；当前通过 provisioning API 初始化，未启用 App Check 强制校验，但 API Key 已做域名限制。

### 代码托管镜像

同一份源码已同步到三个公开仓库，均为零构建静态站点：

| 平台 | 仓库 | 默认分支 |
|---|---|---|
| GitHub | https://github.com/vip-81/neon-plinko | `main` |
| Gitee | https://gitee.com/vip882/neon-plinko | `master` |
| AtomGit | https://atomgit.com/zzw1208/neon-plinko | `main` |

- 三个仓库仅用于源码分发与备份；线上生产仍以 Cloudflare Pages 为 canonical。
- `.nojekyll` 为平台标记文件，内容为一个换行符，便于 Gitee / AtomGit 正确写入空标记文件。
- 更新任一仓库后，其他两个仓库需手动同步同一批文件；操作凭据使用环境变量或平台 Secrets，勿写入项目文件。

## 本地预览

任选一种静态服务器（不要直接双击 `index.html`）：

```bash
# Node.js
npx serve .

# Python 3
python -m http.server 8080

# PHP
php -S localhost:8080
```

打开 `http://localhost:8080/`。开发时可加 `?debug=1` 使用调试接口：

```js
window.__NEON_PLINKO_DEBUG__.snapshot()
window.__NEON_PLINKO_DEBUG__.start()
window.__NEON_PLINKO_DEBUG__.drop()
window.__NEON_PLINKO_DEBUG__.setBalance(5000)
window.__NEON_PLINKO_DEBUG__.finish(true)
```

正式发布若不需要调试入口，可删除 `index.html` 中 `__NEON_PLINKO_DEBUG__` 相关代码。

## SEO / GEO 实现

- 语义化 `header` / `main` / `section` / `footer`，单一 H1，完整 H2/H3 层级。
- Title、Description、Keywords、Canonical、Robots、Theme Color。
- Open Graph：类型、站点名、语言、标题、描述、URL、绝对图片、图片尺寸与 alt。
- Twitter Card：`summary_large_image`、标题、描述、绝对图片与 alt。
- JSON-LD：`WebSite` + `WebPage` + `VideoGame` + `FAQPage`。
- 页面内包含一句话摘要、游戏规格、玩法步骤、倍率表、技术特性与 FAQ，便于搜索引擎和生成式引擎提取。
- `llms.txt` 提供可直接引用的游戏事实、规则、倍率与 FAQ，并注明引用来源。
- `sitemap.xml` 与 `robots.txt` 已指向正式域名。
- Google Search Console：已通过 API 创建 URL-prefix 资源 `https://neon-plinko.pages.dev/`；因所有权尚未验证，sitemap 提交返回 403。需在 GSC 完成验证（HTML 文件 / DNS / meta 标签）后重新提交 `sitemap.xml`。
- AI 助手页为 `noindex` 辅助页，不进入 sitemap，也不作为生成式引擎的引用来源；GEO 仍以主页语义化内容、JSON-LD、FAQ 与 `llms.txt` 为准。

### 绑定自定义域名后

如果以后绑定新域名，请全局替换以下文件中的 `https://neon-plinko.pages.dev/`：

- `index.html`（canonical、OG、Twitter、JSON-LD）
- `sitemap.xml`
- `robots.txt`
- `llms.txt`

然后在 Cloudflare Pages 的 **Custom domains** 中添加域名并开启 HTTPS。建议同时在 Google Search Console / Bing Webmaster Tools 提交新的 sitemap。

## 性能与可访问性

- Lighthouse 本地桌面测试：Accessibility / Best Practices / SEO 均为 100，0 项失败。
- Firebase Hosting 生产 URL 复测：Accessibility / Best Practices / SEO 均为 100，0 项失败。
- 页面无外部字体、图片、统计或第三方脚本请求。
- `index.html` 约 132 KB；`og-cover.png` 约 0.8 MB。
- 支持键盘（方向键、空格、M）与触屏/指针操作，带 `aria-live` 状态播报。
- 支持 `prefers-reduced-motion` 与高对比度模式。
- 已在约 800 × 654 的矮屏桌面、375 px 与 320 px 宽移动布局下检查。
- 上线后仍建议在真实 iOS Safari、Android Chrome 和桌面 Firefox 上各测一局。

## 安全提示（重要）

- 项目文件不包含任何 Cloudflare、GitHub、Gitee、AtomGit、Google 或 itch.io 密钥；Firebase Web 配置只提供 `firebase-config.example.js` 模板，真实 `firebase-config.js` 只在部署目录生成。
- Firebase Web API Key 是公开的项目标识而非私密凭据，已通过 Google API Keys API 限制为仅允许指定域名；请勿把 Gemini API Key 写进前端。
- 本次部署使用的凭据仅通过命令环境传递，没有写入 `index.html`、README、Git 或静态资源；Google ADC 凭据保存在用户目录 `%APPDATA%\gcloud\application_default_credentials.json`，属于本机登录态，不在项目目录内。
- 你在对话中提供的 **Cloudflare API Token、R2 Access Key / Secret Key、itch.io API Key、两个 GitHub Token、Gitee Token、AtomGit Token 均已出现在聊天记录中，请立即撤销并重新生成**。尤其是 R2 Secret Access Key、Cloudflare API Token 与 classic GitHub Token，应视为已泄露。
- 后续更新时，使用环境变量或平台 Secrets 管理，不要把密钥粘贴到对话或提交到仓库。

## 说明

页面中的品牌、文案与玩法为原创演示内容；游戏筹码仅为娱乐数值，不涉及真实货币投注。
