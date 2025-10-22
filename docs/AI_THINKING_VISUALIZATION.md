# AI思考可视化功能文档

## 概述

本文档描述了AI思考可视化功能的实现细节。该功能在AI进行移动决策时，向用户展示实时的思考进度和状态信息，提升用户体验和交互透明度。

## 功能特性

### 1. 实时进度指示
- **进度条**: 显示AI当前搜索深度的百分比进度
- **百分比**: 数字形式展示当前进度（0%-100%）
- **动画效果**: 平滑的进度条填充动画

### 2. 状态文本
- **初始化**: "初始化..."
- **搜索进度**: "搜索深度 X/Y"（如："搜索深度 2/4"）
- **完成状态**: "完成，评估了 N 个节点"

### 3. 视觉设计
- **颜色方案**: 使用蓝色主题表示AI思考
  - 背景: `Colors.blue.shade50`
  - 边框: `Colors.blue.shade200`
  - 进度条: `Colors.blue.shade400`
  - 文本: `Colors.blue.shade800`
- **图标**: 旋转的CircularProgressIndicator
- **布局**: 紧凑的卡片式设计，嵌入到游戏信息面板中

## 技术实现

### 1. 数据流

```
MinimaxAI (进度回调)
    ↓
GameBloc (状态更新)
    ↓
GameState (进度数据)
    ↓
GamePage (读取状态)
    ↓
GameInfoPanel (UI渲染)
    ↓
_AIThinkingIndicator (进度展示)
```

### 2. 核心组件

#### 2.1 MinimaxAI进度回调

**文件**: `lib/ai/minimax_ai.dart`

```dart
class MinimaxAI extends AIPlayer {
  // 进度回调函数
  Function(double progress, String status)? _progressCallback;
  
  /// 设置进度回调
  void setProgressCallback(Function(double progress, String status)? callback) {
    _progressCallback = callback;
  }
  
  @override
  Future<AIMoveResult?> selectMove(BoardState board) async {
    // 迭代加深搜索中报告进度
    for (int depth = 1; depth <= maxDepth; depth++) {
      _progressCallback?.call(
        depth / maxDepth,
        '搜索深度 $depth/$maxDepth',
      );
      // ... 搜索逻辑
    }
    
    // 完成时报告
    _progressCallback?.call(1.0, '完成，评估了 $nodesEvaluated 个节点');
  }
}
```

**关键点**:
- 在迭代加深的每个深度开始时调用回调
- 提供归一化的进度值（0.0-1.0）
- 提供可读的状态描述

#### 2.2 GameState状态字段

**文件**: `lib/bloc/game_state.dart`

新增字段：
```dart
abstract class GameState extends Equatable {
  /// AI思考进度 (0.0-1.0)
  final double aiThinkingProgress;
  
  /// AI思考状态描述
  final String aiThinkingStatus;
  
  // ... 其他字段
}
```

**关键点**:
- 所有GameState子类都包含这些字段
- GamePlaying.copyWith支持更新进度和状态
- 包含在Equatable的props中，确保状态变化触发UI重建

#### 2.3 GameBloc进度处理

**文件**: `lib/bloc/game_bloc.dart`

```dart
Future<void> _onAIPlay(AIPlayEvent event, Emitter<GameState> emit) async {
  // 初始化
  emit(playing.copyWith(
    isAIThinking: true,
    aiThinkingProgress: 0.0,
    aiThinkingStatus: '初始化...',
  ));
  
  // 创建AI并设置回调
  final ai = MinimaxAI(aiDifficulty);
  ai.setProgressCallback((progress, status) {
    if (state is GamePlaying) {
      emit((state as GamePlaying).copyWith(
        isAIThinking: true,
        aiThinkingProgress: progress,
        aiThinkingStatus: status,
      ));
    }
  });
  
  // 执行AI思考
  final aiMove = await ai.selectMove(playing.boardState);
  
  // 完成，清除进度
  emit(playing.copyWith(
    isAIThinking: false,
    aiThinkingProgress: 0.0,
    aiThinkingStatus: '',
  ));
}
```

**关键点**:
- 在AI开始前设置初始状态
- 通过回调实时更新状态
- 完成后清除所有进度信息

#### 2.4 GameInfoPanel UI组件

**文件**: `lib/ui/widgets/game_info_panel.dart`

```dart
class GameInfoPanel extends StatelessWidget {
  final double aiThinkingProgress;
  final String aiThinkingStatus;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // 当前玩家指示器
          _CurrentPlayerIndicator(...),
          
          // AI思考指示器（条件渲染）
          if (isAIThinking)
            _AIThinkingIndicator(
              progress: aiThinkingProgress,
              status: aiThinkingStatus,
            ),
          
          // 其他组件...
        ],
      ),
    );
  }
}
```

#### 2.5 _AIThinkingIndicator组件

**文件**: `lib/ui/widgets/game_info_panel.dart`

```dart
class _AIThinkingIndicator extends StatelessWidget {
  final double progress;
  final String status;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          // 标题行
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(...),
              ),
              Text('AI思考中'),
              Spacer(),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          
          // 进度条
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
          ),
          
          // 状态文本
          if (status.isNotEmpty)
            Text(status, style: ...),
        ],
      ),
    );
  }
}
```

