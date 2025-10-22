# 背景音乐资源说明

本目录用于存放游戏背景音乐文件。

## 所需音乐列表

根据设计文档，游戏需要以下6种背景音乐主题：

### 1. main.mp3
- **用途**: 主菜单背景音乐
- **时长**: 2-3分钟
- **循环**: 是
- **风格**: 轻松愉快，欢迎氛围
- **特征**: 旋律优美、节奏舒缓、不过于激烈

### 2. gameplay.mp3
- **用途**: 游戏进行中背景音乐
- **时长**: 2-3分钟
- **循环**: 是
- **风格**: 节奏适中，专注氛围
- **特征**: 有助于思考，不会分散注意力

### 3. victory.mp3
- **用途**: 胜利音乐
- **时长**: 30-60秒
- **循环**: 否
- **风格**: 欢快激昂，庆祝氛围
- **特征**: 旋律上扬、节奏明快、令人愉悦

### 4. classic.mp3
- **用途**: 经典主题音乐
- **时长**: 2-3分钟
- **循环**: 是
- **风格**: 古典、优雅
- **特征**: 类似古典棋类游戏的配乐风格

### 5. night.mp3
- **用途**: 夜间主题音乐
- **时长**: 2-3分钟
- **循环**: 是
- **风格**: 舒缓、宁静
- **特征**: 适合夜间游戏，不会过于刺激

### 6. relaxing.mp3
- **用途**: 轻松主题音乐
- **时长**: 2-3分钟
- **循环**: 是
- **风格**: 轻松、休闲
- **特征**: 放松心情，适合休闲娱乐

## 音乐格式要求

- **格式**: MP3（推荐）
- **采样率**: 44.1kHz
- **比特率**: 128-192kbps（平衡质量和文件大小）
- **声道**: 立体声（Stereo）
- **音量标准化**: 使用音频编辑工具统一音量，避免音量差异过大
- **无缝循环**: 对于循环音乐，确保首尾可以平滑衔接

## 音乐来源建议

### 免费音乐资源网站

1. **Incompetech** - https://incompetech.com/music/
   - Kevin MacLeod的免费音乐库
   - CC BY 3.0协议，需标注作者

2. **Free Music Archive** - https://freemusicarchive.org/
   - 大量免费CC协议音乐
   - 多种风格可选

3. **YouTube Audio Library** - https://www.youtube.com/audiolibrary
   - YouTube官方音频库
   - 免费且无需署名

4. **Bensound** - https://www.bensound.com/
   - 高质量免费音乐
   - 需要标注来源

5. **Purple Planet** - https://www.purple-planet.com/
   - 专注于游戏和视频音乐
   - 免费使用

### AI音乐生成工具

- **Soundraw** - https://soundraw.io/
  - AI生成音乐，可自定义风格
  
- **AIVA** - https://www.aiva.ai/
  - AI作曲工具，适合游戏配乐

### 音乐编辑工具

- **Audacity** - 免费开源音频编辑器
  - 音量标准化
  - 淡入淡出效果
  - 格式转换
  - 循环点制作

- **Ocenaudio** - 简单易用的音频编辑器

## 文件命名规范

音乐文件应严格按照以下命名：
```
main.mp3
gameplay.mp3
victory.mp3
classic.mp3
night.mp3
relaxing.mp3
```

## 音乐路径配置

这些音乐文件需要在 `pubspec.yaml` 中声明：

```yaml
flutter:
  assets:
    - assets/sounds/music/
```

或者单独列出每个文件：

```yaml
flutter:
  assets:
    - assets/sounds/music/main.mp3
    - assets/sounds/music/gameplay.mp3
    - assets/sounds/music/victory.mp3
    - assets/sounds/music/classic.mp3
    - assets/sounds/music/night.mp3
    - assets/sounds/music/relaxing.mp3
```

## 音量控制建议

### 各主题推荐音量
| 主题 | 音量 | 说明 |
|------|------|------|
| main | 0.4 | 主菜单音量适中 |
| gameplay | 0.3 | 游戏中音量较低，不影响思考 |
| victory | 0.5 | 胜利音乐稍大，庆祝氛围 |
| classic | 0.4 | 古典主题音量适中 |
| night | 0.3 | 夜间主题音量偏低 |
| relaxing | 0.35 | 轻松主题音量舒适 |

## 测试音乐

添加音乐后，可以通过以下方式测试：

```dart
import 'package:foursquare/services/music_service.dart';

void testMusicService() async {
  final musicService = MusicService();
  await musicService.initialize();
  
  // 测试各种音乐主题
  await musicService.playMusic(MusicTheme.main);
  await Future.delayed(Duration(seconds: 5));
  
  await musicService.switchTheme(MusicTheme.gameplay);
  await Future.delayed(Duration(seconds: 5));
  
  // 测试淡入淡出
  await musicService.fadeOut();
  await musicService.fadeIn(MusicTheme.victory);
}
```

## 文件大小控制

为了控制应用包大小，建议：
- 单个音乐文件不超过 2MB
- 音乐总大小控制在 10MB 以内
- 使用适当的比特率（128-192kbps已足够）
- 如需要，可以缩短循环音乐的时长到1-2分钟

## 版权声明

使用音乐时请注意：
- 确保音乐符合项目的使用授权
- 如使用CC协议音乐，需要在应用中标注作者信息
- 商业使用请确保获得相应授权
- 建议在应用设置页面添加"音乐鸣谢"部分

## 推荐搜索关键词

在音乐资源网站搜索时，可以使用以下关键词：

- **Main Menu**: "upbeat menu", "casual game menu", "cheerful background"
- **Gameplay**: "puzzle game", "thinking music", "concentration", "ambient game"
- **Victory**: "victory fanfare", "success jingle", "achievement", "win music"
- **Classic**: "classical game", "chess music", "elegant piano"
- **Night**: "calm night", "peaceful ambient", "soft piano", "meditation"
- **Relaxing**: "chill out", "lounge", "easy listening", "smooth jazz"

---

**当前状态**: ⚠️ 音乐文件待添加

请按照上述要求准备音乐文件并放置在本目录中。

## 快速开始指南

1. 从推荐的音乐资源网站下载或生成音乐
2. 使用Audacity等工具编辑音乐（标准化音量、制作循环、格式转换）
3. 按照规范命名文件
4. 放置在本目录（`assets/sounds/music/`）
5. 运行 `flutter pub get` 确保资源配置生效
6. 在游戏中测试音乐播放效果
