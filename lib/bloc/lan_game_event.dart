import 'package:equatable/equatable.dart';
import '../../models/move.dart';

abstract class LanGameEvent extends Equatable {
  const LanGameEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new LAN game
class StartLanGame extends LanGameEvent {
  final bool isHost;
  const StartLanGame({required this.isHost});

  @override
  List<Object?> get props => [isHost];
}

/// Local player makes a move
class LanLocalPlayerMoved extends LanGameEvent {
  final Move move;
  const LanLocalPlayerMoved(this.move);

  @override
  List<Object?> get props => [move];
}

/// Opponent makes a move (received from network)
class LanOpponentMoved extends LanGameEvent {
  final Move move;
  const LanOpponentMoved(this.move);

  @override
  List<Object?> get props => [move];
}

/// Opponent disconnected
class LanOpponentDisconnected extends LanGameEvent {}

/// Restart requested
class LanRestartGame extends LanGameEvent {}

/// Exit game
class LanExitGame extends LanGameEvent {}
