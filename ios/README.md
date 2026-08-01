# iOS Phase 2 工程说明

本目录由项目锁定的 Flutter 3.35.6 生成，最低支持 iOS 13。当前
`com.qoder.foursquare` 仅为开发 Bundle ID；Xcode 的 Release 构建阶段会执行
`scripts/verify_release_configuration.sh`，在永久 Bundle ID 未替换前中止构建。

LAN 使用 iOS 本地网络权限和 `_foursquare._tcp` Bonjour 服务。Phase 2 不声明
麦克风或语音识别权限。`GeneratedPluginRegistrant` 由 `flutter pub get` 生成，当前
依赖图已包含 `nsd_ios` 与 `sentry_flutter`。

`Runner/{zh,en,ja}.lproj/InfoPlist.strings` 覆盖系统显示名称和本地网络权限说明。
正式品牌名称确认前，三种语言均保留开发显示名 `Foursquare`。

## macOS 验证门禁

Windows 可以生成和静态检查工程，但不能运行 Xcode、CocoaPods、iOS 模拟器或
签名归档。因此本工程在合并后仍不代表 iOS 可发布；必须在 macOS 上完成：

1. `flutter pub get`
2. `flutter build ios --debug --no-codesign`
3. 用 Xcode 打开 `Runner.xcworkspace`，确认插件集成和 iOS 13 真机启动
4. 替换永久 Bundle ID，配置 Apple Developer Team、签名和 Provisioning Profile
5. 执行 Release Archive、上传 dSYM，并完成 iPhone/iPad 与双设备 LAN 验证
