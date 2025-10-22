/// Game Events - 游戏事件定义
/// 
/// 职责：
/// - 定义所有可能的游戏事件
/// - 为BLoC提供类型安全的事件接口
/// 
/// 事件类型：
/// - SelectPiece: 选中棋子
/// - MovePiece: 移动棋子
/// - DeselectPiece: 取消选中
/// - RestartGame: 重新开始游戏
/// - UndoMove: 撤销移动
/// - NewGame: 开始新游戏
library;

import 'package:equatable/equatable.dart';
import '../models/position.dart';

/// 游戏事件基类
abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// 选中棋子事件
/// 
/// 当用户点击己方棋子时触发
class SelectPieceEvent extends GameEvent {
  final Position position;

  const SelectPieceEvent(this.position);

  @override
  List<Object?> get props => [position];

  @override
  String toString() => 'SelectPieceEvent(position: $position)';
}

/// 移动棋子事件
/// 
/// 当用户选中棋子后点击合法位置时触发
class MovePieceEvent extends GameEvent {
  final Position from;
  final Position to;

  const MovePieceEvent({
    required this.from,
    required this.to,
  });

  @override
  List<Object?> get props => [from, to];

  @override
  String toString() => 'MovePieceEvent(from: $from, to: $to)';
}

/// 取消选中事件
/// 
/// 当用户点击空白处或已选中的棋子时触发
class DeselectPieceEvent extends GameEvent {
  const DeselectPieceEvent();

  @override
  String toString() => 'DeselectPieceEvent()';
}

/// 重新开始游戏事件
/// 
/// 重置当前游戏到初始状态，保留游戏模式
class RestartGameEvent extends GameEvent {
  const RestartGameEvent();

  @override
  String toString() => 'RestartGameEvent()';
}

/// 开始新游戏事件
/// 
/// 可以选择不同的游戏模式
class NewGameEvent extends GameEvent {
  final GameMode mode;
  final String? aiDifficulty; // 'easy', 'medium', 'hard'

  const NewGameEvent({
    required this.mode,
    this.aiDifficulty,
  });

  @override
  List<Object?> get props => [mode, aiDifficulty];

  @override
  String toString() => 'NewGameEvent(mode: $mode, aiDifficulty: $aiDifficulty)';
}

/// 撤销移动事件
/// 
/// 撤销上一步移动（双人模式可能需要撤销2步，AI模式撤销1步）
class UndoMoveEvent extends GameEvent {
  final int steps; // 撤销步数，默认1步

  const UndoMoveEvent({this.steps = 1});

  @override
  List<Object?> get props => [steps];

  @override
  String toString() => 'UndoMoveEvent(steps: $steps)';
}

/// 重做移动事件
/// 
/// 重做之前撤销的移动
class RedoMoveEvent extends GameEvent {
  final int steps; // 重做步数，默认1步

  const RedoMoveEvent({this.steps = 1});

  @override
  List<Object?> get props => [steps];

  @override
  String toString() => 'RedoMoveEvent(steps: $steps)';
}

/// 确认移动事件
/// 
/// 当启用移动确认机制时，用户需要确认移动
class ConfirmMoveEvent extends GameEvent {
  const ConfirmMoveEvent();

  @override
  String toString() => 'ConfirmMoveEvent()';
}

/// 取消移动事件
/// 
/// 取消当前待确认的移动
class CancelMoveEvent extends GameEvent {
  const CancelMoveEvent();

  @override
  String toString() => 'CancelMoveEvent()';
}

/// 切换玩家事件（主要用于测试）
class SwitchPlayerEvent extends GameEvent {
  const SwitchPlayerEvent();

  @override
  String toString() => 'SwitchPlayerEvent()';
}

/// AI移动事件
/// 
/// 触发AI计算并执行移动
class AIPlayEvent extends GameEvent {
  const AIPlayEvent();

  @override
  String toString() => 'AIPlayEvent()';
}

/// 保存游戏事件
class SaveGameEvent extends GameEvent {
  const SaveGameEvent();

  @override
  String toString() => 'SaveGameEvent()';
}

/// 加载游戏事件
class LoadGameEvent extends GameEvent {
  const LoadGameEvent();

  @override
  String toString() => 'LoadGameEvent()';
}

/// 设置更新事件
/// 
/// 当游戏设置改变时触发
class SettingsChangedEvent extends GameEvent {
  final bool? soundEnabled;
  final bool? musicEnabled;
  final bool? vibrationEnabled;
  final String? theme;

  const SettingsChangedEvent({
    this.soundEnabled,
    this.musicEnabled,
    this.vibrationEnabled,
    this.theme,
  });

  @override
  List<Object?> get props => [
        soundEnabled,
        musicEnabled,
        vibrationEnabled,
        theme,
      ];

  @override
  String toString() =>
      'SettingsChangedEvent(sound: $soundEnabled, music: $musicEnabled, '
      'vibration: $vibrationEnabled, theme: $theme)';
}

/// 游戏模式枚举
enum GameMode {
  /// 双人对战模式（本地）
  pvp,

  /// 人机对战模式
  pve,

  /// 在线对战模式（未来功能）
  online,
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.pvp:
        return '双人对战';
      case GameMode.pve:
        return '人机对战';
      case GameMode.online:
        return '在线对战';
    }
  }

  bool get isAIMode => this == GameMode.pve;
  bool get isOnlineMode => this == GameMode.online;
}
