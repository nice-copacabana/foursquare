# 阶段5：游戏体验细节优化 - 设计规范

## 概述

本文档详细描述阶段5未完成任务的设计规范，为后续实现提供完整的技术方案。

## 任务5.1：移动确认和撤销增强

### 1.1 移动确认机制

#### 功能需求
- 用户执行移动后，棋子显示为"待确认"状态
- 提供"确认"和"取消"按钮
- 确认后才正式执行移动并切换回合
- 可在设置中开启/关闭此功能

#### 数据模型扩展

```dart
// lib/bloc/game_state.dart
abstract class GameState extends Equatable {
  // 现有字段...
  
  /// 待确认的移动（移动确认模式）
  final Move? pendingMove;
  
  /// 待确认移动的棋盘预览状态
  final BoardState? pendingBoardState;
  
  /// 是否启用移动确认
  final bool moveConfirmationEnabled;
}

class GamePlaying extends GameState {
  const GamePlaying({
    // 现有参数...
    super.pendingMove,
    super.pendingBoardState,
    super.moveConfirmationEnabled = false,
  });
  
  GamePlaying copyWith({
    // 现有参数...
    Move? pendingMove,
    bool clearPendingMove = false,
    BoardState? pendingBoardState,
    bool clearPendingBoardState = false,
    bool? moveConfirmationEnabled,
  }) {
    return GamePlaying(
      // ...
      pendingMove: clearPendingMove ? null : (pendingMove ?? this.pendingMove),
      pendingBoardState: clearPendingBoardState ? null : (pendingBoardState ?? this.pendingBoardState),
      moveConfirmationEnabled: moveConfirmationEnabled ?? this.moveConfirmationEnabled,
    );
  }
  
  /// 是否有待确认的移动
  bool get hasPendingMove => pendingMove != null;
}
```

#### 事件处理

已在game_event.dart添加：
- `ConfirmMoveEvent`: 确认当前待确认的移动
- `CancelMoveEvent`: 取消当前待确认的移动

#### BLoC逻辑

```dart
// lib/bloc/game_bloc.dart
Future<void> _onMovePiece(MovePieceEvent event, Emitter<GameState> emit) async {
  if (state is! GamePlaying) return;
  final playing = state as GamePlaying;
  
  // 验证移动合法性
  if (!_moveValidator.isValidMove(playing.boardState, event.from, event.to)) {
    return;
  }
  
  // 执行移动（生成新棋盘）
  final result = _gameEngine.executeMove(playing.boardState, event.from, event.to);
  if (!result.success || result.newBoard == null) return;
  
  // 如果启用移动确认
  if (playing.moveConfirmationEnabled) {
    _audioService.playSound(SoundType.select);
    emit(playing.copyWith(
      pendingMove: result.move,
      pendingBoardState: result.newBoard,
      selectedPiece: null,
      clearSelectedPiece: true,
      validMoves: const [],
    ));
    return;
  }
  
  // 否则直接执行移动
  _executeConfirmedMove(result, playing, emit);
}

Future<void> _onConfirmMove(ConfirmMoveEvent event, Emitter<GameState> emit) async {
  if (state is! GamePlaying) return;
  final playing = state as GamePlaying;
  
  if (playing.pendingMove == null || playing.pendingBoardState == null) {
    return;
  }
  
  // 播放音效
  if (playing.pendingMove!.capturedPiece != null) {
    _audioService.playSound(SoundType.capture);
  } else {
    _audioService.playSound(SoundType.move);
  }
  
  // 执行确认的移动
  final newMoveHistory = [...playing.moveHistory, playing.pendingMove!];
  
  // 检查游戏是否结束
  final gameResult = _gameEngine.checkGameOver(playing.pendingBoardState!);
  
  if (gameResult != null) {
    // 游戏结束逻辑...
  } else {
    emit(playing.copyWith(
      boardState: playing.pendingBoardState!,
      moveHistory: newMoveHistory,
      lastMove: playing.pendingMove,
      clearPendingMove: true,
      clearPendingBoardState: true,
    ));
    
    // AI回合
    if (playing.isAITurn) {
      add(const AIPlayEvent());
    }
  }
}

Future<void> _onCancelMove(CancelMoveEvent event, Emitter<GameState> emit) async {
  if (state is! GamePlaying) return;
  final playing = state as GamePlaying;
  
  _audioService.playSound(SoundType.click);
  
  emit(playing.copyWith(
    clearPendingMove: true,
    clearPendingBoardState: true,
  ));
}
```

