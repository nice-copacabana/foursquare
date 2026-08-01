# 代码审计报告：文档与实际代码一致性核查

> 审计日期：2026-05-07
> 审计方法：基于源码逐模块交叉验证，不信任文档/commit message 的自述
>
> 2026-08-01 修订：本报告主体保留历史审计背景；语音/冥想模块已按当前代码重新核对并在下文修正。项目当前总状态以 `README.md`、`TEST_STRATEGY.md` 和 `RELEASE_CHECKLIST.md` 为准。

---

## 核查结论总表

| 模块 | 文档/log 宣称 | 代码实际 | 判定 |
|---|---|---|---|
| 核心引擎（move/capture/engine） | ✅ 完成，60+ 测试 | `executeMove/checkGameOver/simulateMove/undoLastMove` 均有实逻辑，无 stub | **一致 ✅** |
| AI（三难度 + α-β + 置换表） | ✅ 完成 | 剪枝、`_transpositionTable`、历史启发、动态深度、迭代加深均真实存在 | **一致 ✅** |
| LAN 对战（含 move sync） | ✅ 已完成（cf43bea） | mDNS 注册+发现、WS 服务端、`_onLocalMove/_onOpponentMove` 真实收发 | **基本一致 ✅** |
| 在线对战后端 | ✅ 权威同步完成 | Socket.io + 房间管理 + 服务端规则校验 + 60 秒行棋超时 + 30 秒重连宽限 | **当前纯核心一致，发布门禁未完成 ⚠️** |
| 在线对战前端 | 历史审计曾判定落子未完成 | 当前已有权威会话、BLoC、页面落子链与传输测试；生产导航和真机联调仍未完成 | **历史问题已修正 ⚠️** |
| 语音控制 + 冥想模式 | 历史文档曾宣称完成 | 隐藏的 Phase 4 核心、存储装配、现代东方冥想页面和懒加载候选生产 Adapter 已实现；旧 Bloc/页面原型已移除；平台声明/设置跳转、正式入口和真机门禁未完成 | **历史宣称已纠正 ⚠️** |
| 回放 / 存储 / i18n / 主题 | ✅ 完成 | 三语 ARB 齐全、Hive 存档真实、3 套主题 presets 齐 | **一致 ✅** |
| **测试证据** | CHANGELOG 曾宣称未复测的覆盖率 | 当前共 72 个 `_test.dart` 文件；本次全量 `flutter test` 为 723 通过、1 跳过；未重新测量覆盖率 | **只采用当前命令证据 ⚠️** |

---

## 详细分析

### A. 核心引擎 ✅ 完全实现

**文件**：
- `lib/engine/game_engine.dart` (303 行)
- `lib/engine/move_validator.dart` (130 行)
- `lib/engine/capture_detector.dart` (218 行)

**验证结果**：
- `executeMove()` → 验证、执行、检测吃子、更新棋盘
- `checkGameOver()` → 检查棋子数量，返回 GameResult
- `simulateMove()` → AI 模拟用完整逻辑
- `undoLastMove()` → 从历史重放重建棋盘状态
- `getPossibleMoves()` / `getCaptureOpportunities()` → 完整实现
- `CaptureDetector` → 四方向"己-己-敌"模式检测 + 威胁评估

**无 TODO、无 FIXME、无 UnimplementedError。**

---

### B. AI 系统 ✅ 完全实现

**文件**：
- `lib/ai/minimax_ai.dart` (380 行)
- `lib/ai/evaluation.dart` (172 行)
- `lib/ai/ai_player.dart` (91 行)

**验证结果**：
- Alpha-Beta 剪枝：真实实现（非注释宣称）
- 置换表：`_transpositionTable` (Map<String, _TranspositionEntry>)，10,000 条上限
- 历史启发：`_historyTable` 用于走法排序
- 动态深度：根据剩余棋子数调整
- 迭代加深：支持
- 进度回调：UI 集成

**难度配置**：
- Easy: 3 层深度, 500ms 超时
- Medium: 4 层深度, 2000ms 超时
- Hard: 5 层深度, 5000ms 超时

**评估函数**（evaluation.dart）：
- 棋子数量（1000 分/子）
- 位置价值（中心格更高）
- 机动性（10 分/可用走法）
- 威胁检测（200 分/两子连线）
- 防御价值（150 分/对手威胁）

