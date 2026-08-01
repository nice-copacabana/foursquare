/// Game Replay Page - 游戏回放页面
///
/// 显示游戏回放界面，包括：
/// - 棋盘显示（只读）
/// - 回放控制按钮
/// - 步骤导航
/// - 移动历史列表
library;

import 'package:flutter/material.dart';
import '../../models/move.dart';
import '../../models/piece_type.dart';
import '../../services/game_replay_service.dart';
import '../widgets/themed_board_widget.dart';

class GameReplayPage extends StatefulWidget {
  /// 移动历史
  final List<Move> moveHistory;

  /// 游戏模式标题
  final String gameTitle;
  final PieceType startingPlayer;

  const GameReplayPage({
    super.key,
    required this.moveHistory,
    this.gameTitle = '游戏回放',
    this.startingPlayer = PieceType.black,
  });

  @override
  State<GameReplayPage> createState() => _GameReplayPageState();
}

class _GameReplayPageState extends State<GameReplayPage> {
  late final GameReplayService _replayService;
  late ReplayState _replayState;

  @override
  void initState() {
    super.initState();
    _replayService = GameReplayService();
    _replayState = _replayService.startReplay(
      widget.moveHistory,
      startingPlayer: widget.startingPlayer,
    );
  }

  @override
  void dispose() {
    _replayService.exitReplay();
    super.dispose();
  }

  void _updateState(ReplayState newState) {
    setState(() {
      _replayState = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showReplayInfo,
            tooltip: '回放说明',
          ),
        ],
      ),
      body: Column(
        children: [
          // 步骤信息
          _buildStepInfo(),

          // 棋盘显示
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ThemedBoardWidget(
                    boardState: _replayState.boardState,
                    selectedPiece: null,
                    validMoves: const [],
                    lastMoveFrom: _replayState.currentMove?.from,
                    lastMoveTo: _replayState.currentMove?.to,
                    capturedPiecePosition:
                        _replayState.currentMove?.capturedPiece,
                    onPositionTapped: (_) {}, // 禁用交互
                  ),
                ),
              ),
            ),
          ),

          // 当前移动信息
          if (_replayState.currentMove != null) _buildCurrentMoveInfo(),

          // 回放控制按钮
          _buildControls(),

          // 移动历史列表
          _buildMoveHistory(),
        ],
      ),
    );
  }

  Widget _buildStepInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 20),
          const SizedBox(width: 8),
          Text(
            _replayState.stepDescription,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMoveInfo() {
    final move = _replayState.currentMove!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            move.hasCapture ? Icons.close : Icons.arrow_forward,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              move.getDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: (_replayState.currentStep + 1).toDouble(),
              min: 0,
              max: _replayState.totalSteps.toDouble(),
              divisions:
                  _replayState.totalSteps > 0 ? _replayState.totalSteps : 1,
              label: _replayState.isAtStart
                  ? '初始'
                  : '第 ${_replayState.currentStep + 1} 步',
              onChanged: (value) {
                _updateState(_replayService.goToStep(value.toInt() - 1));
              },
            ),
          ),
          const SizedBox(height: 8),

          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _replayState.canGoBackward
                    ? () => _updateState(_replayService.goToStart())
                    : null,
                tooltip: '第一步',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _replayState.canGoBackward
                    ? () => _updateState(_replayService.goBackward())
                    : null,
                tooltip: '上一步',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _replayState.canGoForward
                    ? () => _updateState(_replayService.goForward())
                    : null,
                tooltip: '下一步',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _replayState.canGoForward
                    ? () => _updateState(_replayService.goToEnd())
                    : null,
                tooltip: '最后一步',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoveHistory() {
    if (widget.moveHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: widget.moveHistory.length,
        itemBuilder: (context, index) {
          final move = widget.moveHistory[index];
          final isCurrentStep = index == _replayState.currentStep;

          return Card(
            color: isCurrentStep
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            elevation: isCurrentStep ? 2 : 0,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                child: Text('${index + 1}'),
              ),
              title: Text(
                move.getDescription(),
                style: TextStyle(
                  fontWeight: isCurrentStep ? FontWeight.bold : null,
                ),
              ),
              trailing:
                  move.hasCapture ? const Icon(Icons.close, size: 20) : null,
              onTap: () {
                _updateState(_replayService.goToStep(index));
              },
            ),
          );
        },
      ),
    );
  }

  void _showReplayInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('回放说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📱 控制说明：'),
              SizedBox(height: 8),
              Text('• 使用滑块可快速跳转到任意步骤'),
              Text('• 点击按钮可逐步回放'),
              Text('• 点击历史记录可直接跳转'),
              SizedBox(height: 16),
              Text('🎮 功能说明：'),
              SizedBox(height: 8),
              Text('• 棋盘为只读模式，不可操作'),
              Text('• 高亮显示当前步骤的移动'),
              Text('• 带❌标记表示该步骤有吃子'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
