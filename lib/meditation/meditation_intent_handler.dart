import 'package:equatable/equatable.dart';

import '../ai/ai_player.dart';
import '../ai/voice_command_parser.dart';
import '../ai/voice_game_intent.dart';
import '../models/game_result.dart';
import '../models/move.dart';
import '../models/piece_type.dart';
import '../models/position.dart';
import 'meditation_session.dart';
import 'meditation_session_controller.dart';

final class MeditationPrompt extends Equatable {
  final String text;

  const MeditationPrompt(this.text);

  @override
  List<Object?> get props => [text];

  @override
  String toString() => 'MeditationPrompt(textLength: ${text.length})';
}

final class MeditationTurnResponse {
  final MeditationPrompt prompt;
  final MeditationActionResult? action;
  final MeditationActionResult? aiAction;
  final bool exitConfirmationRequested;

  const MeditationTurnResponse({
    required this.prompt,
    this.action,
    this.aiAction,
    this.exitConfirmationRequested = false,
  });

  @override
  String toString() =>
      'MeditationTurnResponse(promptLength: ${prompt.text.length}, '
      'exitConfirmationRequested: $exitConfirmationRequested)';
}

/// Applies already-typed voice intents and narrates committed authority state.
final class MeditationIntentHandler {
  final MeditationSessionController _controller;
  final AIPlayer _aiPlayer;
  final Future<void> Function(MeditationSession session)? _onSessionChanged;
  MeditationPrompt? _lastPrompt;
  bool _pendingExitConfirmation = false;
  Future<MeditationActionResult>? _aiFlight;
  int? _aiFlightRevision;
  Future<void>? _notificationFlight;
  int? _notificationRevision;
  int? _committedRevision;
  Future<void> _notificationTail = Future<void>.value();

  MeditationIntentHandler({
    required MeditationSessionController controller,
    required AIPlayer aiPlayer,
    Future<void> Function(MeditationSession session)? onSessionChanged,
    int? initialCommittedRevision,
  })  : _controller = controller,
        _aiPlayer = aiPlayer,
        _onSessionChanged = onSessionChanged,
        _committedRevision = initialCommittedRevision;

  MeditationPrompt openingPrompt() {
    final session = _controller.session;
    final prompt = MeditationPrompt(
      '冥想对局开始。您执${_playerName(session.humanPlayer)}，'
      '${_playerName(session.firstPlayer)}先手。',
    );
    _lastPrompt = prompt;
    return prompt;
  }

  Future<MeditationTurnResponse> start() async {
    final initialPhase = _controller.session.phase;
    if (initialPhase == MeditationSessionPhase.completed) {
      await _notifySession(_controller.session);
      return _remember(
        MeditationTurnResponse(
          prompt: MeditationPrompt(
            _describeTerminal(_controller.session.gameResult!),
          ),
        ),
      );
    }
    if (initialPhase == MeditationSessionPhase.paused) {
      await _notifySession(_controller.session);
      return _remember(
        const MeditationTurnResponse(
          prompt: MeditationPrompt('冥想对局处于暂停状态，请说继续。'),
        ),
      );
    }

    MeditationActionResult lifecycle;
    if (initialPhase == MeditationSessionPhase.opening) {
      lifecycle = _controller.completeOpening();
    } else {
      lifecycle = _controller.tick();
    }
    if (lifecycle.outcome == MeditationActionOutcome.completed) {
      await _notifyAction(lifecycle);
      return _remember(
        MeditationTurnResponse(
          prompt: MeditationPrompt(
            _describeTerminal(lifecycle.session.gameResult!),
          ),
          action: lifecycle,
        ),
      );
    }

    final session = _controller.session;
    if (session.phase == MeditationSessionPhase.aiTurn) {
      return _advanceAiTurn(prefix: '对手先行。', action: lifecycle);
    }
    await _notifySession(session);
    return _remember(
      MeditationTurnResponse(
        prompt: const MeditationPrompt('轮到您行棋。'),
        action: lifecycle,
      ),
    );
  }

