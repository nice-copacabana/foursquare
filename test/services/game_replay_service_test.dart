/// Game Replay Service Test - 游戏回放服务测试
/// 
/// 测试范围：
/// - 回放初始化
/// - 前进/后退导航
/// - 跳转功能
/// - 边界条件
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/game_replay_service.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/board_state.dart';

void main() {
  group('GameReplayService', () {
    late GameReplayService service;
    late List<Move> sampleMoves;

    setUp(() {
      service = GameReplayService();
      
      // 创建示例移动历史
      sampleMoves = [
        Move.now(
          from: const Position(0, 0),
          to: const Position(0, 1),
          player: PieceType.black,
        ),
        Move.now(
          from: const Position(3, 3),
          to: const Position(3, 2),
          player: PieceType.white,
        ),
        Move.now(
          from: const Position(1, 0),
          to: const Position(1, 1),
          player: PieceType.black,
        ),
      ];
    });

    test('初始状态应该正确', () {
      expect(service.state.currentStep, -1);
      expect(service.state.totalSteps, 0);
      expect(service.state.isReplaying, false);
    });

    test('startReplay应该正确初始化回放', () {
      final state = service.startReplay(sampleMoves);

      expect(state.currentStep, -1);
      expect(state.totalSteps, 3);
      expect(state.isReplaying, true);
      expect(state.boardState, BoardState.initial());
    });

    test('goForward应该前进一步', () {
      service.startReplay(sampleMoves);
      final state = service.goForward();

      expect(state.currentStep, 0);
      expect(state.currentMove, sampleMoves[0]);
      expect(state.canGoForward, true);
      expect(state.canGoBackward, true);
    });

    test('goForward在最后一步时不应该继续前进', () {
      service.startReplay(sampleMoves);
      service.goToEnd();
      final beforeState = service.state;
      final afterState = service.goForward();

      expect(afterState.currentStep, beforeState.currentStep);
      expect(afterState.canGoForward, false);
    });

    test('goBackward应该后退一步', () {
      service.startReplay(sampleMoves);
      service.goForward();
      service.goForward();
      
      final state = service.goBackward();

      expect(state.currentStep, 0);
      expect(state.currentMove, sampleMoves[0]);
    });

    test('goBackward在初始状态时不应该继续后退', () {
      service.startReplay(sampleMoves);
      final beforeState = service.state;
      final afterState = service.goBackward();

      expect(afterState.currentStep, beforeState.currentStep);
      expect(afterState.canGoBackward, false);
    });

    test('goToStart应该跳转到初始状态', () {
      service.startReplay(sampleMoves);
      service.goToEnd();
      
      final state = service.goToStart();

      expect(state.currentStep, -1);
      expect(state.boardState, BoardState.initial());
      expect(state.currentMove, null);
    });

    test('goToEnd应该跳转到最后一步', () {
      service.startReplay(sampleMoves);
      
      final state = service.goToEnd();

      expect(state.currentStep, 2);
      expect(state.currentMove, sampleMoves[2]);
      expect(state.canGoForward, false);
    });

    test('goToStep应该跳转到指定步骤', () {
      service.startReplay(sampleMoves);
      
      final state = service.goToStep(1);

      expect(state.currentStep, 1);
      expect(state.currentMove, sampleMoves[1]);
    });

    test('goToStep超出范围时不应该改变状态', () {
      service.startReplay(sampleMoves);
      final beforeState = service.state;
      
      final state = service.goToStep(10);

      expect(state.currentStep, beforeState.currentStep);
    });

    test('exitReplay应该退出回放模式', () {
      service.startReplay(sampleMoves);
      service.exitReplay();

      expect(service.state.isReplaying, false);
      expect(service.moveHistory, isEmpty);
    });

    test('reset应该重置服务状态', () {
      service.startReplay(sampleMoves);
      service.goForward();
      service.reset();

      expect(service.state.currentStep, -1);
      expect(service.state.totalSteps, 0);
      expect(service.state.isReplaying, false);
      expect(service.moveHistory, isEmpty);
    });

    test('getMoveAtStep应该返回正确的移动', () {
      service.startReplay(sampleMoves);

      expect(service.getMoveAtStep(0), sampleMoves[0]);
      expect(service.getMoveAtStep(1), sampleMoves[1]);
      expect(service.getMoveAtStep(2), sampleMoves[2]);
    });

    test('getMoveAtStep超出范围时应该返回null', () {
      service.startReplay(sampleMoves);

      expect(service.getMoveAtStep(-1), null);
      expect(service.getMoveAtStep(10), null);
    });

    test('连续前进应该正确更新棋盘状态', () {
      service.startReplay(sampleMoves);

      // 第一步
      var state = service.goForward();
      var piece = state.boardState.getPiece(const Position(0, 1));
      expect(piece, PieceType.black);

      // 第二步
      state = service.goForward();
      piece = state.boardState.getPiece(const Position(3, 2));
      expect(piece, PieceType.white);

      // 第三步
      state = service.goForward();
      piece = state.boardState.getPiece(const Position(1, 1));
      expect(piece, PieceType.black);
    });

    test('前进再后退应该恢复到之前的状态', () {
      service.startReplay(sampleMoves);

      service.goForward();
      final afterForwardState = service.state;
      
      service.goForward();
      service.goBackward();
      final afterBackwardState = service.state;

      expect(afterBackwardState.currentStep, afterForwardState.currentStep);
      expect(
        afterBackwardState.boardState.toString(),
        afterForwardState.boardState.toString(),
      );
    });
  });

  group('ReplayState', () {
    test('isAtStart应该正确判断', () {
      final state = ReplayState(
        currentStep: -1,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );

      expect(state.isAtStart, true);
    });

    test('isAtEnd应该正确判断', () {
      final state = ReplayState(
        currentStep: 4,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );

      expect(state.isAtEnd, true);
    });

    test('canGoForward应该正确判断', () {
      final state = ReplayState(
        currentStep: 2,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );

      expect(state.canGoForward, true);
    });

    test('canGoBackward应该正确判断', () {
      final state = ReplayState(
        currentStep: 2,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );

      expect(state.canGoBackward, true);
    });

    test('stepDescription应该返回正确的描述', () {
      final initialState = ReplayState(
        currentStep: -1,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );
      expect(initialState.stepDescription, '初始状态');

      final midState = ReplayState(
        currentStep: 2,
        totalSteps: 5,
        boardState: BoardState.initial(),
      );
      expect(midState.stepDescription, '第 3 步 / 共 5 步');
    });

    test('copyWith应该正确复制', () {
      final original = ReplayState(
        currentStep: 1,
        totalSteps: 5,
        boardState: BoardState.initial(),
        isReplaying: true,
      );

      final copied = original.copyWith(currentStep: 2);

      expect(copied.currentStep, 2);
      expect(copied.totalSteps, original.totalSteps);
      expect(copied.isReplaying, original.isReplaying);
    });
  });
}
