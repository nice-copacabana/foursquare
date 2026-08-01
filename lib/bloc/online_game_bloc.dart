import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/online_protocol.dart';
import '../services/online_authority_session.dart';
import '../services/online_game_transport.dart';
import '../services/online_identity_service.dart';
import 'online_game_event.dart';
import 'online_game_state.dart';

typedef OnlineSessionFactory = OnlineAuthoritySession Function(
  OnlineStateSnapshot snapshot,
);

class OnlineGameBloc extends Bloc<OnlineGameEvent, OnlineBattleState> {
  OnlineGameBloc({
    required OnlineGameTransportClient transport,
    required OnlineIdentityService identityService,
    OnlineSessionFactory? sessionFactory,
  })  : _transport = transport,
        _identityService = identityService,
        _sessionFactory = sessionFactory ??
            ((snapshot) => OnlineAuthoritySession(snapshot: snapshot)),
        super(const OnlineBattleState()) {
    on<OnlineGameEvent>(_onEvent, transformer: _sequential());
    _transportSubscription = _transport.events.listen(
      (event) => add(_TransportEventArrived(event)),
    );
  }

  final OnlineGameTransportClient _transport;
  final OnlineIdentityService _identityService;
  final OnlineSessionFactory _sessionFactory;

  late final StreamSubscription<OnlineGameTransportEvent>
      _transportSubscription;
  OnlineAuthoritySession? _session;
  String? _identity;

  Future<void> _onEvent(
    OnlineGameEvent event,
    Emitter<OnlineBattleState> emit,
  ) async {
    switch (event) {
      case StartOnlineMatching():
        await _startMatching(emit);
      case CancelOnlineMatching():
        _cancelMatching(emit);
      case SubmitOnlineMove():
        _submitMove(event, emit);
      case RetryOnlineConnection():
        await _retryConnection(emit);
      case LeaveOnlineGame():
        await _leaveGame(emit);
      case _TransportEventArrived():
        _handleTransportEvent(event.event, emit);
    }
  }

  Future<void> _startMatching(Emitter<OnlineBattleState> emit) async {
    if (state.phase == OnlineBattlePhase.connecting ||
        state.phase == OnlineBattlePhase.matching ||
        state.phase == OnlineBattlePhase.playing) {
      return;
    }
    _session = null;
    emit(const OnlineBattleState(phase: OnlineBattlePhase.connecting));

    try {
      _identity ??= await _identityService.getOrCreate();
    } catch (_) {
      emit(
        const OnlineBattleState(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.identityUnavailable,
        ),
      );
      return;
    }

    final connected = await _transport.connect();
    if (!connected) {
      emit(
        const OnlineBattleState(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.connectionFailed,
        ),
      );
      return;
    }
    if (!_transport.requestMatch(_identity!)) {
      emit(
        const OnlineBattleState(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.requestFailed,
        ),
      );
    }
  }