  Future<MeditationTurnResponse> handle(VoiceGameIntent intent) async {
    if (_pendingExitConfirmation) {
      return _handlePendingExit(intent);
    }
    switch (intent) {
      case VoicePositionIntent(:final position):
        return _handleAuthorityAction(
          _controller.activateHumanPosition(position),
        );
      case VoiceMoveIntent(:final from, :final to):
        return _handleAuthorityAction(
          _controller.submitHumanMove(from, to),
        );
      case VoiceActionIntent(action: VoiceGameAction.cancelSelection):
        return _handleAuthorityAction(_controller.cancelSelection());
      case VoiceActionIntent(action: VoiceGameAction.repeat):
        return MeditationTurnResponse(
          prompt: _lastPrompt ?? const MeditationPrompt('暂无可重复的播报。'),
        );
      case VoiceActionIntent(action: VoiceGameAction.pause):
        return _handleAuthorityAction(_controller.pause());
      case VoiceActionIntent(action: VoiceGameAction.resume):
        final resumed = _controller.resume();
        if (resumed.outcome == MeditationActionOutcome.resumed &&
            _controller.session.phase == MeditationSessionPhase.aiTurn) {
          return _advanceAiTurn(
            prefix: _describeAction(resumed),
            action: resumed,
          );
        }
        return _handleAuthorityAction(resumed);
      case VoiceActionIntent(action: VoiceGameAction.exit):
        _pendingExitConfirmation = true;
        return _remember(
          const MeditationTurnResponse(
            prompt: MeditationPrompt('请确认退出冥想对局。确认后本局将按弃局结束。'),
            exitConfirmationRequested: true,
          ),
        );
      case VoiceActionIntent(action: VoiceGameAction.confirmExit):
        return _remember(
          const MeditationTurnResponse(
            prompt: MeditationPrompt('当前没有等待确认的退出请求。'),
          ),
        );
      case VoiceActionIntent(action: VoiceGameAction.cancelExit):
        return _remember(
          const MeditationTurnResponse(
            prompt: MeditationPrompt('当前没有需要取消的退出请求。'),
          ),
        );
      case VoiceActionIntent(action: VoiceGameAction.retry):
        return _advanceAiTurn();
      case VoiceActionIntent(action: VoiceGameAction.myPieces):
        return _handleQuery(
          () => MeditationPrompt(
            _describePieces(
              _controller.session.humanPlayer,
              owner: '您的棋子',
            ),
          ),
        );
      case VoiceActionIntent(action: VoiceGameAction.opponentPieces):
        return _handleQuery(
          () => MeditationPrompt(
            _describePieces(
              _controller.session.aiPlayer,
              owner: '对手棋子',
            ),
          ),
        );
      case VoiceActionIntent(action: VoiceGameAction.pieceCount):
        return _handleQuery(
          () => MeditationPrompt(_describePieceCount()),
        );
      case VoiceActionIntent(action: VoiceGameAction.availableMoves):
        return _handleQuery(
          () => MeditationPrompt(_describeAvailableMoves()),
        );
    }
  }

  /// Re-evaluates the absolute turn deadline without requiring voice input.
  Future<MeditationActionResult> settle() async {
    final action = _controller.tick();
    await _notifyAction(action);
    return action;
  }

  Future<MeditationTurnResponse> _handlePendingExit(
    VoiceGameIntent intent,
  ) async {
    if (intent case VoiceActionIntent(:final action)) {
      switch (action) {
        case VoiceGameAction.confirmExit:
          _pendingExitConfirmation = false;
          return _handleAuthorityAction(_controller.abandon());
        case VoiceGameAction.cancelExit:
        case VoiceGameAction.cancelSelection:
        case VoiceGameAction.resume:
          _pendingExitConfirmation = false;
          return _remember(
            const MeditationTurnResponse(
              prompt: MeditationPrompt('已取消退出，继续对局。'),
            ),
          );
        case VoiceGameAction.repeat:
        case VoiceGameAction.exit:
          return MeditationTurnResponse(
            prompt: _lastPrompt ?? const MeditationPrompt('请确认退出，或说取消退出继续对局。'),
            exitConfirmationRequested: true,
          );
        case VoiceGameAction.pause:
        case VoiceGameAction.retry:
        case VoiceGameAction.myPieces:
        case VoiceGameAction.opponentPieces:
        case VoiceGameAction.pieceCount:
        case VoiceGameAction.availableMoves:
          break;
      }
    }
    return _remember(
      const MeditationTurnResponse(
        prompt: MeditationPrompt('请先说确认退出，或说取消退出继续对局。'),
        exitConfirmationRequested: true,
      ),
    );
  }

  Future<MeditationTurnResponse> _handleAuthorityAction(
    MeditationActionResult action,
  ) async {
    await _notifyAction(action);
    if (action.outcome != MeditationActionOutcome.moved) {
      final prompt = action.outcome == MeditationActionOutcome.completed &&
              action.committedMove != null
          ? '${_describeCommittedMove(action.committedMove!, true)} '
              '${_describeTerminal(action.session.gameResult!)}'
          : _describeAction(action);
      return _remember(
        MeditationTurnResponse(
          prompt: MeditationPrompt(prompt),
          action: action,
        ),
      );
    }

    final humanMove = _describeCommittedMove(action.committedMove!, true);
    if (_controller.session.phase == MeditationSessionPhase.aiTurn) {
      return _advanceAiTurn(
        prefix: humanMove,
        action: action,
        actionPersisted: true,
      );
    }
    return _remember(
      MeditationTurnResponse(
        prompt: MeditationPrompt('$humanMove 轮到您行棋。'),
        action: action,
      ),
    );
  }

