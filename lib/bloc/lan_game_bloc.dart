import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engine/game_engine.dart';
import '../../models/board_state.dart';
import '../../models/game_result.dart';
import '../../models/game_record.dart';
import '../../models/lan_protocol.dart';
import '../../models/message_type.dart';
import '../../models/move.dart';
import '../../models/piece_type.dart';
import '../../models/websocket_message.dart';
import '../../services/audio_coordinator.dart';
import '../../services/lan_authority.dart';
import '../../services/local_network_service.dart';
import '../../services/logger_service.dart';
import '../../services/storage_service.dart';
import 'lan_game_event.dart';
import 'lan_game_state.dart';

typedef LanStartingPlayerGenerator = PieceType Function();
typedef LanIdentifierGenerator = String Function();

class LanGameBloc extends Bloc<LanGameEvent, LanGameState> {
  final LocalNetworkService _networkService;
  final GameEngine _gameEngine;
  final AudioCoordinator _audioCoordinator;
  final StorageService _storageService;
  final LanAuthorityClock _clock;
  final LanStartingPlayerGenerator _startingPlayerGenerator;
  final LanIdentifierGenerator _gameIdGenerator;
  final LanIdentifierGenerator _commandIdGenerator;

  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<LocalNetworkConnectionState>? _connSubscription;
  Timer? _deadlineTimer;
  LanHostAuthority? _authority;
  bool? _isHost;
  PieceType? _lastStartingPlayer;
  int _identifierSequence = 0;
  final Set<String> _archivedGameIds = {};

  LanGameBloc({
    LocalNetworkService? networkService,
    GameEngine? gameEngine,
    AudioCoordinator? audioCoordinator,
    StorageService? storageService,
    LanAuthorityClock? clock,
    LanStartingPlayerGenerator? startingPlayerGenerator,
    LanIdentifierGenerator? gameIdGenerator,
    LanIdentifierGenerator? commandIdGenerator,
  })  : _networkService = networkService ?? LocalNetworkService(),
        _gameEngine = gameEngine ?? GameEngine(),
        _audioCoordinator = audioCoordinator ?? AudioCoordinator(),
        _storageService = storageService ?? StorageService(),
        _clock = clock ?? DateTime.now,
        _startingPlayerGenerator = startingPlayerGenerator ??
            (() =>
                math.Random().nextBool() ? PieceType.black : PieceType.white),
        _gameIdGenerator = gameIdGenerator ??
            (() => 'lan-game-${DateTime.now().microsecondsSinceEpoch}'),
        _commandIdGenerator = commandIdGenerator ??
            (() => 'lan-command-${DateTime.now().microsecondsSinceEpoch}'),
        super(const LanGameInitial()) {
    on<StartLanGame>(_onStartGame);
    on<LanLocalPlayerMoved>(_onLocalMove);
    on<LanOpponentMoved>(_onLegacyOpponentMove);
    on<LanProtocolReceived>(_onProtocolReceived);
    on<LanSnapshotRequested>(_onSnapshotRequested);
    on<LanOpponentDisconnected>(_onOpponentDisconnected);
    on<LanConnectionRestored>(_onConnectionRestored);
    on<LanAuthorityTick>(_onAuthorityTick);
    on<LanRestartGame>(_onRestartGame);
    on<LanExitGame>(_onExitGame);

    _listenToNetwork();
  }

  void _listenToNetwork() {
    _messageSubscription = _networkService.messageStream.listen((message) {
      try {
        if (message.type == MessageType.lanProtocol) {
          add(
            LanProtocolReceived(
              LanProtocol.fromJson(Map<String, dynamic>.from(message.payload)),
            ),
          );
        } else if (message.type == MessageType.lanSnapshotRequest) {
          add(LanSnapshotRequested());
        } else if (message.type == MessageType.lanRestartRequest) {
          add(LanRestartGame());
        } else if (message.type == MessageType.disconnect) {
          add(LanOpponentDisconnected());
        } else if (message.type == MessageType.move) {
          logger.warning(
            'Ignored legacy peer-computed LAN move',
            'LanGameBloc',
          );
        }
      } on LanProtocolException catch (error) {
        logger.warning('Rejected LAN protocol payload: $error', 'LanGameBloc');
      } catch (error) {
        logger.error('Failed to process LAN message', 'LanGameBloc', error);
      }
    });

    _connSubscription = _networkService.connectionStateStream.listen((state) {
      if (state == LocalNetworkConnectionState.disconnected) {
        add(LanOpponentDisconnected());
      } else if (state == LocalNetworkConnectionState.connected) {
        add(LanConnectionRestored());
      }
    });
  }

