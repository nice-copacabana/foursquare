import 'package:equatable/equatable.dart';
import 'package:nsd/nsd.dart';

abstract class LanLobbyEvent extends Equatable {
  const LanLobbyEvent();

  @override
  List<Object?> get props => [];
}

/// Start scanning for local hosts
class StartDiscovery extends LanLobbyEvent {}

/// Stop scanning
class StopDiscovery extends LanLobbyEvent {}

/// Start hosting a game
class StartHosting extends LanLobbyEvent {
  final String roomName;
  const StartHosting({this.roomName = 'Foursquare Room'});

  @override
  List<Object?> get props => [roomName];
}

/// Stop hosting
class StopHosting extends LanLobbyEvent {}

/// Connect to a discovered host
class ConnectToHost extends LanLobbyEvent {
  final Service service;
  const ConnectToHost(this.service);

  @override
  List<Object?> get props => [service];
}

/// Disconnect from current session
class DisconnectLan extends LanLobbyEvent {}

/// Internal: List of services updated
class ServicesUpdated extends LanLobbyEvent {
  final List<Service> services;
  const ServicesUpdated(this.services);

  @override
  List<Object?> get props => [services];
}

/// Internal: Connection status changed (connected/disconnected)
class LanConnectionStatusChanged extends LanLobbyEvent {
  final bool isConnected;
  final bool isHost;
  const LanConnectionStatusChanged({
    required this.isConnected,
    required this.isHost,
  });

  @override
  List<Object?> get props => [isConnected, isHost];
}
