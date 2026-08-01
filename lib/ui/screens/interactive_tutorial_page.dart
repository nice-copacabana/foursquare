import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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

  static const _messageCount = 5;

  List<String> _messages(AppLocalizations l10n) => [
        l10n.tutorialStep1,
        l10n.tutorialStep2,
        l10n.tutorialStep3,
        l10n.tutorialStep4,
        l10n.tutorialStep5,
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
    if (_step < _messageCount - 1) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = _messages(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tutorialTitle)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _messageCount),
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
                                  messages[_step],
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
                    _step == _messageCount - 1
                        ? l10n.finishTutorial
                        : l10n.next,
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
    final l10n = AppLocalizations.of(context)!;
    final cells = [
      (label: l10n.ownPiece, kind: 1),
      (label: l10n.ownPiece, kind: 1),
      (label: l10n.enemyPiece, kind: 0),
      (label: l10n.emptyCell, kind: -1),
    ];
    return Semantics(
      label: l10n.tutorialCapturePatternSemantics,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cells
            .map(
              (cell) => Container(
                width: 48,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cell.kind == 1
                      ? Theme.of(context).colorScheme.primaryContainer
                      : cell.kind == 0
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(cell.label),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
