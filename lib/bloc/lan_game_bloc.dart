import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/local_network_service.dart';
import '../../services/audio_coordinator.dart';
import '../../services/logger_service.dart';
import '../../engine/game_engine.dart';
import '../../models/board_state.dart';
import '../../models/piece_type.dart';
import '../../models/websocket_message.dart';
import '../../models/message_type.dart';
import '../../models/move.dart';
import '../../models/position.dart';
import 'lan_game_event.dart';
import 'lan_game_state.dart';

class LanGameBloc extends Bloc<LanGameEvent, LanGameState> {
  final LocalNetworkService _networkService;
  final GameEngine _gameEngine;
  final AudioCoordinator _audioCoordinator;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<LocalNetworkConnectionState>? _connSubscription;

  LanGameBloc({
    LocalNetworkService? networkService,
    GameEngine? gameEngine,
    AudioCoordinator? audioCoordinator,
  })  : _networkService = networkService ?? LocalNetworkService(),
        _gameEngine = gameEngine ?? GameEngine(),
        _audioCoordinator = audioCoordinator ?? AudioCoordinator(),
        super(const LanGameInitial()) {
    on<StartLanGame>(_onStartGame);
    on<LanLocalPlayerMoved>(_onLocalMove);
    on<LanOpponentMoved>(_onOpponentMove);
    on<LanOpponentDisconnected>(_onOpponentDisconnected);
    on<LanExitGame>(_onExitGame);

    _listenToNetwork();
  }

  void _listenToNetwork() {
    _messageSubscription = _networkService.messageStream.listen((message) {
      if (message.type == MessageType.move) {
        final moveData = message.payload['move'] as Map<String, dynamic>;
        final move = _parseMove(moveData);
        if (move != null) {
          add(LanOpponentMoved(move));
        }
      } else if (message.type == MessageType.disconnect) {
        add(LanOpponentDisconnected());
      }
    });

    _connSubscription = _networkService.connectionStateStream.listen((state) {
      if (state == LocalNetworkConnectionState.disconnected) {
        add(LanOpponentDisconnected());
      }
    });
  }

  Move? _parseMove(Map<String, dynamic> data) {
    try {
      // Assuming data matches Move.toJson() or similar structure expected by OnlineGameBloc
      // We need to implement robust parsing.
      // Let's assume standard format: from: {x,y}, to: {x,y}, player: 'black'/'white'
      final fromMap = data['from'];
      final toMap = data['to'];
      final playerStr = data['player'];

      return Move.now(
        from: Position(fromMap['x'], fromMap['y']),
        to: Position(toMap['x'], toMap['y']),
        player: playerStr == 'black' ? PieceType.black : PieceType.white,
      );
    } catch (e) {
      logger.error('Failed to parse move', 'LanGameBloc', e);
      return null;
    }
  }

  Future<void> _onStartGame(
    StartLanGame event,
    Emitter<LanGameState> emit,
  ) async {
    final localColor = event.isHost ? PieceType.black : PieceType.white;
    final board = BoardState.initial();

    emit(LanGamePlaying(
      boardState: board,
      localColor: localColor,
      lastUpdate: DateTime.now(),
    ),);

    logger.info('LAN Game Started. Local: $localColor', 'LanGameBloc');
  }

  Future<void> _onLocalMove(
    LanLocalPlayerMoved event,
    Emitter<LanGameState> emit,
  ) async {
    if (state is! LanGamePlaying) return;
    final currentState = state as LanGamePlaying;

    if (!currentState.isLocalTurn) {
      return; // Not your turn
    }

    final result = _gameEngine.executeMove(
      currentState.boardState,
      event.move.from,
      event.move.to,
    );

    if (!result.success || result.newBoard == null) return;

    // Send move to network
    // We need to construct payload resembling what _parseMove expects
    final movePayload = {
      'from': {'x': event.move.from.x, 'y': event.move.from.y},
      'to': {'x': event.move.to.x, 'y': event.move.to.y},
      'player': event.move.player == PieceType.black ? 'black' : 'white',
      // 'captured': ... if needed
    };

    _networkService.send(WebSocketMessage(
      type: MessageType.move,
      payload: {'move': movePayload},
      timestamp: DateTime.now(),
    ),);

    // Update Local State
    final nextState = currentState.copyWith(
      boardState: result.newBoard,
      moveHistory: [...currentState.moveHistory, result.move!],
      lastMove: result.move,
    );

    if (result.gameResult != null) {
      emit(LanGameFinished(
        finalBoard: result.newBoard!,
        winner: result.gameResult!.winner,
        reason: result.gameResult!.reason,
        isWin: result.gameResult!.winner == currentState.localColor,
        localColor: currentState.localColor,
        moveHistory: [...currentState.moveHistory, result.move!],
      ),);
    } else {
      emit(nextState);
    }

    // Audio
    if (result.captured != null) {
      _audioCoordinator.onGameEvent(GameEvent.pieceCaptured);
    } else {
      _audioCoordinator.onGameEvent(GameEvent.pieceMoved);
    }
  }

  Future<void> _onOpponentMove(
    LanOpponentMoved event,
    Emitter<LanGameState> emit,
  ) async {
    if (state is! LanGamePlaying) return;
    final currentState = state as LanGamePlaying;

    // Apply move
    final result = _gameEngine.executeMove(
      currentState.boardState,
      event.move.from,
      event.move.to,
    );

    if (!result.success || result.newBoard == null) {
      logger.warning('Invalid opponent move received', 'LanGameBloc');
      // Force sync? or Error?
      return;
    }

    final nextState = currentState.copyWith(
      boardState: result.newBoard,
      moveHistory: [...currentState.moveHistory, result.move!],
      lastMove: result.move,
    );

    if (result.gameResult != null) {
      emit(LanGameFinished(
        finalBoard: result.newBoard!,
        winner: result.gameResult!.winner,
        reason: result.gameResult!.reason,
        isWin: result.gameResult!.winner == currentState.localColor,
        localColor: currentState.localColor,
        moveHistory: [...currentState.moveHistory, result.move!],
      ),);
    } else {
      emit(nextState);
    }

    // Audio
    if (result.captured != null) {
      _audioCoordinator.onGameEvent(GameEvent.pieceCaptured);
    } else {
      _audioCoordinator.onGameEvent(GameEvent.pieceMoved);
    }
  }

  Future<void> _onOpponentDisconnected(
    LanOpponentDisconnected event,
    Emitter<LanGameState> emit,
  ) async {
    emit(LanOpponentLeft());
  }

  Future<void> _onExitGame(
    LanExitGame event,
    Emitter<LanGameState> emit,
  ) async {
    // _networkService.stop(); // Don't stop service, just leave game state?
    // Actually stopping network service might be what we want if we go back to menu.
    // user might want to go back to Lobby.
    // If we go back to Lobby, we might keep connection?
    // For now, assume Exit Game means disconnect.
    await _networkService.stop();
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connSubscription?.cancel();
    return super.close();
  }
}
