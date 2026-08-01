# 四子游戏发布门禁清单

> 状态：当前权威发布清单
> 产品决策确认日期：2026-08-01
> 官方要求最后核验日期：2026-08-01
> 使用方式：每个版本从本清单复制一份发布记录，填写 commit、构建环境、测试证据、产物哈希和审批结果。未勾选硬门禁时不得宣称可正式发布。

## 1. 通用门禁

### 1.1 范围与真实性

- [ ] 发布功能严格属于当前阶段，没有提前暴露后续阶段入口。
- [ ] 应用内规则、教程、商店描述、截图和实际代码行为一致。
- [ ] README、路线图、变更日志和发布说明没有无证据的“100%完成”、覆盖率或性能数据。
- [ ] `CHANGELOG.md` 只记录真实发布版本和可复现的验证结果。
- [ ] 已记录本次发布 commit，工作树不包含未知或无关改动。

### 1.2 质量证据

- [ ] `flutter analyze` 无 error；剩余 warning/info 已审阅并记录。
- [ ] Dart/Flutter 单元和 Widget 测试全部通过。
- [ ] 当前阶段集成测试全部通过。
- [ ] 规则契约测试覆盖所有合法、非法、双向吃子和终局优先级。
- [ ] 存档迁移、进程终止恢复和回放一致性测试通过。
- [ ] 无障碍、字号、横竖屏和减少动态效果验证通过。
- [ ] 依赖许可证、字体、图标、音频和图片的商业使用授权可追溯。
- [ ] 发布产物、符号文件和构建日志已归档，产物 SHA-256 已记录。

### 1.3 隐私与诊断

- [ ] Sentry 仅用于匿名崩溃和性能诊断，默认开启，设置中可以关闭。
- [ ] `sendDefaultPii` 等价能力关闭，发送前过滤敏感字段和棋局内容。
- [ ] 不接入行为分析、广告标识、广告 SDK、用户画像或应用内购买。
- [ ] 隐私政策、应用内说明、Google Play Data Safety 和 App Store App Privacy 与最终 SDK 清单一致。
- [ ] 已启用环境的诊断事件使用独立 environment；Phase 1/2 只有 development、production，Phase 3 再加入 staging。
- [ ] Sentry 符号上传凭证和其他密钥未进入仓库或应用资产。

## 2. Phase 1：Android 正式发布

### 2.1 功能门禁

- [ ] 本地双人对战完整。
- [ ] 简单、中等、困难三档 AI 完整。
- [ ] LAN Host/Client、发现、连接、移动、计时、重赛、30 秒重连和全量重同步完整。
- [ ] 单槽自动存档在每次确认落子后写入。
- [ ] 首页显示可用的“继续游戏”。
- [ ] 结局或明确放弃后清除当前存档。
- [ ] 本地双人、AI、LAN 均进入统计。
- [ ] 最近 20 局已完成对局可以逐步回放。
- [ ] 交互式教程和权威规则页面完成。
- [ ] Phase 1 只暴露中文界面和现代东方棋艺主题。
- [ ] 在线、普通对局语音和冥想模式入口未暴露，商店文案也未宣称可用。

### 2.2 Android 工程门禁

- [ ] `minSdk` 明确设置为 26。
- [ ] `compileSdk` 和 `targetSdk` 设置为 36，并在发布构建中复核。
- [ ] Java、Kotlin、Android Gradle Plugin、Gradle 和 Flutter 版本已锁定并记录。
- [ ] Android command-line tools 已安装，SDK licenses 已确认。
- [ ] 最终永久 `applicationId` 已替换开发期 `com.qoder.foursquare`。
- [ ] 正式应用名称和 Android label 已确认。
- [ ] `versionName` 和递增的 `versionCode` 已确认。
- [ ] release 构建不使用 debug key。
- [ ] upload key、app-signing key 和备份责任已确认；密钥文件不进入仓库。
- [ ] 使用正式签名生成 Android App Bundle（AAB）。
- [ ] 使用 bundletool 或 Google Play 交付产物完成安装验证。
- [ ] `RECORD_AUDIO` 等 Phase 4 权限未进入 Phase 1 主清单。
- [ ] LAN 仅声明 `INTERNET` 与组播所需权限；网络不可用或系统阻止本地网络时有可理解的降级体验。
- [ ] Android 26、典型中间版本和 Android 35/36 真机或高可信设备矩阵通过。
- [ ] 冷启动、离线启动、后台、锁屏、升级安装和低存储场景通过。

