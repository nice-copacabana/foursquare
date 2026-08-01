import 'package:flutter/material.dart';

import '../../models/board_state.dart';
import '../../models/piece_type.dart';
import '../../models/position.dart';
import '../widgets/themed_board_widget.dart';

class InteractiveTutorialPage extends StatefulWidget {
  const InteractiveTutorialPage({super.key});

  @override
  State<InteractiveTutorialPage> createState() =>
      _InteractiveTutorialPageState();
}

class _InteractiveTutorialPageState extends State<InteractiveTutorialPage> {
  BoardState _board = BoardState.initial(currentPlayer: PieceType.black);
  Position? _selected;
  List<Position> _validMoves = const [];
  int _step = 0;

  static const _messages = [
    '先选择左上角的墨方棋子。',
    '很好。现在把它移动到下方相邻空位。',
    '落子完成。实战中每回合有 60 秒，双方轮流移动。',
    '吃子必须匹配完整四格：己-己-敌-空，或规定的反向排列。落子必须属于相邻双子。',
    '横向与竖向可同时吃子；对方只剩一子、无合法移动或超时都会判负。',
  ];

  void _onPositionTapped(Position position) {
    if (_step == 0 && position == const Position(0, 0)) {
      setState(() {
        _selected = position;
        _validMoves = const [Position(0, 1)];
        _step = 1;
      });
      return;
    }
    if (_step == 1 &&
        _selected == const Position(0, 0) &&
        position == const Position(0, 1)) {
      setState(() {
        _board = _board
            .movePiece(const Position(0, 0), const Position(0, 1))
            .switchPlayer();
        _selected = null;
        _validMoves = const [];
        _step = 2;
      });
    }
  }

  void _advance() {
    if (_step < _messages.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('互动教程')),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _messages.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(child: Text('${_step + 1}')),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _messages[_step],
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ThemedBoardWidget(
                          boardState: _board,
                          selectedPiece: _selected,
                          validMoves: _validMoves,
                          onPositionTapped: _onPositionTapped,
                        ),
                      ),
                    ),
                    if (_step >= 3) ...[
                      const SizedBox(height: 20),
                      const _CapturePattern(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _step < 2 ? null : _advance,
                  child: Text(
                    _step == _messages.length - 1 ? '完成教程' : '下一步',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePattern extends StatelessWidget {
  const _CapturePattern();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '允许的吃子排列，己、己、敌、空',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['己', '己', '敌', '空']
            .map(
              (value) => Container(
                width: 48,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == '己'
                      ? Theme.of(context).colorScheme.primaryContainer
                      : value == '敌'
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(value),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
