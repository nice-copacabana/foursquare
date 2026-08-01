import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/online_game_transport.dart';
import 'package:foursquare/services/online_identity_service.dart';
import 'package:foursquare/ui/screens/online_game_page.dart';
import 'package:foursquare/ui/widgets/animated_board_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  for (final testCase in [
    (const Locale('zh'), '在线对战', '寻找对手'),
    (const Locale('en'), 'Online game', 'Find an opponent'),
    (const Locale('ja'), 'オンライン対局', '対戦相手を探す'),
  ]) {
    testWidgets('idle online page is localized for ${testCase.$1.languageCode}',
        (tester) async {
      final transport = FakeOnlinePageTransport();
      await tester.pumpWidget(
        _app(
          locale: testCase.$1,
          transport: transport,
          identityService: FakeOnlinePageIdentity(),
        ),
      );

      expect(find.text(testCase.$2), findsOneWidget);
      expect(find.text(testCase.$3), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('authoritative board never exposes device or match identifiers',
      (tester) async {
    final transport = FakeOnlinePageTransport();
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        transport: transport,
        identityService: FakeOnlinePageIdentity(),
      ),
    );

    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(),
        source: OnlineSnapshotSource.matchFound,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('device-12345678'), findsNothing);
    expect(find.textContaining('match-1'), findsNothing);
    expect(find.text('Your turn'), findsOneWidget);
  });

  testWidgets('opponent disconnect keeps the board and shows server deadline',
      (tester) async {
    final transport = FakeOnlinePageTransport();
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        transport: transport,
        identityService: FakeOnlinePageIdentity(),
        now: () => DateTime.fromMillisecondsSinceEpoch(1000000),
      ),
    );
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(turnDeadline: 1060000),
        source: OnlineSnapshotSource.matchFound,
      ),
    );
    await tester.pump();
    transport.add(
      const OnlineOpponentPresenceChanged(
        matchId: 'match-1',
        isConnected: false,
        reconnectDeadlineEpochMs: 1030000,
      ),
    );
    await tester.pump();

    expect(find.textContaining('Opponent disconnected'), findsOneWidget);
    expect(find.textContaining('30 more seconds'), findsOneWidget);
    expect(find.byType(OnlineGameView), findsOneWidget);
  });

  testWidgets('authoritative double capture reaches the board animation',
      (tester) async {
    final transport = FakeOnlinePageTransport();
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        transport: transport,
        identityService: FakeOnlinePageIdentity(),
      ),
    );
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(),
        source: OnlineSnapshotSource.matchFound,
      ),
    );
    await tester.pump();
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _doubleCaptureSnapshot(),
        source: OnlineSnapshotSource.authoritativeSnapshot,
      ),
    );
    await tester.pump();

    final board = tester.widget<AnimatedBoardWidget>(
      find.byType(AnimatedBoardWidget),
    );
    expect(
      board.capturedPiecePositions,
      const [Position(1, 1), Position(2, 2)],
    );
  });

  testWidgets('recovering a live match offers an explicit reconnect action',
      (tester) async {
    final transport = FakeOnlinePageTransport();
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        transport: transport,
        identityService: FakeOnlinePageIdentity(),
      ),
    );
    await tester.tap(find.text('Find an opponent'));
    await tester.pump();
    await tester.pump();
    transport.add(
      OnlineSnapshotReceived(
        snapshot: _snapshot(),
        source: OnlineSnapshotSource.matchFound,
      ),
    );
    await tester.pump();
    transport.add(
      const OnlineTransportFailure(
        reason: OnlineTransportFailureReason.unexpectedDisconnect,
        sourceEvent: 'disconnect',
      ),
    );
    await tester.pump();

    expect(find.text('Retry connection'), findsOneWidget);
    await tester.tap(find.text('Retry connection'));
    await tester.pump();
    await tester.pump();

    expect(transport.connectCalls, 2);
    expect(transport.resumedMatches, [('device-12345678', 'match-1')]);
  });

  for (final testCase in [
    (
      'black',
      'timeout',
      'You win',
      'Jade ran out of time and loses',
    ),
    (
      'white',
      'disconnect',
      'You lose',
      'Ink was disconnected for over 30 seconds and loses',
    ),
    (
      'draw',
      'no_capture_limit',
      'Draw',
      'Draw after 50 moves without a capture',
    ),
  ]) {
    testWidgets('terminal ${testCase.$2} explains the authoritative result',
        (tester) async {
      final transport = FakeOnlinePageTransport();
      await tester.pumpWidget(
        _app(
          locale: const Locale('en'),
          transport: transport,
          identityService: FakeOnlinePageIdentity(),
        ),
      );
      transport.add(
        OnlineSnapshotReceived(
          snapshot: _snapshot(),
          source: OnlineSnapshotSource.matchFound,
        ),
      );
      await tester.pump();
      transport.add(
        OnlineGameOverReceived(
          matchId: 'match-1',
          state: OnlineGameState.fromJson({
            ..._playingStateJson(),
            'status': 'finished',
            'winner': testCase.$1,
            'endReason': testCase.$2,
            'revision': 1,
          }),
        ),
      );
      await tester.pump();

      expect(find.text(testCase.$3), findsOneWidget);
      expect(find.text(testCase.$4), findsOneWidget);
      expect(find.textContaining('Opponent disconnected'), findsNothing);
    });
  }
}

