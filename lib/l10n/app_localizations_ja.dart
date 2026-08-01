// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '四子ゲーム';

  @override
  String get homeTagline => '動 · 囲 · 取 · 勝';

  @override
  String get developmentEdition => '現代東方棋芸 · 開発版 0.1.0';

  @override
  String get continueGame => '続きから';

  @override
  String get continueGameDescription => '前回の手から再開';

  @override
  String get playerVsPlayer => '二人対戦';

  @override
  String get playerVsPlayerDescription => '一台の端末で交互に指す';

  @override
  String get playerVsAI => 'AI 対戦';

  @override
  String get playerVsAIDescription => '初級 · 中級 · 上級';

  @override
  String get lanGame => 'LAN 対戦';

  @override
  String get lanGameDescription => '同じネットワークで対面対局';

  @override
  String get statistics => '戦績';

  @override
  String get rules => 'ルール';

  @override
  String get settings => '設定';

  @override
  String get chooseDifficulty => '難易度を選択';

  @override
  String get difficultyEasy => '初級';

  @override
  String get difficultyEasyDescription => 'ルールと指し方に慣れる';

  @override
  String get difficultyMedium => '中級';

  @override
  String get difficultyMediumDescription => '思考の深さと速さのバランス';

  @override
  String get difficultyHard => '上級';

  @override
  String get difficultyHardDescription => '局面をより深く読む';

  @override
  String get skip => 'スキップ';

  @override
  String get previous => '前へ';

  @override
  String get next => '次へ';

  @override
  String get startGame => '対局を始める';

  @override
  String get onboardingWelcomeTitle => '四子ゲーム';

  @override
  String get onboardingWelcomeSubtitle => '四方を制する戦略対局';

  @override
  String get onboardingWelcomeBody => '四方棋へようこそ！\nゲームのルールを簡単にご案内します。';

  @override
  String get onboardingBoardTitle => '盤と駒';

  @override
  String get onboardingBoardFourByFour => '4×4 の盤';

  @override
  String get onboardingBoardFourByFourDescription => '4×4 の交点盤で対局します';

  @override
  String get onboardingFourPieces => '各陣営 4 個';

  @override
  String get onboardingFourPiecesDescription => '墨方と玉方はそれぞれ 4 個の駒で始めます';

  @override
  String get onboardingMovementTitle => '移動ルール';

  @override
  String get onboardingOrthogonalMove => '上下左右へ移動';

  @override
  String get onboardingOrthogonalMoveDescription => '隣接する空き交点へ一つ移動します';

  @override
  String get onboardingNoDiagonal => '斜め移動は禁止';

  @override
  String get onboardingNoDiagonalDescription => '斜め移動、飛び越し、駒のある交点への移動はできません';

  @override
  String get onboardingCaptureTitle => '取り方';

  @override
  String get emptyCell => '空';

  @override
  String get ownPiece => '自';

  @override
  String get enemyPiece => '敵';

  @override
  String get onboardingExactPattern => '正確な四点配列';

  @override
  String get onboardingExactPatternDescription =>
      '「自-自-敵-空」または指定された反転形で敵駒を取ります';

  @override
  String get onboardingMovedPieceParticipates => '動かした駒が参加';

  @override
  String get onboardingMovedPieceParticipatesDescription =>
      '動かした駒が隣接する二駒の一つであること。縦横同時取りも可能です';

  @override
  String get onboardingFeaturesTitle => '主な機能';

  @override
  String get onboardingAiFeature => 'AI 対戦';

  @override
  String get onboardingAiFeatureDescription => '3 段階の AI と練習できます';

  @override
  String get onboardingReplayFeature => '棋譜再生';

  @override
  String get onboardingReplayFeatureDescription => '対局の一手一手を振り返れます';

  @override
  String get onboardingThemeFeature => '現代東方棋芸';

  @override
  String get onboardingThemeFeatureDescription => '第一期の統一テーマ。今後さらに追加予定です';

  @override
  String get onboardingStatisticsFeature => '戦績統計';

  @override
  String get onboardingStatisticsFeatureDescription => '端末内の対局データを確認できます';

  @override
  String get rulesTitle => '対局ルール';

  @override
  String get startInteractiveTutorial => '体験チュートリアルを開始';

  @override
  String get rulesSectionOne => '一';

  @override
  String get rulesSectionTwo => '二';

  @override
  String get rulesSectionThree => '三';

  @override
  String get rulesSectionFour => '四';

  @override
  String get rulesHeroTitle => '駒で形を作り、正確に取る';

  @override
  String get rulesHeroDescription => '画面、AI、棋譜再生、LAN 対戦を含む全モードで同じルールを使用します。';

  @override
  String get rulesBoardSection => '盤と移動';

  @override
  String get rulesBoardLine1 => '盤は 4×4。墨方と玉方はそれぞれ 4 個の駒を持ちます。';

  @override
  String get rulesBoardLine2 => '初局の先手はランダム。再戦では先手を交互に替えます。';

  @override
  String get rulesBoardLine3 => '自分の駒一つを上下左右に隣接する空き交点へ移動します。斜め移動や飛び越しは禁止です。';

  @override
  String get rulesBoardLine4 => '各手は 60 秒。オフライン対局はバックグラウンドで停止し、LAN 対局は継続します。';

  @override
  String get rulesCaptureSection => '正確な取り';

  @override
  String get rulesCaptureIntro => '動かした駒を含む完全な四点の横列と縦列だけを確認します。次の配列で「敵」を取れます：';

  @override
  String get rulesCaptureLine1 => '動かした駒は隣接する二つの自駒の一つでなければなりません。';

  @override
  String get rulesCaptureLine2 => '相手の手によって受動的にできた配列では取りは発生しません。';

  @override
  String get rulesCaptureLine3 => '横と縦は別々に判定し、一手で最大 2 個取れます。';

  @override
  String get rulesCaptureLine4 => '1100、1110、0110 など正確でない配列では取れません。';

  @override
  String get rulesEndingSection => '勝敗と引き分け';

  @override
  String get rulesEndingLine1 => '駒が 1 個以下になった陣営は直ちに負けです。';

  @override
  String get rulesEndingLine2 => '手番開始時に合法手がない陣営は負けです。';

  @override
  String get rulesEndingLine3 => '持ち時間が 0 になった手番側は負けです。';

  @override
  String get rulesEndingLine4 => '取りがない状態で 50 ply 続くと引き分け。取りがあればカウントを 0 に戻します。';

  @override
  String get rulesEndingLine5 => 'LAN 対戦の再接続猶予は 30 秒。超過すると切断した側の負けです。';

  @override
  String get rulesUndoSection => '取り消しと記録';

  @override
  String get rulesUndoLine1 => '二人対戦は 1 ply、AI 対戦はプレイヤーと AI の 2 ply をまとめて戻します。';

  @override
  String get rulesUndoLine2 => '取り消した手はやり直せます。新しい手を指すと、やり直し履歴は消えます。';

  @override
  String get rulesUndoLine3 => 'LAN 対戦は取り消せません。直近 20 局を一手ずつ再生できます。';

  @override
  String get tutorialTitle => '体験チュートリアル';

  @override
  String get tutorialStep1 => '左上の墨方の駒を選んでください。';

  @override
  String get tutorialStep2 => 'その駒を一つ下の空き交点へ動かしてください。';

  @override
  String get tutorialStep3 => '移動完了です。実戦では一手 60 秒で、交互に駒を動かします。';

  @override
  String get tutorialStep4 =>
      '取りには完全な「自-自-敵-空」または指定された反転形が必要です。動かした駒は隣接する二駒に含まれます。';

  @override
  String get tutorialStep5 => '縦横で同時に取れます。駒が一つ、合法手なし、または時間切れで負けです。';

  @override
  String get finishTutorial => 'チュートリアルを終了';

  @override
  String get tutorialCapturePatternSemantics => '有効な取りの配列：自、自、敵、空';

  @override
  String get gameTitle => '四子ゲーム';

  @override
  String get gameUnavailable => '現在この対局を続けられません';

  @override
  String get restart => '最初から';

  @override
  String get restartConfirmTitle => '対局をやり直す';

  @override
  String get restartConfirmBody => '現在の進行を破棄して最初からやり直しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get pvpReplayTitle => '二人対戦の棋譜';

  @override
  String get pveReplayTitle => 'AI 対戦の棋譜';

  @override
  String get lanReplayTitle => 'LAN 対戦の棋譜';

  @override
  String get blackSide => '墨方';

  @override
  String get whiteSide => '玉方';

  @override
  String get blackTurn => '墨方の手番';

  @override
  String get whiteTurn => '玉方の手番';

  @override
  String firstPlayerAnnouncement(String side) {
    return '$sideが先手';
  }

  @override
  String get gameStarting => 'まもなく対局開始';

  @override
  String boardCellPosition(int row, int column) {
    return '$row 行 $column 列';
  }

  @override
  String get boardEmptyPosition => '空き交点';

  @override
  String get boardSelected => '選択中';

  @override
  String get boardLegalDestination => '移動可能な交点';

  @override
  String get boardSelectablePiece => '選択できる駒';

  @override
  String get boardPreviousMoveStart => '直前の手の開始点';

  @override
  String get boardPreviousMoveEnd => '直前の手の到着点';

  @override
  String get aiThinking => 'AI が思考中';

  @override
  String turnSecondsRemaining(int seconds) {
    return 'この手の残り時間は $seconds 秒';
  }

  @override
  String secondsCount(int seconds) {
    return '$seconds 秒';
  }

  @override
  String moveHistoryCount(int count) {
    return '棋譜（$count 手）';
  }

  @override
  String get noMoveHistory => 'まだ指し手はありません';

  @override
  String get undo => '取り消す';

  @override
  String get redo => 'やり直す';

  @override
  String get gameOver => '対局終了';

  @override
  String get blackWins => '墨方の勝利！';

  @override
  String get whiteWins => '玉方の勝利！';

  @override
  String get draw => '引き分け';

  @override
  String get exit => '退出';

  @override
  String get playAgain => 'もう一局';

  @override
  String get viewReplay => '棋譜を見る';

  @override
  String get endReasonPieceCountBlack => '玉方は駒が 1 個以下のため敗北';

  @override
  String get endReasonPieceCountWhite => '墨方は駒が 1 個以下のため敗北';

  @override
  String get endReasonNoLegalMovesBlack => '玉方は合法手がないため敗北';

  @override
  String get endReasonNoLegalMovesWhite => '墨方は合法手がないため敗北';

  @override
  String get endReasonNoCaptureLimit => '取りなしで 50 手続いたため引き分け';

  @override
  String get endReasonTimeoutBlack => '玉方は時間切れのため敗北';

  @override
  String get endReasonTimeoutWhite => '墨方は時間切れのため敗北';

  @override
  String get endReasonDisconnectBlack => '玉方は切断が 30 秒を超えたため敗北';

  @override
  String get endReasonDisconnectWhite => '墨方は切断が 30 秒を超えたため敗北';

  @override
  String get endReasonAbandonedBlack => '玉方が投了しました';

  @override
  String get endReasonAbandonedWhite => '墨方が投了しました';

  @override
  String get endReasonUnknown => '対局は終了しました';

  @override
  String get historyTitle => '最近の対局';

  @override
  String get refresh => '更新';

  @override
  String get historyEmptyTitle => '完了した対局はまだありません';

  @override
  String get historyEmptyDescription => '対局を終えると、直近 20 局の棋譜を一手ずつ再生できます。';

  @override
  String get modePvp => '二人対戦';

  @override
  String get modePve => 'AI 対戦';

  @override
  String get modeLan => 'LAN';

  @override
  String modePveWithDifficulty(String difficulty) {
    return 'AI · $difficulty';
  }

  @override
  String resultSideWins(String side) {
    return '$sideの勝利';
  }

  @override
  String get resultFinished => '終了';

  @override
  String historySummary(int moves, int captures, String date) {
    return '$moves 手 · $captures 個取得 · $date';
  }

  @override
  String dateMonthDayTime(int month, int day, String time) {
    return '$month月$day日 $time';
  }

  @override
  String get replayTitle => '棋譜再生';

  @override
  String get replayHelp => '再生ガイド';

  @override
  String get replayInitial => '初期局面';

  @override
  String replayStepLabel(int step) {
    return '第 $step 手';
  }

  @override
  String replayProgress(int step, int total) {
    return '$total 手中の第 $step 手';
  }

  @override
  String moveDescription(String from, String to) {
    return '$from → $to';
  }

  @override
  String moveDescriptionCapture(String from, String to, int count) {
    return '$from → $to，$count 個取得';
  }

  @override
  String get replayFirst => '最初の手';

  @override
  String get replayPrevious => '前の手';

  @override
  String get replayNext => '次の手';

  @override
  String get replayLast => '最後の手';

  @override
  String get replayControlsHeading => '操作方法：';

  @override
  String get replayHelpSlider => 'スライダーで任意の手へ移動できます';

  @override
  String get replayHelpButtons => 'ボタンで一手ずつ再生できます';

  @override
  String get replayHelpHistory => '棋譜を選ぶとその手へ移動します';

  @override
  String get replayFeaturesHeading => '表示内容：';

  @override
  String get replayHelpReadonly => '再生中の盤は操作できません';

  @override
  String get replayHelpHighlight => '現在の指し手を強調表示します';

  @override
  String get replayHelpCapture => '× 印は駒を取った手です';

  @override
  String get gotIt => '了解';

  @override
  String get statisticsTitle => '対局統計';

  @override
  String get statisticsResetTitle => '統計をリセット';

  @override
  String get statisticsResetConfirm => '累計統計と直近 20 局の棋譜を消去します。元に戻せません。続けますか？';

  @override
  String get statisticsResetAction => 'リセット';

  @override
  String get statisticsResetDone => '統計と最近の対局をリセットしました';

  @override
  String get statisticsResetFailed => 'リセットできませんでした。後でもう一度お試しください';

  @override
  String get statisticsHistoryTooltip => '最近の対局と棋譜';

  @override
  String get statisticsOverviewTitle => '棋譜の概要';

  @override
  String get statisticsOverviewDescription => '異なる対局モードの勝敗を混ぜず、一手ずつ記録します。';

  @override
  String get statisticsTotalGames => '累計対局';

  @override
  String get statisticsTotalMoves => '累計手数';

  @override
  String get statisticsAverageMoves => '平均手数';

  @override
  String get statisticsTotalCaptures => '累計取得数';

  @override
  String statisticsLastMove(String date) {
    return '最終対局：$date';
  }

  @override
  String get statisticsNoRecord => '記録なし';

  @override
  String get statisticsRecentTitle => '最近の対局';

  @override
  String get statisticsRecentEyebrow => '最近の成績';

  @override
  String get statisticsRecentEmpty => '対局を終えると、モード別の結果を表示します。';

  @override
  String statisticsRecentDescription(int count) {
    return '端末に保存された直近 $count 局のみを使用し、累計統計とは別に集計します。';
  }

  @override
  String get statisticsPvpTitle => '二人対戦 · 直近 20 局';

  @override
  String get statisticsPvpWin => '墨方勝ち';

  @override
  String get statisticsPvpLoss => '玉方勝ち';

  @override
  String get statisticsPvpNote => '二人対戦は陣営別に記録し、個人勝率は計算しません。';

  @override
  String get statisticsPveTitle => 'AI 対戦 · 直近 20 局';

  @override
  String get statisticsPveWin => 'プレイヤー勝ち';

  @override
  String get statisticsPveLoss => 'AI 勝ち';

  @override
  String get statisticsPveNote => '端末のプレイヤーが担当した陣営で計算します。';

  @override
  String get statisticsLanTitle => 'LAN · 直近 20 局';

  @override
  String get statisticsLanWin => '自端末の勝ち';

  @override
  String get statisticsLanLoss => '自端末の負け';

  @override
  String get statisticsLanNote => 'LAN 対局で自端末が担当した陣営から計算します。';

  @override
  String statisticsDrawCount(int count) {
    return '引き分け $count';
  }

  @override
  String statisticsUnknownCount(int count) {
    return '不明 $count';
  }

  @override
  String statisticsNoModeRecord(String note) {
    return 'このモードの記録はありません。$note';
  }

  @override
  String get statisticsUnavailable => '統計データを読み込めません';

  @override
  String get reload => '再読み込み';

  @override
  String get lanTitle => 'LAN 対戦';

  @override
  String get lanCreateRoomTab => '部屋を作る';

  @override
  String get lanJoinRoomTab => '部屋に入る';

  @override
  String get lanConnectedTitle => '対局に接続しました';

  @override
  String get lanConnectedDescription => '対局画面へ移動します。しばらくお待ちください。';

  @override
  String get lanDisconnect => '切断';

  @override
  String get lanWaitingTitle => '参加者を待っています';

  @override
  String lanRoomNameValue(String name) {
    return '部屋名：$name';
  }

  @override
  String get lanCancelCreate => '作成を中止';

  @override
  String get lanCreateHeading => '対局室を作る';

  @override
  String get lanCreateDescription => '同じ LAN 内のプレイヤーが見つけて参加できます。';

  @override
  String get lanRoomNameLabel => '部屋名';

  @override
  String get lanDefaultRoomName => '私の対局室';

  @override
  String get lanCreateRoom => '部屋を作成';

  @override
  String get lanNearbyRooms => '近くの部屋';

  @override
  String get lanStopSearch => '検索を停止';

  @override
  String get lanSearch => '近くの部屋を検索';

  @override
  String get lanUnnamedRoom => '名前のない部屋';

  @override
  String get lanUnknownAddress => '不明なアドレス';

  @override
  String get lanJoin => '参加';

  @override
  String get lanSearching => '近くの対局室を検索中…';

  @override
  String get lanNoRooms => '部屋が見つかりません';

  @override
  String get lanSearchingHint => '両方の端末を同じネットワークに接続してください。';

  @override
  String get lanSearchHint => '右上の検索ボタンで部屋を探します。';

  @override
  String get lanDiscoveryFailed =>
      '近くの部屋を検索できません。両方の端末が同じネットワークにあることを確認し、もう一度お試しください。';

  @override
  String get lanHostingFailed => '部屋を作成できません。ローカルネットワークを確認し、もう一度お試しください。';

  @override
  String get lanConnectionFailed => '部屋に参加できません。相手の部屋がまだ利用できるか確認してください。';

  @override
  String get lanOpponentLeft => '相手が対局を退出しました';

  @override
  String get lanGameError => 'LAN 対局でエラーが発生しました。退出してもう一度お試しください。';

  @override
  String get lanUnknownState => '不明な状態';

  @override
  String get lanReconnecting => '接続が切れました。再接続を待っています…';

  @override
  String get lanSyncing => 'ホストの局面を同期中…';

  @override
  String get lanExitTitle => '対局を退出しますか？';

  @override
  String get lanExitDescription => '対局との接続が切れます。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAudioSection => 'オーディオ';

  @override
  String get settingsSoundToggle => '効果音';

  @override
  String get settingsSoundDescription => '移動や取りなどのゲーム効果音';

  @override
  String get settingsSoundVolume => '効果音の音量';

  @override
  String get settingsMusicToggle => 'BGM';

  @override
  String get settingsMusicDescription => '対局中の背景音楽';

  @override
  String get settingsMusicVolume => 'BGM の音量';

  @override
  String get settingsHapticsSection => '振動';

  @override
  String get settingsHapticsToggle => '触覚フィードバック';

  @override
  String get settingsHapticsDescription => 'タッチやゲーム操作時の振動';

  @override
  String get settingsLanguageSection => '言語';

  @override
  String get settingsLanguage => '表示言語';

  @override
  String get settingsLanguageDescription => 'アプリの表示言語を切り替えます';

  @override
  String get settingsAiSection => 'AI 設定';

  @override
  String get settingsDefaultAiDifficulty => '既定の AI 難易度';

  @override
  String get settingsDefaultAiDifficultyDescription => '新しい AI 対局で使用する難易度';

  @override
  String get settingsBoardThemeSection => '盤のテーマ';

  @override
  String get settingsModernEasternTheme => '現代東方棋芸';

  @override
  String get settingsModernEasternThemeDescription => '第一期の既定テーマ。今後さらに追加予定です';

  @override
  String get settingsAnimationToggle => 'アニメーション';

  @override
  String get settingsAnimationDescription => '駒の移動と取りのアニメーション';

  @override
  String get settingsParticleToggle => 'パーティクル効果';

  @override
  String get settingsParticleDescription => '取りや勝敗を演出する装飾効果';

  @override
  String get settingsPrivacyPerformanceSection => 'プライバシーと性能';

  @override
  String get settingsAnonymousDiagnostics => '匿名診断';

  @override
  String get settingsAnonymousDiagnosticsDescription =>
      '匿名化したクラッシュ・性能情報を送信します。棋譜や広告 ID は含みません';

  @override
  String get settingsResourceWarmup => 'リソースを事前読込';

  @override
  String get settingsResourceWarmupDescription => '盤と音声を先に読み込み、初回操作の待ち時間を減らします';

  @override
  String get settingsAboutSection => 'このアプリについて';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsReviewGuide => 'ゲームガイドをもう一度見る';

  @override
  String get settingsReviewGuideDescription => '初回ガイドとゲームルールを確認します';

  @override
  String get settingsOpenSourceLicenses => 'オープンソースライセンス';

  @override
  String get settingsDangerSection => 'データ操作';

  @override
  String get settingsClearStatistics => '統計を消去';

  @override
  String get settingsClearStatisticsConfirm => '累計統計と直近 20 局の棋譜を消去します。元に戻せません。';

  @override
  String get settingsStatisticsCleared => '統計と最近の対局を消去しました';

  @override
  String get settingsResetAll => 'すべての設定をリセット';

  @override
  String get settingsResetAllConfirm => 'すべての設定とデータをリセットしますか？元に戻せません。';

  @override
  String get settingsResetAllDone => 'すべての設定をリセットしました';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get clear => '消去';

  @override
  String get meditationTitle => '瞑想対局';

  @override
  String get meditationEyebrow => '静 · 聴 · 行';

  @override
  String get meditationDisclosureTitle => '音を聴いてから対局へ';

  @override
  String get meditationDisclosureBody =>
      '瞑想モードは中国語の音声指示を1回ずつ使用します。聴き取りボタンを押した時だけマイクを使用し、常時は起動しません。';

  @override
  String get meditationPrivacyNote =>
      '現在のコアは認識文や録音を保存しません。最終音声エンジンのデータフローは公開前に確認します。';

  @override
  String get meditationChineseOnly => 'Phase 4 の音声は中国語のみ';

  @override
  String get meditationEnable => '理解して有効にする';

  @override
  String get meditationBegin => '開局を読み上げる';

  @override
  String get meditationListen => '私の手を聴く';

  @override
  String get meditationRepeat => 'もう一度読み上げる';

  @override
  String get meditationPause => '一時停止';

  @override
  String get meditationResume => '再開';

  @override
  String get meditationExit => '対局を終える';

  @override
  String get meditationConfirmExit => '投了を確認';

  @override
  String get meditationCancelExit => '対局を続ける';

  @override
  String get meditationLeave => '保存して戻る';

  @override
  String get meditationPromptLabel => '現在の読み上げ';

  @override
  String meditationMoves(int count) {
    return '$count 手';
  }

  @override
  String meditationRemaining(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get meditationVoiceDisabled => '音声は無効です';

  @override
  String get meditationVoicePreparing => '音声を準備中';

  @override
  String get meditationVoiceReady => '聴き取り可能';

  @override
  String get meditationVoiceListening => '聴き取り中';

  @override
  String get meditationVoiceProcessing => '解釈中';

  @override
  String get meditationVoiceSpeaking => '読み上げ中';

  @override
  String get meditationVoiceReplay => '読み上げが中断されました';

  @override
  String get meditationVoicePermissionDenied => 'マイク権限がありません';

  @override
  String get meditationVoiceUnavailable => '音声サービスを利用できません';

  @override
  String get meditationVoiceInterrupted => '音声が中断されました';

  @override
  String get meditationVoiceFailed => '音声操作に失敗しました';

  @override
  String get meditationVoiceUnrecognized => '聞き取れませんでした。もう一度お話しください';

  @override
  String get meditationFinished => '対局終了。対局記録を確認しています';

  @override
  String get meditationPreparingTitle => '静かな盤面を準備中';

  @override
  String get meditationPreparingBody => '正式な対局を復元してから音声サービスを作成します。';

  @override
  String get meditationLoadFailedTitle => '瞑想対局を準備できませんでした';

  @override
  String get meditationLoadFailedBody => '音声や対局の詳細は表示されていません。もう一度読み込めます。';

  @override
  String get meditationRetry => 'もう一度読み込む';

  @override
  String get meditationNoSaveTitle => '再開できる瞑想対局はありません';

  @override
  String get meditationNoSaveBody => 'この機能の公開後、新しい瞑想対局を開始できます。';

  @override
  String get onlineBattleTitle => 'オンライン対局';

  @override
  String get onlineIntroTitle => '信頼できるオンライン対局';

  @override
  String get onlineIntroBody =>
      '盤面はサーバーの確認後にのみ更新されます。匿名 ID はマッチングと再接続にだけ使用します。';

  @override
  String get onlineFindOpponent => '対戦相手を探す';

  @override
  String get onlineConnecting => 'サーバーに接続しています…';

  @override
  String get onlineSearching => '対戦相手を探しています…';

  @override
  String get onlineCancelSearch => 'マッチングをキャンセル';

  @override
  String get onlineYourTurn => 'あなたの手番';

  @override
  String get onlineOpponentTurn => '相手の手番';

  @override
  String get onlineWaitingForServer => 'サーバーの確認を待っています…';

  @override
  String get onlineOpponentDisconnected => '相手が切断しました。サーバーの時計は進みます';

  @override
  String onlineReconnectSeconds(int seconds) {
    return '相手はあと $seconds 秒以内に再接続できます';
  }

  @override
  String get onlineRecovering => '正式な局面を復元しています…';

  @override
  String get onlineRetry => '再接続';

  @override
  String get onlineLeave => '対局を退出';

  @override
  String get onlineYouWin => 'あなたの勝ち';

  @override
  String get onlineYouLose => 'あなたの負け';

  @override
  String get onlineGameDraw => '引き分け';

  @override
  String get onlineFinished => '対局終了';

  @override
  String get onlineMoveRejected => 'その手はサーバーに受理されませんでした。現在の盤面から指し直してください。';

  @override
  String onlineYourSide(String side) {
    return 'あなたは $side';
  }

  @override
  String get onlineFailureConnection => 'オンラインサービスに接続できません';

  @override
  String get onlineFailureIdentity => '匿名オンライン ID を準備できません';

  @override
  String get onlineFailureRequest => 'リクエストを送信できませんでした。再試行してください。';

  @override
  String get onlineFailureMatch => '現在マッチングを開始できません';

  @override
  String get onlineFailureResume => '以前の対局は復元できません';

  @override
  String get onlineFailureSnapshot => '最新の局面を取得できません';

  @override
  String get onlineFailureProtocol => 'サーバーから未対応のメッセージを受信しました';
}
