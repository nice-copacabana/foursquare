// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Four Square Game';

  @override
  String get homeTagline => 'MOVE · FORM · CAPTURE · WIN';

  @override
  String get developmentEdition => 'Modern Eastern · Development 0.1.0';

  @override
  String get continueGame => 'Continue';

  @override
  String get continueGameDescription => 'Resume from your last move';

  @override
  String get playerVsPlayer => 'Two Players';

  @override
  String get playerVsPlayerDescription => 'Take turns on one device';

  @override
  String get playerVsAI => 'Play against AI';

  @override
  String get playerVsAIDescription => 'Easy · Medium · Hard';

  @override
  String get lanGame => 'LAN Game';

  @override
  String get lanGameDescription => 'Play face to face on the same network';

  @override
  String get statistics => 'Records';

  @override
  String get rules => 'Rules';

  @override
  String get settings => 'Settings';

  @override
  String get chooseDifficulty => 'Choose difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyEasyDescription => 'Learn the rules and moves';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyMediumDescription => 'Balanced depth and speed';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyHardDescription => 'Calculate positions more deeply';

  @override
  String get skip => 'Skip';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get startGame => 'Start playing';

  @override
  String get onboardingWelcomeTitle => 'Four Square Game';

  @override
  String get onboardingWelcomeSubtitle => 'A compact game of strategy';

  @override
  String get onboardingWelcomeBody =>
      'Welcome to Four Square!\nHere is a quick guide to the rules.';

  @override
  String get onboardingBoardTitle => 'Board and pieces';

  @override
  String get onboardingBoardFourByFour => '4×4 board';

  @override
  String get onboardingBoardFourByFourDescription =>
      'The game is played on a 4×4 intersection board';

  @override
  String get onboardingFourPieces => 'Four pieces each';

  @override
  String get onboardingFourPiecesDescription =>
      'Ink and Jade each start with four pieces';

  @override
  String get onboardingMovementTitle => 'Movement';

  @override
  String get onboardingOrthogonalMove => 'Move orthogonally';

  @override
  String get onboardingOrthogonalMoveDescription =>
      'A piece moves to an adjacent empty point';

  @override
  String get onboardingNoDiagonal => 'No diagonal moves';

  @override
  String get onboardingNoDiagonalDescription =>
      'Pieces cannot move diagonally, jump, or land on an occupied point';

  @override
  String get onboardingCaptureTitle => 'Capturing';

  @override
  String get emptyCell => 'Empty';

  @override
  String get ownPiece => 'Own';

  @override
  String get enemyPiece => 'Foe';

  @override
  String get onboardingExactPattern => 'Exact four-point pattern';

  @override
  String get onboardingExactPatternDescription =>
      'Capture with Own-Own-Foe-Empty or one of its specified reversals';

  @override
  String get onboardingMovedPieceParticipates =>
      'The moved piece must participate';

  @override
  String get onboardingMovedPieceParticipatesDescription =>
      'It must be in the adjacent pair; one move may capture on both axes';

  @override
  String get onboardingFeaturesTitle => 'Features';

  @override
  String get onboardingAiFeature => 'AI games';

  @override
  String get onboardingAiFeatureDescription =>
      'Practise against three AI levels';

  @override
  String get onboardingReplayFeature => 'Replays';

  @override
  String get onboardingReplayFeatureDescription =>
      'Review every move of a completed game';

  @override
  String get onboardingThemeFeature => 'Modern Eastern';

  @override
  String get onboardingThemeFeatureDescription =>
      'The first theme, with more planned later';

  @override
  String get onboardingStatisticsFeature => 'Game records';

  @override
  String get onboardingStatisticsFeatureDescription =>
      'Review your local game data';

  @override
  String get rulesTitle => 'Rules';

  @override
  String get startInteractiveTutorial => 'Start interactive tutorial';

  @override
  String get rulesSectionOne => '1';

  @override
  String get rulesSectionTwo => '2';

  @override
  String get rulesSectionThree => '3';

  @override
  String get rulesSectionFour => '4';

  @override
  String get rulesHeroTitle => 'Form a position. Capture precisely.';

  @override
  String get rulesHeroDescription =>
      'Every mode uses these same rules, including the interface, AI, replays, and LAN games.';

  @override
  String get rulesBoardSection => 'Board and movement';

  @override
  String get rulesBoardLine1 =>
      'The board is 4×4. Ink and Jade each have four pieces.';

  @override
  String get rulesBoardLine2 =>
      'The first player is random in game one and alternates in rematches.';

  @override
  String get rulesBoardLine3 =>
      'Move one piece to an orthogonally adjacent empty point. No diagonal moves or jumps.';

  @override
  String get rulesBoardLine4 =>
      'Each turn lasts 60 seconds. Offline clocks pause in the background; LAN clocks continue.';

  @override
  String get rulesCaptureSection => 'Exact captures';

  @override
  String get rulesCaptureIntro =>
      'Only the moved piece\'s complete four-point row and column are checked. These patterns capture Foe:';

  @override
  String get rulesCaptureLine1 =>
      'The moved piece must be one of the adjacent Own pair.';

  @override
  String get rulesCaptureLine2 =>
      'A pattern formed passively by the opponent\'s move does not capture.';

  @override
  String get rulesCaptureLine3 =>
      'Row and column are independent, so one move can capture up to two pieces.';

  @override
  String get rulesCaptureLine4 =>
      'Inexact patterns such as 1100, 1110, and 0110 do not capture.';

  @override
  String get rulesEndingSection => 'Wins and draws';

  @override
  String get rulesEndingLine1 =>
      'A side immediately loses when it has one piece or fewer.';

  @override
  String get rulesEndingLine2 =>
      'A side loses if it has no legal move when its turn begins.';

  @override
  String get rulesEndingLine3 =>
      'The current side loses when its turn clock reaches zero.';

  @override
  String get rulesEndingLine4 =>
      'The game is drawn after 50 consecutive plies without a capture; any capture resets the count.';

  @override
  String get rulesEndingLine5 =>
      'LAN games allow 30 seconds to reconnect; after that the disconnected side loses.';

  @override
  String get rulesUndoSection => 'Undo and records';

  @override
  String get rulesUndoLine1 =>
      'Two-player games undo one ply; AI games undo the player and AI pair of plies.';

  @override
  String get rulesUndoLine2 =>
      'You can redo after undoing. A new move clears the redo branch.';

  @override
  String get rulesUndoLine3 =>
      'LAN games cannot be undone. The last 20 completed games can be replayed move by move.';

  @override
  String get tutorialTitle => 'Interactive tutorial';

  @override
  String get tutorialStep1 => 'Select the Ink piece at the top left.';

  @override
  String get tutorialStep2 =>
      'Good. Move it to the adjacent empty point below.';

  @override
  String get tutorialStep3 =>
      'Move complete. In a real game, players alternate with 60 seconds per turn.';

  @override
  String get tutorialStep4 =>
      'A capture must match the full Own-Own-Foe-Empty pattern or a specified reversal. The moved piece must be in the pair.';

  @override
  String get tutorialStep5 =>
      'A move can capture on both axes. A side loses with one piece, no legal move, or a timeout.';

  @override
  String get finishTutorial => 'Finish tutorial';

  @override
  String get tutorialCapturePatternSemantics =>
      'Allowed capture pattern: Own, Own, Foe, Empty';

  @override
  String get gameTitle => 'Four Square Game';

  @override
  String get gameUnavailable => 'This game cannot continue right now';

  @override
  String get restart => 'Restart';

  @override
  String get restartConfirmTitle => 'Restart game';

  @override
  String get restartConfirmBody => 'Restart and discard the current progress?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get pvpReplayTitle => 'Two-player replay';

  @override
  String get pveReplayTitle => 'AI game replay';

  @override
  String get lanReplayTitle => 'LAN game replay';

  @override
  String get blackSide => 'Ink';

  @override
  String get whiteSide => 'Jade';

  @override
  String get blackTurn => 'Ink\'s turn';

  @override
  String get whiteTurn => 'Jade\'s turn';

  @override
  String firstPlayerAnnouncement(String side) {
    return '$side moves first';
  }

  @override
  String get gameStarting => 'The game is about to begin';

  @override
  String boardCellPosition(int row, int column) {
    return 'Row $row, column $column';
  }

  @override
  String get boardEmptyPosition => 'Empty point';

  @override
  String get boardSelected => 'Selected';

  @override
  String get boardLegalDestination => 'Legal destination';

  @override
  String get boardSelectablePiece => 'Selectable piece';

  @override
  String get boardPreviousMoveStart => 'Previous move start';

  @override
  String get boardPreviousMoveEnd => 'Previous move end';

  @override
  String get aiThinking => 'AI is thinking';

  @override
  String turnSecondsRemaining(int seconds) {
    return '$seconds seconds left this turn';
  }

  @override
  String secondsCount(int seconds) {
    return '$seconds sec';
  }

  @override
  String moveHistoryCount(int count) {
    return 'Move history ($count)';
  }

  @override
  String get noMoveHistory => 'No moves yet';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get gameOver => 'Game over';

  @override
  String get blackWins => 'Ink wins!';

  @override
  String get whiteWins => 'Jade wins!';

  @override
  String get draw => 'Draw';

  @override
  String get exit => 'Exit';

  @override
  String get playAgain => 'Play again';

  @override
  String get viewReplay => 'View replay';

  @override
  String get endReasonPieceCountBlack =>
      'Jade has one piece or fewer and loses';

  @override
  String get endReasonPieceCountWhite => 'Ink has one piece or fewer and loses';

  @override
  String get endReasonNoLegalMovesBlack => 'Jade has no legal move and loses';

  @override
  String get endReasonNoLegalMovesWhite => 'Ink has no legal move and loses';

  @override
  String get endReasonNoCaptureLimit => 'Draw after 50 moves without a capture';

  @override
  String get endReasonTimeoutBlack => 'Jade ran out of time and loses';

  @override
  String get endReasonTimeoutWhite => 'Ink ran out of time and loses';

  @override
  String get endReasonDisconnectBlack =>
      'Jade was disconnected for over 30 seconds and loses';

  @override
  String get endReasonDisconnectWhite =>
      'Ink was disconnected for over 30 seconds and loses';

  @override
  String get endReasonAbandonedBlack => 'Jade resigned';

  @override
  String get endReasonAbandonedWhite => 'Ink resigned';

  @override
  String get endReasonUnknown => 'The game has ended';

  @override
  String get historyTitle => 'Recent games';

  @override
  String get refresh => 'Refresh';

  @override
  String get historyEmptyTitle => 'No completed games yet';

  @override
  String get historyEmptyDescription =>
      'Complete a game to review and replay any of the most recent 20 games.';

  @override
  String get modePvp => 'Two players';

  @override
  String get modePve => 'AI';

  @override
  String get modeLan => 'LAN';

  @override
  String modePveWithDifficulty(String difficulty) {
    return 'AI · $difficulty';
  }

  @override
  String resultSideWins(String side) {
    return '$side wins';
  }

  @override
  String get resultFinished => 'Completed';

  @override
  String historySummary(int moves, int captures, String date) {
    return '$moves moves · $captures captures · $date';
  }

  @override
  String dateMonthDayTime(int month, int day, String time) {
    return '$month/$day $time';
  }

  @override
  String get replayTitle => 'Game replay';

  @override
  String get replayHelp => 'Replay guide';

  @override
  String get replayInitial => 'Initial';

  @override
  String replayStepLabel(int step) {
    return 'Move $step';
  }

  @override
  String replayProgress(int step, int total) {
    return 'Move $step of $total';
  }

  @override
  String moveDescription(String from, String to) {
    return '$from → $to';
  }

  @override
  String moveDescriptionCapture(String from, String to, int count) {
    return '$from → $to, $count captured';
  }

  @override
  String get replayFirst => 'First move';

  @override
  String get replayPrevious => 'Previous move';

  @override
  String get replayNext => 'Next move';

  @override
  String get replayLast => 'Last move';

  @override
  String get replayControlsHeading => 'Controls:';

  @override
  String get replayHelpSlider => 'Use the slider to jump to any move';

  @override
  String get replayHelpButtons => 'Use the buttons to step through moves';

  @override
  String get replayHelpHistory => 'Select a history item to jump to it';

  @override
  String get replayFeaturesHeading => 'Details:';

  @override
  String get replayHelpReadonly => 'The replay board is read-only';

  @override
  String get replayHelpHighlight => 'The current move is highlighted';

  @override
  String get replayHelpCapture => 'A × marks a move that captured a piece';

  @override
  String get gotIt => 'Got it';

  @override
  String get statisticsTitle => 'Game records';

  @override
  String get statisticsResetTitle => 'Reset records';

  @override
  String get statisticsResetConfirm =>
      'This clears aggregate statistics and the last 20 replays. This cannot be undone. Continue?';

  @override
  String get statisticsResetAction => 'Reset';

  @override
  String get statisticsResetDone => 'Statistics and recent games were reset';

  @override
  String get statisticsResetFailed => 'Could not reset. Try again later.';

  @override
  String get statisticsHistoryTooltip => 'Recent games and replays';

  @override
  String get statisticsOverviewTitle => 'Record overview';

  @override
  String get statisticsOverviewDescription =>
      'Every move is recorded without mixing outcomes from different game modes.';

  @override
  String get statisticsTotalGames => 'Total games';

  @override
  String get statisticsTotalMoves => 'Total moves';

  @override
  String get statisticsAverageMoves => 'Average moves';

  @override
  String get statisticsTotalCaptures => 'Total captures';

  @override
  String statisticsLastMove(String date) {
    return 'Last played: $date';
  }

  @override
  String get statisticsNoRecord => 'No records yet';

  @override
  String get statisticsRecentTitle => 'Recent games';

  @override
  String get statisticsRecentEyebrow => 'RECENT FORM';

  @override
  String get statisticsRecentEmpty =>
      'Complete a game to see outcomes by mode here.';

  @override
  String statisticsRecentDescription(int count) {
    return 'Based only on the latest $count games stored on this device, separate from aggregate statistics.';
  }

  @override
  String get statisticsPvpTitle => 'Two players · Last 20';

  @override
  String get statisticsPvpWin => 'Ink wins';

  @override
  String get statisticsPvpLoss => 'Jade wins';

  @override
  String get statisticsPvpNote =>
      'Two-player outcomes are by side, not personal win rate.';

  @override
  String get statisticsPveTitle => 'AI games · Last 20';

  @override
  String get statisticsPveWin => 'Player wins';

  @override
  String get statisticsPveLoss => 'AI wins';

  @override
  String get statisticsPveNote => 'Calculated from the local player\'s side.';

  @override
  String get statisticsLanTitle => 'LAN · Last 20';

  @override
  String get statisticsLanWin => 'Local wins';

  @override
  String get statisticsLanLoss => 'Local losses';

  @override
  String get statisticsLanNote =>
      'Calculated from the local side in each LAN game.';

  @override
  String statisticsDrawCount(int count) {
    return 'Draws $count';
  }

  @override
  String statisticsUnknownCount(int count) {
    return 'Unknown $count';
  }

  @override
  String statisticsNoModeRecord(String note) {
    return 'No games in this mode. $note';
  }

  @override
  String get statisticsUnavailable => 'Statistics are temporarily unavailable';

  @override
  String get reload => 'Reload';

  @override
  String get lanTitle => 'LAN game';

  @override
  String get lanCreateRoomTab => 'Create room';

  @override
  String get lanJoinRoomTab => 'Join room';

  @override
  String get lanConnectedTitle => 'Connected';

  @override
  String get lanConnectedDescription => 'Entering the game. Please wait.';

  @override
  String get lanDisconnect => 'Disconnect';

  @override
  String get lanWaitingTitle => 'Waiting for another player';

  @override
  String lanRoomNameValue(String name) {
    return 'Room: $name';
  }

  @override
  String get lanCancelCreate => 'Cancel room';

  @override
  String get lanCreateHeading => 'Create a game room';

  @override
  String get lanCreateDescription =>
      'Players on the same local network can discover and join it.';

  @override
  String get lanRoomNameLabel => 'Room name';

  @override
  String get lanDefaultRoomName => 'My room';

  @override
  String get lanCreateRoom => 'Create room';

  @override
  String get lanNearbyRooms => 'Nearby rooms';

  @override
  String get lanStopSearch => 'Stop searching';

  @override
  String get lanSearch => 'Search for nearby rooms';

  @override
  String get lanUnnamedRoom => 'Unnamed room';

  @override
  String get lanUnknownAddress => 'Unknown address';

  @override
  String get lanJoin => 'Join';

  @override
  String get lanSearching => 'Searching for nearby rooms…';

  @override
  String get lanNoRooms => 'No rooms found';

  @override
  String get lanSearchingHint => 'Keep both devices on the same network.';

  @override
  String get lanSearchHint => 'Use the search button above to find rooms.';

  @override
  String get lanDiscoveryFailed =>
      'Could not find nearby rooms. Confirm both devices are on the same network and try again.';

  @override
  String get lanHostingFailed =>
      'Could not create the room. Check the local network and try again.';

  @override
  String get lanConnectionFailed =>
      'Could not join the room. Confirm that the other player\'s room is still available.';

  @override
  String get lanOpponentLeft => 'The other player left the game';

  @override
  String get lanGameError =>
      'The LAN game encountered an error. Leave and try again.';

  @override
  String get lanUnknownState => 'Unknown state';

  @override
  String get lanReconnecting => 'Connection lost. Waiting to reconnect…';

  @override
  String get lanSyncing => 'Syncing the host game…';

  @override
  String get lanExitTitle => 'Leave game?';

  @override
  String get lanExitDescription => 'This will disconnect from the game.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAudioSection => 'Audio';

  @override
  String get settingsSoundToggle => 'Sound effects';

  @override
  String get settingsSoundDescription =>
      'Sounds for moves, captures, and other game events';

  @override
  String get settingsSoundVolume => 'Sound volume';

  @override
  String get settingsMusicToggle => 'Background music';

  @override
  String get settingsMusicDescription => 'Music during the game';

  @override
  String get settingsMusicVolume => 'Music volume';

  @override
  String get settingsHapticsSection => 'Haptics';

  @override
  String get settingsHapticsToggle => 'Haptic feedback';

  @override
  String get settingsHapticsDescription =>
      'Feedback for touches and game actions';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsLanguageDescription =>
      'Change the language used by the app';

  @override
  String get settingsAiSection => 'AI';

  @override
  String get settingsDefaultAiDifficulty => 'Default AI difficulty';

  @override
  String get settingsDefaultAiDifficultyDescription =>
      'Default level for new AI games';

  @override
  String get settingsBoardThemeSection => 'Board theme';

  @override
  String get settingsModernEasternTheme => 'Modern Eastern';

  @override
  String get settingsModernEasternThemeDescription =>
      'The first release theme; more themes will arrive later';

  @override
  String get settingsAnimationToggle => 'Animations';

  @override
  String get settingsAnimationDescription =>
      'Piece movement and capture animations';

  @override
  String get settingsParticleToggle => 'Particle effects';

  @override
  String get settingsParticleDescription =>
      'Decorative capture and result effects';

  @override
  String get settingsPrivacyPerformanceSection => 'Privacy and performance';

  @override
  String get settingsAnonymousDiagnostics => 'Anonymous diagnostics';

  @override
  String get settingsAnonymousDiagnosticsDescription =>
      'Send redacted crash and performance data, never game content or advertising IDs';

  @override
  String get settingsResourceWarmup => 'Preload resources';

  @override
  String get settingsResourceWarmupDescription =>
      'Load board and audio resources early to reduce the first wait';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsReviewGuide => 'View game guide again';

  @override
  String get settingsReviewGuideDescription =>
      'Review onboarding and the game rules';

  @override
  String get settingsOpenSourceLicenses => 'Open-source licenses';

  @override
  String get settingsDangerSection => 'Destructive actions';

  @override
  String get settingsClearStatistics => 'Clear statistics';

  @override
  String get settingsClearStatisticsConfirm =>
      'This clears aggregate statistics and the last 20 replays. This cannot be undone.';

  @override
  String get settingsStatisticsCleared =>
      'Statistics and recent games were cleared';

  @override
  String get settingsResetAll => 'Reset all settings';

  @override
  String get settingsResetAllConfirm =>
      'Reset all settings and data? This cannot be undone.';

  @override
  String get settingsResetAllDone => 'All settings were reset';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get clear => 'Clear';

  @override
  String get onlineBattleTitle => 'Online game';

  @override
  String get onlineIntroTitle => 'Reliable online play';

  @override
  String get onlineIntroBody =>
      'The board changes only after server confirmation. Your anonymous identity is used only for matching and recovery.';

  @override
  String get onlineFindOpponent => 'Find an opponent';

  @override
  String get onlineConnecting => 'Connecting to the server…';

  @override
  String get onlineSearching => 'Looking for an opponent…';

  @override
  String get onlineCancelSearch => 'Cancel matching';

  @override
  String get onlineYourTurn => 'Your turn';

  @override
  String get onlineOpponentTurn => 'Opponent\'s turn';

  @override
  String get onlineWaitingForServer => 'Waiting for server confirmation…';

  @override
  String get onlineOpponentDisconnected =>
      'Opponent disconnected; the server clock continues';

  @override
  String onlineReconnectSeconds(int seconds) {
    return 'Opponent can reconnect for $seconds more seconds';
  }

  @override
  String get onlineRecovering => 'Recovering the authoritative game…';

  @override
  String get onlineRetry => 'Retry connection';

  @override
  String get onlineLeave => 'Leave game';

  @override
  String get onlineYouWin => 'You win';

  @override
  String get onlineYouLose => 'You lose';

  @override
  String get onlineGameDraw => 'Draw';

  @override
  String get onlineFinished => 'Game finished';

  @override
  String get onlineMoveRejected =>
      'The server did not accept that move. Try again from the current board.';

  @override
  String onlineYourSide(String side) {
    return 'You play $side';
  }

  @override
  String get onlineFailureConnection => 'Could not connect to online play';

  @override
  String get onlineFailureIdentity =>
      'Could not prepare an anonymous online identity';

  @override
  String get onlineFailureRequest => 'The request was not sent. Try again.';

  @override
  String get onlineFailureMatch => 'Matching cannot start right now';

  @override
  String get onlineFailureResume =>
      'The previous game can no longer be recovered';

  @override
  String get onlineFailureSnapshot =>
      'Could not retrieve the latest game state';

  @override
  String get onlineFailureProtocol => 'The server sent an unsupported message';
}
