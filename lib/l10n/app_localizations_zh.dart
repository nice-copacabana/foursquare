// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '四子游戏';

  @override
  String get homeTagline => '移 · 围 · 取 · 胜';

  @override
  String get developmentEdition => '现代东方棋艺 · 开发版本 0.1.0';

  @override
  String get continueGame => '继续游戏';

  @override
  String get continueGameDescription => '从上次落子继续';

  @override
  String get playerVsPlayer => '双人对战';

  @override
  String get playerVsPlayerDescription => '同屏轮流落子';

  @override
  String get playerVsAI => '人机对战';

  @override
  String get playerVsAIDescription => '简单 · 中等 · 困难';

  @override
  String get lanGame => '局域网对战';

  @override
  String get lanGameDescription => '同一网络面对面对弈';

  @override
  String get statistics => '战绩';

  @override
  String get rules => '规则';

  @override
  String get settings => '设置';

  @override
  String get chooseDifficulty => '选择棋力';

  @override
  String get difficultyEasy => '简单';

  @override
  String get difficultyEasyDescription => '熟悉规则与走法';

  @override
  String get difficultyMedium => '中等';

  @override
  String get difficultyMediumDescription => '平衡思考与速度';

  @override
  String get difficultyHard => '困难';

  @override
  String get difficultyHardDescription => '更深入地计算局面';

  @override
  String get skip => '跳过';

  @override
  String get previous => '上一页';

  @override
  String get next => '下一页';

  @override
  String get startGame => '开始游戏';

  @override
  String get onboardingWelcomeTitle => '四子游戏';

  @override
  String get onboardingWelcomeSubtitle => '策略对弈，智胜四方';

  @override
  String get onboardingWelcomeBody => '欢迎来到四子棋！\n让我们快速了解游戏规则';

  @override
  String get onboardingBoardTitle => '棋盘与棋子';

  @override
  String get onboardingBoardFourByFour => '4×4 棋盘';

  @override
  String get onboardingBoardFourByFourDescription => '游戏在 4×4 交点棋盘上进行';

  @override
  String get onboardingFourPieces => '双方各 4 子';

  @override
  String get onboardingFourPiecesDescription => '墨方和玉方各有 4 枚棋子';

  @override
  String get onboardingMovementTitle => '移动规则';

  @override
  String get onboardingOrthogonalMove => '上下左右移动';

  @override
  String get onboardingOrthogonalMoveDescription => '棋子只能移动到相邻的空位';

  @override
  String get onboardingNoDiagonal => '不能斜向移动';

  @override
  String get onboardingNoDiagonalDescription => '不能斜走、跳子或落到已有棋子的位置';

  @override
  String get onboardingCaptureTitle => '吃子规则';

  @override
  String get emptyCell => '空';

  @override
  String get ownPiece => '己';

  @override
  String get enemyPiece => '敌';

  @override
  String get onboardingExactPattern => '精确四格排列';

  @override
  String get onboardingExactPatternDescription => '形成“己-己-敌-空”或规定的反向排列时吃掉敌子';

  @override
  String get onboardingMovedPieceParticipates => '落子必须参与';

  @override
  String get onboardingMovedPieceParticipatesDescription =>
      '刚移动的棋子必须属于相邻双子；横纵可同时吃子';

  @override
  String get onboardingFeaturesTitle => '功能特色';

  @override
  String get onboardingAiFeature => 'AI 对战';

  @override
  String get onboardingAiFeatureDescription => '3 种难度的 AI 陪你练习';

  @override
  String get onboardingReplayFeature => '游戏回放';

  @override
  String get onboardingReplayFeatureDescription => '回顾每一步精彩对局';

  @override
  String get onboardingThemeFeature => '现代东方棋艺';

  @override
  String get onboardingThemeFeatureDescription => '一期统一视觉，后续将扩展更多主题';

  @override
  String get onboardingStatisticsFeature => '战绩统计';

  @override
  String get onboardingStatisticsFeatureDescription => '查看你的游戏数据';

  @override
  String get rulesTitle => '对弈规则';

  @override
  String get startInteractiveTutorial => '开始互动教程';

  @override
  String get rulesSectionOne => '一';

  @override
  String get rulesSectionTwo => '二';

  @override
  String get rulesSectionThree => '三';

  @override
  String get rulesSectionFour => '四';

  @override
  String get rulesHeroTitle => '移子成势，精确取子';

  @override
  String get rulesHeroDescription => '所有模式共享同一套规则；界面、AI、回放与局域网均以此为准。';

  @override
  String get rulesBoardSection => '棋盘与行棋';

  @override
  String get rulesBoardLine1 => '棋盘为 4×4，墨方与玉方各四枚棋子。';

  @override
  String get rulesBoardLine2 => '首局随机决定先手；复局双方交替先手。';

  @override
  String get rulesBoardLine3 => '每手将一枚己方棋子移到上下左右相邻的空位，不能斜走或越子。';

  @override
  String get rulesBoardLine4 => '每回合 60 秒；离线对局进入后台会暂停，局域网对局继续计时。';

  @override
  String get rulesCaptureSection => '精确吃子';

  @override
  String get rulesCaptureIntro => '只检查本次落子所在的完整四格横线与竖线。以下排列可以吃掉“敌”：';

  @override
  String get rulesCaptureLine1 => '刚移动的棋子必须属于相邻的两枚己方棋子。';

  @override
  String get rulesCaptureLine2 => '仅因对手落子而被动形成的排列不触发吃子。';

  @override
  String get rulesCaptureLine3 => '横向与竖向可同时成立，一手最多吃两枚。';

  @override
  String get rulesCaptureLine4 => '1100、1110、0110 等非精确排列均不吃子。';

  @override
  String get rulesEndingSection => '胜负与和棋';

  @override
  String get rulesEndingLine1 => '一方棋子只剩一枚或更少时，该方立即判负。';

  @override
  String get rulesEndingLine2 => '一方回合开始时没有任何合法移动，该方判负。';

  @override
  String get rulesEndingLine3 => '回合倒计时归零，当前行棋方判负。';

  @override
  String get rulesEndingLine4 => '连续 50 个单方落子都未吃子时和棋；任意吃子会把计数清零。';

  @override
  String get rulesEndingLine5 => '局域网断线有 30 秒重连宽限，超时未恢复则断线方判负。';

  @override
  String get rulesUndoSection => '撤销与记录';

  @override
  String get rulesUndoLine1 => '本地双人每次撤销一手；人机对战按“玩家 + AI”两手成对撤销。';

  @override
  String get rulesUndoLine2 => '撤销后可以重做；落下新棋后原重做分支失效。';

  @override
  String get rulesUndoLine3 => '局域网对战不提供撤销。完成对局会进入最近 20 局记录，可逐手回放。';

  @override
  String get tutorialTitle => '互动教程';

  @override
  String get tutorialStep1 => '先选择左上角的墨方棋子。';

  @override
  String get tutorialStep2 => '很好。现在把它移动到下方相邻空位。';

  @override
  String get tutorialStep3 => '落子完成。实战中每回合有 60 秒，双方轮流移动。';

  @override
  String get tutorialStep4 => '吃子必须匹配完整四格：己-己-敌-空，或规定的反向排列。落子必须属于相邻双子。';

  @override
  String get tutorialStep5 => '横向与竖向可同时吃子；对方只剩一子、无合法移动或超时都会判负。';

  @override
  String get finishTutorial => '完成教程';

  @override
  String get tutorialCapturePatternSemantics => '允许的吃子排列：己、己、敌、空';

  @override
  String get gameTitle => '四子游戏';

  @override
  String get gameUnavailable => '棋局暂时无法继续';

  @override
  String get restart => '重新开始';

  @override
  String get restartConfirmTitle => '重新开始';

  @override
  String get restartConfirmBody => '确定要重新开始游戏吗？当前进度将丢失。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get pvpReplayTitle => '双人对局回放';

  @override
  String get pveReplayTitle => '人机对局回放';

  @override
  String get lanReplayTitle => '局域网对局回放';

  @override
  String get blackSide => '墨方';

  @override
  String get whiteSide => '玉方';

  @override
  String get blackTurn => '墨方回合';

  @override
  String get whiteTurn => '玉方回合';

  @override
  String firstPlayerAnnouncement(String side) {
    return '$side 先手';
  }

  @override
  String get gameStarting => '对局即将开始';

  @override
  String boardCellPosition(int row, int column) {
    return '第 $row 行，第 $column 列';
  }

  @override
  String get boardEmptyPosition => '空位';

  @override
  String get boardSelected => '已选中';

  @override
  String get boardLegalDestination => '可移动到此处';

  @override
  String get boardSelectablePiece => '可选棋子';

  @override
  String get boardPreviousMoveStart => '上一手起点';

  @override
  String get boardPreviousMoveEnd => '上一手终点';

  @override
  String get aiThinking => 'AI 思考中';

  @override
  String turnSecondsRemaining(int seconds) {
    return '本回合剩余 $seconds 秒';
  }

  @override
  String secondsCount(int seconds) {
    return '$seconds 秒';
  }

  @override
  String moveHistoryCount(int count) {
    return '移动历史（$count 手）';
  }

  @override
  String get noMoveHistory => '暂无移动记录';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get gameOver => '游戏结束';

  @override
  String get blackWins => '墨方获胜！';

  @override
  String get whiteWins => '玉方获胜！';

  @override
  String get draw => '和棋';

  @override
  String get exit => '退出';

  @override
  String get playAgain => '再来一局';

  @override
  String get viewReplay => '查看回放';

  @override
  String get endReasonPieceCountBlack => '玉方只剩一枚或更少棋子';

  @override
  String get endReasonPieceCountWhite => '墨方只剩一枚或更少棋子';

  @override
  String get endReasonNoLegalMovesBlack => '玉方没有合法移动，判负';

  @override
  String get endReasonNoLegalMovesWhite => '墨方没有合法移动，判负';

  @override
  String get endReasonNoCaptureLimit => '连续 50 手未发生吃子，和棋';

  @override
  String get endReasonTimeoutBlack => '玉方回合超时，判负';

  @override
  String get endReasonTimeoutWhite => '墨方回合超时，判负';

  @override
  String get endReasonDisconnectBlack => '玉方断线超过 30 秒，判负';

  @override
  String get endReasonDisconnectWhite => '墨方断线超过 30 秒，判负';

  @override
  String get endReasonAbandonedBlack => '玉方已认输';

  @override
  String get endReasonAbandonedWhite => '墨方已认输';

  @override
  String get endReasonUnknown => '对局已结束';

  @override
  String get historyTitle => '最近对局';

  @override
  String get refresh => '刷新';

  @override
  String get historyEmptyTitle => '尚无已完成对局';

  @override
  String get historyEmptyDescription => '完成一局后，可在这里查看最近 20 局并逐手回放。';

  @override
  String get modePvp => '双人';

  @override
  String get modePve => '人机';

  @override
  String get modeLan => '局域网';

  @override
  String modePveWithDifficulty(String difficulty) {
    return '人机 · $difficulty';
  }

  @override
  String resultSideWins(String side) {
    return '$side胜';
  }

  @override
  String get resultFinished => '已结束';

  @override
  String historySummary(int moves, int captures, String date) {
    return '$moves 手 · $captures 次吃子 · $date';
  }

  @override
  String dateMonthDayTime(int month, int day, String time) {
    return '$month月$day日 $time';
  }

  @override
  String get replayTitle => '游戏回放';

  @override
  String get replayHelp => '回放说明';

  @override
  String get replayInitial => '初始';

  @override
  String replayStepLabel(int step) {
    return '第 $step 步';
  }

  @override
  String replayProgress(int step, int total) {
    return '第 $step 手 / 共 $total 手';
  }

  @override
  String moveDescription(String from, String to) {
    return '$from → $to';
  }

  @override
  String moveDescriptionCapture(String from, String to, int count) {
    return '$from → $to，吃 $count 子';
  }

  @override
  String get replayFirst => '第一步';

  @override
  String get replayPrevious => '上一步';

  @override
  String get replayNext => '下一步';

  @override
  String get replayLast => '最后一步';

  @override
  String get replayControlsHeading => '控制说明：';

  @override
  String get replayHelpSlider => '使用滑块可快速跳转到任意步骤';

  @override
  String get replayHelpButtons => '点击按钮可逐步回放';

  @override
  String get replayHelpHistory => '点击历史记录可直接跳转';

  @override
  String get replayFeaturesHeading => '功能说明：';

  @override
  String get replayHelpReadonly => '棋盘为只读模式，不可操作';

  @override
  String get replayHelpHighlight => '高亮显示当前步骤的移动';

  @override
  String get replayHelpCapture => '带 × 标记表示该步骤有吃子';

  @override
  String get gotIt => '知道了';

  @override
  String get statisticsTitle => '对局统计';

  @override
  String get statisticsResetTitle => '重置统计';

  @override
  String get statisticsResetConfirm => '将清空累计统计和最近 20 局回放。此操作无法撤销，确定继续吗？';

  @override
  String get statisticsResetAction => '确认重置';

  @override
  String get statisticsResetDone => '统计与最近对局已重置';

  @override
  String get statisticsResetFailed => '重置失败，请稍后重试';

  @override
  String get statisticsHistoryTooltip => '最近对局与回放';

  @override
  String get statisticsOverviewTitle => '棋谱总览';

  @override
  String get statisticsOverviewDescription => '记录走过的每一步，不把不同对局模式混成一项输赢。';

  @override
  String get statisticsTotalGames => '累计对局';

  @override
  String get statisticsTotalMoves => '累计手数';

  @override
  String get statisticsAverageMoves => '平均手数';

  @override
  String get statisticsTotalCaptures => '累计吃子';

  @override
  String statisticsLastMove(String date) {
    return '最近落子：$date';
  }

  @override
  String get statisticsNoRecord => '尚无记录';

  @override
  String get statisticsRecentTitle => '最近对局';

  @override
  String get statisticsRecentEyebrow => '近期表现';

  @override
  String get statisticsRecentEmpty => '完成一局后，将在这里按模式呈现结果。';

  @override
  String statisticsRecentDescription(int count) {
    return '仅基于设备内保留的最近 $count 局，不与累计数据混算。';
  }

  @override
  String get statisticsPvpTitle => '本地双人 · 近 20 局';

  @override
  String get statisticsPvpWin => '墨方胜';

  @override
  String get statisticsPvpLoss => '玉方胜';

  @override
  String get statisticsPvpNote => '本地双人按双方棋色记录，不计算个人胜率。';

  @override
  String get statisticsPveTitle => '人机对弈 · 近 20 局';

  @override
  String get statisticsPveWin => '玩家胜';

  @override
  String get statisticsPveLoss => 'AI 胜';

  @override
  String get statisticsPveNote => '按本机玩家执棋颜色计算。';

  @override
  String get statisticsLanTitle => '局域网 · 近 20 局';

  @override
  String get statisticsLanWin => '本机胜';

  @override
  String get statisticsLanLoss => '本机负';

  @override
  String get statisticsLanNote => '按本机在联机对局中的执棋颜色计算。';

  @override
  String statisticsDrawCount(int count) {
    return '和棋 $count';
  }

  @override
  String statisticsUnknownCount(int count) {
    return '未识别 $count';
  }

  @override
  String statisticsNoModeRecord(String note) {
    return '暂无该模式记录。$note';
  }

  @override
  String get statisticsUnavailable => '统计数据暂时无法读取';

  @override
  String get reload => '重新加载';

  @override
  String get lanTitle => '局域网对战';

  @override
  String get lanCreateRoomTab => '创建房间';

  @override
  String get lanJoinRoomTab => '加入房间';

  @override
  String get lanConnectedTitle => '已连接到对局';

  @override
  String get lanConnectedDescription => '正在进入棋局，请稍候。';

  @override
  String get lanDisconnect => '断开连接';

  @override
  String get lanWaitingTitle => '正在等待玩家加入';

  @override
  String lanRoomNameValue(String name) {
    return '房间名：$name';
  }

  @override
  String get lanCancelCreate => '取消创建';

  @override
  String get lanCreateHeading => '开一间棋室';

  @override
  String get lanCreateDescription => '同一局域网内的玩家可以发现并加入。';

  @override
  String get lanRoomNameLabel => '房间名称';

  @override
  String get lanDefaultRoomName => '我的棋室';

  @override
  String get lanCreateRoom => '创建房间';

  @override
  String get lanNearbyRooms => '附近的房间';

  @override
  String get lanStopSearch => '停止搜索';

  @override
  String get lanSearch => '搜索附近房间';

  @override
  String get lanUnnamedRoom => '未命名房间';

  @override
  String get lanUnknownAddress => '未知地址';

  @override
  String get lanJoin => '加入';

  @override
  String get lanSearching => '正在搜索附近棋室…';

  @override
  String get lanNoRooms => '暂未发现房间';

  @override
  String get lanSearchingHint => '请保持双方设备连接同一网络。';

  @override
  String get lanSearchHint => '点击右上角搜索按钮开始查找。';

  @override
  String get lanDiscoveryFailed => '搜索附近房间失败，请确认已连接同一网络后重试。';

  @override
  String get lanHostingFailed => '创建房间失败，请检查本地网络后重试。';

  @override
  String get lanConnectionFailed => '无法加入房间，请确认对方房间仍可用。';

  @override
  String get lanOpponentLeft => '对方已离开游戏';

  @override
  String get lanGameError => '局域网对局发生错误，请退出后重试。';

  @override
  String get lanUnknownState => '未知状态';

  @override
  String get lanReconnecting => '连接中断，正在等待重连…';

  @override
  String get lanSyncing => '正在同步主机棋局…';

  @override
  String get lanExitTitle => '退出游戏？';

  @override
  String get lanExitDescription => '这将断开连接。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAudioSection => '音频设置';

  @override
  String get settingsSoundToggle => '音效开关';

  @override
  String get settingsSoundDescription => '移动、吃子等游戏音效';

  @override
  String get settingsSoundVolume => '音效音量';

  @override
  String get settingsMusicToggle => '背景音乐';

  @override
  String get settingsMusicDescription => '游戏背景音乐';

  @override
  String get settingsMusicVolume => '音乐音量';

  @override
  String get settingsHapticsSection => '震动设置';

  @override
  String get settingsHapticsToggle => '震动反馈';

  @override
  String get settingsHapticsDescription => '触摸和游戏操作时的震动反馈';

  @override
  String get settingsLanguageSection => '语言';

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageDescription => '切换应用界面语言';

  @override
  String get settingsAiSection => 'AI 设置';

  @override
  String get settingsDefaultAiDifficulty => '默认 AI 难度';

  @override
  String get settingsDefaultAiDifficultyDescription => '新游戏的默认 AI 难度';

  @override
  String get settingsBoardThemeSection => '棋盘主题';

  @override
  String get settingsModernEasternTheme => '现代东方棋艺';

  @override
  String get settingsModernEasternThemeDescription => '一期默认主题；更多主题将在后续版本开放';

  @override
  String get settingsAnimationToggle => '动画效果';

  @override
  String get settingsAnimationDescription => '棋子移动和吃子动画';

  @override
  String get settingsParticleToggle => '粒子效果';

  @override
  String get settingsParticleDescription => '吃子与胜负反馈中的装饰效果';

  @override
  String get settingsPrivacyPerformanceSection => '隐私与性能';

  @override
  String get settingsAnonymousDiagnostics => '匿名诊断';

  @override
  String get settingsAnonymousDiagnosticsDescription =>
      '发送脱敏崩溃与性能信息；不含棋局内容和广告标识';

  @override
  String get settingsResourceWarmup => '资源预加载';

  @override
  String get settingsResourceWarmupDescription => '提前加载棋盘与音频资源，减少首次操作等待';

  @override
  String get settingsAboutSection => '关于';

  @override
  String get settingsVersion => '版本号';

  @override
  String get settingsReviewGuide => '重新查看游戏说明';

  @override
  String get settingsReviewGuideDescription => '查看新手引导和游戏规则';

  @override
  String get settingsOpenSourceLicenses => '开源许可';

  @override
  String get settingsDangerSection => '危险操作';

  @override
  String get settingsClearStatistics => '清空统计数据';

  @override
  String get settingsClearStatisticsConfirm => '将清空累计统计和最近 20 局回放。此操作无法撤销。';

  @override
  String get settingsStatisticsCleared => '统计与最近对局已清空';

  @override
  String get settingsResetAll => '重置所有设置';

  @override
  String get settingsResetAllConfirm => '确定要重置所有设置和数据吗？此操作无法撤销。';

  @override
  String get settingsResetAllDone => '已重置所有设置';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get clear => '清空';

  @override
  String get meditationTitle => '冥想对局';

  @override
  String get meditationEyebrow => '静 · 听 · 行';

  @override
  String get meditationDisclosureTitle => '先听见，再入局';

  @override
  String get meditationDisclosureBody =>
      '冥想模式使用中文单次语音指令完成行棋。每次只在你主动点击后聆听，不会连续开启麦克风。';

  @override
  String get meditationPrivacyNote => '当前核心不保存识别原文或录音。最终语音引擎的数据流向将在正式开放前核验。';

  @override
  String get meditationChineseOnly => '一期语音仅支持中文';

  @override
  String get meditationEnable => '了解并开启';

  @override
  String get meditationBegin => '播报开局';

  @override
  String get meditationListen => '听我行棋';

  @override
  String get meditationRepeat => '重复播报';

  @override
  String get meditationPause => '暂停';

  @override
  String get meditationResume => '继续';

  @override
  String get meditationExit => '结束对局';

  @override
  String get meditationConfirmExit => '确认弃局';

  @override
  String get meditationCancelExit => '继续对局';

  @override
  String get meditationLeave => '返回并保留存档';

  @override
  String get meditationPromptLabel => '当前播报';

  @override
  String meditationMoves(int count) {
    return '$count 手';
  }

  @override
  String meditationRemaining(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get meditationVoiceDisabled => '语音尚未开启';

  @override
  String get meditationVoicePreparing => '正在准备语音';

  @override
  String get meditationVoiceReady => '可以聆听';

  @override
  String get meditationVoiceListening => '正在聆听';

  @override
  String get meditationVoiceProcessing => '正在理解';

  @override
  String get meditationVoiceSpeaking => '正在播报';

  @override
  String get meditationVoiceReplay => '播报中断，可重试';

  @override
  String get meditationVoicePermissionDenied => '未获得麦克风权限';

  @override
  String get meditationVoiceUnavailable => '语音服务暂不可用';

  @override
  String get meditationVoiceInterrupted => '语音已中断';

  @override
  String get meditationVoiceFailed => '语音操作失败';

  @override
  String get meditationVoiceUnrecognized => '未听懂，请再说一次';

  @override
  String get meditationFinished => '本局已结束，正在确认对局记录';

  @override
  String get meditationPreparingTitle => '正在备好静心棋局';

  @override
  String get meditationPreparingBody => '先恢复权威对局，再创建语音服务。';

  @override
  String get meditationLoadFailedTitle => '暂时无法准备冥想对局';

  @override
  String get meditationLoadFailedBody => '语音和棋局细节没有显示，可重新加载本局。';

  @override
  String get meditationRetry => '重新加载';

  @override
  String get meditationNoSaveTitle => '没有可继续的冥想对局';

  @override
  String get meditationNoSaveBody => '此功能开放后，可从新建冥想对局开始。';

  @override
  String get gameVoiceTitle => '语音行棋';

  @override
  String get gameVoiceDisclosureBody =>
      '在人机对局中，可用单条中文语音选择或移动自己的棋子。每次只在按下按钮后聆听。';

  @override
  String get gameVoiceChineseOnly => 'Phase 4 首期仅支持中文语音输入';

  @override
  String get gameVoiceEnable => '启用语音行棋';

  @override
  String get gameVoiceListen => '聆听一条指令';

  @override
  String get gameVoiceWaitForTurn => '轮到您时才可使用语音行棋';

  @override
  String get gameVoiceSetupFailed => '暂时无法准备语音行棋，请在您的回合重试。';

  @override
  String get onlineBattleTitle => '在线对战';

  @override
  String get onlineIntroTitle => '可靠在线对局';

  @override
  String get onlineIntroBody => '服务器确认后才会更新棋盘。匿名身份仅用于匹配和断线恢复。';

  @override
  String get onlineFindOpponent => '寻找对手';

  @override
  String get onlineConnecting => '正在连接服务器…';

  @override
  String get onlineSearching => '正在寻找对手…';

  @override
  String get onlineCancelSearch => '取消匹配';

  @override
  String get onlineYourTurn => '你的回合';

  @override
  String get onlineOpponentTurn => '对手回合';

  @override
  String get onlineWaitingForServer => '等待服务器确认…';

  @override
  String get onlineOpponentDisconnected => '对手已断线，棋局仍由服务器计时';

  @override
  String onlineReconnectSeconds(int seconds) {
    return '对手还可在 $seconds 秒内重连';
  }

  @override
  String get onlineRecovering => '正在恢复权威棋局…';

  @override
  String get onlineRetry => '重试连接';

  @override
  String get onlineLeave => '离开对局';

  @override
  String get onlineYouWin => '你赢了';

  @override
  String get onlineYouLose => '你输了';

  @override
  String get onlineGameDraw => '本局和棋';

  @override
  String get onlineFinished => '对局已结束';

  @override
  String get onlineMoveRejected => '服务器未接受这一步，请根据当前棋盘重试';

  @override
  String onlineYourSide(String side) {
    return '你执 $side';
  }

  @override
  String get onlineFailureConnection => '无法连接在线服务';

  @override
  String get onlineFailureIdentity => '无法准备匿名在线身份';

  @override
  String get onlineFailureRequest => '请求未发送，请重试';

  @override
  String get onlineFailureMatch => '当前无法开始匹配';

  @override
  String get onlineFailureResume => '原对局已无法恢复';

  @override
  String get onlineFailureSnapshot => '无法取得最新棋局';

  @override
  String get onlineFailureProtocol => '收到无法识别的服务器消息';
}
