import 'package:equatable/equatable.dart';

import '../models/position.dart';

abstract class OnlineGameEvent extends Equatable {
  const OnlineGameEvent();

  @override
  List<Object?> get props => const [];
}

class StartOnlineMatching extends OnlineGameEvent {
  const StartOnlineMatching();
}

class CancelOnlineMatching extends OnlineGameEvent {
  const CancelOnlineMatching();
}

class SubmitOnlineMove extends OnlineGameEvent {
  final Position from;
  final Position to;

  const SubmitOnlineMove({
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [from, to];
}

class RetryOnlineConnection extends OnlineGameEvent {
  const RetryOnlineConnection();
}

class LeaveOnlineGame extends OnlineGameEvent {
  const LeaveOnlineGame();
}