Widget _app({
  required Locale locale,
  required FakeOnlinePageTransport transport,
  required OnlineIdentityService identityService,
  DateTime Function()? now,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: OnlineGamePage(
      transport: transport,
      identityService: identityService,
      now: now,
    ),
  );
}

OnlineStateSnapshot _snapshot({int turnDeadline = 1060000}) =>
    OnlineStateSnapshot.fromJson({
      'protocolVersion': 1,
      'matchId': 'match-1',
      'color': 'black',
      'turnDeadlineEpochMs': turnDeadline,
      'opponentConnected': true,
      'state': _playingStateJson(),
    });

OnlineStateSnapshot _doubleCaptureSnapshot() => OnlineStateSnapshot.fromJson({
      'protocolVersion': 1,
      'matchId': 'match-1',
      'color': 'black',
      'turnDeadlineEpochMs': 1120000,
      'opponentConnected': true,
      'state': {
        ..._playingStateJson(),
        'currentTurn': 'white',
        'moveHistory': [
          {
            'matchId': 'match-1',
            'from': {'x': 0, 'y': 0},
            'to': {'x': 0, 'y': 1},
            'player': 'black',
            'capturedPieces': [
              {'x': 1, 'y': 1},
              {'x': 2, 'y': 2},
            ],
          },
        ],
        'revision': 1,
      },
    });

Map<String, dynamic> _playingStateJson() => {
      'board': [
        ['black', 'black', 'black', 'black'],
        [null, null, null, null],
        [null, null, null, null],
        ['white', 'white', 'white', 'white'],
      ],
      'currentTurn': 'black',
      'status': 'playing',
      'moveHistory': <Map<String, dynamic>>[],
      'noCapturePly': 0,
      'revision': 0,
    };

class FakeOnlinePageIdentity extends OnlineIdentityService {
  @override
  Future<String> getOrCreate() async => 'device-12345678';
}

class FakeOnlinePageTransport implements OnlineGameTransportClient {
  final StreamController<OnlineGameTransportEvent> _events =
      StreamController<OnlineGameTransportEvent>.broadcast();
  final StreamController<OnlineTransportConnection> _connections =
      StreamController<OnlineTransportConnection>.broadcast();
  final List<(String, String)> resumedMatches = [];
  int connectCalls = 0;
  OnlineTransportConnection currentConnection =
      OnlineTransportConnection.connected;

  void add(OnlineGameTransportEvent event) {
    if (event is OnlineTransportFailure &&
        event.reason == OnlineTransportFailureReason.unexpectedDisconnect) {
      currentConnection = OnlineTransportConnection.disconnected;
    }
    _events.add(event);
  }

  @override
  Stream<OnlineGameTransportEvent> get events => _events.stream;

  @override
  Stream<OnlineTransportConnection> get connectionStates => _connections.stream;

  @override
  OnlineTransportConnection get connectionState => currentConnection;

  @override
  bool get isConnected =>
      currentConnection == OnlineTransportConnection.connected;

  @override
  Future<bool> connect() async {
    connectCalls += 1;
    currentConnection = OnlineTransportConnection.connected;
    return true;
  }

  @override
  bool requestMatch(String playerId) => true;

  @override
  bool resumeMatch(String playerId, String matchId) {
    resumedMatches.add((playerId, matchId));
    return true;
  }

  @override
  bool requestSnapshot(String matchId) => true;

  @override
  bool cancelMatch(String playerId) => true;

  @override
  bool submitMove(OnlineMoveIntent intent) => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    await _events.close();
    await _connections.close();
  }
}
