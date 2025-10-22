# 应用图标资源目录

本目录用于存放应用图标相关资源文件。

## 需要的资源文件

### 主图标
- **app_icon.png** (1024x1024 PNG)
  - 用途：生成所有平台的应用图标
  - 要求：无圆角、无透明背景、24位RGB颜色
  - 状态：❌ 待创建

### Android自适应图标
- **adaptive_foreground.png** (432x432 PNG)
  - 用途：Android自适应图标前景层
  - 要求：支持透明背景、安全区域中心288x288
  - 状态：❌ 待创建

## 生成图标

创建好资源文件后，运行以下命令生成各平台图标：

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 设计规范

详细设计规范请参考：[DESIGN_SPEC.md](./DESIGN_SPEC.md)

**配色方案**:
- 主色：#1976D2（蓝色）
- 黑色棋子：#212121
- 白色棋子：#FAFAFA

**设计元素**:
- 4x4棋盘网格
- 黑白棋子各4个
- 简约扁平化风格
