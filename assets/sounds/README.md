# 音效资源说明

本目录用于存放游戏音效文件。

## 所需音效列表

根据 `SoundType` 枚举定义，游戏需要以下6种音效：

### 1. select.mp3
- **用途**: 选中棋子时播放
- **时长**: 0.1-0.2秒
- **特征**: 轻快的点击音，音调稍高
- **参考**: 按钮点击音、轻敲木块音

### 2. move.mp3
- **用途**: 移动棋子时播放
- **时长**: 0.2-0.3秒
- **特征**: 滑动音，表示棋子移动
- **参考**: 棋子滑动音、平滑过渡音

### 3. capture.mp3
- **用途**: 吃子时播放
- **时长**: 0.3-0.5秒
- **特征**: 响亮清脆，表示成功吃子
- **参考**: 得分音、碰撞音、清脆的打击音

### 4. win.mp3
- **用途**: 获胜时播放
- **时长**: 1-2秒
- **特征**: 欢快的胜利音效，令人愉悦
- **参考**: 胜利号角、成就解锁音、欢呼声

### 5. lose.mp3
- **用途**: 失败时播放
- **时长**: 1-2秒
- **特征**: 低沉的失败音效，但不过于消极
- **参考**: 遗憾音、叹息音

### 6. click.mp3
- **用途**: 界面按钮点击时播放
- **时长**: 0.1秒
- **特征**: 简短的点击音
- **参考**: UI按钮音、轻触音

## 音效格式要求

- **格式**: MP3（推荐）或 WAV
- **采样率**: 44.1kHz
- **比特率**: 128kbps（MP3）
- **声道**: 单声道（Mono）或立体声（Stereo）
- **音量**: 归一化处理，避免音量过大或过小

## 音效来源建议

### 免费音效资源网站
1. **Freesound.org** - https://freesound.org/
   - 需要注册，有大量免费CC协议音效
   
2. **ZapSplat** - https://www.zapsplat.com/
   - 免费使用，有大量游戏音效
   
3. **Mixkit** - https://mixkit.co/free-sound-effects/
   - 完全免费，无需注册

4. **OpenGameArt** - https://opengameart.org/
   - 专注于游戏资源，包含音效

### 自制音效工具
- **BFXR** - https://www.bfxr.net/
  - 在线工具，适合制作8-bit风格游戏音效
  
- **ChipTone** - https://sfbgames.itch.io/chiptone
  - 复古游戏音效生成器

## 文件命名规范

音效文件应严格按照以下命名：
```
select.mp3
move.mp3
capture.mp3
win.mp3
lose.mp3
click.mp3
```

## 音效路径配置

这些音效文件需要在 `pubspec.yaml` 中声明：

```yaml
flutter:
  assets:
    - assets/sounds/select.mp3
    - assets/sounds/move.mp3
    - assets/sounds/capture.mp3
    - assets/sounds/win.mp3
    - assets/sounds/lose.mp3
    - assets/sounds/click.mp3
```

## 测试音效

添加音效后，可以通过以下方式测试：

```dart
import 'package:foursquare/services/audio_service.dart';

void testAudioService() async {
  final audioService = AudioService();
  await audioService.initialize();
  
  // 测试各种音效
  audioService.playSound(SoundType.select);
  await Future.delayed(Duration(seconds: 1));
  
  audioService.playSound(SoundType.move);
  await Future.delayed(Duration(seconds: 1));
  
  audioService.playSound(SoundType.capture);
  // ... 依此类推
}
```

## 版权声明

使用音效时请注意：
- 确保音效符合项目的使用授权
- 如使用CC协议音效，需要标注作者信息
- 商业使用请确保获得相应授权

---

**当前状态**: ⚠️ 音效文件待添加

请按照上述要求准备音效文件并放置在本目录中。