  Future<void> _onStartGame(
    StartLanGame event,
    Emitter<LanGameState> emit,
  ) async {
    _deadlineTimer?.cancel();
    _isHost = event.isHost;
    final localColor = event.isHost ? PieceType.black : PieceType.white;

    if (event.isHost) {
      final startingPlayer = _startingPlayerGenerator();
      _lastStartingPlayer = startingPlayer;
      _authority = LanHostAuthority.newGame(
        gameId: _nextGameId(),
        startingPlayer: startingPlayer,
        clock: _clock,
        engine: _gameEngine,
      );
      final snapshot = _authority!.createSnapshot();
      _emitSnapshot(snapshot, localColor, emit);
      _sendProtocol(snapshot);
      _scheduleAuthorityDeadline();
    } else {
      _authority = null;
      emit(
        LanGamePlaying(
          boardState: BoardState.initial(),
          localColor: localColor,
          lastUpdate: _nowUtc(),
          isSynchronized: false,
        ),
      );
      _requestSnapshot();
    }

    logger.info('LAN Game Started. Local: $localColor', 'LanGameBloc');
  }

  Future<void> _onLocalMove(
    LanLocalPlayerMoved event,
    Emitter<LanGameState> emit,
  ) async {
    if (state is! LanGamePlaying) return;
    final currentState = state as LanGamePlaying;
    if (!currentState.isLocalTurn) return;

    final isHost = _isHost ?? currentState.localColor == PieceType.black;
    _isHost ??= isHost;

    if (isHost) {
      final authority = _ensureAuthority(currentState);
      final intent = LanMoveIntent(
        gameId: authority.gameId,
        commandId: _nextCommandId(),
        expectedRevision: authority.revision,
        from: event.move.from,
        to: event.move.to,
      );
      final response = authority.handleMoveIntent(
        intent,
        sender: currentState.localColor,
      );
      _sendProtocol(response);
      if (response is LanMoveCommitted) {
        _emitSnapshot(
          authority.createSnapshot(),
          currentState.localColor,
          emit,
        );
        _playMoveAudio(response.move);
        _scheduleAuthorityDeadline();
      } else if (response is LanMoveRejected) {
        emit(
          currentState.copyWith(
            gameId: authority.gameId,
            revision: authority.revision,
            lastRejection: response.reason,
            lastUpdate: _nowUtc(),
          ),
        );
      }
      return;
    }

    final gameId = currentState.gameId;
    if (gameId == null) {
      _requestSnapshot();
      return;
    }
    final intent = LanMoveIntent(
      gameId: gameId,
      commandId: _nextCommandId(),
      expectedRevision: currentState.revision,
      from: event.move.from,
      to: event.move.to,
    );
    _sendProtocol(intent);
    emit(
      currentState.copyWith(
        pendingCommandId: intent.commandId,
        clearLastRejection: true,
        lastUpdate: _nowUtc(),
      ),
    );
  }

