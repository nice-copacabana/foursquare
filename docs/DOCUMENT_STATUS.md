# 文档状态与权威来源索引

> 状态：当前权威索引
> 最后核查日期：2026-08-13
> 目的：区分当前要求、当前代码事实、历史快照和未来方案，避免旧文档中的完成度、规则或发布结论重新进入实现。

## 1. 如何判断冲突

不同问题使用不同的权威来源：

1. **产品阶段、平台和功能边界**：以 `PRODUCT_ROADMAP.md` 为准。
2. **游戏规则、模式差异和 LAN 不变量**：以 `GAME_RULES.md` 为准。
3. **测试范围和验收证据**：以 `TEST_STRATEGY.md` 为准。
4. **能否正式发布**：以 `RELEASE_CHECKLIST.md` 逐项通过和对应构建/测试证据为准。
5. **数据、SDK 和隐私边界**：以 `PRIVACY_DATA_MAP.md` 为准。
6. **视觉和主题包约束**：以 `VISUAL_DESIGN_SYSTEM.md` 为准。
7. **当前实现事实**：以当前 commit 的源代码、可运行测试和构建结果为准，不能由计划或历史报告代替。
8. **发布后增长、运营、容量与保护框架**：以 `POST_LAUNCH_OPERATIONS_PLAN.md` 为准；其中建议和阈值不自动扩展产品范围或构成法律意见。

README 是项目入口和摘要。README 与上述权威文档冲突时，应修正 README，不能反向修改权威规则来迁就摘要。

## 2. 当前权威文档

| 文档 | 权威范围 | 不负责的内容 |
|---|---|---|
| [PRODUCT_ROADMAP.md](PRODUCT_ROADMAP.md) | 四阶段顺序、各阶段范围、平台与环境边界、用户后补门禁 | 当前代码完成度 |
| [GAME_RULES.md](GAME_RULES.md) | 移动、吃子、计时、终局顺序、先手、撤销、存档和 LAN/在线协议不变量 | 发布渠道政策 |
| [TEST_STRATEGY.md](TEST_STRATEGY.md) | 测试分层、规则场景、TDD 切片、LAN/在线故障矩阵和验收证据 | 产品范围变更 |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Android、iOS、在线和语音阶段的正式发布门禁 | 代替实际执行测试 |
| [PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md) | 本地、LAN、Sentry、在线和语音数据流及隐私变更控制 | 法律意见 |
| [PENDING_CONFIRMATIONS.md](PENDING_CONFIRMATIONS.md) | 项目方已确认、暂缓或需在发布前集中补齐的外部输入 | 产品规则或代码完成度 |
| [VISUAL_DESIGN_SYSTEM.md](VISUAL_DESIGN_SYSTEM.md) | 现代东方棋艺、响应式布局、无障碍和主题包架构 | 具体页面已经实现的声明 |
| [POST_LAUNCH_OPERATIONS_PLAN.md](POST_LAUNCH_OPERATIONS_PLAN.md) | 商店推广、聚合信息收集、优化闭环、容量演进、支持、安全与知识产权保护框架 | 产品范围变更、完成度证明、付费授权或法律意见 |
| [DOCUMENT_STATUS.md](DOCUMENT_STATUS.md) | 文档分类、冲突处理和维护规则 | 游戏或产品规则本身 |
| [../README.md](../README.md) | 项目入口、当前阶段摘要、开发命令和权威文档导航 | 独立权威来源 |

这些文档描述的是已确认目标和门禁。只有源代码、测试和构建证据满足对应条目后，才能把目标标记为完成。

## 3. 历史记录与审计快照

以下内容保留用于追溯，不作为当前要求或完成证明：

| 路径或文档 | 分类 | 使用限制 |
|---|---|---|
| `docs/reports/**` | 历次迭代、月度、阶段和任务报告 | 只说明当时记录；其中完成度、测试数和发布结论不得用于当前状态 |
| `CHANGELOG.md` | 旧版本记录 | 保留历史；未经同一 commit 复测的覆盖率、性能和通过率不作为证据 |
| `IMPLEMENTATION_PLAN.md` | 旧 LAN 实施进度 | 已被四阶段路线图替代 |
| `PROJECT_REPORT.md` | 旧项目总结 | 不能证明当前功能或发布状态 |
| `docs/design/IMPLEMENTATION_PLAN.md` | 旧开发计划 | 已被路线图、规则和测试策略替代 |
| `docs/项目现状总结.md` | 旧现状快照 | “100%”等结论不再有效 |
| `docs/项目交付总结.md` | 旧交付总结 | 不代表已完成商店交付 |
| `docs/项目启动检查清单.md` | 旧启动阶段清单 | 仅供追溯 |
| `docs/CODE_AUDIT_REPORT.md` | 2026-05-07 审计快照 | 可用于定位历史问题；其中“后端100%”和阶段编号已过时，不能作当前完成度来源 |
| `docs/CLAUDE.md`、`docs/CLAUDE2.md` | 旧开发上下文 | 不覆盖仓库 `AGENTS.md` 或当前权威文档 |

