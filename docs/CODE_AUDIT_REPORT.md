# 代码审计报告：文档与实际代码一致性核查

> 审计日期：2026-05-07
> 审计方法：基于源码逐模块交叉验证，不信任文档/commit message 的自述

---

## 核查结论总表

| 模块 | 文档/log 宣称 | 代码实际 | 判定 |
|---|---|---|---|
| 核心引擎（move/capture/engine） | ✅ 完成，60+ 测试 | `executeMove/checkGameOver/simulateMove/undoLastMove` 均有实逻辑，无 stub | **一致 ✅** |
| AI（三难度 + α-β + 置换表） | ✅ 完成 | 剪枝、`_transpositionTable`、历史启发、动态深度、迭代加深均真实存在 | **一致 ✅** |
| LAN 对战（含 move sync） | ✅ 已完成（cf43bea） | mDNS 注册+发现、WS 服务端、`_onLocalMove/_onOpponentMove` 真实收发 | **基本一致 ✅** |
| 在线对战后端 | ✅ 权威同步完成 | Socket.io + 房间管理 + 服务端规则校验 + 30s 超时齐备 | **一致 ✅** |
| 在线对战前端 | 文档未明说 | `online_game_page.dart:483` 存在 `// TODO: 实现完整的棋子选中和移动逻辑` — 落子交互未完成 | **⚠️ 文档遗漏** |
| 语音控制 + 冥想模式 | ✅ 完成 | speech_to_text / flutter_tts 真接入；voice_command_parser 四种解析模式；meditation_mode_bloc 662 行实逻辑 | **一致 ✅** |
| 回放 / 存储 / i18n / 主题 | ✅ 完成 | 三语 ARB 齐全、Hive 存档真实、3 套主题 presets 齐 | **一致 ✅** |
| **测试覆盖** | CHANGELOG："135+ 单元测试，95.7% 覆盖率" | **实测仅 19 个测试文件** | **❌ 与事实严重不符** |

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

**未完成项**（与文档一致）：
- 计时器同步
- 断线重连处理

---

### D. 在线对战 ⚠️ 后端完整，前端未完工

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
- 30 秒超时机制
- 重复排队检测

#### 前端 ⚠️ ~70% 完成

**文件**：
- `lib/services/websocket_service.dart` (267 行)
- `lib/bloc/online_game_bloc.dart` (475 行)
- `lib/ui/screens/matching_page.dart`
- `lib/ui/screens/online_game_page.dart`

**问题**：
- `online_game_page.dart:483` 存在 TODO：`// TODO: 实现完整的棋子选中和移动逻辑`
- `websocket_service.dart` 使用裸 `print()` 而非 `LoggerService`
- 匹配/ELO/排行榜 UI 未实现

---

### E. 语音控制 + 冥想模式 ✅ 功能完整

**文件**：
- `lib/services/voice_recognition_service.dart` (284 行)
- `lib/services/voice_synthesis_service.dart` (276 行)
- `lib/ai/voice_command_parser.dart` (224 行)
- `lib/bloc/meditation_mode_bloc.dart` (662 行)
- `lib/ui/screens/meditation_game_page.dart`

**验证结果**：
- 真实集成 `speech_to_text` 和 `flutter_tts`
- 四种解析模式：方向、传统中文坐标（横X竖Y）、国际（A1）、自然语言
- 中文数字映射（零-四）
- 字母映射（A-D → 0-3）
- 冥想 BLoC 处理 10+ 事件，含语音引导、状态播报、查询响应

---

### F. 测试覆盖 ❌ 文档严重虚高

**文档宣称**：135+ 单元测试，95.7% 覆盖率

**实际情况**：19 个测试文件