  Future<MeditationTurnResponse> _advanceAiTurn({
    String? prefix,
    MeditationActionResult? action,
    bool actionPersisted = false,
  }) async {
    if (!actionPersisted) {
      final actionChanged = await _notifyAction(action);
      if (!actionChanged) {
        await _notifySession(_controller.session);
      }
    }
    final parts = <String>[if (prefix != null) prefix];
    final aiAction = await _playAiTurnOnce();
    await _notifyAction(aiAction);
    if (aiAction.committedMove != null) {
      parts.add(_describeCommittedMove(aiAction.committedMove!, false));
    }

    final session = _controller.session;
    if (session.gameResult != null) {
      parts.add(_describeTerminal(session.gameResult!));
    } else if (aiAction.rejection == MeditationRejection.aiUnavailable ||
        aiAction.rejection == MeditationRejection.illegalMove) {
      parts.add('对手暂时无法完成行棋，请稍后说重试。');
    } else if (session.phase == MeditationSessionPhase.humanTurn) {
      parts.add('轮到您行棋。');
    } else {
      parts.add(_describeAction(aiAction));
    }

    return _remember(
      MeditationTurnResponse(
        prompt: MeditationPrompt(parts.join(' ')),
        action: action,
        aiAction: aiAction,
      ),
    );
  }

  String _describeAction(MeditationActionResult action) {
    switch (action.outcome) {
      case MeditationActionOutcome.selected:
        final selected = action.session.selectedPosition!;
        final targets = action.session.validMoves
            .map(VoiceCommandParser.formatPosition)
            .join('、');
        return targets.isEmpty
            ? '已选中${VoiceCommandParser.formatPosition(selected)}，但该棋子没有可移动位置。'
            : '已选中${VoiceCommandParser.formatPosition(selected)}。可移动到：$targets。';
      case MeditationActionOutcome.deselected:
        return '已取消选择。';
      case MeditationActionOutcome.started:
        return action.session.phase == MeditationSessionPhase.humanTurn
            ? '轮到您行棋。'
            : '轮到对手行棋。';
      case MeditationActionOutcome.paused:
        return '冥想对局已暂停。';
      case MeditationActionOutcome.resumed:
        return action.session.phase == MeditationSessionPhase.humanTurn
            ? '冥想对局已继续。轮到您行棋。'
            : '冥想对局已继续。轮到对手行棋。';
      case MeditationActionOutcome.completed:
        return _describeTerminal(action.session.gameResult!);
      case MeditationActionOutcome.rejected:
        return _describeRejection(action.rejection!);
      case MeditationActionOutcome.unchanged:
        return '当前没有选中的棋子。';
      case MeditationActionOutcome.moved:
        return _describeCommittedMove(action.committedMove!, true);
    }
  }

  static String _describeCommittedMove(Move move, bool humanMove) {
    final actor = humanMove ? '您' : '对手';
    final from = VoiceCommandParser.formatPosition(move.from);
    final to = VoiceCommandParser.formatPosition(move.to);
    final captures = _describeCaptures(move.capturedPieces);
    return '$actor从$from移动到$to$captures。';
  }

  static String _describeCaptures(List<Position> positions) {
    if (positions.isEmpty) {
      return '';
    }
    final coordinates =
        positions.map(VoiceCommandParser.formatPosition).join('、');
    return '，并吃掉位于$coordinates的${positions.length}枚棋子';
  }

  String _describeTerminal(GameResult result) {
    if (result.status == GameStatus.draw) {
      return '对局结束，双方和棋。${result.reason}。';
    }
    if (result.status == GameStatus.abandoned) {
      return '对局已按弃局结束。';
    }
    final humanWon = result.winner == _controller.session.humanPlayer;
    return humanWon
        ? '对局结束，您获胜。${result.reason}。'
        : '对局结束，对手获胜。${result.reason}。';
  }

  static String _describeRejection(MeditationRejection rejection) {
    switch (rejection) {
      case MeditationRejection.openingNotCompleted:
        return '开场播报尚未完成，请稍候。';
      case MeditationRejection.openingAlreadyCompleted:
        return '对局已经开始。';
      case MeditationRejection.invalidPosition:
        return '坐标超出棋盘，请重新说明。';
      case MeditationRejection.noOwnPiece:
        return '该位置没有您的棋子，请重新选择。';
      case MeditationRejection.illegalMove:
        return '不能这样移动，请选择相邻空位。';
      case MeditationRejection.notHumanTurn:
        return '当前轮到对手，请稍候。';
      case MeditationRejection.notAiTurn:
        return '当前不是对手回合。';
      case MeditationRejection.paused:
        return '对局已暂停，请先说继续。';
      case MeditationRejection.notPaused:
        return '对局当前没有暂停。';
      case MeditationRejection.finished:
        return '本局已经结束。';
      case MeditationRejection.staleRevision:
        return '对局状态已变化，旧操作已取消。';
      case MeditationRejection.aiUnavailable:
        return '对手暂时无法行棋，请稍后重试。';
    }
  }