  Future<void> _onProtocolReceived(
    LanProtocolReceived event,
    Emitter<LanGameState> emit,
  ) async {
    final message = event.message;
    final isHost = _isHost == true;

    if (message is LanMoveIntent) {
      if (!isHost || state is! LanGamePlaying) return;
      final currentState = state as LanGamePlaying;
      final authority = _ensureAuthority(currentState);
      final response = authority.handleMoveIntent(
        message,
        sender: currentState.localColor.getOpponent(),
      );
      _sendProtocol(response);
      if (response is LanMoveCommitted) {
        _emitSnapshot(
          authority.createSnapshot(),
          currentState.localColor,
          emit,
        );
        _playMoveAudio(response.move);
        _scheduleAuthorityDeadline();
      } else if (response is LanMoveRejected) {
        emit(
          currentState.copyWith(
            revision: authority.revision,
            lastRejection: response.reason,
            lastUpdate: _nowUtc(),
          ),
        );
        _sendProtocol(authority.createSnapshot());
      }
      return;
    }

    if (message is LanMoveCommitted) {
      if (isHost || state is! LanGamePlaying) return;
      _applyClientCommit(message, state as LanGamePlaying, emit);
      return;
    }

    if (message is LanMoveRejected) {
      if (isHost || state is! LanGamePlaying) return;
      final currentState = state as LanGamePlaying;
      if (message.gameId != currentState.gameId ||
          message.commandId != currentState.pendingCommandId) {
        return;
      }
      emit(
        currentState.copyWith(
          revision: message.revision > currentState.revision
              ? message.revision
              : currentState.revision,
          clearPendingCommand: true,
          lastRejection: message.reason,
          lastUpdate: _nowUtc(),
        ),
      );
      if (message.reason == LanMoveRejectionReason.staleRevision) {
        _requestSnapshot();
      }
      return;
    }

    if (message is LanStateSnapshot) {
      if (isHost) return;
      if (state is LanGameFinished) {
        final currentState = state as LanGameFinished;
        if (currentState.gameId == message.gameId) {
          return;
        }
      }
      if (state is LanGamePlaying) {
        final currentState = state as LanGamePlaying;
        if (currentState.gameId == message.gameId &&
            message.revision < currentState.revision) {
          return;
        }
      }
      final localColor = state is LanGamePlaying
          ? (state as LanGamePlaying).localColor
          : state is LanGameFinished
              ? (state as LanGameFinished).localColor
              : PieceType.white;
      _lastStartingPlayer = message.startingPlayer;
      _emitSnapshot(message, localColor, emit);
    }
  }

  Future<void> _onSnapshotRequested(
    LanSnapshotRequested event,
    Emitter<LanGameState> emit,
  ) async {
    if (_isHost != true || _authority == null) return;
    final result = _authority!.tick();
    final snapshot = _authority!.createSnapshot();
    _sendProtocol(snapshot);
    if (result != null && state is LanGamePlaying) {
      _emitSnapshot(
        snapshot,
        (state as LanGamePlaying).localColor,
        emit,
      );
    }
    _scheduleAuthorityDeadline();
  }

  Future<void> _onOpponentDisconnected(
    LanOpponentDisconnected event,
    Emitter<LanGameState> emit,
  ) async {
    if (state is! LanGamePlaying) return;
    final currentState = state as LanGamePlaying;

    if (_isHost == true) {
      final authority = _ensureAuthority(currentState);
      final peerColor = currentState.localColor.getOpponent();
      final deadline = authority.markDisconnected(peerColor);
      if (authority.isFinished) {
        final snapshot = authority.createSnapshot();
        _sendProtocol(snapshot);
        _emitSnapshot(snapshot, currentState.localColor, emit);
        _scheduleAuthorityDeadline();
        return;
      }
      emit(
        currentState.copyWith(
          isReconnecting: true,
          disconnectDeadlineUtc: deadline,
          lastUpdate: _nowUtc(),
        ),
      );
      _scheduleAuthorityDeadline();
    } else {
      final deadline = _nowUtc().add(LanHostAuthority.reconnectGrace);
      emit(
        currentState.copyWith(
          isReconnecting: true,
          disconnectDeadlineUtc: deadline,
          lastUpdate: _nowUtc(),
        ),
      );
      _scheduleClientDisconnectDeadline(deadline);
    }
  }

  Future<void> _onConnectionRestored(
    LanConnectionRestored event,
    Emitter<LanGameState> emit,
  ) async {
    if (state is! LanGamePlaying) return;
    final currentState = state as LanGamePlaying;
    if (!currentState.isReconnecting) return;

    if (_isHost == true && _authority != null) {
      final snapshot = _authority!.markReconnected(
        currentState.localColor.getOpponent(),
      );
      if (snapshot != null) {
        _sendProtocol(snapshot);
        _emitSnapshot(snapshot, currentState.localColor, emit);
        _scheduleAuthorityDeadline();
      }
    } else {
      _deadlineTimer?.cancel();
      emit(
        currentState.copyWith(
          isSynchronized: false,
          lastUpdate: _nowUtc(),
        ),
      );
      _requestSnapshot();
    }
  }

