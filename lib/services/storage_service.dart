/// Storage Service - 数据持久化服务
/// 
/// 职责：
/// - 管理游戏设置的保存和加载
/// - 管理统计数据的保存和加载
/// - 提供统一的存储接口
/// 
/// 技术实现：
/// - 使用 shared_preferences 存储简单设置
/// - 使用 hive 存储复杂数据结构
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/game_save.dart';

/// 游戏设置数据模型
class GameSettings {
  final bool soundEnabled;
  final double soundVolume;
  final bool musicEnabled;
  final double musicVolume;
  final String? musicTheme; // 音乐主题: 'main', 'gameplay', 'classic', 'night', 'relaxing'
  final bool vibrationEnabled;
  final String selectedTheme;
  final String difficulty; // 'easy', 'medium', 'hard'
  
  const GameSettings({
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.musicEnabled = true,
    this.musicVolume = 0.5,
    this.musicTheme = 'main',
    this.vibrationEnabled = true,
    this.selectedTheme = 'default',
    this.difficulty = 'medium',
  });
  
  Map<String, dynamic> toJson() => {
    'soundEnabled': soundEnabled,
    'soundVolume': soundVolume,
    'musicEnabled': musicEnabled,
    'musicVolume': musicVolume,
    'musicTheme': musicTheme,
    'vibrationEnabled': vibrationEnabled,
    'selectedTheme': selectedTheme,
    'difficulty': difficulty,
  };
  
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      soundVolume: json['soundVolume'] ?? 0.7,
      musicEnabled: json['musicEnabled'] ?? true,
      musicVolume: json['musicVolume'] ?? 0.5,
      musicTheme: json['musicTheme'] ?? 'main',
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      selectedTheme: json['selectedTheme'] ?? 'default',
      difficulty: json['difficulty'] ?? 'medium',
    );
  }
  
  GameSettings copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? musicEnabled,
    double? musicVolume,
    String? musicTheme,
    bool? vibrationEnabled,
    String? selectedTheme,
    String? difficulty,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      musicTheme: musicTheme ?? this.musicTheme,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

/// 游戏统计数据模型
class GameStatistics {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final int winStreak;
  final int maxWinStreak;
  final int totalMoves;
  final int totalCaptures;
  final DateTime? lastPlayedAt;
  final Map<String, int> difficultyWins; // AI难度胜利次数
  final Map<String, double> dailyWinRate; // 每日胜率 (日期字符串 -> 胜率)
  final Map<String, int> hourlyGames; // 每小时游戏数 (小时字符串 -> 游戏数)
  
  const GameStatistics({
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winStreak = 0,
    this.maxWinStreak = 0,
    this.totalMoves = 0,
    this.totalCaptures = 0,
    this.lastPlayedAt,
    this.difficultyWins = const {},
    this.dailyWinRate = const {},
    this.hourlyGames = const {},
  });
  
  double get winRate => totalGames > 0 ? wins / totalGames : 0.0;
  
  Map<String, dynamic> toJson() => {
    'totalGames': totalGames,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'winStreak': winStreak,
    'maxWinStreak': maxWinStreak,
    'totalMoves': totalMoves,
    'totalCaptures': totalCaptures,
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    'difficultyWins': difficultyWins,
    'dailyWinRate': dailyWinRate,
    'hourlyGames': hourlyGames,
  };
  
  factory GameStatistics.fromJson(Map<String, dynamic> json) {
    return GameStatistics(
      totalGames: json['totalGames'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      winStreak: json['winStreak'] ?? 0,
      maxWinStreak: json['maxWinStreak'] ?? 0,
      totalMoves: json['totalMoves'] ?? 0,
      totalCaptures: json['totalCaptures'] ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null 
          ? DateTime.parse(json['lastPlayedAt']) 
          : null,
      difficultyWins: Map<String, int>.from(json['difficultyWins'] ?? {}),
      dailyWinRate: Map<String, double>.from(json['dailyWinRate'] ?? {}),
      hourlyGames: Map<String, int>.from(json['hourlyGames'] ?? {}),
    );
  }
  
  GameStatistics copyWith({
    int? totalGames,
    int? wins,
    int? losses,
    int? draws,
    int? winStreak,
    int? maxWinStreak,
    int? totalMoves,
    int? totalCaptures,
    DateTime? lastPlayedAt,
    Map<String, int>? difficultyWins,
    Map<String, double>? dailyWinRate,
    Map<String, int>? hourlyGames,
  }) {
    return GameStatistics(
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winStreak: winStreak ?? this.winStreak,
      maxWinStreak: maxWinStreak ?? this.maxWinStreak,
      totalMoves: totalMoves ?? this.totalMoves,
      totalCaptures: totalCaptures ?? this.totalCaptures,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      difficultyWins: difficultyWins ?? this.difficultyWins,
      dailyWinRate: dailyWinRate ?? this.dailyWinRate,
      hourlyGames: hourlyGames ?? this.hourlyGames,
    );
  }
}

/// 存储服务 - 单例模式
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  SharedPreferences? _prefs;
  Box? _statisticsBox;
  Box? _gameSaveBox;
  