  String _describePieces(PieceType player, {required String owner}) {
    final positions = _controller.session.boardState
        .getAllPieces(player)
        .map(VoiceCommandParser.formatPosition)
        .join('、');
    return positions.isEmpty ? '$owner已全部被吃掉。' : '$owner位于：$positions。';
  }

  String _describePieceCount() {
    final session = _controller.session;
    final humanCount = session.boardState.getPieceCount(session.humanPlayer);
    final aiCount = session.boardState.getPieceCount(session.aiPlayer);
    return '您还有$humanCount枚棋子，对手还有$aiCount枚棋子。';
  }

  String _describeAvailableMoves() {
    final phase = _controller.session.phase;
    if (phase == MeditationSessionPhase.paused) {
      return '对局已暂停，请先说继续。';
    }
    if (phase == MeditationSessionPhase.completed) {
      return '本局已经结束。';
    }
    if (phase == MeditationSessionPhase.aiTurn) {
      return '当前轮到对手，请稍候。';
    }
    final moves = _controller.availableHumanMoves();
    if (moves.isEmpty) {
      return '您当前没有可移动的棋子。';
    }
    final descriptions = moves.entries.map((entry) {
      final from = VoiceCommandParser.formatPosition(entry.key);
      final targets =
          entry.value.map(VoiceCommandParser.formatPosition).join('、');
      return '$from可以移动到$targets';
    }).join('；');
    return '$descriptions。';
  }

  Future<MeditationTurnResponse> _handleQuery(
    MeditationPrompt Function() describe,
  ) async {
    final tick = _controller.tick();
    if (tick.outcome == MeditationActionOutcome.completed) {
      await _notifyAction(tick);
      return _remember(
        MeditationTurnResponse(
          prompt: MeditationPrompt(_describeTerminal(tick.session.gameResult!)),
          action: tick,
        ),
      );
    }
    return _remember(MeditationTurnResponse(prompt: describe()));
  }

  Future<bool> _notifyAction(MeditationActionResult? action) async {
    if (action == null) {
      return false;
    }
    final changed = switch (action.outcome) {
      MeditationActionOutcome.started ||
      MeditationActionOutcome.selected ||
      MeditationActionOutcome.deselected ||
      MeditationActionOutcome.moved ||
      MeditationActionOutcome.paused ||
      MeditationActionOutcome.resumed ||
      MeditationActionOutcome.completed =>
        true,
      MeditationActionOutcome.unchanged ||
      MeditationActionOutcome.rejected =>
        false,
    };
    if (changed) {
      await _notifySession(action.session);
    }
    return changed;
  }

  Future<void> _notifySession(MeditationSession session) async {
    final notify = _onSessionChanged;
    final committed = _committedRevision;
    if (notify == null ||
        (committed != null && committed >= session.revision)) {
      return;
    }
    final pending = _notificationFlight;
    if (pending != null && _notificationRevision == session.revision) {
      await pending;
      return;
    }

    final future = _notificationTail.then((_) async {
      final latestCommitted = _committedRevision;
      if (latestCommitted != null && latestCommitted >= session.revision) {
        return;
      }
      await notify(session);
      final committedAfterSave = _committedRevision;
      if (committedAfterSave == null || session.revision > committedAfterSave) {
        _committedRevision = session.revision;
      }
    });
    _notificationTail = future.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    _notificationRevision = session.revision;
    _notificationFlight = future;
    try {
      await future;
    } finally {
      if (identical(_notificationFlight, future)) {
        _notificationFlight = null;
        _notificationRevision = null;
      }
    }
  }

  Future<MeditationActionResult> _playAiTurnOnce() async {
    final revision = _controller.session.revision;
    final pending = _aiFlight;
    if (pending != null && _aiFlightRevision == revision) {
      return pending;
    }

    final future = _controller.playAiTurn(_aiPlayer);
    _aiFlight = future;
    _aiFlightRevision = revision;
    try {
      return await future;
    } finally {
      if (identical(_aiFlight, future)) {
        _aiFlight = null;
        _aiFlightRevision = null;
      }
    }
  }

  MeditationTurnResponse _remember(MeditationTurnResponse response) {
    _lastPrompt = response.prompt;
    return response;
  }

  static String _playerName(PieceType player) =>
      player == PieceType.black ? '黑方' : '白方';
}