  Future<void> _onAuthorityTick(
    LanAuthorityTick event,
    Emitter<LanGameState> emit,
  ) async {
    if (_isHost == true && _authority != null) {
      final result = _authority!.tick();
      if (result != null) {
        final snapshot = _authority!.createSnapshot();
        _sendProtocol(snapshot);
        if (state is LanGamePlaying) {
          _emitSnapshot(
            snapshot,
            (state as LanGamePlaying).localColor,
            emit,
          );
        }
      }
      _scheduleAuthorityDeadline();
      return;
    }

    if (_isHost == false && state is LanGamePlaying) {
      final currentState = state as LanGamePlaying;
      final deadline = currentState.disconnectDeadlineUtc;
      if (!currentState.isSynchronized ||
          !currentState.isReconnecting ||
          currentState.gameId == null ||
          deadline == null ||
          _nowUtc().isBefore(deadline)) {
        return;
      }
      final disconnectedPlayer = currentState.localColor.getOpponent();
      final turnDeadline = currentState.turnDeadlineUtc;
      final result = turnDeadline != null && !turnDeadline.isAfter(deadline)
          ? GameResult.timeout(
              timeoutPlayer: currentState.boardState.currentPlayer,
              moveCount: currentState.moveHistory.length,
              duration: Duration.zero,
            )
          : _clientDisconnectResult(
              disconnectedPlayer,
              currentState.moveHistory.length,
            );
      _deadlineTimer?.cancel();
      _emitFinished(
        boardState: currentState.boardState,
        localColor: currentState.localColor,
        moveHistory: currentState.moveHistory,
        gameId: currentState.gameId!,
        revision: currentState.revision + 1,
        startingPlayer: currentState.startingPlayer,
        noCapturePlyCount: currentState.noCapturePlyCount,
        result: result,
        stateHash:
            'client-disconnect-${currentState.gameId}-${currentState.revision + 1}',
        emit: emit,
      );
    }
  }

  Future<void> _onRestartGame(
    LanRestartGame event,
    Emitter<LanGameState> emit,
  ) async {
    if (_isHost != true) {
      _requestRestart();
      return;
    }
    final localColor = state is LanGamePlaying
        ? (state as LanGamePlaying).localColor
        : state is LanGameFinished
            ? (state as LanGameFinished).localColor
            : PieceType.black;
    final startingPlayer =
        (_lastStartingPlayer ?? PieceType.black).getOpponent();
    _lastStartingPlayer = startingPlayer;
    _authority = LanHostAuthority.newGame(
      gameId: _nextGameId(),
      startingPlayer: startingPlayer,
      clock: _clock,
      engine: _gameEngine,
    );
    final snapshot = _authority!.createSnapshot();
    _sendProtocol(snapshot);
    _emitSnapshot(snapshot, localColor, emit);
    _scheduleAuthorityDeadline();
  }

  Future<void> _onLegacyOpponentMove(
    LanOpponentMoved event,
    Emitter<LanGameState> emit,
  ) async {
    logger.warning(
      'Ignored legacy LanOpponentMoved; authority commit is required',
      'LanGameBloc',
    );
  }

  Future<void> _onExitGame(
    LanExitGame event,
    Emitter<LanGameState> emit,
  ) async {
    _deadlineTimer?.cancel();
    await _networkService.stop();
  }