```
test/
├── ai/
│   ├── minimax_ai_test.dart
│   └── voice_command_parser_test.dart
├── bloc/
│   ├── game_bloc_test.dart
│   └── lan_game_bloc_test.dart
├── engine/
│   ├── capture_detector_test.dart
│   ├── game_engine_test.dart
│   └── move_validator_test.dart
├── models/
│   ├── board_state_test.dart
│   ├── game_result_test.dart
│   ├── move_test.dart
│   ├── piece_type_test.dart
│   └── position_test.dart
├── services/
│   ├── audio_service_test.dart
│   ├── game_replay_service_test.dart
│   ├── music_service_test.dart
│   └── storage_service_test.dart
├── ui/widgets/
│   ├── board_widget_test.dart
│   └── game_over_dialog_test.dart
└── widget_test.dart
```

**评估**：
- 核心引擎和模型层覆盖较好
- BLoC 层仅 game_bloc 和 lan_game_bloc 有测试
- 在线对战、冥想模式、语音服务无测试
- UI 测试极少（仅 2 个 widget）
- 无集成测试（integration_test/ 目录存在但未确认内容）

---

### G. 其他功能验证

| 功能 | 状态 | 说明 |
|---|---|---|
| 游戏回放 | ✅ | `game_replay_service.dart` (259 行)，前进/后退/跳转/进度条完整 |
| 本地存储 (Hive) | ✅ | `storage_service.dart` (407 行)，GameSettings toJson/fromJson |
| 国际化 (zh/en/ja) | ✅ | 三语 ARB 文件齐全，含真实翻译 |
| 主题系统 | ✅ | 3 套预设（经典木纹/现代简约/深夜），含棋子风格 |
| 背景音乐 | ✅ | `music_service.dart` (208 行)，5 种主题 |
| Wear OS | ⏸ 搁置 | `.dart.disabled` 文件存在，README 已说明原因 |

---

## 主要问题清单

### 严重（需修正）

1. **CHANGELOG 测试数据虚假** — "135+ 单元测试，95.7% 覆盖率" 与实际 19 个测试文件严重不符，属 AI 生成幻觉
2. **在线对战前端 TODO** — `online_game_page.dart:483` 棋子选中/移动逻辑未实现，是上线阻塞项

### 中等（建议修复）

3. **WebSocket 服务裸 print()** — 项目有 `LoggerService` 却未统一使用
4. **LAN 计时器同步缺失** — 文档已标注，但对实际对战体验有影响
5. **Watch 文件混乱** — 同时存在 `.dart` 和 `.dart.disabled` 副本，编译时可能引入问题

### 轻微（可后续处理）

6. **IMPLEMENTATION_PLAN.md 状态过时** — 根文件和 docs/design/ 下各有一份，内容不同步
7. **缺少在线对战相关测试** — online_game_bloc、websocket_service 无测试覆盖

---

## 修正后的真实完成度

| 阶段 | 真实完成度 |
|---|---|
| P1 核心游戏（引擎 + 双人） | **100%** |
| P2 人机对战（AI 三难度） | **100%** |
| P3 局域网对战 | **90%**（缺计时器同步、断线处理） |
| P4 在线对战 | **后端 100%，前端 ~70%**（落子 UI 是瓶颈） |
| P5 打包发布 | **0%** |
| 扩展：语音 + 冥想 | **95%**（功能完整，缺测试） |
| 扩展：Wear OS | **搁置**（基建保留） |
| 测试覆盖 | **~30%**（核心模块有，外围缺失） |

**总体项目完成度：约 75%**

---

## 后续优化方向

### 近期（收尾当前阶段）

- 补完 `online_game_page.dart` 的棋子选中和移动逻辑
- LAN 计时器同步 + 断线重连
- 统一日志（替换裸 print 为 LoggerService）
- 修正 CHANGELOG 中虚假的测试数据

### 中期（质量与发布）

- 补充在线对战、冥想模式的单元测试
- 端到端集成测试（LAN / Online 流程）
- 真机 profile（AI 置换表内存、低端机渲染）
- P5 打包发布流程（APK/AAB/iOS/Web + 商店素材）

### 远期（体验与商业化）

- 语音识别离线化（弱网场景）
- 匹配系统完善（ELO、排行榜、好友房）
- 社交分享 + 观战模式
- 参考《盈利模式与运营部署规划.md》落地付费点
- Wear OS 待 Flutter watch 生态稳定后重启