### 2.3 LAN 专项门禁

- [ ] Host 通过权威绝对截止时间计算回合超时，不依赖后台定时器持续执行。
- [ ] 双方同步首局随机先手，重赛时交替先手。
- [ ] 重复、乱序或缺失消息不会造成静默分叉。
- [ ] 每个状态更新具备可校验的顺序或版本信息。
- [ ] 重连后以 Host 权威快照恢复棋盘、当前方、剩余时间、未吃子计数和历史。
- [ ] Host/Client 互换、家庭 Wi-Fi、手机热点、锁屏和网络切换场景通过。
- [ ] 同一落子横纵双吃能够完整同步，不丢失任一被吃棋子。
- [ ] LAN 不显示或接受撤销、重做请求。

### 2.4 Google Play 发布门禁

- [ ] Google Play 开发者身份已验证。
- [ ] 最终包名已按 Play Console 要求注册。
- [ ] 开发者账户类型和创建日期已确认。
- [ ] 若适用新个人账户规则，至少 12 名测试者连续加入封闭测试 14 天，并保留真实反馈记录。
- [ ] 已完成内部测试。
- [ ] 已完成封闭测试和正式发布资格申请（若适用）。
- [ ] Google Play 预发布报告无未处理的崩溃、ANR 或严重兼容问题。
- [ ] 已填写应用访问权限、内容分级、目标受众、广告声明和 Data Safety。
- [ ] 隐私政策 URL 可公开访问、非 PDF、无地域限制，并可从应用内访问。
- [ ] 商店标题、简短描述、完整描述均只宣传 Phase 1 已交付功能。
- [ ] 512×512 应用图标、1024×500 feature graphic、手机截图和必要的平板截图完成。
- [ ] 截图来自最终 UI，文字与 Phase 1 中文支持范围一致。
- [ ] 发布顺序为内部测试 → 封闭测试 → 正式发布；这些渠道不作为独立 Beta 产品宣传。

### 2.5 Google Play 官方要求核验

以下要求于 2026-08-01 复核，提交前仍需再次查看最新官方政策：