---

### C. LAN 对战 ✅ 完全实现

**文件**：
- `lib/services/local_network_service.dart` (265 行)
- `lib/bloc/lan_game_bloc.dart` (230 行)
- `lib/bloc/lan_lobby_bloc.dart` (165 行)
- `lib/ui/screens/lan/lan_lobby_page.dart`
- `lib/ui/screens/lan/lan_game_page.dart`

**验证结果**：
- `startHost()` → 启动 WebSocket 服务器（端口 4040，Shelf）
- `register()` → 注册 mDNS 服务 (`_foursquare._tcp`)
- `startDiscovery()` → mDNS 发现 + 自动解析
- `_onLocalMove()` → 执行走法 + 网络发送
- `_onOpponentMove()` → 接收解析 + 棋盘更新
- 走法序列化：`{'from': {x,y}, 'to': {x,y}, 'player': ...}`

**当前边界**：
- 主机权威 60 秒时钟、30 秒重连宽限、断线/恢复和状态同步已有代码与测试。
- 双完整客户端/真机网络切换、后台和复杂路由环境仍需发布级联调。

---

### D. 在线对战 🚧 权威核心已形成，发布闭环未完成

#### 后端（server/src/）✅

**文件**：
- `server/src/index.ts` → Express + Socket.io + CORS
- `server/src/gateway/socket.ts` → 事件处理
- `server/src/game/room_manager.ts` → 房间管理
- `server/src/game/rules.ts` → 服务端规则校验

**验证结果**：
- `request_match` → 排队、创建房间、emit match_found
- `submit_move` → 服务端规则验证 + 广播
- 非法走法拒绝
- 60 秒行棋超时与 30 秒断线重连宽限
- 重复排队检测

#### 前端：权威落子链已形成，生产接入待完成

**文件**：
- `lib/services/websocket_service.dart` (267 行)
- `lib/bloc/online_game_bloc.dart` (475 行)
- `lib/ui/screens/matching_page.dart`
- `lib/ui/screens/online_game_page.dart`

**当前边界**：
- 权威页面落子链、匿名身份、快照同步和传输测试已经存在。
- 生产导航、两台完整 Flutter 应用/真机联调、真实 PostgreSQL、staging 和运维门禁仍未完成。
- ELO、排行榜不属于当前正式路线承诺。

---

### E. 语音控制 + 冥想模式 🚧 隐藏核心已实现

**文件**：
- `lib/services/voice_recognition_service.dart`
- `lib/services/voice_synthesis_service.dart`
- `lib/ai/voice_command_parser.dart`
- `lib/ai/voice_game_intent.dart`
- `lib/services/voice/voice_ports.dart`
- `lib/services/voice/voice_interaction_controller.dart`
- `lib/meditation/meditation_session.dart`
- `lib/meditation/meditation_session_controller.dart`
- `lib/meditation/meditation_intent_handler.dart`
- `lib/meditation/meditation_session_snapshot.dart`
- `lib/meditation/meditation_session_persistence.dart`
- `lib/meditation/meditation_session_committer.dart`
- `lib/meditation/meditation_session_runtime.dart`

**验证结果**：
- 默认关闭且不会在隐藏阶段初始化 TTS；识别原文不进入日志、普通状态字符串、存档或网络。
- 类型化位置、移动和控制动作采用整句白名单；用户坐标 1–4 与引擎 0–3 可逆，歧义中心、否定、多坐标和尾随内容不执行。
- 权限、识别和播报均通过可替换端口；单次监听状态机覆盖 completion、中断、迟到回调和播报失败恢复。
- 基于 `permission_handler`、`speech_to_text` 和 `flutter_tts` 的独立 Adapter 只在明确操作时触碰平台；权限映射 fail-closed，STT 错误不携带插件正文，TTS 的 cancel/error 不会误报播放成功，停止缺少终止回调时会熔断而非复用污染状态。
- 内存权威冥想 session/controller 维护棋盘、执色/先手、完整历史、未吃计数、时钟、选择、结果和修订号；所有落子复用 `GameEngine`。
- 开场播报完成后才启动 60 秒时钟；intent handler 提供 AI 先手/失败重试、查询、暂停/恢复和退出确认的类型化闭环。
- 假端口已完成查询、重复、选子取消、暂停恢复、退出取消、AI 失败重试到 15 ply 自然终局的完整无屏对局。
- 冥想存档使用独立版本化格式与 Hive 适配器，严格拒绝损坏数据并通过历史重放恢复权威状态。运行时已实现修订自动保存、绝对时限驱动、AI 前耐久化屏障、恢复单飞、销毁竞态隔离和终局安全收口；`StorageService` 已负责冥想 Box 生命周期和完成记录注入，现代东方隐藏页面已接入用途说明、显式启用、单次聆听和对局控制。
- 旧 `MeditationModeBloc`、事件/状态和不可达页面已经删除，不能再作为“功能完整”的证据。