#### UI实现

```dart
// lib/ui/screens/game_page.dart
Widget _buildBoard(BuildContext context, GameState state) {
  if (state is GamePlaying && state.hasPendingMove) {
    return Stack(
      children: [
        // 显示待确认状态的棋盘
        AnimatedBoardWidget(
          boardState: state.pendingBoardState!,
          selectedPiece: null,
          validMoves: const [],
          pendingMove: state.pendingMove,
          onPositionTapped: null, // 待确认时禁用点击
        ),
        // 确认/取消按钮
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: _MoveConfirmationButtons(
            onConfirm: () {
              context.read<GameBloc>().add(const ConfirmMoveEvent());
            },
            onCancel: () {
              context.read<GameBloc>().add(const CancelMoveEvent());
            },
          ),
        ),
      ],
    );
  }
  
  // 正常棋盘
  return AnimatedBoardWidget(/* ... */);
}

class _MoveConfirmationButtons extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('取消'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('确认'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 1.2 Redo（重做）功能

#### 功能需求
- 支持重做之前撤销的移动
- 维护撤销/重做栈
- UI显示Redo按钮（当有可重做的移动时）

#### 数据模型

```dart
abstract class GameState extends Equatable {
  // 现有字段...
  
  /// 重做栈（存储被撤销的移动）
  final List<Move> redoStack;
}

class GamePlaying extends GameState {
  const GamePlaying({
    // ...
    super.redoStack = const [],
  });
  
  /// 是否可以重做
  bool get canRedo => redoStack.isNotEmpty && !isGameOver;
}
```

#### 事件处理

已添加：
- `RedoMoveEvent`: 重做之前撤销的移动

#### BLoC逻辑

```dart
// Undo逻辑需要更新
Future<void> _onUndoMove(UndoMoveEvent event, Emitter<GameState> emit) async {
  if (state is! GamePlaying) return;
  final playing = state as GamePlaying;
  
  if (!playing.canUndo) return;
  
  final stepsToUndo = event.steps.clamp(1, playing.moveHistory.length);
  
  // 保存被撤销的移动到redoStack
  final undoneMove = playing.moveHistory.sublist(
    playing.moveHistory.length - stepsToUndo,
  );
  final newRedoStack = [...undoneMove, ...playing.redoStack];
  
  // 撤销逻辑...
  final newMoveHistory = playing.moveHistory.sublist(
    0,
    playing.moveHistory.length - stepsToUndo,
  );
  
  // 重建棋盘
  var newBoard = BoardState.initial();
  for (final move in newMoveHistory) {
    final result = _gameEngine.executeMove(newBoard, move.from, move.to);
    if (result.success && result.newBoard != null) {
      newBoard = result.newBoard!;
    }
  }
  
  emit(playing.copyWith(
    boardState: newBoard,
    moveHistory: newMoveHistory,
    redoStack: newRedoStack,
    clearSelectedPiece: true,
    validMoves: const [],
  ));
}

Future<void> _onRedoMove(RedoMoveEvent event, Emitter<GameState> emit) async {
  if (state is! GamePlaying) return;
  final playing = state as GamePlaying;
  
  if (!playing.canRedo) return;
  
  final stepsToRedo = event.steps.clamp(1, playing.redoStack.length);
  
  // 从redoStack取出移动
  final movesToRedo = playing.redoStack.sublist(0, stepsToRedo);
  final newRedoStack = playing.redoStack.sublist(stepsToRedo);
  
  // 执行重做的移动
  var newBoard = playing.boardState;
  final newMoveHistory = [...playing.moveHistory];
  
  for (final move in movesToRedo) {
    final result = _gameEngine.executeMove(newBoard, move.from, move.to);
    if (result.success && result.newBoard != null) {
      newBoard = result.newBoard!;
      newMoveHistory.add(move);
    }
  }
  
  _audioService.playSound(SoundType.move);
  
  emit(playing.copyWith(
    boardState: newBoard,
    moveHistory: newMoveHistory,
    redoStack: newRedoStack,
    lastMove: movesToRedo.last,
  ));
}
```

#### UI更新

```dart
// lib/ui/widgets/game_info_panel.dart
class _ActionButtons extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onRestart;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo),
                label: const Text('撤销'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canRedo ? onRedo : null,
                icon: const Icon(Icons.redo),
                label: const Text('重做'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            label: const Text('重新开始'),
          ),
        ),
      ],
    );
  }
}
```

## 任务5.2：棋盘坐标和教程

### 2.1 棋盘坐标显示

#### 功能需求
- 在棋盘边缘显示坐标（行：1-4，列：A-D）
- 坐标样式：小巧、不突兀
- 可在设置中开启/关闭

#### UI实现

```dart
// lib/ui/widgets/board_widget.dart
class BoardWidget extends StatelessWidget {
  final bool showCoordinates;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部列坐标
        if (showCoordinates) _buildColumnLabels(),
        
