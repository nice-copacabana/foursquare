# 四子游戏 (Four Square Chess)

一个基于Flutter开发的跨平台四子棋类游戏，支持双人对战和人机对战模式。

## 项目概述

四子游戏是一款策略性棋类游戏，在4×4的棋盘上进行。游戏目标是通过移动棋子形成特定的三子连线来吃掉对方的棋子，最终吃掉对方所有棋子或使对方无子可走获得胜利。

### 核心特性

- 🎮 **双人对战模式** - 本地双人对战
- 🤖 **人机对战模式** - 三种AI难度（简单/中等/困难）
- 📊 **完整统计系统** - 胜率、连胜记录、难度战绩、图表分析
- ⚙️ **灵活设置系统** - 音效、音乐、震动、主题等可自定义
- 🎬 **游戏回放功能** - 完整的历史记录回放和步骤导航
- 🎵 **背景音乐系统** - 5种音乐主题可选
- 🎨 **多主题皮肤** - 4种预设主题（默认/经典/夜间/彩色）
- 🎬 **流畅动画效果** - 移动动画、吃子动画
- 💾 **游戏保存/加载** - 支持中途保存和继续游戏
- 📱 **跨平台支持** - Android、iOS、Web

## 技术栈

### 核心框架
- **Flutter** ^3.0.0 - UI框架
- **Dart** ^3.0.0 - 编程语言

### 状态管理
- **flutter_bloc** ^8.1.3 - BLoC模式状态管理
- **equatable** ^2.0.5 - 值对象相等性比较

### 数据持久化
- **hive** ^2.2.3 - 轻量级NoSQL数据库
- **hive_flutter** ^1.1.0 - Hive Flutter集成
- **shared_preferences** ^2.2.2 - 简单键值存储

### 音频系统
- **audioplayers** ^5.2.1 - 音效播放

### UI增强
- **flutter_animate** ^4.3.0 - 动画效果
- **fl_chart** ^0.66.0 - 图表绘制

## 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android设备/模拟器（Android 5.0+）或 iOS设备/模拟器（iOS 11.0+）

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/yourusername/foursquare.git
   cd foursquare
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行项目**
   ```bash
   # 运行在连接的设备上
   flutter run
   
   # 运行在Chrome浏览器（Web）
   flutter run -d chrome
   
   # 运行在指定设备
   flutter devices
   flutter run -d [device_id]
   ```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 游戏规则

### 基本规则

1. **棋盘**: 4×4网格，共16个位置
2. **棋子**: 黑方和白方各4个棋子
3. **先手**: 黑方先走
4. **移动**: 只能移动到上下左右相邻的空位（不可斜向）

### 移动规则

✅ **合法移动**:
- 移动到上下左右相邻的空位

❌ **非法移动**:
- 移动到非相邻位置
- 移动到已有棋子的位置
- 斜向移动

### 吃子规则

**核心规则**: 当移动后形成"己-己-敌"三子连线时（横向或纵向），可以吃掉最远端的敌方棋子。

**重要提示**:
- 移动的棋子必须参与形成三子连线
- 只能吃掉最远端的敌方棋子
- 斜向的三子连线不能吃子

### 胜负判定

**获胜条件**:
- 吃掉对方所有棋子
- 对方无子可走

**平局条件**:
- 双方都无法吃子且重复移动50步

## 项目结构

```
foursquare/
├── lib/
│   ├── ai/                 # AI系统
│   │   ├── ai_player.dart
│   │   ├── minimax_ai.dart
│   │   └── evaluation.dart
│   ├── bloc/               # 状态管理
│   │   ├── game_bloc.dart
│   │   ├── game_event.dart
│   │   └── game_state.dart
│   ├── engine/             # 游戏引擎
│   │   ├── game_engine.dart
│   │   ├── move_validator.dart
│   │   └── capture_detector.dart
│   ├── models/             # 数据模型
│   │   ├── board_state.dart
│   │   ├── position.dart
│   │   ├── piece_type.dart
│   │   ├── move.dart
│   │   ├── game_result.dart
│   │   └── game_save.dart
│   ├── services/           # 服务层
│   │   ├── audio_service.dart
│   │   └── storage_service.dart
│   ├── ui/                 # UI层
│   │   ├── screens/        # 页面
│   │   │   ├── home_page.dart
│   │   │   ├── game_page.dart
│   │   │   ├── statistics_page.dart
│   │   │   ├── rules_page.dart
│   │   │   └── settings_page.dart
│   │   └── widgets/        # 组件
│   │       ├── board_widget.dart
│   │       ├── animated_board_widget.dart
│   │       ├── board_painter.dart
│   │       ├── game_info_panel.dart
│   │       └── game_over_dialog.dart
│   └── main.dart           # 入口文件
├── test/                   # 单元测试
├── assets/                 # 资源文件
│   ├── images/
│   └── sounds/
├── docs/                   # 文档
├── pubspec.yaml
└── README.md
```