  void _applyClientCommit(
    LanMoveCommitted committed,
    LanGamePlaying currentState,
    Emitter<LanGameState> emit,
  ) {
    if (!currentState.isSynchronized || currentState.gameId == null) {
      _requestSnapshot();
      return;
    }
    if (currentState.gameId != null &&
        committed.gameId != currentState.gameId) {
      _requestSnapshot();
      return;
    }
    if (committed.revision <= currentState.revision) {
      return;
    }
    if (committed.revision != currentState.revision + 1) {
      emit(
        currentState.copyWith(
          isSynchronized: false,
          isReconnecting: true,
          lastUpdate: _nowUtc(),
        ),
      );
      _requestSnapshot();
      return;
    }

    var board = currentState.boardState.movePiece(
      committed.move.from,
      committed.move.to,
    );
    for (final captured in committed.move.capturedPieces) {
      board = board.removePiece(captured);
    }
    board = board.copyWith(currentPlayer: committed.currentPlayer);
    final history = [...currentState.moveHistory, committed.move];

    if (committed.gameResult != null) {
      _emitFinished(
        boardState: board,
        localColor: currentState.localColor,
        moveHistory: history,
        gameId: committed.gameId,
        revision: committed.revision,
        startingPlayer: currentState.startingPlayer,
        noCapturePlyCount: committed.noCapturePlyCount,
        result: committed.gameResult!,
        stateHash: committed.stateHash,
        emit: emit,
      );
    } else {
      emit(
        currentState.copyWith(
          boardState: board,
          gameId: committed.gameId,
          revision: committed.revision,
          moveHistory: history,
          lastMove: committed.move,
          noCapturePlyCount: committed.noCapturePlyCount,
          turnDeadlineUtc: committed.turnDeadlineUtc,
          clearDisconnectDeadline: true,
          isSynchronized: true,
          isReconnecting: false,
          clearPendingCommand: true,
          clearLastRejection: true,
          stateHash: committed.stateHash,
          lastUpdate: _nowUtc(),
        ),
      );
    }
    _playMoveAudio(committed.move);
  }

  void _emitSnapshot(
    LanStateSnapshot snapshot,
    PieceType localColor,
    Emitter<LanGameState> emit,
  ) {
    if (snapshot.gameResult != null) {
      _emitFinished(
        boardState: snapshot.boardState,
        localColor: localColor,
        moveHistory: snapshot.moveHistory,
        gameId: snapshot.gameId,
        revision: snapshot.revision,
        startingPlayer: snapshot.startingPlayer,
        noCapturePlyCount: snapshot.noCapturePlyCount,
        result: snapshot.gameResult!,
        stateHash: snapshot.stateHash,
        emit: emit,
      );
      return;
    }

    emit(
      LanGamePlaying(
        boardState: snapshot.boardState,
        localColor: localColor,
        moveHistory: snapshot.moveHistory,
        lastMove:
            snapshot.moveHistory.isEmpty ? null : snapshot.moveHistory.last,
        lastUpdate: _nowUtc(),
        gameId: snapshot.gameId,
        revision: snapshot.revision,
        startingPlayer: snapshot.startingPlayer,
        noCapturePlyCount: snapshot.noCapturePlyCount,
        turnDeadlineUtc: snapshot.turnDeadlineUtc,
        isSynchronized: true,
        stateHash: snapshot.stateHash,
      ),
    );
  }

  void _emitFinished({
    required BoardState boardState,
    required PieceType localColor,
    required List<Move> moveHistory,
    required String gameId,
    required int revision,
    required PieceType startingPlayer,
    required int noCapturePlyCount,
    required GameResult result,
    required String stateHash,
    required Emitter<LanGameState> emit,
  }) {
    emit(
      LanGameFinished(
        finalBoard: boardState,
        winner: result.winner,
        reason: result.reason,
        isWin: result.winner == localColor,
        localColor: localColor,
        moveHistory: moveHistory,
        gameId: gameId,
        revision: revision,
        startingPlayer: startingPlayer,
        noCapturePlyCount: noCapturePlyCount,
        authoritativeResult: result,
        stateHash: stateHash,
      ),
    );
    if (_archivedGameIds.add(gameId)) {
      unawaited(
        _archiveCompletedGame(
          gameId: gameId,
          startingPlayer: startingPlayer,
          localColor: localColor,
          result: result,
          moveHistory: moveHistory,
        ),
      );
    }
  }

  Future<void> _archiveCompletedGame({
    required String gameId,
    required PieceType startingPlayer,
    required PieceType localColor,
    required GameResult result,
    required List<Move> moveHistory,
  }) async {
    await _storageService.recordCompletedGame(
      GameRecord(
        id: gameId,
        completedAt: _nowUtc(),
        mode: 'lan',
        startingPlayer: startingPlayer,
        humanPlayer: localColor,
        result: result,
        moves: List.unmodifiable(moveHistory),
      ),
    );
  }

