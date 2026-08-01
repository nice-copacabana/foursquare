import 'package:equatable/equatable.dart';
import '../../models/lan_protocol.dart';
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

/// A typed authority message received through the transport envelope.
class LanProtocolReceived extends LanGameEvent {
  final LanProtocolMessage message;

  const LanProtocolReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Client requested a complete host snapshot.
class LanSnapshotRequested extends LanGameEvent {}

/// Connection became available again.
class LanConnectionRestored extends LanGameEvent {}

/// Drives host absolute deadlines; exposed for deterministic tests.
class LanAuthorityTick extends LanGameEvent {}

/// Restart requested
class LanRestartGame extends LanGameEvent {}

/// Exit game
class LanExitGame extends LanGameEvent {}
