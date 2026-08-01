import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/lan_lobby_bloc.dart';
import '../../../bloc/lan_lobby_event.dart';
import '../../../bloc/lan_lobby_state.dart';
import '../../../l10n/app_localizations.dart';
import 'lan_game_page.dart';

class LanLobbyPage extends StatelessWidget {
  const LanLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanLobbyBloc(),
      child: const LanLobbyView(),
    );
  }
}

class LanLobbyView extends StatefulWidget {
  const LanLobbyView({super.key});

  @override
  State<LanLobbyView> createState() => _LanLobbyViewState();
}

class _LanLobbyViewState extends State<LanLobbyView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _roomNameController = TextEditingController();
  bool _defaultRoomNameSet = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_defaultRoomNameSet) {
      _roomNameController.text =
          AppLocalizations.of(context)!.lanDefaultRoomName;
      _defaultRoomNameSet = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lanTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.lanCreateRoomTab),
            Tab(text: l10n.lanJoinRoomTab),
          ],
        ),
      ),
      body: BlocConsumer<LanLobbyBloc, LanLobbyState>(
        listener: (context, state) {
          if (state.status == LanLobbyStatus.failure && state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_failureMessage(state.failure!, l10n))),
            );
          }
          if (state.status == LanLobbyStatus.connected) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => LanGamePage(isHost: state.isHost),
              ),
            ).then((_) {
              if (context.mounted) {
                context.read<LanLobbyBloc>().add(DisconnectLan());
              }
            });
          }
        },
        builder: (context, state) {
          if (state.status == LanLobbyStatus.connected) {
            return _LobbyStatusPane(
              icon: Icons.check_circle_outline_rounded,
              iconColor: scheme.primary,
              title: l10n.lanConnectedTitle,
              description: l10n.lanConnectedDescription,
              action: OutlinedButton(
                onPressed: () {
                  context.read<LanLobbyBloc>().add(DisconnectLan());
                },
                child: Text(l10n.lanDisconnect),
              ),
            );
          }

          if (state.status == LanLobbyStatus.hosting) {
            return _LobbyStatusPane(
              icon: Icons.wifi_tethering_rounded,
              iconColor: scheme.primary,
              progress: true,
              title: l10n.lanWaitingTitle,
              description: l10n.lanRoomNameValue(_roomNameController.text),
              action: OutlinedButton(
                onPressed: () {
                  context.read<LanLobbyBloc>().add(StopHosting());
                },
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                child: Text(l10n.lanCancelCreate),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 32
                          ? constraints.maxHeight - 32
                          : 0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.wifi_tethering_rounded,
                                    size: 38,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.lanCreateHeading,
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.lanCreateDescription,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _roomNameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.lanRoomNameLabel,
                                    prefixIcon: const Icon(
                                      Icons.meeting_room_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: const Key('lan_create_room_button'),
                                    onPressed: () {
                                      context.read<LanLobbyBloc>().add(
                                            StartHosting(
                                              roomName:
                                                  _roomNameController.text,
                                            ),
                                          );
                                    },
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(l10n.lanCreateRoom),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.lanNearbyRooms,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (state.status == LanLobbyStatus.scanning)
                          IconButton(
                            tooltip: l10n.lanStopSearch,
                            icon: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            onPressed: () => context
                                .read<LanLobbyBloc>()
                                .add(StopDiscovery()),
                          )
                        else
                          IconButton(
                            tooltip: l10n.lanSearch,
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: () => context
                                .read<LanLobbyBloc>()
                                .add(StartDiscovery()),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: state.foundServices.isEmpty
                        ? Center(
                            child: _EmptyRooms(
                              scanning: state.status == LanLobbyStatus.scanning,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: state.foundServices.length,
                            itemBuilder: (context, index) {
                              final service = state.foundServices[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 6, 12, 6),
                                child: Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.computer_rounded),
                                    title: Text(
                                      service.name ?? l10n.lanUnnamedRoom,
                                    ),
                                    subtitle: Text(
                                      '${service.host ?? l10n.lanUnknownAddress}:${service.port}',
                                    ),
                                    trailing: FilledButton(
                                      onPressed: () {
                                        context
                                            .read<LanLobbyBloc>()
                                            .add(ConnectToHost(service));
                                      },
                                      child: Text(l10n.lanJoin),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _failureMessage(
    LanLobbyFailure failure,
    AppLocalizations l10n,
  ) =>
      switch (failure) {
        LanLobbyFailure.discovery => l10n.lanDiscoveryFailed,
        LanLobbyFailure.hosting => l10n.lanHostingFailed,
        LanLobbyFailure.connection => l10n.lanConnectionFailed,
      };
}

class _LobbyStatusPane extends StatelessWidget {
  const _LobbyStatusPane({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.action,
    this.progress = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Widget action;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                constraints.maxHeight > 32 ? constraints.maxHeight - 32 : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: iconColor, size: 56),
                      if (progress) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      action,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            scanning ? Icons.radar_rounded : Icons.lan_outlined,
            size: 48,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            scanning ? l10n.lanSearching : l10n.lanNoRooms,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            scanning ? l10n.lanSearchingHint : l10n.lanSearchHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
