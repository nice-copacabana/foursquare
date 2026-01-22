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

class LanLobbyState extends Equatable {
  final LanLobbyStatus status;
  final List<Service> foundServices;
  final String? errorMessage;
  final bool isHost;

  const LanLobbyState({
    this.status = LanLobbyStatus.initial,
    this.foundServices = const [],
    this.errorMessage,
    this.isHost = false,
  });

  LanLobbyState copyWith({
    LanLobbyStatus? status,
    List<Service>? foundServices,
    String? errorMessage,
    bool? isHost,
  }) {
    return LanLobbyState(
      status: status ?? this.status,
      foundServices: foundServices ?? this.foundServices,
      errorMessage: errorMessage ?? this.errorMessage,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [status, foundServices, errorMessage, isHost];
}
