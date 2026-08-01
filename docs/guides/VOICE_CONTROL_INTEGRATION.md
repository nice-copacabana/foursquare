# 语音控制集成指南

## 当前状态

语音能力仍处于 Phase 4 隐藏开发阶段，不能作为可用或可发布功能对外声明。

当前代码已经具备可测试的纯核心：

- `VoiceGameIntentParser`：把完整语句转换为类型化位置、移动或生命周期动作。
- `MicrophonePermissionPort`、`VoiceRecognitionPort`、`VoiceSynthesisPort`：隔离平台权限、识别和播报实现。
- `VoiceInteractionController`：管理显式启用、单次监听、处理、播报、打断、恢复和销毁。
- `VoiceGameIntentDispatcher`：把类型化意图转换为普通游戏事件，不判断棋规。
- `ActivateBoardPositionEvent`：触屏与语音共用的单坐标输入边界。

当前尚未完成生产 Adapter、用户用途说明、系统权限配置、正式入口、真机质量验证和隐私披露。因此不要在 Android/iOS 清单中提前声明麦克风权限，也不要把隐藏入口开放给用户。

## 架构边界

```text
用户显式开启
  -> MicrophonePermissionPort
  -> VoiceInteractionController
  -> VoiceRecognitionPort（一次监听）
  -> VoiceGameIntentParser（整句白名单）
  -> VoiceGameIntentDispatcher
  -> GameBloc
  -> MoveValidator / GameEngine（最终规则裁决）
```

语音层不得导入或调用 `MoveValidator`、`GameEngine`，不得自行修改棋盘，也不得把移动标记为 `isAIMove: true`。规则是否合法、是否超时、是否轮到玩家、吃子与终局结果始终由现有 `GameBloc` 和引擎决定。

触屏同样发送 `ActivateBoardPositionEvent`。GameBloc 根据收到事件时的最新状态解释为选中、重选、取消或移动，避免页面和语音各维护一套交互规则。

## 时序契约

- 默认状态为 `disabled`，不得初始化识别或播报，也不得请求权限。
- 只有用户看过用途说明并主动操作后，才调用 `enableAfterDisclosure()`。
- 只有 `ready` 接受 `listenOnce()`；每次调用只监听一轮，不自动连续监听。
- 播报开始前先作废旧识别回调并停止麦克风。
- `VoiceSynthesisPort.speak()` 必须等到实际播放完成后才完成 Future。
- TTS 播放期间拒绝新的监听请求；播放完成后只回到 `ready`，不会自动开麦。
- 来电、音频焦点变化或页面进入后台时调用 `interrupt()`；恢复只回到 `ready`，不会自动监听。
- 页面销毁必须调用 `dispose()`；迟到的识别、错误或 TTS 回调不得再改变状态。

## 指令契约

当前首期只规划中文语音。解析器使用整句白名单，不做高风险猜测。

支持的类型包括：

- 单位置：`横一竖二`、`A2`、`移动到 A2`、`左上`。
- 完整移动：`从 A1 移动到 A2`、`将横一竖一移到横四竖四`。
- 生命周期动作：取消选择、重复、暂停、继续、退出语音模式。

4×4 棋盘没有唯一中心格，因此“中间”“中心”必须要求重说。否定句、缺少来源的双坐标句、包含额外坐标或未消费尾缀的语句必须拒绝，例如：

- `不要移动到 A2`
- `A1 到 A2`
- `从 A1 移动到 A2 再到 A3`

识别原文只能作为一次回调中的局部值存在。它不得进入 `GameState`、日志、Sentry、持久化、网络请求或任何对象的明文 `toString()`。

## 平台 Adapter 待办

最终选定 ASR/TTS 引擎后，再实现以下 Adapter：

1. 麦克风权限 Adapter：区分拒绝、永久拒绝和受限状态，只由显式用户动作触发请求。
2. 识别 Adapter：一次会话只产生一个最终结果；停止后旧 session 回调失效。
3. 播报 Adapter：以平台 completion callback 完成 Future，不能把插件 `speak()` 调用被接受当作播放完成。
4. 音频焦点 Adapter：覆盖来电、蓝牙切换、耳机拔出、后台和系统抢占。

生产 Adapter 必须使用当前端口接入，不能让页面或 GameBloc 直接协调插件回调。

## 验证门禁

在开放入口前至少完成：

- 权限通过、拒绝、永久拒绝、受限和设置跳转。
- 识别/TTS 初始化失败、运行失败和音频中断。
- 播报与监听永不重叠，挂起启动、挂起停止和迟到回调均安全。
- 语音移动和触屏移动经过同一权威规则链。
- Android/iOS 真机中文识别、TTS completion、来电、蓝牙和后台恢复。
- 隐私政策与 Google Play 数据安全声明和实际引擎的数据处理方式一致。

纯核心自动化：

```powershell
flutter test test/ai/voice_game_intent_parser_test.dart
flutter test test/services/voice_interaction_controller_test.dart
flutter test test/services/voice_game_intent_dispatcher_test.dart
flutter test test/services/voice_privacy_contract_test.dart
flutter test test/bloc/game_bloc_test.dart
```