  LanHostAuthority _ensureAuthority(LanGamePlaying currentState) {
    if (_authority != null) return _authority!;
    final deadline = currentState.turnDeadlineUtc ??
        _nowUtc().add(LanHostAuthority.turnDuration);
    final snapshot = LanStateSnapshot(
      gameId: currentState.gameId ?? _nextGameId(),
      revision: currentState.revision,
      boardState: currentState.boardState,
      startingPlayer: currentState.startingPlayer,
      moveHistory: currentState.moveHistory,
      noCapturePlyCount: currentState.noCapturePlyCount,
      turnDeadlineUtc: deadline,
      gameResult: null,
      stateHash: currentState.stateHash ?? 'restored-state',
    );
    _authority = LanHostAuthority.fromSnapshot(
      snapshot,
      clock: _clock,
      engine: _gameEngine,
    );
    return _authority!;
  }

  void _sendProtocol(LanProtocolMessage message) {
    _networkService.send(
      WebSocketMessage(
        type: MessageType.lanProtocol,
        payload: message.toJson(),
        timestamp: _nowUtc(),
      ),
    );
  }

  void _requestSnapshot() {
    final currentRevision = state is LanGamePlaying
        ? (state as LanGamePlaying).revision
        : state is LanGameFinished
            ? (state as LanGameFinished).revision
            : 0;
    _networkService.send(
      WebSocketMessage(
        type: MessageType.lanSnapshotRequest,
        payload: {'revision': currentRevision},
        timestamp: _nowUtc(),
      ),
    );
  }

  void _requestRestart() {
    final gameId = state is LanGamePlaying
        ? (state as LanGamePlaying).gameId
        : state is LanGameFinished
            ? (state as LanGameFinished).gameId
            : null;
    _networkService.send(
      WebSocketMessage(
        type: MessageType.lanRestartRequest,
        payload: {'gameId': gameId},
        timestamp: _nowUtc(),
      ),
    );
  }

  void _playMoveAudio(Move move) {
    _audioCoordinator.onGameEvent(
      move.hasCapture ? GameEvent.pieceCaptured : GameEvent.pieceMoved,
    );
  }

  void _scheduleAuthorityDeadline() {
    _deadlineTimer?.cancel();
    final authority = _authority;
    if (authority == null || authority.isFinished) return;

    final deadlines = <DateTime>[
      if (authority.turnDeadlineUtc != null) authority.turnDeadlineUtc!,
      for (final player in [PieceType.black, PieceType.white])
        if (authority.disconnectDeadlineFor(player) != null)
          authority.disconnectDeadlineFor(player)!,
    ]..sort();
    if (deadlines.isEmpty) return;

    final delay = deadlines.first.difference(_nowUtc());
    _deadlineTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        if (!isClosed) add(LanAuthorityTick());
      },
    );
  }

  void _scheduleClientDisconnectDeadline(DateTime deadline) {
    _deadlineTimer?.cancel();
    final delay = deadline.difference(_nowUtc());
    _deadlineTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        if (!isClosed) add(LanAuthorityTick());
      },
    );
  }

  GameResult _clientDisconnectResult(
    PieceType disconnectedPlayer,
    int moveCount,
  ) {
    final winner = disconnectedPlayer.getOpponent();
    final reason = '${disconnectedPlayer.getDisplayName()}断线超时';
    if (winner == PieceType.black) {
      return GameResult.blackWin(
        reason: reason,
        endReason: GameEndReason.disconnect,
        moveCount: moveCount,
        duration: Duration.zero,
      );
    }
    return GameResult.whiteWin(
      reason: reason,
      endReason: GameEndReason.disconnect,
      moveCount: moveCount,
      duration: Duration.zero,
    );
  }

  String _nextGameId() {
    _identifierSequence++;
    return '${_gameIdGenerator()}-$_identifierSequence';
  }

  String _nextCommandId() {
    _identifierSequence++;
    return '${_commandIdGenerator()}-$_identifierSequence';
  }

  DateTime _nowUtc() => _clock().toUtc();

  @override
  Future<void> close() async {
    _deadlineTimer?.cancel();
    await _messageSubscription?.cancel();
    await _connSubscription?.cancel();
    return super.close();
  }
}