  // 存储键
  static const String _keySettings = 'game_settings';
  static const String _keyStatistics = 'game_statistics';
  static const String _keyGameSave = 'current_game_save';
  static const String _boxNameStatistics = 'statistics';
  static const String _boxNameGameSave = 'game_save';
  
  /// 初始化存储服务
  Future<void> initialize() async {
    // 初始化 SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // 初始化 Hive
    await Hive.initFlutter();
    _statisticsBox = await Hive.openBox(_boxNameStatistics);
    _gameSaveBox = await Hive.openBox(_boxNameGameSave);
  }
  
  /// 保存游戏设置
  Future<bool> saveSettings(GameSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      return await _prefs!.setString(_keySettings, json);
    } catch (e) {
      print('保存设置失败: $e');
      return false;
    }
  }
  
  /// 加载游戏设置
  Future<GameSettings> loadSettings() async {
    try {
      final json = _prefs!.getString(_keySettings);
      if (json == null) {
        return const GameSettings();
      }
      final map = jsonDecode(json) as Map<String, dynamic>;
      return GameSettings.fromJson(map);
    } catch (e) {
      print('加载设置失败: $e');
      return const GameSettings();
    }
  }
  
  /// 保存游戏统计
  Future<bool> saveStatistics(GameStatistics statistics) async {
    try {
      await _statisticsBox!.put(_keyStatistics, statistics.toJson());
      return true;
    } catch (e) {
      print('保存统计数据失败: $e');
      return false;
    }
  }
  
  /// 加载游戏统计
  Future<GameStatistics> loadStatistics() async {
    try {
      final json = _statisticsBox!.get(_keyStatistics);
      if (json == null) {
        return const GameStatistics();
      }
      return GameStatistics.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      print('加载统计数据失败: $e');
      return const GameStatistics();
    }
  }
  
  /// 更新统计数据（游戏结束后调用）
  Future<bool> updateStatistics({
    required bool isWin,
    required bool isLoss,
    required bool isDraw,
    required int moves,
    required int captures,
    String? difficulty,
  }) async {
    try {
      final current = await loadStatistics();
      
      final newWinStreak = isWin ? current.winStreak + 1 : 0;
      final newMaxWinStreak = newWinStreak > current.maxWinStreak 
          ? newWinStreak 
          : current.maxWinStreak;
      
      final newDifficultyWins = Map<String, int>.from(current.difficultyWins);
      if (isWin && difficulty != null) {
        newDifficultyWins[difficulty] = (newDifficultyWins[difficulty] ?? 0) + 1;
      }
      
      final updated = current.copyWith(
        totalGames: current.totalGames + 1,
        wins: isWin ? current.wins + 1 : current.wins,
        losses: isLoss ? current.losses + 1 : current.losses,
        draws: isDraw ? current.draws + 1 : current.draws,
        winStreak: newWinStreak,
        maxWinStreak: newMaxWinStreak,
        totalMoves: current.totalMoves + moves,
        totalCaptures: current.totalCaptures + captures,
        lastPlayedAt: DateTime.now(),
        difficultyWins: newDifficultyWins,
      );
      
      return await saveStatistics(updated);
    } catch (e) {
      print('更新统计数据失败: $e');
      return false;
    }
  }
  
  /// 重置统计数据
  Future<bool> resetStatistics() async {
    try {
      await _statisticsBox!.delete(_keyStatistics);
      return true;
    } catch (e) {
      print('重置统计数据失败: $e');
      return false;
    }
  }
  
  /// 重置所有数据（包括设置）
  Future<bool> resetAll() async {
    try {
      await _prefs!.clear();
      await _statisticsBox!.clear();
      return true;
    } catch (e) {
      print('重置所有数据失败: $e');
      return false;
    }
  }
  
  /// 清理资源
  Future<void> dispose() async {
    await _statisticsBox?.close();
    await _gameSaveBox?.close();
  }
  
  /// 保存游戏状态
  Future<bool> saveGame(GameSave gameSave) async {
    try {
      await _gameSaveBox!.put(_keyGameSave, gameSave.toJson());
      return true;
    } catch (e) {
      print('保存游戏失败: $e');
      return false;
    }
  }
  
  /// 加载游戏状态
  Future<GameSave?> loadGame() async {
    try {
      final json = _gameSaveBox!.get(_keyGameSave);
      if (json == null) {
        return null;
      }
      return GameSave.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      print('加载游戏失败: $e');
      return null;
    }
  }
  
  /// 删除游戏存档
  Future<bool> deleteGameSave() async {
    try {
      await _gameSaveBox!.delete(_keyGameSave);
      return true;
    } catch (e) {
      print('删除游戏存档失败: $e');
      return false;
    }
  }
  
  /// 检查是否有存档
  Future<bool> hasSavedGame() async {
    try {
      return _gameSaveBox!.containsKey(_keyGameSave);
    } catch (e) {
      return false;
    }
  }
}
