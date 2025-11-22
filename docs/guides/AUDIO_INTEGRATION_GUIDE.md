# 音频资源集成指南

## 概述

本指南详细说明如何为四子游戏准备和集成音频资源文件（音效和背景音乐）。

## 目录结构

```
assets/
└── sounds/
    ├── README.md              # 音效资源说明
    ├── select.mp3             # 选中棋子音效 (待添加)
    ├── move.mp3               # 移动棋子音效 (待添加)
    ├── capture.mp3            # 吃子音效 (待添加)
    ├── win.mp3                # 获胜音效 (待添加)
    ├── lose.mp3               # 失败音效 (待添加)
    ├── click.mp3              # 按钮点击音效 (待添加)
    └── music/
        ├── README.md          # 背景音乐说明
        ├── main.mp3           # 主菜单音乐 (待添加)
        ├── gameplay.mp3       # 游戏进行音乐 (待添加)
        ├── victory.mp3        # 胜利音乐 (待添加)
        ├── classic.mp3        # 经典主题音乐 (待添加)
        ├── night.mp3          # 夜间主题音乐 (待添加)
        └── relaxing.mp3       # 轻松主题音乐 (待添加)
```

## 快速开始（3步完成）

### 第1步：获取音频文件

有三种方式获取音频文件：

#### 方式A：使用免费音频库（推荐）

