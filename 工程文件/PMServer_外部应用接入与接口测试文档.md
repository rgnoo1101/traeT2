# PMServer 外部应用接入与接口测试文档

## 1. 文档目标
本文件用于指导外部应用（Flutter/Web/Node/Postman）如何连接 PMServer 服务端进行联调与测试，覆盖：
1. 本地测试环境连接方式。
2. 鉴权与 token 获取。
3. 接口调用格式。
4. 函数名映射关系。
5. 常见问题排查。

---

## 2. 服务端基础信息

### 2.1 项目信息
1. Firebase Project ID：`pmserver-0411`
2. 函数所在目录：`PMSever/functions`
3. 运行方式：Firebase Functions v2 Callable + Emulator

### 2.2 本地端口
1. Emulator UI：`http://127.0.0.1:4000`
2. Functions：`127.0.0.1:5001`
3. Firestore：`127.0.0.1:8080`
4. Auth：`127.0.0.1:9099`
5. Storage：`127.0.0.1:9199`

---

## 3. 先决条件

## 3.1 启动服务端
在 `PMSever/functions` 下执行：
```powershell
npm run serve
```

### 3.2 建议验证
1. 打开 `http://127.0.0.1:4000`，确认 emulators 均为 Running。
2. 查看终端输出，确认 functions 已加载导出函数。

### 3.3 初始化测试数据（可选）
在 `PMSever/functions` 下执行：
```powershell
npx ts-node scripts/seed-test-data.ts
```

说明：
1. 当前 seed 脚本主要写 Firestore 基础数据（users/counters）。
2. 若外部应用使用 Auth 登录测试，请在 Auth Emulator 中注册测试账号，或通过 SDK 执行注册流程创建账号。

---

## 4. 接入方式总览

## 4.1 推荐方式：Firebase SDK 直连 Emulator
优点：
1. 自动处理 callable 协议封装。
2. 自动携带认证信息（ID Token）。
3. 最接近真实应用接入方式。

## 4.2 通用方式：原始 HTTP 调用 Callable Endpoint
适用场景：
1. Postman 调试。
2. 非 Firebase SDK 的测试客户端。
3. 自动化脚本回归。

---

## 5. 接口映射关系（业务名 -> 实际函数名）

| 业务契约名 | 实际导出函数名 | 类型 |
|---|---|---|
| auth.getCurrentUser | authGetCurrentUser | Callable |
| shot.submitShot | shotSubmitShot | Callable |
| match.getCurrentSession | matchGetCurrentSession | Callable |
| match.updateInviteDecision | matchUpdateInviteDecision | Callable |
| friend.listFriends | friendListFriends | Callable |
| chat.listChats | chatListChats | Callable |
| chat.listMessages | chatListMessages | Callable |
| chat.sendMessage | chatSendMessage | Callable |
| album.listMyShots | albumListMyShots | Callable |
| notification.getTodayPlan | notificationGetTodayPlan | Callable |

说明：
1. 外部测试时请使用右侧“实际导出函数名”作为调用入口。
2. 所有写接口必须携带 `requestId`。

---

## 6. 统一请求与响应协议

## 6.1 Callable 请求体格式
无论 SDK 还是 HTTP，业务参数都放在 `data` 下：
```json
{
  "data": {
    "apiVersion": "v1"
  }
}
```

## 6.2 统一响应格式
```json
{
  "success": true,
  "data": {},
  "errorCode": "",
  "message": "",
  "traceId": "trc_xxxx",
  "serverTime": "2026-04-11T09:00:00.000Z"
}
```

---

## 7. 认证与 Token 获取

## 7.1 外部应用必须带认证
当前所有 callable 统一走 `requireAuth`，未登录会返回：
1. `AUTH_REQUIRED`

## 7.2 Web/Node SDK 获取 token（Auth Emulator）
示例流程：
1. 连接 Auth Emulator。
2. 注册或登录测试账号。
3. 读取当前用户 ID Token。

```ts
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, signInWithEmailAndPassword } from 'firebase/auth';

const app = initializeApp({
  projectId: 'pmserver-0411',
  apiKey: 'fake-api-key',
  appId: '1:demo:web:demo',
});

const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099');

const cred = await signInWithEmailAndPassword(auth, 'u001@test.local', 'password123');
const idToken = await cred.user.getIdToken();
```

---

## 8. 使用 Firebase SDK 连接（推荐）

## 8.1 Web/Node 示例
```ts
import { initializeApp } from 'firebase/app';
import { getFunctions, connectFunctionsEmulator, httpsCallable } from 'firebase/functions';

const app = initializeApp({
  projectId: 'pmserver-0411',
  apiKey: 'fake-api-key',
  appId: '1:demo:web:demo',
});

const functions = getFunctions(app);
connectFunctionsEmulator(functions, '127.0.0.1', 5001);

const fn = httpsCallable(functions, 'authGetCurrentUser');
const result = await fn({ apiVersion: 'v1' });
console.log(result.data);
```

## 8.2 Flutter 示例
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

await Firebase.initializeApp();

FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
FirebaseFunctions.instanceFor(region: 'us-central1')
  .useFunctionsEmulator('127.0.0.1', 5001);

final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
  .httpsCallable('authGetCurrentUser');

final result = await callable.call({'apiVersion': 'v1'});
print(result.data);
```

说明：
1. Flutter 模拟器里如需访问宿主机，Android 模拟器常用 `10.0.2.2` 代替 `127.0.0.1`。
2. Windows 桌面 Flutter 直接使用 `127.0.0.1`。

---

## 9. 使用原始 HTTP 调用（Postman/curl）

## 9.1 本地 callable URL 规则
```text
http://127.0.0.1:5001/{projectId}/{region}/{functionName}
```

本项目示例：
```text
http://127.0.0.1:5001/pmserver-0411/us-central1/authGetCurrentUser
```

## 9.2 HTTP 头
1. `Content-Type: application/json`
2. `Authorization: Bearer <ID_TOKEN>`

## 9.3 cURL 示例：调用 authGetCurrentUser
```bash
curl -X POST "http://127.0.0.1:5001/pmserver-0411/us-central1/authGetCurrentUser" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -d "{\"data\":{\"apiVersion\":\"v1\"}}"
```

## 9.4 cURL 示例：调用 shotSubmitShot
```bash
curl -X POST "http://127.0.0.1:5001/pmserver-0411/us-central1/shotSubmitShot" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -d "{\"data\":{\"apiVersion\":\"v1\",\"requestId\":\"req_u_001_123456\",\"localDate\":\"2026-04-11\",\"shotAt\":\"2026-04-11T08:00:00.000Z\",\"storagePath\":\"shots/u_001/2026-04-11/img_001.jpg\"}}"
```

---

## 10. 外部应用测试建议流程

1. 登录并拿到 ID Token。
2. 调 `authGetCurrentUser` 验证链路通。
3. 先上传图片到 Storage Emulator，拿到 `storagePath`。
4. 调 `shotSubmitShot`（写接口要带 `requestId`）。
5. 调 `matchGetCurrentSession` 检查是否已有匹配会话。
6. 双端分别调 `matchUpdateInviteDecision` 完成同意流程。
7. 调 `chatListChats`、`chatSendMessage`、`chatListMessages`。
8. 调 `albumListMyShots`、`notificationGetTodayPlan`。

---

## 11. 写接口 requestId 规则
建议规则：
1. 格式：`req_<uid>_<uuid>` 或 `req_<uid>_<timestamp>`。
2. 同一次业务重试必须复用同一个 `requestId`。
3. 不同业务请求必须使用不同 `requestId`。

典型写接口：
1. `shotSubmitShot`
2. `matchUpdateInviteDecision`
3. `chatSendMessage`

---

## 12. 常见报错与排查

## 12.1 AUTH_REQUIRED
原因：
1. 未登录。
2. Authorization 头缺失或 token 失效。

处理：
1. 重新登录 Auth Emulator。
2. 重新获取 token 并重发请求。

## 12.2 PERMISSION_DENIED
原因：
1. 当前用户无该会话/聊天权限。
2. 请求试图访问他人资源。

处理：
1. 检查 uid 与资源归属关系。
2. 检查是否用错测试账号。

## 12.3 INVALID_REQUEST
原因：
1. 字段缺失。
2. 字段格式不符（如 localDate、requestId、shotAt）。

处理：
1. 对照 09 接口文档逐字段修正。

## 12.4 IDEMPOTENCY_CONFLICT
原因：
1. 同 requestId 但 payload 不同。

处理：
1. 重试时必须保持 payload 完全一致。
2. 新业务请求请更换 requestId。

## 12.5 ECONNREFUSED
原因：
1. Emulator 未启动。
2. 端口不对。

处理：
1. 执行 `npm run serve`。
2. 确认 `firebase.json` 端口与客户端配置一致。

---

## 13. 启动、关闭、重启（给外部测试方）

## 13.1 启动
在 `PMSever/functions`：
```powershell
npm run serve
```

## 13.2 关闭
1. 在运行终端按 `Ctrl + C`。
2. 确认后退出。

## 13.3 重启
1. 先关闭。
2. 再启动：
```powershell
npm run serve
```

## 13.4 快速健康检查
1. 打开 UI：`http://127.0.0.1:4000`
2. 调用：`authGetCurrentUser`

---

## 14. 云端测试（可选）
当部署到云端后，外部应用可把函数入口切换为云端地址：
```text
https://us-central1-pmserver-0411.cloudfunctions.net/{functionName}
```

注意：
1. 云端也要带有效 Firebase ID Token。
2. 本地与云端使用同一请求/响应契约。
3. 建议先在 `real_local` 完成回归后再切 `real_cloud`。

---

## 15. 与现有文档的关系
1. 接口字段与错误码：以 `09-应用端与服务端接口文档（执行版）` 为准。
2. 应用端连接规范：以 `10-应用端设计规范纲要（执行版）` 为准。
3. 服务端实现规范：以 `11-服务端设计规范纲要（执行版）` 为准。
4. 代码职责与运维总览：见 `PMServer_服务端代码说明与运维手册.md`。
