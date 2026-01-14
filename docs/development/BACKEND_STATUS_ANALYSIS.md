# 后端功能现状与差距分析报告 (Backend Status Analysis)

**日期**: 2026-01-14
**分析对象**: Foursquare 项目代码库

## 1. 核心结论
**当前状态**: **客户端就绪，服务端缺失**。
目前项目 (`d:\Develop\outworks\foursquare`) 是一个纯粹的 Flutter 客户端项目。虽然客户端已经封装好了与服务器通信的 SDK 层，但**没有任何实际的后端服务器代码** (Server-Side Code) 存在于本项目中。

所有已实现的"后端功能"实际上是**客户端对后端接口的定义和模拟**。

---

## 2. ✅ 已实现功能 (客户端 SDK 层)

这部分代码位于 `lib/services/` 和 `lib/models/`，为接入未来后端做好了准备：

### 2.1 通信基础设施 (`WebSocketService`)
-   [x] **连接管理**: 支持 `connect`, `disconnect` 及连接状态流 (`stateStream`)。
-   [x] **自动重连**: 实现了指数退避策略的断线重连机制 (`_attemptReconnect`)。
-   [x] **心跳保活**: 客户端侧的心跳包发送逻辑 (`_startHeartbeat`)。
-   [x] **消息封装**: 统一的 `WebSocketMessage` 模型，支持 JSON 序列化/反序列化。

### 2.2 业务协议定义
-   [x] **匹配请求**: `requestMatch(playerId)` 协议已定义。
-   [x] **移动同步**: `sendMove` 协议，包含完整的坐标 (`from`, `to`) 和吃子信息。
-   [x] **数据模型**: `OnlineMatch` 完整定义了在线对局所需的数据结构（双方 ID、当前回合、移动历史）。

---

## 3. 🛑 缺失功能 (核心服务端)

以下模块在当前代码库中**完全不存在**，需要从零开发（通常建议新建一个 `server/` 目录或独立仓库）：

### 3.1 接入层 (Gateway)
-   [ ] **WebSocket Server**: 实际监听端口、握手升级 (Upgrade) 及维护千人/万人长连接的服务器程序。
-   [ ] **路由分发**: 将收到的 `WebSocketMessage` 分发给对应的业务控制器 (Controller)。

### 3.2 业务逻辑层 (Game Logic)
-   [ ] **匹配队列 (Matchmaking Queue)**: 
    -   服务端没有队列暂存请求。
    -   缺乏匹配算法 (FCFS 或 Elo) 来将两个 `requestMatch` 的玩家配对。
-   [ ] **房间管理器 (Room Manager)**:
    -   无法在内存中创建房间实例。
    -   无法管理房间内的状态同步 (Broadcasting moves)。
-   [ ] **裁判逻辑 (Anti-Cheat)**:
    -   服务端无法验证客户端上传的 `Move` 是否合法（目前全靠客户端自觉，极易作弊）。

### 3.3 数据持久层 (Persistence)
-   [ ] **用户数据库**: 没有 Users 表，无法存储 `player1Id` 对应的真实用户信息。
-   [ ] **对战记录**: 没有 MatchHistory 表，无法回放或统计战绩。

### 3.4 用户认证 (Auth)
-   [ ] **账户系统**: 没有注册/登录 API，现在的 `playerId` 仅为本地生成的字符串。

---

## 4. 建议的下一步行动

1.  **技术选型**: 根据团队技术栈选择后端语言。
    -   *Dart (Server)*: 代码复用率高，可直接复用 `lib/models` 中的数据模型。
    -   *Node.js (Socket.io)*: 生态成熟，开发速度快。
    -   *Go*: 并发性能强，适合高在线人数。

2.  **创建 Server 项目**:
    ```bash
    mkdir server
    cd server
    # 初始化后端项目...
    ```

3.  **最小闭环 (MVP)**:
    -   搭建一个简单的 Echo Server 验证 `WebSocketService` 连接。
    -   实现"死板匹配"：只要有两个连接就自动配对。
    -   实现"透传模式"：A 发的消息直接转发给 B，服务端暂不校验逻辑。