---

### F. 当前测试证据（2026-08-01 修订）

- `test/` 与 `integration_test/` 当前共有 72 个 `_test.dart` 文件。
- 本次全量 `flutter test`：723 项通过、1 项显式跳过。
- 当前覆盖引擎、模型、Game/LAN/Online BLoC、在线协议/会话/传输、语音状态机、权威冥想核心、页面契约和发布契约。
- `test/integration/` 已包含真实在线传输和假端口冥想语音核心流程；它们仍不能替代 staging、真实数据库、双真机和平台音频验收。
- 本次没有重新运行覆盖率统计，因此不保留历史 95.7% 或其他主观百分比。

---

### G. 其他功能验证

| 功能 | 状态 | 说明 |
|---|---|---|
| 游戏回放 | ✅ | `game_replay_service.dart` (259 行)，前进/后退/跳转/进度条完整 |
| 本地存储 (Hive) | ✅ | `storage_service.dart` (407 行)，GameSettings toJson/fromJson |
| 国际化 (zh/en/ja) | ✅ | 三语 ARB 文件齐全，含真实翻译 |
| 主题系统 | ✅ Phase 1 | 正式 registry 只暴露现代东方棋艺；主题包接口为后续扩展保留 |
| 背景音乐 | ✅ | `music_service.dart` (208 行)，5 种主题 |
| Wear OS | ⏸ 搁置 | `.dart.disabled` 文件存在，README 已说明原因 |

---

## 当前主要未完成项

1. **Phase 2 外部门禁**：macOS/Xcode、iOS 真机、TestFlight 和商店资料尚未完成。
2. **Phase 3 发布闭环**：生产导航、两台完整客户端/真机联调、真实 PostgreSQL、staging、持久化恢复、TLS、限流、负载与运维演练尚未完成。
3. **Phase 4 产品化**：候选生产 ASR/TTS Adapter 已实现但尚未接正式页面；平台权限与设置跳转、正式入口、真机音频/隐私验收尚未完成，隐藏页面、无屏整局和持久化编排已有自动化证据。
4. **正式发布资料**：包名、签名、Google Play 身份和素材按项目决定继续暂缓，不阻塞当前代码开发。

---

## 当前阶段判定

| 正式阶段 | 当前判定 |
|---|---|
| Phase 1 Android 本地/AI/LAN | 代码与自动化基础已形成；正式签名、商店身份、素材和真机发布矩阵仍待补齐 |
| Phase 2 iOS 与三语 | 代码与 Windows 可执行契约已形成；Xcode、真机和 TestFlight 外部门禁未完成 |
| Phase 3 在线 | 权威服务端、客户端和本地真实传输证据已形成；staging 与生产运维门禁未完成 |
| Phase 4 语音与冥想 | 隐藏核心、现代东方页面和懒加载候选生产 Adapter 已形成无屏整局、独立存档和自动收口证据；平台声明、正式入口和真机门禁未完成 |

不再使用未经测量的“总体完成度”或覆盖率百分比。

---

## 后续优化方向

- Phase 1/2：完成 Android/iOS 正式身份、签名、商店素材、Xcode、TestFlight 和真机发布矩阵。
- Phase 3：完成生产导航、双完整客户端/真机联调、staging、真实 PostgreSQL、持久化恢复、TLS、限流、负载和运维演练。
- Phase 4：继续完成候选 Adapter 的隐藏页面生产装配、平台权限与设置跳转、正式入口和真机音频/隐私验收。
- 在线与冥想现有集成测试继续下钻到双完整客户端、进程重启、真实数据库和平台设备层级。

离线语音、ELO/排行榜/好友房、社交分享/观战、付费点和 Wear OS 仅为历史想法，不属于当前正式路线承诺。