- 2026-08-31 起，新应用和应用更新必须以 Android 16（API 36）或更高版本为目标：[Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)。
- 新应用在 Google Play 使用 Android App Bundle 发布：[About Android App Bundles](https://developer.android.com/guide/app-bundle)。
- 2023-11-13 后创建的个人开发者账户，在申请正式发布前需满足至少 12 名测试者连续加入封闭测试 14 天等要求：[App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)。
- 所有应用都要提供准确的 Data Safety 信息；即使不收集用户数据，也必须完成表单并提供隐私政策：[Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469)。
- 隐私政策须在 Play Console 和应用内可访问，公开、非地域限制、非 PDF，并说明数据访问、使用、共享、保留和删除：[Google Play Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/17190352)。
- 自 2026-09-30 起，Play 包名须完成 Android 开发者验证和包名注册：[Registering Play package names](https://support.google.com/googleplay/android-developer/answer/16984799)。

## 3. Phase 2：iOS 正式发布

- [ ] `ios/` 工程完整创建并纳入版本管理。
- [ ] 最低系统版本设置为 iOS 13。
- [ ] iOS Bundle ID 与已确认的永久标识一致。
- [ ] Apple Developer Team、证书、Provisioning Profile 和 App Store Connect 权限就绪。
- [ ] 使用符合当期要求的 Xcode 和 SDK 构建；当前门禁为 Xcode 26/iOS 26 SDK 或更高版本。
- [ ] iOS 完整具备 Phase 1 的单机、AI、LAN、存档、统计、最近 20 局回放、规则和教程。
- [ ] `NSLocalNetworkUsageDescription` 和 `_foursquare._tcp` Bonjour 声明准确描述 LAN 用途。
- [ ] Phase 4 前不提前申请麦克风权限。
- [ ] 中文、英文、日文所有用户可见文本均已本地化，Android 同步更新。
- [ ] iOS 13 与当前 iOS、iPhone 与 iPad、横竖屏测试通过。
- [ ] TestFlight 内部和外部验证按发布策略完成。
- [ ] App Privacy、隐私政策、内容分级、App Store 描述、截图和审核备注完成。
- [ ] dSYM 已上传到诊断平台并归档。

Apple 官方要求于 2026-08-01 复核：

- 自 2026-04-28 起，iOS/iPadOS 应用须使用 iOS/iPadOS 26 SDK 或更高版本构建：[Submitting to the App Store](https://developer.apple.com/app-store/submitting/)。
- iOS 应用需要隐私政策 URL，并须声明自身及第三方 SDK 的数据处理实践：[Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)。

## 4. Phase 3：可靠在线对战发布

### 4.1 环境门禁

- [ ] Phase 1/2 继续只有 development 和 production；staging 仅在 Phase 3 引入。
- [ ] staging 应用、服务器、数据库、域名、密钥和 Sentry environment 与 production 隔离。
- [ ] staging 不读取或复制 production 用户数据。
- [ ] production 仅使用 HTTPS/WSS 和有效证书。
- [ ] 配置启动时进行完整校验，不以示例域名或明文 IP 回退。

### 4.2 客户端与协议门禁

- [ ] 本地随机匿名设备 ID，不要求手机号、邮箱或真实姓名。
- [ ] 服务端绑定 socket、match、设备身份和执棋颜色，客户端字段不能越权。
- [ ] 服务端权威验证全部规则，客户端预测失败时可回滚或重同步。
- [ ] 每个落子都有权威确认或拒绝、序号、协议版本和可校验状态。
- [ ] 多吃子使用列表表示，客户端和服务器不会只保留第一枚被吃棋子。
- [ ] 断线重连、超时竞态、重复提交和全量重同步测试通过。
- [ ] 设置页可删除在线数据并重置身份。
- [ ] 不实现自动跨设备同步。

### 4.3 服务端与运维门禁

- [ ] 使用受支持的 Node.js 版本和锁定依赖的生产镜像。
- [ ] 生产容器运行编译产物，不运行开发热重载进程。
- [ ] 数据库 migration 可前进、回滚并在 staging 演练。
- [ ] 健康检查、优雅停机、限流、输入校验、CORS 白名单和 TLS 完成。
- [ ] 数据库、Redis 不直接暴露到公网。
- [ ] 密钥来自安全配置，不写入 Compose、镜像或仓库。
- [ ] 备份、恢复、保留期和删除任务已验证。
- [ ] Sentry 服务端接入且日志、breadcrumbs、异常上下文完成脱敏。
- [ ] 契约、集成、并发、负载、服务重启和故障注入测试通过。
- [ ] 部署和回滚步骤可由清单复现。

### 4.4 当前本地开发证据（不等于发布完成）

- 服务端权威规则、协议版本、身份/颜色绑定、幂等落子、60 秒超时、30 秒重连、缓存回收和 Socket 输入边界已有本地自动化测试。
- 客户端匿名身份持久化、权威快照/确认/拒绝解析、修订缺口恢复、旧连接隔离，以及“仅在 Socket onConnect 后确认连接成功”的语义已有本地自动化测试。
- 尚未接入生产导航的在线 BLoC/UI 已接入权威状态，中英日基础状态、断线恢复入口、服务端确认前不改棋盘、终局协议完整性和标识隐私已有本地自动化测试。
- 本地真实 Node Socket.IO 双客户端，以及两个具体 Flutter `OnlineGameTransport` 实例直连 Node 生产入口的显式启用型测试，已自动验证匹配、双方收到同一权威提交、断线通知、30 秒内同身份恢复和主动全量快照；这不等同于两台完整 Flutter 应用、真机或 staging 联调已通过。
- 服务端对局记录已使用稳定 `matchId` 幂等写入模型，并提供 Prisma migration；真实 PostgreSQL 迁移、备份恢复、删除和并发集成仍未验证。
- 在线入口继续隐藏；staging、真实 PostgreSQL、持久化 outbox/恢复 worker、负载、进程重启故障恢复、TLS、限流和外部部署门禁仍未完成，因此 Phase 3 不能标记为可用或可发布。当前内存退避重试只能覆盖服务进程持续存活的短时数据库故障，不能作为生产级不丢局保证。

## 5. Phase 4：语音与冥想发布

- [ ] 普通对局语音控制和播报完整。
- [ ] 中文无屏冥想模式可以不看屏幕完成整局。
- [ ] 麦克风权限在用户主动进入语音功能后按需请求。
- [ ] 权限用途文案、拒绝路径和设置跳转清晰。
- [ ] 识别失败、TTS 失败、音频焦点中断、来电和蓝牙耳机场景通过。
- [ ] 语音输入不会进入 Sentry 或普通日志。
- [ ] 是否经过系统或第三方语音服务传输已核实并写入隐私政策及商店声明。
- [ ] Phase 4 首期只承诺中文语音，不宣称多语言语音。

## 6. 国内 Android 应用商店

- [ ] Phase 1 不同步发布国内商店，也不提前接入商店专属 SDK。
- [ ] Google Play 正式版稳定后，再确定目标商店和发布顺序。
- [ ] 首次 Google Play 发布前确认 app-signing key 的跨商店复用和备份方案，避免后续同包名更新发生签名冲突。
- [ ] 国内商店阶段另行核验实名、备案、隐私清单、SDK 合规、版号或游戏分类等当期要求。
- [ ] 每个商店使用与实际功能一致的独立素材和合规声明。

## 7. 发布前由项目方补齐

### Phase 1 硬门禁

- [ ] 最终应用名称。
- [ ] 永久 Android applicationId。
- [ ] 开发者展示名称或法律主体。
- [ ] 隐私政策公开 URL。
- [ ] 隐私联系和支持邮箱。
- [ ] Sentry Flutter DSN、组织和项目。
- [ ] Google Play 账户类型、创建日期、验证和包名注册状态。
- [ ] 签名密钥所有权、备份和操作责任。
- [ ] 发布国家/地区、目标年龄和内容分级答案。
- [ ] 最终商店素材和发布说明。

### Phase 2 硬门禁

- [ ] iOS Bundle ID。
- [ ] Apple Developer Team 和 App Store Connect 权限。
- [ ] SKU、发布地区和审核联系信息。

### Phase 3 硬门禁

- [ ] staging/production 域名和部署区域。
- [ ] 数据库、缓存和备份方案。
- [ ] 在线数据保留期限和删除 SLA。
- [ ] 服务端 Sentry DSN 和告警接收方。

### Phase 4 硬门禁

- [ ] 最终语音识别与播报引擎及平台支持范围。
- [ ] 语音联网/离线边界、第三方处理区域和数据保留条款。
- [ ] 所需外部账号、凭据提供方式及隐私声明责任。

## 8. 单次发布记录模板

- 版本：
- 阶段/平台：
- Git commit：
- 构建环境：
- `versionName` / `versionCode` 或 iOS build：
- 测试命令及结果：
- 真机矩阵：
- 已知非阻塞问题：
- 产物路径及 SHA-256：
- 符号文件归档位置：
- 隐私声明复核人：
- 发布审批人：
- 渠道和发布时间：
- 回滚版本与步骤：
