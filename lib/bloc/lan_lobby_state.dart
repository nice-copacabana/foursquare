import 'package:equatable/equatable.dart';
import 'package:nsd/nsd.dart';

enum LanLobbyStatus {
  initial,
  scanning,
  hosting,
  connecting,
  connected,
  failure,
}

/// Stable failure categories that the presentation layer can localize.
enum LanLobbyFailure {
  discovery,
  hosting,
  connection,
}

class LanLobbyState extends Equatable {
  final LanLobbyStatus status;
  final List<Service> foundServices;
  final LanLobbyFailure? failure;
  final bool isHost;

  const LanLobbyState({
    this.status = LanLobbyStatus.initial,
    this.foundServices = const [],
    this.failure,
    this.isHost = false,
  });

  LanLobbyState copyWith({
    LanLobbyStatus? status,
    List<Service>? foundServices,
    LanLobbyFailure? failure,
    bool clearFailure = false,
    bool? isHost,
  }) {
    return LanLobbyState(
      status: status ?? this.status,
      foundServices: foundServices ?? this.foundServices,
      failure: clearFailure ? null : failure ?? this.failure,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [status, foundServices, failure, isHost];
}