**关键点**:
- 使用Container创建卡片式设计
- CircularProgressIndicator提供动态旋转动画
- LinearProgressIndicator显示进度
- 条件渲染状态文本

#### 2.6 GamePage集成

**文件**: `lib/ui/screens/game_page.dart`

```dart
Widget _buildInfoPanel(BuildContext context, GameState state) {
  final isAIThinking = state is GamePlaying && state.isAIThinking;
  final aiProgress = state is GamePlaying ? state.aiThinkingProgress : 0.0;
  final aiStatus = state is GamePlaying ? state.aiThinkingStatus : '';

  return GameInfoPanel(
    // ... 其他属性
    isAIThinking: isAIThinking,
    aiThinkingProgress: aiProgress,
    aiThinkingStatus: aiStatus,
  );
}
```

**关键点**:
- 安全地从GameState中提取进度数据
- 仅在GamePlaying状态下有效
- 传递给GameInfoPanel进行渲染

## 用户体验流程

### 1. AI开始思考
- GameBloc接收到AIPlayEvent
- 状态更新为`isAIThinking: true, progress: 0.0, status: '初始化...'`
- UI显示AI思考指示器，进度为0%

### 2. 搜索过程
- MinimaxAI进行迭代加深搜索
- 每完成一个深度，调用进度回调
- 状态更新：`progress: 0.25, status: '搜索深度 1/4'`
- UI更新进度条和百分比

### 3. 搜索完成
- MinimaxAI完成所有深度搜索
- 最后一次回调：`progress: 1.0, status: '完成，评估了 1234 个节点'`
- 短暂显示完成状态

### 4. 执行移动
- GameBloc清除AI思考状态
- 状态更新：`isAIThinking: false, progress: 0.0, status: ''`
- AI思考指示器从UI中移除
- 棋盘执行AI的移动

## 性能考虑

### 1. 状态更新频率
- **问题**: 频繁的状态更新可能导致UI闪烁或性能下降
- **解决方案**: 仅在深度变化时更新，不在每个节点评估时更新
- **效果**: 通常每次AI思考只有3-4次状态更新

### 2. 异步回调
- **问题**: 回调在AI线程中执行，可能与主线程冲突
- **解决方案**: 使用Emitter确保线程安全
- **效果**: BLoC框架自动处理状态同步

### 3. UI重建
- **问题**: 状态变化触发整个GamePage重建
- **解决方案**: 使用BlocBuilder局部重建
- **效果**: 只有GameInfoPanel重建，棋盘不受影响

## 扩展性

### 可能的增强功能

1. **思考深度可视化**
   - 显示当前搜索树的层级结构
   - 展示已评估的移动数量

2. **最佳移动预览**
   - 在思考过程中高亮当前最佳移动
   - 显示评估分数

3. **性能指标**
   - 显示节点评估速率（nodes/sec）
   - 显示剪枝效率

4. **历史记录**
   - 记录每次AI思考的时间
   - 展示思考时间趋势图

5. **可配置选项**
   - 用户可选择是否显示AI思考
   - 可调整详细程度（简单/详细）

## 测试建议

### 单元测试
```dart
test('AI progress callback updates state', () async {
  final bloc = GameBloc();
  bloc.add(NewGameEvent(mode: GameMode.pve));
  bloc.add(AIPlayEvent());
  
  await expectLater(
    bloc.stream,
    emitsInOrder([
      isA<GamePlaying>().having((s) => s.aiThinkingProgress, 'progress', 0.0),
      isA<GamePlaying>().having((s) => s.aiThinkingProgress, 'progress', greaterThan(0.0)),
      isA<GamePlaying>().having((s) => s.isAIThinking, 'thinking', false),
    ]),
  );
});
```

### UI测试
```dart
testWidgets('AI thinking indicator shows progress', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameInfoPanel(
        isAIThinking: true,
        aiThinkingProgress: 0.5,
        aiThinkingStatus: '搜索深度 2/4',
        // ...
      ),
    ),
  );
  
  expect(find.text('AI思考中'), findsOneWidget);
  expect(find.text('50%'), findsOneWidget);
  expect(find.text('搜索深度 2/4'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

### 集成测试
- 启动PVE游戏，AI先手
- 验证AI思考指示器出现
- 验证进度从0%增长到100%
- 验证状态文本变化
- 验证移动执行后指示器消失

## 总结

AI思考可视化功能通过以下方式提升用户体验：

1. **透明性**: 用户可以看到AI正在工作，不会觉得应用卡顿
2. **反馈**: 实时进度让用户了解还需等待多久
3. **专业性**: 详细的状态信息展示AI的复杂性
4. **信任**: 可见的思考过程增加对AI的信任

实现简洁高效，仅涉及5个文件的修改：
- 1个AI类（进度回调）
- 2个BLoC类（状态管理）
- 2个UI类（视觉展示）

整体代码增量约150行，无性能影响，用户体验显著提升。
