/// Music Service - 游戏音乐服务
/// 
/// 职责：
/// - 管理背景音乐播放
/// - 支持多种音乐主题切换
/// - 控制音乐音量
/// - 循环播放控制
library;

import 'package:audioplayers/audioplayers.dart';

/// 音乐主题类型
enum MusicTheme {
  /// 主菜单音乐
  main,
  
  /// 游戏进行中音乐
  gameplay,
  
  /// 胜利音乐
  victory,
  
  /// 经典主题
  classic,
  
  /// 夜间主题
  night,
  
  /// 轻松主题
  relaxing,
}

/// 音乐服务
/// 
/// 负责游戏背景音乐的播放和管理
class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _player = AudioPlayer();
  
  bool _enabled = true;
  double _volume = 0.4;
  MusicTheme? _currentTheme;
  bool _isPlaying = false;

  /// 音乐文件映射
  final Map<MusicTheme, String> _musicFiles = {
    MusicTheme.main: 'sounds/music/main.wav',
    MusicTheme.gameplay: 'sounds/music/gameplay.wav',
    MusicTheme.victory: 'sounds/music/main.wav',  // 暂时复用
    MusicTheme.classic: 'sounds/music/gameplay.wav',  // 暂时复用
    MusicTheme.night: 'sounds/music/gameplay.wav',  // 暂时复用
    MusicTheme.relaxing: 'sounds/music/main.wav',  // 暂时复用
  };

  /// 初始化音乐服务
  Future<void> initialize() async {
    await _player.setVolume(_volume);
    
    // 设置循环播放
    await _player.setReleaseMode(ReleaseMode.loop);
    
    // 监听播放完成事件
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
    });

    // 监听播放状态变化
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// 播放指定主题音乐
  Future<void> playMusic(MusicTheme theme) async {
    if (!_enabled) return;

    // 如果已经在播放相同主题，不需要重新播放
    if (_currentTheme == theme && _isPlaying) {
      return;
    }

    final musicFile = _musicFiles[theme];
    if (musicFile == null) return;

    try {
      // 停止当前播放
      await _player.stop();
      
      // 设置新的音乐源
      await _player.setSource(AssetSource(musicFile));
      
      // 开始播放
      await _player.resume();
      
      _currentTheme = theme;
      _isPlaying = true;
    } catch (e) {
      print('Failed to play music: $musicFile - $e');
      _isPlaying = false;
    }
  }

  /// 停止音乐
  Future<void> stopMusic() async {
    await _player.stop();
    _isPlaying = false;
    _currentTheme = null;
  }

  /// 暂停音乐
  Future<void> pauseMusic() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// 恢复音乐
  Future<void> resumeMusic() async {
    if (_enabled && !_isPlaying) {
      await _player.resume();
      _isPlaying = true;
    }
  }

  /// 切换音乐主题
  Future<void> switchTheme(MusicTheme theme) async {
    await playMusic(theme);
  }

  /// 设置音乐开关
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    
    if (!enabled && _isPlaying) {
      await pauseMusic();
    } else if (enabled && _currentTheme != null) {
      await playMusic(_currentTheme!);
    }
  }

  /// 获取音乐开关状态
  bool isEnabled() => _enabled;

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  /// 获取音量
  double getVolume() => _volume;

  /// 获取当前主题
  MusicTheme? getCurrentTheme() => _currentTheme;

  /// 是否正在播放
  bool isPlaying() => _isPlaying;

  /// 淡入效果播放
  Future<void> fadeIn(MusicTheme theme, {Duration duration = const Duration(seconds: 2)}) async {
    if (!_enabled) return;

    final targetVolume = _volume;
    await _player.setVolume(0);
    await playMusic(theme);

    // 逐渐增加音量
    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = targetVolume / steps;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDuration));
      if (!_isPlaying) break;
      await _player.setVolume(volumeStep * i);
    }
  }

  /// 淡出效果停止
  Future<void> fadeOut({Duration duration = const Duration(seconds: 2)}) async {
    if (!_isPlaying) return;

    final currentVolume = _volume;
    
    // 逐渐减小音量
    const steps = 20;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeStep = currentVolume / steps;

    for (int i = steps - 1; i >= 0; i--) {
      await Future.delayed(Duration(milliseconds: stepDuration));
      await _player.setVolume(volumeStep * i);
    }

    await stopMusic();
    await _player.setVolume(currentVolume);
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