        Row(
          children: [
            // 左侧行坐标
            if (showCoordinates) _buildRowLabels(),
            
            // 棋盘主体
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildBoard(context),
              ),
            ),
            
            // 右侧行坐标（镜像）
            if (showCoordinates) _buildRowLabels(),
          ],
        ),
        
        // 底部列坐标
        if (showCoordinates) _buildColumnLabels(),
      ],
    );
  }
  
  Widget _buildColumnLabels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['A', 'B', 'C', 'D']
            .map((label) => Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ))
            .toList(),
      ),
    );
  }
  
  Widget _buildRowLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['1', '2', '3', '4']
          .map((label) => Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ))
          .toList(),
    );
  }
}
```

### 2.2 教程系统

#### 功能需求
- 首次启动时显示交互式教程
- 教程内容：
  1. 游戏规则介绍
  2. 如何选择和移动棋子
  3. 吃子规则演示
  4. 获胜条件说明
- 支持跳过和重新查看

#### 数据模型

```dart
// lib/models/tutorial_step.dart
class TutorialStep {
  final String title;
  final String description;
  final String? imagePath;
  final Position? highlightPosition;
  final List<Position>? highlightPositions;
  final TutorialAction? action;
  
  const TutorialStep({
    required this.title,
    required this.description,
    this.imagePath,
    this.highlightPosition,
    this.highlightPositions,
    this.action,
  });
}

enum TutorialAction {
  selectPiece,
  movePiece,
  capturePiece,
  none,
}

class TutorialData {
  static final List<TutorialStep> steps = [
    TutorialStep(
      title: '欢迎来到四子游戏',
      description: '这是一个策略棋类游戏，目标是将4个己方棋子连成一线。',
    ),
    TutorialStep(
      title: '选择棋子',
      description: '点击你的棋子（黑色）来选中它。',
      highlightPositions: [
        Position(0, 0),
        Position(1, 0),
        Position(2, 0),
        Position(3, 0),
      ],
      action: TutorialAction.selectPiece,
    ),
    // ... 更多步骤
  ];
}
```

#### UI实现

```dart
// lib/ui/screens/tutorial_page.dart
class TutorialPage extends StatefulWidget {
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _currentStep = 0;
  
  @override
  Widget build(BuildContext context) {
    final step = TutorialData.steps[_currentStep];
    
    return Scaffold(
      body: Stack(
        children: [
          // 背景棋盘（演示用）
          _buildDemoBoard(step),
          
          // 高亮覆盖层
          if (step.highlightPositions != null)
            _buildHighlightOverlay(step.highlightPositions!),
          
          // 教程说明卡片
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _TutorialCard(
              step: step,
              currentIndex: _currentStep,
              totalSteps: TutorialData.steps.length,
              onNext: _nextStep,
              onPrevious: _previousStep,
              onSkip: _skipTutorial,
            ),
          ),
        ],
      ),
    );
  }
  
  void _nextStep() {
    if (_currentStep < TutorialData.steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _completeTutorial();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  void _skipTutorial() {
    Navigator.of(context).pop();
  }
  
  void _completeTutorial() {
    // 标记教程已完成
    StorageService().saveSetting('tutorial_completed', true);
    Navigator.of(context).pop();
  }
}
```

## 任务5.3：成就和排行榜系统

### 3.1 成就系统

#### 数据模型

```dart
// lib/models/achievement.dart
enum AchievementType {
  firstWin,        // 首胜
  win10Games,      // 赢得10场游戏
  win50Games,      // 赢得50场游戏
  win100Games,     // 赢得100场游戏
  perfectGame,     // 完美游戏（不失一子获胜）
  quickWin,        // 快速获胜（<10步）
  longGame,        // 持久战（>50步）
  captureStreak,   // 连续吃子
  beatHardAI,      // 击败困难AI
  winStreak5,      // 5连胜
  // ...更多成就
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final String iconPath;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0-1.0
  
  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
  });
}

