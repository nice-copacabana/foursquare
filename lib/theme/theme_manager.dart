/// Theme Manager - 主题管理器
/// 
/// 职责：
/// - 管理应用主题
/// - 提供多种预设主题
/// - 支持自定义主题配置
/// - 管理棋盘主题
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/board_theme.dart';
import '../constants/theme_presets.dart';

/// 主题类型枚举
enum AppThemeType {
  /// 默认主题
  defaultTheme,
  
  /// 经典主题
  classic,
  
  /// 夜间主题
  night,
  
  /// 彩色主题
  colorful,
}

/// 棋盘颜色配置
class BoardColors {
  final Color lightSquare;
  final Color darkSquare;
  final Color border;
  
  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.border,
  });
}

/// 棋子颜色配置
class PieceColors {
  final Color black;
  final Color white;
  final Color blackBorder;
  final Color whiteBorder;
  final Color selected;
  final Color validMove;
  
  const PieceColors({
    required this.black,
    required this.white,
    required this.blackBorder,
    required this.whiteBorder,
    required this.selected,
    required this.validMove,
  });
}

/// 游戏主题配置
class GameTheme {
  final String name;
  final ThemeData materialTheme;
  final BoardColors boardColors;
  final PieceColors pieceColors;
  final Color backgroundColor;
  
  const GameTheme({
    required this.name,
    required this.materialTheme,
    required this.boardColors,
    required this.pieceColors,
    required this.backgroundColor,
  });
}

/// 主题管理器
class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  SharedPreferences? _prefs;
  BoardTheme _currentBoardTheme = ThemePresets.defaultTheme;
  final _themeController = StreamController<BoardTheme>.broadcast();

  static const String _keyBoardTheme = 'board_theme_id';

  /// 主题变化流
  Stream<BoardTheme> get themeStream => _themeController.stream;

  /// 当前棋盘主题
  BoardTheme get currentBoardTheme => _currentBoardTheme;

  /// 初始化主题管理器
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBoardTheme();
  }

  /// 加载棋盘主题
  Future<void> _loadBoardTheme() async {
    try {
      final themeId = _prefs?.getString(_keyBoardTheme);
      if (themeId != null) {
        final theme = ThemePresets.getById(themeId);
        if (theme != null) {
          _currentBoardTheme = theme;
        }
      }
    } catch (e) {
      print('加载棋盘主题失败: $e');
    }
  }

  /// 切换棋盘主题
  Future<void> setBoardTheme(BoardTheme theme) async {
    _currentBoardTheme = theme;
    _themeController.add(theme);
    await _prefs?.setString(_keyBoardTheme, theme.id);
  }

  /// 根据ID切换主题
  Future<void> setBoardThemeById(String themeId) async {
    final theme = ThemePresets.getById(themeId);
    if (theme != null) {
      await setBoardTheme(theme);
    }
  }

  /// 获取所有可用棋盘主题
  List<BoardTheme> getAllBoardThemes() {
    return ThemePresets.all;
  }

  /// 释放资源
  void dispose() {
    _themeController.close();
  }

  /// 获取默认主题
  static GameTheme get defaultTheme => GameTheme(
    name: '默认',
    materialTheme: ThemeData(
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    boardColors: const BoardColors(
      lightSquare: Color(0xFFF0D9B5),
      darkSquare: Color(0xFFB58863),
      border: Color(0xFF8B4513),
    ),
    pieceColors: const PieceColors(
      black: Color(0xFF2C2C2C),
      white: Color(0xFFFAFAFA),
      blackBorder: Color(0xFF000000),
      whiteBorder: Color(0xFF999999),
      selected: Color(0xFF90CAF9),
      validMove: Color(0xFF66BB6A),
    ),
    backgroundColor: Colors.grey.shade50,
  );

  /// 获取经典主题
  static GameTheme get classicTheme => GameTheme(
    name: '经典',
    materialTheme: ThemeData(
      primarySwatch: Colors.brown,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    boardColors: const BoardColors(
      lightSquare: Color(0xFFE8D5C4),
      darkSquare: Color(0xFF9E7B5C),
      border: Color(0xFF6B4423),
    ),
    pieceColors: const PieceColors(
      black: Color(0xFF1A1A1A),
      white: Color(0xFFF5F5F5),
      blackBorder: Color(0xFF000000),
      whiteBorder: Color(0xFFAAAAAA),
      selected: Color(0xFFFFCA28),
      validMove: Color(0xFF81C784),
    ),
    backgroundColor: const Color(0xFFF5EBE0),
  );

  /// 获取夜间主题
  static GameTheme get nightTheme => GameTheme(
    name: '夜间',
    materialTheme: ThemeData(
      primarySwatch: Colors.indigo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    boardColors: const BoardColors(
      lightSquare: Color(0xFF3A4A5C),
      darkSquare: Color(0xFF1E2A38),
      border: Color(0xFF0D1621),
    ),
    pieceColors: const PieceColors(
      black: Color(0xFF0A0A0A),
      white: Color(0xFFE0E0E0),
      blackBorder: Color(0xFF000000),
      whiteBorder: Color(0xFF666666),
      selected: Color(0xFF7986CB),
      validMove: Color(0xFF4CAF50),
    ),
    backgroundColor: const Color(0xFF121212),
  );

  /// 获取彩色主题
  static GameTheme get colorfulTheme => GameTheme(
    name: '彩色',
    materialTheme: ThemeData(
      primarySwatch: Colors.purple,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    ),
    boardColors: const BoardColors(
      lightSquare: Color(0xFFFFE4E1),
      darkSquare: Color(0xFFFF69B4),
      border: Color(0xFFFF1493),
    ),
    pieceColors: const PieceColors(
      black: Color(0xFF4A148C),
      white: Color(0xFFFFF9C4),
      blackBorder: Color(0xFF311B92),
      whiteBorder: Color(0xFFFBC02D),
      selected: Color(0xFFBA68C8),
      validMove: Color(0xFF26C6DA),
    ),
    backgroundColor: const Color(0xFFFCE4EC),
  );

  /// 根据类型获取主题
  static GameTheme getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.defaultTheme:
        return defaultTheme;
      case AppThemeType.classic:
        return classicTheme;
      case AppThemeType.night:
        return nightTheme;
      case AppThemeType.colorful:
        return colorfulTheme;
    }
  }

  /// 根据名称获取主题类型
  static AppThemeType getThemeTypeByName(String name) {
    switch (name) {
      case 'classic':
        return AppThemeType.classic;
      case 'night':
        return AppThemeType.night;
      case 'colorful':
        return AppThemeType.colorful;
      default:
        return AppThemeType.defaultTheme;
    }
  }

  /// 获取所有可用主题
  static Map<AppThemeType, GameTheme> getAllThemes() {
    return {
      AppThemeType.defaultTheme: defaultTheme,
      AppThemeType.classic: classicTheme,
      AppThemeType.night: nightTheme,
      AppThemeType.colorful: colorfulTheme,
    };
  }

  /// 获取主题名称列表
  static List<String> getThemeNames() {
    return ['default', 'classic', 'night', 'colorful'];
  }

  /// 获取主题显示名称映射
  static Map<String, String> getThemeDisplayNames() {
    return {
      'default': '默认',
      'classic': '经典',
      'night': '夜间',
      'colorful': '彩色',
    };
  }
}
