import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/lan_lobby_bloc.dart';
import '../../../bloc/lan_lobby_event.dart';
import '../../../bloc/lan_lobby_state.dart';

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
  late TabController _tabController;
  final TextEditingController _roomNameController =
      TextEditingController(text: 'My Room');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('局域网对战'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '创建房间'),
            Tab(text: '加入房间'),
          ],
        ),
      ),
      body: BlocConsumer<LanLobbyBloc, LanLobbyState>(
        listener: (context, state) {
          if (state.status == LanLobbyStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.status == LanLobbyStatus.connected) {
            // Navigate to Game Page (Placeholder for now)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已连接! 准备开始游戏...')),
            );
            // TODO: Navigate to Game Page
          }
        },
        builder: (context, state) {
          if (state.status == LanLobbyStatus.connected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('已连接到对局', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LanLobbyBloc>().add(DisconnectLan());
                    },
                    child: const Text('断开连接'),
                  ),
                ],
              ),
            );
          }

          if (state.status == LanLobbyStatus.hosting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('正在等待玩家加入...', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('房间名: ${_roomNameController.text}'),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LanLobbyBloc>().add(StopHosting());
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,),
                    child: const Text('取消创建'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Host Tab
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_tethering,
                        size: 80, color: Colors.blueAccent,),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        labelText: '房间名称',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<LanLobbyBloc>().add(
                                StartHosting(
                                    roomName: _roomNameController.text,),
                              );
                        },
                        child:
                            const Text('创建房间', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),

              // Join Tab
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('附近的房间',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,),),
                        if (state.status == LanLobbyStatus.scanning)
                          IconButton(
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
                            icon: const Icon(Icons.refresh),
                            onPressed: () => context
                                .read<LanLobbyBloc>()
                                .add(StartDiscovery()),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: state.foundServices.isEmpty
                        ? Center(
                            child: Text(
                              state.status == LanLobbyStatus.scanning
                                  ? '正在搜索...'
                                  : '点击刷新按钮搜索房间',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.foundServices.length,
                            itemBuilder: (context, index) {
                              final service = state.foundServices[index];
                              return ListTile(
                                leading: const Icon(Icons.computer),
                                title: Text(service.name ?? 'Unknown Room'),
                                subtitle: Text(
                                    '${service.host ?? "Unknown IP"}:${service.port}',),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    context
                                        .read<LanLobbyBloc>()
                                        .add(ConnectToHost(service));
                                  },
                                  child: const Text('加入'),
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
}