class AchievementData {
  static final Map<AchievementType, Achievement> achievements = {
    AchievementType.firstWin: Achievement(
      type: AchievementType.firstWin,
      title: '首次胜利',
      description: '赢得你的第一场游戏',
      iconPath: 'assets/achievements/first_win.png',
      points: 10,
    ),
    // ... 更多成就定义
  };
}
```

#### 检测逻辑

```dart
// lib/services/achievement_service.dart
class AchievementService {
  final StorageService _storage = StorageService();
  
  Future<List<Achievement>> checkAchievements(GameResult result, GameStatistics stats) async {
    final unlockedAchievements = <Achievement>[];
    
    // 检查首胜
    if (result.status == GameStatus.blackWin && stats.totalGames == 1) {
      unlockedAchievements.add(await _unlockAchievement(AchievementType.firstWin));
    }
    
    // 检查胜场数成就
    if (stats.wins == 10) {
      unlockedAchievements.add(await _unlockAchievement(AchievementType.win10Games));
    }
    
    // 检查完美游戏
    if (result.status == GameStatus.blackWin) {
      final noCaptures = result.moveCount > 0 && 
          /* 检查没有被吃子 */;
      if (noCaptures) {
        unlockedAchievements.add(await _unlockAchievement(AchievementType.perfectGame));
      }
    }
    
    // ... 更多检查逻辑
    
    return unlockedAchievements;
  }
  
  Future<Achievement> _unlockAchievement(AchievementType type) async {
    final achievement = AchievementData.achievements[type]!;
    final unlocked = achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    
    await _storage.saveAchievement(unlocked);
    return unlocked;
  }
}
```

### 3.2 排行榜系统

#### 数据模型

```dart
// lib/models/leaderboard.dart
enum LeaderboardType {
  totalWins,
  winRate,
  longestStreak,
  totalPoints,
}

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int rank;
  final int value;
  final String? avatarUrl;
  
  const LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.rank,
    required this.value,
    this.avatarUrl,
  });
}

class Leaderboard {
  final LeaderboardType type;
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdate;
  
  const Leaderboard({
    required this.type,
    required this.entries,
    required this.lastUpdate,
  });
}
```

#### UI实现

```dart
// lib/ui/screens/achievements_page.dart
class AchievementsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: FutureBuilder<List<Achievement>>(
        future: _loadAchievements(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final achievement = snapshot.data![index];
              return _AchievementCard(achievement: achievement);
            },
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: achievement.isUnlocked ? Colors.amber.shade50 : Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 48,
            color: achievement.isUnlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked ? Colors.black : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (!achievement.isUnlocked && achievement.progress > 0)
            Padding(
              padding: const EdgeInsets.all(8),
              child: LinearProgressIndicator(
                value: achievement.progress,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
        ],
      ),
    );
  }
}
```

## 实现优先级

### P0 - 高优先级（建议下一轮实现）
1. ✅ Redo功能 - 事件已添加，需要BLoC逻辑实现
2. ⚠️ 移动确认机制 - 核心逻辑设计完成，需要UI实现
3. ⚠️ 棋盘坐标显示 - 简单功能，快速实现

### P1 - 中优先级
1. ⏸️ 教程系统 - 数据模型设计完成，需要完整UI
2. ⏸️ 成就系统基础 - 模型和检测逻辑已设计

### P2 - 低优先级
1. ⏸️ 排行榜系统 - 需要后端支持
2. ⏸️ 成就UI美化 - 可后续优化

## 预计工作量

| 任务 | 预计时间 | 难度 |
|------|---------|------|
| Redo功能实现 | 1-2小时 | ⭐⭐ |
| 移动确认机制 | 2-3小时 | ⭐⭐⭐ |
| 棋盘坐标显示 | 30分钟 | ⭐ |
| 教程系统 | 4-6小时 | ⭐⭐⭐⭐ |
| 成就系统 | 3-4小时 | ⭐⭐⭐ |
| 排行榜系统 | 1-2天 | ⭐⭐⭐⭐⭐ |

## 总结

本设计文档提供了阶段5所有任务的完整技术规范，包括：
- 详细的数据模型设计
- BLoC事件和状态定义
- UI实现示例代码
- 实现优先级建议

所有设计均遵循项目现有架构和代码规范，可直接用于后续实现。
