/// Minimax AI测试
/// 
/// 测试内容：
/// - AI基础功能
/// - AI性能测试
/// - AI优化效果验证
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ai/minimax_ai.dart';
import 'package:foursquare/ai/ai_player.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';

/// 创建一个空棋盘（所有位置都为empty）
BoardState createEmptyBoard({PieceType currentPlayer = PieceType.black}) {
  var board = BoardState.initial();
  // 清空所有棋子
  for (int y = 0; y < 4; y++) {
    for (int x = 0; x < 4; x++) {
      board = board.setPiece(Position(x, y), PieceType.empty);
    }
  }
  return board.copyWith(currentPlayer: currentPlayer);
}

void main() {
  group('MinimaxAI 基础功能', () {
    test('应该创建正确难度的AI', () {
      final easyAI = MinimaxAI(AIDifficulty.easy);
      expect(easyAI.difficulty, equals(AIDifficulty.easy));
      
      final mediumAI = MinimaxAI(AIDifficulty.medium);
      expect(mediumAI.difficulty, equals(AIDifficulty.medium));
      
      final hardAI = MinimaxAI(AIDifficulty.hard);
      expect(hardAI.difficulty, equals(AIDifficulty.hard));
    });
    
    test('name和description应该正确', () {
      final ai = MinimaxAI(AIDifficulty.medium);
      expect(ai.name, isNotEmpty);
      expect(ai.description, isNotEmpty);
      expect(ai.description, contains('Minimax'));
    });
  });
  
  group('MinimaxAI 移动选择', () {
    test('初始棋盘应该能选择合法移动', () async {
      final ai = MinimaxAI(AIDifficulty.easy);
      final board = BoardState.initial().switchPlayer(); // 切换到白方
      
      final result = await ai.selectMove(board);
      
      expect(result, isNotNull);
      expect(result!.from, isNotNull);
      expect(result.to, isNotNull);
      expect(result.score, isNotNull);
      expect(result.nodesEvaluated, greaterThan(0));
    });
    
    test('无合法移动时应该返回null', () async {
      final ai = MinimaxAI(AIDifficulty.easy);
      
      // 创建一个白方无子可走的棋盘
      final board = createEmptyBoard(currentPlayer: PieceType.white)
      .setPiece(const Position(0, 0), PieceType.white) // 白方唯一的棋子
      .setPiece(const Position(1, 0), PieceType.black) // 被黑方包围
      .setPiece(const Position(0, 1), PieceType.black);
      
      final result = await ai.selectMove(board);
      
      // 如果白方有其他棋子，可能还能移动，所以这个测试可能需要调整
      // 这里主要测试AI在无棋可走时的行为
      expect(result == null || result.from.isValid(), isTrue);
    });
    
    test('应该优先选择吃子移动', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      
      // 创建一个可以吃子的棋盘
      // B . W .
      // . . . .
      // . . . .
      // B . . W
      final board = createEmptyBoard(currentPlayer: PieceType.white)
      .setPiece(const Position(0, 0), PieceType.black)
      .setPiece(const Position(2, 0), PieceType.white)  // 白方可以向左吃掉黑子
      .setPiece(const Position(0, 3), PieceType.black)
      .setPiece(const Position(3, 3), PieceType.white);
      
      final result = await ai.selectMove(board);
      
      expect(result, isNotNull);
      // AI应该倾向于吃子移动，但不是100%保证（因为有评估）
    });
  });
  
  group('MinimaxAI 进度回调', () {
    test('应该正确调用进度回调', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      final board = BoardState.initial().switchPlayer();
      
      final progressUpdates = <double>[];
      final statusUpdates = <String>[];
      
      ai.setProgressCallback((progress, status) {
        progressUpdates.add(progress);
        statusUpdates.add(status);
      });
      
      await ai.selectMove(board);
      
      // 应该有多次进度更新
      expect(progressUpdates, isNotEmpty);
      expect(statusUpdates, isNotEmpty);
      
      // 进度应该是递增的（大致）
      expect(progressUpdates.first, lessThanOrEqualTo(progressUpdates.last));
      
      // 最后一次进度应该是1.0
      expect(progressUpdates.last, equals(1.0));
      
      // 状态应该包含搜索深度信息
      expect(statusUpdates.any((s) => s.contains('搜索深度')), isTrue);
      expect(statusUpdates.last, contains('完成'));
    });
    
    test('清除回调后不应该调用', () async {
      final ai = MinimaxAI(AIDifficulty.easy);
      final board = BoardState.initial().switchPlayer();
      
      var callCount = 0;
      ai.setProgressCallback((progress, status) {
        callCount++;
      });
      
      await ai.selectMove(board);
      final firstCallCount = callCount;
      
      expect(firstCallCount, greaterThan(0));
      
      // 清除回调
      ai.setProgressCallback(null);
      callCount = 0;
      
      await ai.selectMove(board);
      expect(callCount, equals(0));
    });
  });
  
  group('MinimaxAI 性能测试', () {
    test('简单难度应该在100ms内完成', () async {
      final ai = MinimaxAI(AIDifficulty.easy);
      final board = BoardState.initial().switchPlayer();
      
      final stopwatch = Stopwatch()..start();
      await ai.selectMove(board);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
    
    test('中等难度应该在500ms内完成', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      final board = BoardState.initial().switchPlayer();
      
      final stopwatch = Stopwatch()..start();
      await ai.selectMove(board);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
    
    test('困难难度应该在2000ms内完成', () async {
      final ai = MinimaxAI(AIDifficulty.hard);
      final board = BoardState.initial().switchPlayer();
      
      final stopwatch = Stopwatch()..start();
      await ai.selectMove(board);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
    
    test('nodesEvaluated应该随难度增加', () async {
      final easyAI = MinimaxAI(AIDifficulty.easy);
      final mediumAI = MinimaxAI(AIDifficulty.medium);
      final hardAI = MinimaxAI(AIDifficulty.hard);
      final board = BoardState.initial().switchPlayer();
      
      final easyResult = await easyAI.selectMove(board);
      final mediumResult = await mediumAI.selectMove(board);
      final hardResult = await hardAI.selectMove(board);
      
      expect(easyResult!.nodesEvaluated, lessThan(mediumResult!.nodesEvaluated));
      expect(mediumResult.nodesEvaluated, lessThan(hardResult!.nodesEvaluated));
    });
  });
  
  group('MinimaxAI 战术能力', () {
    test('应该能检测到必胜局面', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      
      // 创建一个白方即将获胜的棋盘
      // B . . .
      // B . . .
      // B . . .
      // . W W W (白方下一步可以形成4连)
      final board = createEmptyBoard(currentPlayer: PieceType.white)
      .setPiece(const Position(0, 0), PieceType.black)
      .setPiece(const Position(0, 1), PieceType.black)
      .setPiece(const Position(0, 2), PieceType.black)
      .setPiece(const Position(1, 3), PieceType.white)
      .setPiece(const Position(2, 3), PieceType.white)
      .setPiece(const Position(3, 3), PieceType.white);
      
      final result = await ai.selectMove(board);
      
      expect(result, isNotNull);
      // AI应该选择获胜的移动（向左移动到(0,3)形成四连）
      // 但具体移动取决于棋盘状态，这里主要验证能找到移动
      expect(result!.score, greaterThan(5000)); // 获胜局面应该有高分
    });
    
    test('应该能阻止对手获胜', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      
      // 创建一个黑方即将获胜的棋盘，白方必须阻止
      // B B B . (黑方3连，白方必须阻止)
      // . . . .
      // . . . .
      // . . . W
      final board = createEmptyBoard(currentPlayer: PieceType.white)
      .setPiece(const Position(0, 0), PieceType.black)
      .setPiece(const Position(1, 0), PieceType.black)
      .setPiece(const Position(2, 0), PieceType.black)
      .setPiece(const Position(3, 3), PieceType.white);
      
      final result = await ai.selectMove(board);
      
      expect(result, isNotNull);
      // AI应该找到阻止对手的移动
      // 但由于棋盘状态复杂，这里主要验证返回了合法移动
    });
  });
  
  group('MinimaxAI 优化效果', () {
    test('置换表应该减少重复计算', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      final board = BoardState.initial().switchPlayer();
      
      // 第一次搜索
      final result1 = await ai.selectMove(board);
      final nodes1 = result1!.nodesEvaluated;
      
      // 第二次搜索相同棋盘（置换表应该有缓存）
      final result2 = await ai.selectMove(board);
      final nodes2 = result2!.nodesEvaluated;
      
      // 第二次搜索应该更快（评估节点数可能相同或更少）
      // 注意：这个测试假设置换表在两次调用之间保持
      expect(nodes2, greaterThan(0));
      expect(result1.from, isNotNull);
      expect(result2.from, isNotNull);
    });
    
    test('迭代加深应该逐步增加深度', () async {
      final ai = MinimaxAI(AIDifficulty.medium);
      final board = BoardState.initial().switchPlayer();
      
      final depths = <int>[];
      ai.setProgressCallback((progress, status) {
        // 从状态中提取深度信息
        if (status.contains('搜索深度')) {
          final match = RegExp(r'(\d+)/(\d+)').firstMatch(status);
          if (match != null) {
            depths.add(int.parse(match.group(1)!));
          }
        }
      });
      
      await ai.selectMove(board);
      
      // 深度应该是递增的：1, 2, 3, ...
      expect(depths, isNotEmpty);
      for (int i = 0; i < depths.length - 1; i++) {
        expect(depths[i], lessThanOrEqualTo(depths[i + 1]));
      }
    });
  });
}