  void _cancelMatching(Emitter<OnlineBattleState> emit) {
    final identity = _identity;
    if (identity == null || !_transport.cancelMatch(identity)) {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.requestFailed,
        ),
      );
    }
  }

  void _submitMove(
    SubmitOnlineMove event,
    Emitter<OnlineBattleState> emit,
  ) {
    final session = _session;
    if (session == null || !state.canMove) return;

    late final OnlineMoveIntent intent;
    try {
      intent = session.createMoveIntent(from: event.from, to: event.to);
    } on OnlineSessionException {
      return;
    }

    if (!_transport.submitMove(intent)) {
      session.discardPendingIntent(intent.commandId);
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.recovering,
          isSynchronized: false,
          isMovePending: false,
          failure: OnlineBattleFailure.requestFailed,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isMovePending: true,
        lastMoveRejection: null,
        failure: null,
      ),
    );
  }

  Future<void> _retryConnection(Emitter<OnlineBattleState> emit) async {
    final identity = _identity;
    if (identity == null) {
      await _startMatching(emit);
      return;
    }
    final requiresNewSocket =
        state.failure == OnlineBattleFailure.snapshotRejected;

    emit(
      state.copyWith(
        phase: _session == null
            ? OnlineBattlePhase.connecting
            : OnlineBattlePhase.recovering,
        isSynchronized: _session == null,
        failure: null,
      ),
    );
    final existingSession = _session;
    if (existingSession != null &&
        _transport.isConnected &&
        !requiresNewSocket) {
      if (!_transport.requestSnapshot(existingSession.matchId)) {
        emit(
          state.copyWith(
            phase: OnlineBattlePhase.failure,
            failure: OnlineBattleFailure.requestFailed,
          ),
        );
      }
      return;
    }
    if (requiresNewSocket && _transport.isConnected) {
      await _transport.disconnect();
    }
    final connected = await _transport.connect();
    if (!connected) {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.connectionFailed,
        ),
      );
      return;
    }

    final session = _session;
    final sent = session == null
        ? _transport.requestMatch(identity)
        : _transport.resumeMatch(identity, session.matchId);
    if (!sent) {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.requestFailed,
        ),
      );
    }
  }

  Future<void> _leaveGame(Emitter<OnlineBattleState> emit) async {
    await _transport.disconnect();
    _session = null;
    emit(const OnlineBattleState());
  }

  void _handleTransportEvent(
    OnlineGameTransportEvent event,
    Emitter<OnlineBattleState> emit,
  ) {
    switch (event) {
      case OnlineMatchQueued():
        if (_session != null) return;
        emit(const OnlineBattleState(phase: OnlineBattlePhase.matching));
      case OnlineMatchCancelled():
        if (_session != null) return;
        _session = null;
        emit(const OnlineBattleState());
      case OnlineMatchRejected():
        if (_session != null &&
            event.reason == OnlineMatchRejectionReason.notQueued) {
          return;
        }
        if (event.reason == OnlineMatchRejectionReason.resumeNotFound) {
          _session = null;
          emit(
            const OnlineBattleState(
              phase: OnlineBattlePhase.failure,
              failure: OnlineBattleFailure.resumeNotFound,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            phase: OnlineBattlePhase.failure,
            failure: OnlineBattleFailure.matchRejected,
          ),
        );
      case OnlineSnapshotReceived():
        if (_session != null && event.snapshot.matchId != _session!.matchId) {
          return;
        }
        _applySnapshot(event.snapshot, emit);
      case OnlineSnapshotRejected():
        final session = _session;
        if (session == null || event.matchId != session.matchId) return;
        emit(
          state.copyWith(
            phase: OnlineBattlePhase.failure,
            isSynchronized: false,
            isMovePending: false,
            failure: OnlineBattleFailure.snapshotRejected,
          ),
        );
      case OnlineMoveDecisionReceived():
        _applyDecision(event.decision, emit);
      case OnlineOpponentPresenceChanged():
        final session = _session;
        if (session == null || event.matchId != session.matchId) return;
        emit(
          state.copyWith(
            opponentConnected: event.isConnected,
            opponentReconnectDeadlineEpochMs: event.reconnectDeadlineEpochMs,
          ),
        );
      case OnlineGameOverReceived():
        _applyGameOver(event, emit);
      case OnlineTransportFailure():
        if (event.reason == OnlineTransportFailureReason.invalidPayload &&
            _session != null &&
            _transport.isConnected) {
          _requestSnapshot(emit);
          return;
        }
        emit(
          state.copyWith(
            phase: _session == null
                ? OnlineBattlePhase.failure
                : OnlineBattlePhase.recovering,
            isSynchronized: _session == null,
            isMovePending: false,
            failure: event.reason == OnlineTransportFailureReason.invalidPayload
                ? OnlineBattleFailure.protocolFailure
                : OnlineBattleFailure.connectionFailed,
          ),
        );
    }
  }

  void _applySnapshot(
    OnlineStateSnapshot snapshot,
    Emitter<OnlineBattleState> emit,
  ) {
    try {
      final session = _session;
      if (session == null) {
        _session = _sessionFactory(snapshot);
      } else {
        final update = session.applySnapshot(snapshot);
        if (update == OnlineSessionUpdate.ignored) return;
      }
      _emitSession(
        emit,
        opponentConnected: snapshot.opponentConnected,
        opponentReconnectDeadlineEpochMs:
            snapshot.opponentReconnectDeadlineEpochMs,
      );
    } on OnlineSessionException {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          isSynchronized: false,
          failure: OnlineBattleFailure.protocolFailure,
        ),
      );
    }
  }

  void _applyDecision(
    OnlineMoveDecision decision,
    Emitter<OnlineBattleState> emit,
  ) {
    final session = _session;
    if (session == null) return;
    final update = session.applyDecision(decision);
    switch (update) {
      case OnlineSessionUpdate.applied:
        _emitSession(emit);
      case OnlineSessionUpdate.rejected:
        _emitSession(emit, lastMoveRejection: session.lastRejection);
      case OnlineSessionUpdate.duplicate:
        if (state.isMovePending && session.pendingCommandId == null) {
          emit(state.copyWith(isMovePending: false));
        }
      case OnlineSessionUpdate.requiresSnapshot:
        _requestSnapshot(emit);
      case OnlineSessionUpdate.ignored:
        return;
    }
  }

  void _applyGameOver(
    OnlineGameOverReceived event,
    Emitter<OnlineBattleState> emit,
  ) {
    final session = _session;
    if (session == null) return;
    try {
      final update = session.applyGameOver(
        matchId: event.matchId,
        state: event.state,
      );
      if (update == OnlineSessionUpdate.applied) _emitSession(emit);
    } on OnlineSessionException {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          isSynchronized: false,
          failure: OnlineBattleFailure.protocolFailure,
        ),
      );
    }
  }

  void _requestSnapshot(Emitter<OnlineBattleState> emit) {
    final session = _session;
    if (session == null) return;
    emit(
      state.copyWith(
        phase: OnlineBattlePhase.recovering,
        isSynchronized: false,
        isMovePending: false,
        failure: null,
      ),
    );
    if (!_transport.requestSnapshot(session.matchId)) {
      emit(
        state.copyWith(
          phase: OnlineBattlePhase.failure,
          failure: OnlineBattleFailure.requestFailed,
        ),
      );
    }
  }

  void _emitSession(
    Emitter<OnlineBattleState> emit, {
    bool? opponentConnected,
    Object? opponentReconnectDeadlineEpochMs = _keepValue,
    OnlineMoveRejectionReason? lastMoveRejection,
  }) {
    final session = _session!;
    final finished = session.state.status == OnlineGameStatus.finished;
    emit(
      state.copyWith(
        phase:
            finished ? OnlineBattlePhase.finished : OnlineBattlePhase.playing,
        authoritativeState: session.state,
        localColor: session.color,
        turnDeadlineEpochMs: session.turnDeadlineEpochMs,
        opponentConnected: finished ? true : opponentConnected,
        opponentReconnectDeadlineEpochMs: finished
            ? null
            : identical(opponentReconnectDeadlineEpochMs, _keepValue)
                ? state.opponentReconnectDeadlineEpochMs
                : opponentReconnectDeadlineEpochMs,
        isSynchronized: true,
        isMovePending: false,
        lastMoveRejection: lastMoveRejection,
        failure: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    try {
      await _transportSubscription.cancel();
    } finally {
      try {
        await _transport.dispose();
      } finally {
        await super.close();
      }
    }
  }
}

class _TransportEventArrived extends OnlineGameEvent {
  final OnlineGameTransportEvent event;

  const _TransportEventArrived(this.event);

  @override
  List<Object?> get props => [event];
}

EventTransformer<E> _sequential<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}

const Object _keepValue = Object();