历史文档不删除、不重写成当前结论。后续若必须编辑，应在顶部增加“历史快照”说明并链接本索引。

## 4. 旧规则文档

以下文档可能仍有背景价值，但规则期望已经被 `GAME_RULES.md` 完整取代：

- `docs/游戏规则确认.md`
- `docs/吃子规则完善说明.md`
- `docs/guides/CORE_GAMEPLAY_MECHANICS.md`
- 旧实施计划、项目总结和商店描述中的规则段落

已知旧冲突包括：

- “吃光全部棋子”与当前“小于等于 1 枚立即判负”的差异。
- “己-己-敌三子连线”与当前精确四格排列、移动子必须参与及横纵双吃的差异。
- 固定黑方先手与当前首局随机、复局交替的差异。
- 无和棋、重复 50 步或 100 ply 与当前连续 50 ply 未吃子和棋的差异。
- 单个 `capturedPiece` 与当前完整 `capturedPieces` 列表的差异。

新增或修改测试时不得从旧规则文档复制期望。

## 5. 操作指南与资源指南

`docs/guides/**` 默认属于操作参考，不自动具有当前权威性：

| 文档 | 当前状态 |
|---|---|
| `QUICK_PUBLISH_GUIDE.md` | 历史且不可用于发布；“代码100%完成、可立即发布”和 debug APK 发布步骤无效 |
| `QUICK_START_GUIDE.md` | 旧快速开始；平台最低版本、功能状态和语音描述已过时 |
| `METADATA_CONFIGURATION_GUIDE.md` | 旧元数据示例；minSdk 21、targetSdk 34 和占位标识无效 |
| `STORE_ASSETS_GUIDE.md` | 资源规格参考；占位邮箱、隐私 URL 和功能文案不能直接发布 |
| `ANDROID_BUILD_FIX_GUIDE.md` | 构建排障参考；版本和镜像配置必须按当前工程验证 |
| 图标、启动屏、音频和混淆指南 | 制作参考；最终素材、配置和许可证仍须通过发布门禁 |
| `VOICE_CONTROL_INTEGRATION.md` | Phase 4 未来实现参考，不属于 Phase 1 |

Google Play、Android 和 Apple 要求会变化。发布时只使用 `RELEASE_CHECKLIST.md` 中注明核验日期的官方链接，并在提交前再次检查。

## 6. 未来方案与探索材料

以下内容描述候选设计或远期想法，不构成当前交付承诺：

- `docs/development/FUTURE_ROADMAP.md`
- `docs/design/SERVER_ARCHITECTURE_AND_TECH_STACK.md`
- `docs/design/VOICE_MEDITATION_FEATURE_DESIGN.md`
- `docs/STAGE5_DESIGN_SPECIFICATION.md`
- `docs/技术方案对比.md`
- `docs/技术架构与开发计划.md`
- `docs/开发计划-精简版.md`
- `docs/实施计划书.md`
- `docs/项目立项文档.md`
- `docs/盈利模式与运营部署规划.md`
- AI 可视化、语音、穿戴设备、小程序、社交、排行、账号、聊天和赛季相关提案

其中与当前四阶段路线重合的部分，也必须先进入 `PRODUCT_ROADMAP.md` 才能成为正式范围。

## 7. 当前需要避免的陈述

在发布证据完成前，任何当前文档、商店文案或对外说明都不得使用以下结论：

- “代码100%完成”“配置100%完成”“可立即发布”。
- “规则100%正确”或“所有模式规则一致”。
- “在线后端100%”“LAN已经正式完成”“语音/冥想已经可发布”。
- 未注明 commit、命令和报告路径的覆盖率、测试数、帧率、响应时间或通过率。
- Phase 1 支持 iOS、Web、小程序、在线、语音、冥想、多语言或多套正式主题。
- staging 已在 Phase 1/2 建立，或将测试渠道称为独立 Beta 产品。

## 8. 维护流程

1. 产品范围变化先更新 `PRODUCT_ROADMAP.md`。
2. 规则变化先更新 `GAME_RULES.md`，再更新契约测试和各层实现。
3. 数据或 SDK 变化先更新 `PRIVACY_DATA_MAP.md`，再更新权限、隐私政策和商店声明。
4. 发布要求变化更新 `RELEASE_CHECKLIST.md`，记录官方来源和核验日期。
5. 视觉原则变化更新 `VISUAL_DESIGN_SYSTEM.md`，具体页面实现不能反向制造第二套规范。
6. README 只同步摘要和入口链接。
7. 历史报告保持原貌；新的进度结论必须附 commit 和验证证据。

当文档无法确定当前代码是否完成某项功能时，结论应写为“待验证”，不得根据文件存在、TODO 数量或旧报告推定完成。