**音效资源：**
1. 访问 [Freesound.org](https://freesound.org/)
2. 搜索关键词：
   - `ui click` → select.mp3, click.mp3
   - `slide` → move.mp3
   - `impact` → capture.mp3
   - `success` → win.mp3
   - `fail` → lose.mp3
3. 下载并重命名为对应文件名

**音乐资源：**
1. 访问 [Incompetech](https://incompetech.com/music/)
2. 选择合适的游戏音乐：
   - 类型：Royalty-Free Music
   - 标签：Game, Menu, Background
3. 下载并重命名为对应文件名

#### 方式B：使用在线音效生成工具

1. 访问 [BFXR](https://www.bfxr.net/)
2. 选择预设或自定义参数
3. 生成并导出为MP3格式
4. 适合制作简单的游戏音效

#### 方式C：使用AI音乐生成（音乐）

1. 访问 [Soundraw.io](https://soundraw.io/) 或 [AIVA](https://www.aiva.ai/)
2. 设置参数：
   - 风格：游戏、轻音乐
   - 时长：2-3分钟
   - 节奏：根据主题选择
3. 生成并下载

### 第2步：音频处理（可选但推荐）

使用 [Audacity](https://www.audacityteam.org/)（免费软件）处理音频：

#### 音效处理流程
```
1. 打开音频文件
2. 效果 → 音量标准化 → 设置为 -3dB
3. 如需裁剪：选择区域 → Ctrl+T（裁剪）
4. 淡入淡出：选择开头/结尾 → 效果 → 淡入/淡出
5. 文件 → 导出 → 导出为MP3 → 比特率128kbps
```

#### 音乐处理流程
```
1. 打开音频文件
2. 效果 → 音量标准化 → 设置为 -6dB（音乐音量稍低）
3. 制作循环（针对循环音乐）：
   - 找到循环点（通常是完整小节）
   - 编辑 → 查找零交叉点
   - 应用淡入淡出确保平滑过渡
4. 文件 → 导出 → 导出为MP3 → 比特率128-192kbps
```

### 第3步：集成到项目

1. 将处理好的音频文件放到对应目录：
   ```bash
   # 音效文件放在
   assets/sounds/
   
   # 音乐文件放在
   assets/sounds/music/
   ```

2. 确认文件命名正确（严格区分大小写）

3. 运行Flutter命令更新资源：
   ```bash
   flutter clean
   flutter pub get
   ```

4. 测试音频播放（在SettingsPage或编写测试代码）

## 详细规格要求

### 音效文件规格

| 文件名 | 用途 | 时长 | 特征 | 推荐音量 |
|--------|------|------|------|---------|
| select.mp3 | 选中棋子 | 0.1-0.2s | 轻快点击音 | -3dB |
| move.mp3 | 移动棋子 | 0.2-0.3s | 滑动过渡音 | -3dB |
| capture.mp3 | 吃子 | 0.3-0.5s | 清脆打击音 | -1dB |
| win.mp3 | 获胜 | 1-2s | 欢快胜利音 | 0dB |
| lose.mp3 | 失败 | 1-2s | 低沉遗憾音 | -3dB |
| click.mp3 | UI点击 | 0.1s | 简短点击音 | -6dB |

### 音乐文件规格

| 文件名 | 用途 | 时长 | 循环 | 风格 | 推荐音量 |
|--------|------|------|------|------|---------|
| main.mp3 | 主菜单 | 2-3min | 是 | 轻松愉快 | -6dB |
| gameplay.mp3 | 游戏中 | 2-3min | 是 | 专注平静 | -9dB |
| victory.mp3 | 胜利 | 30-60s | 否 | 欢快激昂 | -3dB |
| classic.mp3 | 经典主题 | 2-3min | 是 | 古典优雅 | -6dB |
| night.mp3 | 夜间主题 | 2-3min | 是 | 舒缓宁静 | -9dB |
| relaxing.mp3 | 轻松主题 | 2-3min | 是 | 休闲放松 | -6dB |

### 通用技术规格

- **格式**: MP3
- **采样率**: 44.1kHz
- **比特率**: 128-192kbps
- **声道**: 音效可以是单声道，音乐推荐立体声
- **文件大小**: 
  - 单个音效 < 100KB
  - 单个音乐 < 2MB
  - 总大小 < 15MB

## 测试清单

在集成完成后，请按照以下清单进行测试：

### 音效测试
- [ ] select.mp3 - 在游戏页面点击棋子，听到选中音效
- [ ] move.mp3 - 移动棋子后，听到移动音效
- [ ] capture.mp3 - 吃子时，听到吃子音效
- [ ] win.mp3 - 游戏获胜时，听到胜利音效
- [ ] lose.mp3 - 游戏失败时，听到失败音效
- [ ] click.mp3 - 点击UI按钮，听到点击音效

### 音乐测试
- [ ] main.mp3 - 主菜单页面，自动播放主菜单音乐，可循环
- [ ] gameplay.mp3 - 游戏进行中，播放游戏音乐，可循环
- [ ] victory.mp3 - 游戏结束（胜利），播放胜利音乐
- [ ] classic.mp3 - 在设置页面切换到经典主题，音乐切换成功
- [ ] night.mp3 - 在设置页面切换到夜间主题，音乐切换成功
- [ ] relaxing.mp3 - 在设置页面切换到轻松主题，音乐切换成功

### 功能测试
- [ ] 音效音量控制 - 在设置页面调节音效音量，音量变化正常
- [ ] 音乐音量控制 - 在设置页面调节音乐音量，音量变化正常
- [ ] 音效开关 - 关闭音效后，不再播放音效
- [ ] 音乐开关 - 关闭音乐后，背景音乐停止
- [ ] 音乐切换 - 从菜单进入游戏，音乐平滑切换
- [ ] 音乐循环 - 循环音乐播放完毕后，自动重新开始

## 推荐资源站点汇总

### 音效资源
| 网站 | 链接 | 特点 | 许可 |
|------|------|------|------|
| Freesound | https://freesound.org/ | 海量音效，质量高 | CC协议 |
| ZapSplat | https://www.zapsplat.com/ | 游戏音效丰富 | 免费（需注册） |
| Mixkit | https://mixkit.co/free-sound-effects/ | 无需注册 | 完全免费 |
| OpenGameArt | https://opengameart.org/ | 专注游戏资源 | 多种协议 |

### 音乐资源
| 网站 | 链接 | 特点 | 许可 |
|------|------|------|------|
| Incompetech | https://incompetech.com/music/ | Kevin MacLeod音乐库 | CC BY 3.0 |
| Free Music Archive | https://freemusicarchive.org/ | 风格多样 | CC协议 |
| YouTube Audio Library | https://www.youtube.com/audiolibrary | YouTube官方 | 免费无署名 |
| Bensound | https://www.bensound.com/ | 高质量 | 免费（需署名） |
| Purple Planet | https://www.purple-planet.com/ | 游戏专用 | 免费使用 |

### 工具
| 工具 | 链接 | 用途 |
|------|------|------|
| Audacity | https://www.audacityteam.org/ | 音频编辑 |
| BFXR | https://www.bfxr.net/ | 音效生成 |
| Soundraw | https://soundraw.io/ | AI音乐生成 |
| AIVA | https://www.aiva.ai/ | AI作曲 |

## 版权声明示例

如果使用了需要署名的CC协议音频，请在应用的"关于"或"设置"页面添加鸣谢信息：

```
音频鸣谢：
- 音效来自 Freesound.org
  - [音效名称] by [作者名] (CC BY 3.0)
- 音乐来自 Incompetech
  - [音乐名称] by Kevin MacLeod (CC BY 3.0)
```

## 故障排查

### 问题1：音频无法播放
**可能原因**：
- 文件名拼写错误
- 文件格式不支持
- 文件路径配置错误

**解决方法**：
1. 检查文件名是否完全匹配（区分大小写）
2. 确认文件格式为MP3
3. 运行 `flutter clean` 和 `flutter pub get`
4. 检查控制台是否有错误信息

### 问题2：音频音量过大或过小
**解决方法**：
1. 使用Audacity进行音量标准化
2. 在代码中调整音量（AudioService和MusicService都支持音量控制）

### 问题3：音乐无法循环
**解决方法**：
1. 检查MusicService中的ReleaseMode是否设置为loop
2. 确认音乐文件本身没有损坏

### 问题4：应用包体积过大
**解决方法**：
1. 降低音频比特率（128kbps通常足够）
2. 缩短循环音乐的时长
3. 使用压缩工具进一步压缩MP3文件

## 进阶优化

### 1. 动态音量调整
根据游戏状态自动调整音乐音量：
```dart
// 游戏思考时降低音乐音量
await musicService.setVolume(0.2);

// 正常游戏时恢复音量
await musicService.setVolume(0.4);
```

### 2. 音乐淡入淡出
使用淡入淡出效果使音乐切换更平滑：
```dart
// 淡出当前音乐
await musicService.fadeOut(duration: Duration(seconds: 1));

// 淡入新音乐
await musicService.fadeIn(MusicTheme.gameplay, duration: Duration(seconds: 2));
```

### 3. 根据主题自动切换音乐
在ThemeManager中监听主题变化，自动切换对应音乐：
```dart
// 在theme_manager.dart中
void _onThemeChanged(AppTheme theme) {
  switch (theme) {
    case AppTheme.classic:
      _musicService.switchTheme(MusicTheme.classic);
      break;
    case AppTheme.night:
      _musicService.switchTheme(MusicTheme.night);
      break;
    // ...
  }
}
```

## 下一步

完成音频集成后：
1. [ ] 在GameBloc中实现背景音乐切换逻辑（任务1.3）
2. [ ] 在SettingsPage添加音频测试功能
3. [ ] 编写音频服务的单元测试
4. [ ] 测试在不同平台（Android、iOS、Web）的音频播放

---

**文档版本**: 1.0  
**最后更新**: 2025-10-22  
**维护者**: Qoder AI

如有问题，请参考：
- `assets/sounds/README.md` - 音效详细说明
- `assets/sounds/music/README.md` - 音乐详细说明
- `lib/services/audio_service.dart` - 音效服务实现
- `lib/services/music_service.dart` - 音乐服务实现