## 功能特性

### 已实现功能

#### 游戏核心
- ✅ 双人对战模式
- ✅ 人机对战模式（3个难度级别）
- ✅ 完整的游戏规则实现
- ✅ 移动验证和吃子检测
- ✅ 胜负判定
- ✅ 撤销功能

#### UI/UX
- ✅ 主菜单页面
- ✅ 游戏页面
- ✅ 统计页面
- ✅ 规则页面
- ✅ 设置页面
- ✅ 流畅的移动动画
- ✅ 吃子动画效果
- ✅ 震动反馈

#### 数据系统
- ✅ 游戏统计数据收集
- ✅ 本地数据持久化
- ✅ 游戏保存/加载
- ✅ 设置保存

#### 高级功能 (v0.2.0)
- ✅ **游戏回放系统**
  - 完整的历史记录回放
  - 步骤导航控制(前进/后退/跳转)
  - 可视化移动历史列表
  - 回放进度滑块

- ✅ **背景音乐系统**
  - 5种音乐主题(主菜单/游戏中/经典/夜间/轻松)
  - 音乐音量控制
  - 淡入淡出效果
  - 循环播放支持

- ✅ **多主题皮肤系统**
  - 4种预设主题(默认/经典/夜间/彩色)
  - 棋盘颜色配置
  - 棋子颜色配置
  - Material Design 3 支持

- ✅ **增强统计分析**
  - 胜率趋势图(折线图)
  - 游戏时间分布图(柱状图)
  - 难度战绩饼图
  - 每日胜率跟踪
  - 每小时游戏数统计

#### 性能优化
- ✅ RepaintBoundary 优化渲染
- ✅ CustomPainter 棋盘绘制
- ✅ 60fps 动画效果
- ✅ 响应式布局
- ✅ 游戏统计（胜率、连胜、难度战绩等）
- ✅ 游戏保存/加载
- ✅ 设置持久化
- ✅ 移动历史记录

#### AI系统
- ✅ 基础AI（规则AI）
- ✅ Minimax算法AI
- ✅ Alpha-Beta剪枝优化
- ✅ 三个难度级别

## 开发文档

### 架构设计

项目采用BLoC架构模式，清晰分离UI层和业务逻辑层：

```
UI层 (Widgets)
    ↓ Events
BLoC层 (GameBloc)
    ↓ Business Logic
Engine层 (GameEngine)
    ↓ Data
Model层 (Models)
```

### 文档导航

- [📚 项目文档导航](docs/项目文档导航.md) - 所有文档的总入口
- [📄 历史报告](docs/reports/README.md) - 项目开发历史报告
- [📝 实施计划](IMPLEMENTATION_PLAN.md) - 当前开发计划
- [📑 变更日志](CHANGELOG.md) - 项目版本变更记录

### 核心模块

#### GameEngine (游戏引擎)
- 负责游戏核心逻辑执行
- 移动验证、吃子检测、胜负判定
- 提供AI模拟接口

#### GameBloc (状态管理)
- 处理所有游戏事件
- 管理游戏状态转换
- 协调各个服务

#### AI系统
- `AIPlayer`: AI接口定义
- `MinimaxAI`: Minimax算法实现
- `BoardEvaluator`: 局面评估

#### 数据持久化
- `StorageService`: 统一存储接口
- `GameStatistics`: 统计数据模型
- `GameSave`: 游戏存档模型

### 代码规范

- ✅ 遵循Dart/Flutter代码规范
- ✅ 使用BLoC模式进行状态管理
- ✅ 完整的文档注释
- ✅ 模块化组件设计
- ✅ Qoder AI署名规范

## 测试

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行指定测试文件
flutter test test/bloc/game_bloc_test.dart

# 生成代码覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 测试覆盖

- 单元测试: Models, Engine, BLoC
- Widget测试: UI组件
- 集成测试: 完整游戏流程

## 性能优化

- ✅ 使用RepaintBoundary隔离动画区域
- ✅ 优化棋盘绘制性能
- ✅ AI算法Alpha-Beta剪枝
- ✅ 懒加载和按需渲染

## 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 版本历史

### v0.1.0 (2025-10-22)
- ✨ 初始版本发布
- ✨ 实现核心游戏功能
- ✨ 支持双人和人机对战
- ✨ 完整的UI/UX系统
- ✨ 统计和设置功能

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 致谢

- Flutter团队提供的优秀跨平台框架
- BLoC库提供的状态管理方案
- 所有开源贡献者

## 联系方式

- 项目主页: [https://github.com/yourusername/foursquare](https://github.com/yourusername/foursquare)
- 问题反馈: [Issues](https://github.com/yourusername/foursquare/issues)
- 作者: Qoder AI

---

**开发工具**: Flutter + Qoder AI  
**开发模式**: 1人+AI全栈开发  
**技术亮点**: BLoC架构 + Minimax AI + 流畅动画  

Made with ❤️ using Flutter
