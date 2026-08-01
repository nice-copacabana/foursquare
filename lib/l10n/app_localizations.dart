import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'四子游戏'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In zh, this message translates to:
  /// **'移 · 围 · 取 · 胜'**
  String get homeTagline;

  /// No description provided for @developmentEdition.
  ///
  /// In zh, this message translates to:
  /// **'现代东方棋艺 · 开发版本 0.1.0'**
  String get developmentEdition;

  /// No description provided for @continueGame.
  ///
  /// In zh, this message translates to:
  /// **'继续游戏'**
  String get continueGame;

  /// No description provided for @continueGameDescription.
  ///
  /// In zh, this message translates to:
  /// **'从上次落子继续'**
  String get continueGameDescription;

  /// No description provided for @playerVsPlayer.
  ///
  /// In zh, this message translates to:
  /// **'双人对战'**
  String get playerVsPlayer;

  /// No description provided for @playerVsPlayerDescription.
  ///
  /// In zh, this message translates to:
  /// **'同屏轮流落子'**
  String get playerVsPlayerDescription;

  /// No description provided for @playerVsAI.
  ///
  /// In zh, this message translates to:
  /// **'人机对战'**
  String get playerVsAI;

  /// No description provided for @playerVsAIDescription.
  ///
  /// In zh, this message translates to:
  /// **'简单 · 中等 · 困难'**
  String get playerVsAIDescription;

  /// No description provided for @lanGame.
  ///
  /// In zh, this message translates to:
  /// **'局域网对战'**
  String get lanGame;

  /// No description provided for @lanGameDescription.
  ///
  /// In zh, this message translates to:
  /// **'同一网络面对面对弈'**
  String get lanGameDescription;

  /// No description provided for @statistics.
  ///
  /// In zh, this message translates to:
  /// **'战绩'**
  String get statistics;

  /// No description provided for @rules.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get rules;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @chooseDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'选择棋力'**
  String get chooseDifficulty;

  /// No description provided for @difficultyEasy.
  ///
  /// In zh, this message translates to:
  /// **'简单'**
  String get difficultyEasy;

  /// No description provided for @difficultyEasyDescription.
  ///
  /// In zh, this message translates to:
  /// **'熟悉规则与走法'**
  String get difficultyEasyDescription;

  /// No description provided for @difficultyMedium.
  ///
  /// In zh, this message translates to:
  /// **'中等'**
  String get difficultyMedium;

  /// No description provided for @difficultyMediumDescription.
  ///
  /// In zh, this message translates to:
  /// **'平衡思考与速度'**
  String get difficultyMediumDescription;

  /// No description provided for @difficultyHard.
  ///
  /// In zh, this message translates to:
  /// **'困难'**
  String get difficultyHard;

  /// No description provided for @difficultyHardDescription.
  ///
  /// In zh, this message translates to:
  /// **'更深入地计算局面'**
  String get difficultyHardDescription;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skip;

  /// No description provided for @previous.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get next;

  /// No description provided for @startGame.
  ///
  /// In zh, this message translates to:
  /// **'开始游戏'**
  String get startGame;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'四子游戏'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'策略对弈，智胜四方'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In zh, this message translates to:
  /// **'欢迎来到四子棋！\n让我们快速了解游戏规则'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingBoardTitle.
  ///
  /// In zh, this message translates to:
  /// **'棋盘与棋子'**
  String get onboardingBoardTitle;

  /// No description provided for @onboardingBoardFourByFour.
  ///
  /// In zh, this message translates to:
  /// **'4×4 棋盘'**
  String get onboardingBoardFourByFour;

  /// No description provided for @onboardingBoardFourByFourDescription.
  ///
  /// In zh, this message translates to:
  /// **'游戏在 4×4 交点棋盘上进行'**
  String get onboardingBoardFourByFourDescription;

  /// No description provided for @onboardingFourPieces.
  ///
  /// In zh, this message translates to:
  /// **'双方各 4 子'**
  String get onboardingFourPieces;

  /// No description provided for @onboardingFourPiecesDescription.
  ///
  /// In zh, this message translates to:
  /// **'墨方和玉方各有 4 枚棋子'**
  String get onboardingFourPiecesDescription;

  /// No description provided for @onboardingMovementTitle.
  ///
  /// In zh, this message translates to:
  /// **'移动规则'**
  String get onboardingMovementTitle;

  /// No description provided for @onboardingOrthogonalMove.
  ///
  /// In zh, this message translates to:
  /// **'上下左右移动'**
  String get onboardingOrthogonalMove;

  /// No description provided for @onboardingOrthogonalMoveDescription.
  ///
  /// In zh, this message translates to:
  /// **'棋子只能移动到相邻的空位'**
  String get onboardingOrthogonalMoveDescription;

  /// No description provided for @onboardingNoDiagonal.
  ///
  /// In zh, this message translates to:
  /// **'不能斜向移动'**
  String get onboardingNoDiagonal;

  /// No description provided for @onboardingNoDiagonalDescription.
  ///
  /// In zh, this message translates to:
  /// **'不能斜走、跳子或落到已有棋子的位置'**
  String get onboardingNoDiagonalDescription;

  /// No description provided for @onboardingCaptureTitle.
  ///
  /// In zh, this message translates to:
  /// **'吃子规则'**
  String get onboardingCaptureTitle;

  /// No description provided for @emptyCell.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get emptyCell;

  /// No description provided for @ownPiece.
  ///
  /// In zh, this message translates to:
  /// **'己'**
  String get ownPiece;

  /// No description provided for @enemyPiece.
  ///
  /// In zh, this message translates to:
  /// **'敌'**
  String get enemyPiece;

  /// No description provided for @onboardingExactPattern.
  ///
  /// In zh, this message translates to:
  /// **'精确四格排列'**
  String get onboardingExactPattern;

  /// No description provided for @onboardingExactPatternDescription.
  ///
  /// In zh, this message translates to:
  /// **'形成“己-己-敌-空”或规定的反向排列时吃掉敌子'**
  String get onboardingExactPatternDescription;

  /// No description provided for @onboardingMovedPieceParticipates.
  ///
  /// In zh, this message translates to:
  /// **'落子必须参与'**
  String get onboardingMovedPieceParticipates;

  /// No description provided for @onboardingMovedPieceParticipatesDescription.
  ///
  /// In zh, this message translates to:
  /// **'刚移动的棋子必须属于相邻双子；横纵可同时吃子'**
  String get onboardingMovedPieceParticipatesDescription;

  /// No description provided for @onboardingFeaturesTitle.
  ///
  /// In zh, this message translates to:
  /// **'功能特色'**
  String get onboardingFeaturesTitle;

  /// No description provided for @onboardingAiFeature.
  ///
  /// In zh, this message translates to:
  /// **'AI 对战'**
  String get onboardingAiFeature;

  /// No description provided for @onboardingAiFeatureDescription.
  ///
  /// In zh, this message translates to:
  /// **'3 种难度的 AI 陪你练习'**
  String get onboardingAiFeatureDescription;

  /// No description provided for @onboardingReplayFeature.
  ///
  /// In zh, this message translates to:
  /// **'游戏回放'**
  String get onboardingReplayFeature;

  /// No description provided for @onboardingReplayFeatureDescription.
  ///
  /// In zh, this message translates to:
  /// **'回顾每一步精彩对局'**
  String get onboardingReplayFeatureDescription;

  /// No description provided for @onboardingThemeFeature.
  ///
  /// In zh, this message translates to:
  /// **'现代东方棋艺'**
  String get onboardingThemeFeature;

  /// No description provided for @onboardingThemeFeatureDescription.
  ///
  /// In zh, this message translates to:
  /// **'一期统一视觉，后续将扩展更多主题'**
  String get onboardingThemeFeatureDescription;

  /// No description provided for @onboardingStatisticsFeature.
  ///
  /// In zh, this message translates to:
  /// **'战绩统计'**
  String get onboardingStatisticsFeature;

  /// No description provided for @onboardingStatisticsFeatureDescription.
  ///
  /// In zh, this message translates to:
  /// **'查看你的游戏数据'**
  String get onboardingStatisticsFeatureDescription;

  /// No description provided for @rulesTitle.
  ///
  /// In zh, this message translates to:
  /// **'对弈规则'**
  String get rulesTitle;

  /// No description provided for @startInteractiveTutorial.
  ///
  /// In zh, this message translates to:
  /// **'开始互动教程'**
  String get startInteractiveTutorial;

  /// No description provided for @rulesSectionOne.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get rulesSectionOne;

  /// No description provided for @rulesSectionTwo.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get rulesSectionTwo;

  /// No description provided for @rulesSectionThree.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get rulesSectionThree;

  /// No description provided for @rulesSectionFour.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get rulesSectionFour;

  /// No description provided for @rulesHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'移子成势，精确取子'**
  String get rulesHeroTitle;

  /// No description provided for @rulesHeroDescription.
  ///
  /// In zh, this message translates to:
  /// **'所有模式共享同一套规则；界面、AI、回放与局域网均以此为准。'**
  String get rulesHeroDescription;

  /// No description provided for @rulesBoardSection.
  ///
  /// In zh, this message translates to:
  /// **'棋盘与行棋'**
  String get rulesBoardSection;

  /// No description provided for @rulesBoardLine1.
  ///
  /// In zh, this message translates to:
  /// **'棋盘为 4×4，墨方与玉方各四枚棋子。'**
  String get rulesBoardLine1;

  /// No description provided for @rulesBoardLine2.
  ///
  /// In zh, this message translates to:
  /// **'首局随机决定先手；复局双方交替先手。'**
  String get rulesBoardLine2;

  /// No description provided for @rulesBoardLine3.
  ///
  /// In zh, this message translates to:
  /// **'每手将一枚己方棋子移到上下左右相邻的空位，不能斜走或越子。'**
  String get rulesBoardLine3;

  /// No description provided for @rulesBoardLine4.
  ///
  /// In zh, this message translates to:
  /// **'每回合 60 秒；离线对局进入后台会暂停，局域网对局继续计时。'**
  String get rulesBoardLine4;

  /// No description provided for @rulesCaptureSection.
  ///
  /// In zh, this message translates to:
  /// **'精确吃子'**
  String get rulesCaptureSection;

  /// No description provided for @rulesCaptureIntro.
  ///
  /// In zh, this message translates to:
  /// **'只检查本次落子所在的完整四格横线与竖线。以下排列可以吃掉“敌”：'**
  String get rulesCaptureIntro;

  /// No description provided for @rulesCaptureLine1.
  ///
  /// In zh, this message translates to:
  /// **'刚移动的棋子必须属于相邻的两枚己方棋子。'**
  String get rulesCaptureLine1;

  /// No description provided for @rulesCaptureLine2.
  ///
  /// In zh, this message translates to:
  /// **'仅因对手落子而被动形成的排列不触发吃子。'**
  String get rulesCaptureLine2;

  /// No description provided for @rulesCaptureLine3.
  ///
  /// In zh, this message translates to:
  /// **'横向与竖向可同时成立，一手最多吃两枚。'**
  String get rulesCaptureLine3;

  /// No description provided for @rulesCaptureLine4.
  ///
  /// In zh, this message translates to:
  /// **'1100、1110、0110 等非精确排列均不吃子。'**
  String get rulesCaptureLine4;

  /// No description provided for @rulesEndingSection.
  ///
  /// In zh, this message translates to:
  /// **'胜负与和棋'**
  String get rulesEndingSection;

  /// No description provided for @rulesEndingLine1.
  ///
  /// In zh, this message translates to:
  /// **'一方棋子只剩一枚或更少时，该方立即判负。'**
  String get rulesEndingLine1;

  /// No description provided for @rulesEndingLine2.
  ///
  /// In zh, this message translates to:
  /// **'一方回合开始时没有任何合法移动，该方判负。'**
  String get rulesEndingLine2;

  /// No description provided for @rulesEndingLine3.
  ///
  /// In zh, this message translates to:
  /// **'回合倒计时归零，当前行棋方判负。'**
  String get rulesEndingLine3;

  /// No description provided for @rulesEndingLine4.
  ///
  /// In zh, this message translates to:
  /// **'连续 50 个单方落子都未吃子时和棋；任意吃子会把计数清零。'**
  String get rulesEndingLine4;

  /// No description provided for @rulesEndingLine5.
  ///
  /// In zh, this message translates to:
  /// **'局域网断线有 30 秒重连宽限，超时未恢复则断线方判负。'**
  String get rulesEndingLine5;

  /// No description provided for @rulesUndoSection.
  ///
  /// In zh, this message translates to:
  /// **'撤销与记录'**
  String get rulesUndoSection;

  /// No description provided for @rulesUndoLine1.
  ///
  /// In zh, this message translates to:
  /// **'本地双人每次撤销一手；人机对战按“玩家 + AI”两手成对撤销。'**
  String get rulesUndoLine1;

  /// No description provided for @rulesUndoLine2.
  ///
  /// In zh, this message translates to:
  /// **'撤销后可以重做；落下新棋后原重做分支失效。'**
  String get rulesUndoLine2;

  /// No description provided for @rulesUndoLine3.
  ///
  /// In zh, this message translates to:
  /// **'局域网对战不提供撤销。完成对局会进入最近 20 局记录，可逐手回放。'**
  String get rulesUndoLine3;

  /// No description provided for @tutorialTitle.
  ///
  /// In zh, this message translates to:
  /// **'互动教程'**
  String get tutorialTitle;

  /// No description provided for @tutorialStep1.
  ///
  /// In zh, this message translates to:
  /// **'先选择左上角的墨方棋子。'**
  String get tutorialStep1;

  /// No description provided for @tutorialStep2.
  ///
  /// In zh, this message translates to:
  /// **'很好。现在把它移动到下方相邻空位。'**
  String get tutorialStep2;

  /// No description provided for @tutorialStep3.
  ///
  /// In zh, this message translates to:
  /// **'落子完成。实战中每回合有 60 秒，双方轮流移动。'**
  String get tutorialStep3;

  /// No description provided for @tutorialStep4.
  ///
  /// In zh, this message translates to:
  /// **'吃子必须匹配完整四格：己-己-敌-空，或规定的反向排列。落子必须属于相邻双子。'**
  String get tutorialStep4;

  /// No description provided for @tutorialStep5.
  ///
  /// In zh, this message translates to:
  /// **'横向与竖向可同时吃子；对方只剩一子、无合法移动或超时都会判负。'**
  String get tutorialStep5;

  /// No description provided for @finishTutorial.
  ///
  /// In zh, this message translates to:
  /// **'完成教程'**
  String get finishTutorial;

  /// No description provided for @tutorialCapturePatternSemantics.
  ///
  /// In zh, this message translates to:
  /// **'允许的吃子排列：己、己、敌、空'**
  String get tutorialCapturePatternSemantics;

  /// No description provided for @gameTitle.
  ///
  /// In zh, this message translates to:
  /// **'四子游戏'**
  String get gameTitle;

  /// No description provided for @gameUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'棋局暂时无法继续'**
  String get gameUnavailable;

  /// No description provided for @restart.
  ///
  /// In zh, this message translates to:
  /// **'重新开始'**
  String get restart;

  /// No description provided for @restartConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'重新开始'**
  String get restartConfirmTitle;

  /// No description provided for @restartConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要重新开始游戏吗？当前进度将丢失。'**
  String get restartConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @pvpReplayTitle.
  ///
  /// In zh, this message translates to:
  /// **'双人对局回放'**
  String get pvpReplayTitle;

  /// No description provided for @pveReplayTitle.
  ///
  /// In zh, this message translates to:
  /// **'人机对局回放'**
  String get pveReplayTitle;

  /// No description provided for @lanReplayTitle.
  ///
  /// In zh, this message translates to:
  /// **'局域网对局回放'**
  String get lanReplayTitle;

  /// No description provided for @blackSide.
  ///
  /// In zh, this message translates to:
  /// **'墨方'**
  String get blackSide;

  /// No description provided for @whiteSide.
  ///
  /// In zh, this message translates to:
  /// **'玉方'**
  String get whiteSide;

  /// No description provided for @blackTurn.
  ///
  /// In zh, this message translates to:
  /// **'墨方回合'**
  String get blackTurn;

  /// No description provided for @whiteTurn.
  ///
  /// In zh, this message translates to:
  /// **'玉方回合'**
  String get whiteTurn;

  /// No description provided for @firstPlayerAnnouncement.
  ///
  /// In zh, this message translates to:
  /// **'{side} 先手'**
  String firstPlayerAnnouncement(String side);

  /// No description provided for @gameStarting.
  ///
  /// In zh, this message translates to:
  /// **'对局即将开始'**
  String get gameStarting;

  /// No description provided for @boardCellPosition.
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行，第 {column} 列'**
  String boardCellPosition(int row, int column);

  /// No description provided for @boardEmptyPosition.
  ///
  /// In zh, this message translates to:
  /// **'空位'**
  String get boardEmptyPosition;

  /// No description provided for @boardSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选中'**
  String get boardSelected;

  /// No description provided for @boardLegalDestination.
  ///
  /// In zh, this message translates to:
  /// **'可移动到此处'**
  String get boardLegalDestination;

  /// No description provided for @boardSelectablePiece.
  ///
  /// In zh, this message translates to:
  /// **'可选棋子'**
  String get boardSelectablePiece;

  /// No description provided for @boardPreviousMoveStart.
  ///
  /// In zh, this message translates to:
  /// **'上一手起点'**
  String get boardPreviousMoveStart;

  /// No description provided for @boardPreviousMoveEnd.
  ///
  /// In zh, this message translates to:
  /// **'上一手终点'**
  String get boardPreviousMoveEnd;

  /// No description provided for @aiThinking.
  ///
  /// In zh, this message translates to:
  /// **'AI 思考中'**
  String get aiThinking;

  /// No description provided for @turnSecondsRemaining.
  ///
  /// In zh, this message translates to:
  /// **'本回合剩余 {seconds} 秒'**
  String turnSecondsRemaining(int seconds);

  /// No description provided for @secondsCount.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String secondsCount(int seconds);

  /// No description provided for @moveHistoryCount.
  ///
  /// In zh, this message translates to:
  /// **'移动历史（{count} 手）'**
  String moveHistoryCount(int count);

  /// No description provided for @noMoveHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无移动记录'**
  String get noMoveHistory;

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get redo;

  /// No description provided for @gameOver.
  ///
  /// In zh, this message translates to:
  /// **'游戏结束'**
  String get gameOver;

  /// No description provided for @blackWins.
  ///
  /// In zh, this message translates to:
  /// **'墨方获胜！'**
  String get blackWins;

  /// No description provided for @whiteWins.
  ///
  /// In zh, this message translates to:
  /// **'玉方获胜！'**
  String get whiteWins;

  /// No description provided for @draw.
  ///
  /// In zh, this message translates to:
  /// **'和棋'**
  String get draw;

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @playAgain.
  ///
  /// In zh, this message translates to:
  /// **'再来一局'**
  String get playAgain;

  /// No description provided for @viewReplay.
  ///
  /// In zh, this message translates to:
  /// **'查看回放'**
  String get viewReplay;

  /// No description provided for @endReasonPieceCountBlack.
  ///
  /// In zh, this message translates to:
  /// **'玉方只剩一枚或更少棋子'**
  String get endReasonPieceCountBlack;

  /// No description provided for @endReasonPieceCountWhite.
  ///
  /// In zh, this message translates to:
  /// **'墨方只剩一枚或更少棋子'**
  String get endReasonPieceCountWhite;

  /// No description provided for @endReasonNoLegalMovesBlack.
  ///
  /// In zh, this message translates to:
  /// **'玉方没有合法移动，判负'**
  String get endReasonNoLegalMovesBlack;

  /// No description provided for @endReasonNoLegalMovesWhite.
  ///
  /// In zh, this message translates to:
  /// **'墨方没有合法移动，判负'**
  String get endReasonNoLegalMovesWhite;

  /// No description provided for @endReasonNoCaptureLimit.
  ///
  /// In zh, this message translates to:
  /// **'连续 50 手未发生吃子，和棋'**
  String get endReasonNoCaptureLimit;

  /// No description provided for @endReasonTimeoutBlack.
  ///
  /// In zh, this message translates to:
  /// **'玉方回合超时，判负'**
  String get endReasonTimeoutBlack;

  /// No description provided for @endReasonTimeoutWhite.
  ///
  /// In zh, this message translates to:
  /// **'墨方回合超时，判负'**
  String get endReasonTimeoutWhite;

  /// No description provided for @endReasonDisconnectBlack.
  ///
  /// In zh, this message translates to:
  /// **'玉方断线超过 30 秒，判负'**
  String get endReasonDisconnectBlack;

  /// No description provided for @endReasonDisconnectWhite.
  ///
  /// In zh, this message translates to:
  /// **'墨方断线超过 30 秒，判负'**
  String get endReasonDisconnectWhite;

  /// No description provided for @endReasonAbandonedBlack.
  ///
  /// In zh, this message translates to:
  /// **'玉方已认输'**
  String get endReasonAbandonedBlack;

  /// No description provided for @endReasonAbandonedWhite.
  ///
  /// In zh, this message translates to:
  /// **'墨方已认输'**
  String get endReasonAbandonedWhite;

  /// No description provided for @endReasonUnknown.
  ///
  /// In zh, this message translates to:
  /// **'对局已结束'**
  String get endReasonUnknown;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近对局'**
  String get historyTitle;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'尚无已完成对局'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'完成一局后，可在这里查看最近 20 局并逐手回放。'**
  String get historyEmptyDescription;

  /// No description provided for @modePvp.
  ///
  /// In zh, this message translates to:
  /// **'双人'**
  String get modePvp;

  /// No description provided for @modePve.
  ///
  /// In zh, this message translates to:
  /// **'人机'**
  String get modePve;

  /// No description provided for @modeLan.
  ///
  /// In zh, this message translates to:
  /// **'局域网'**
  String get modeLan;

  /// No description provided for @modePveWithDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'人机 · {difficulty}'**
  String modePveWithDifficulty(String difficulty);

  /// No description provided for @resultSideWins.
  ///
  /// In zh, this message translates to:
  /// **'{side}胜'**
  String resultSideWins(String side);

  /// No description provided for @resultFinished.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get resultFinished;

  /// No description provided for @historySummary.
  ///
  /// In zh, this message translates to:
  /// **'{moves} 手 · {captures} 次吃子 · {date}'**
  String historySummary(int moves, int captures, String date);

  /// No description provided for @dateMonthDayTime.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日 {time}'**
  String dateMonthDayTime(int month, int day, String time);

  /// No description provided for @replayTitle.
  ///
  /// In zh, this message translates to:
  /// **'游戏回放'**
  String get replayTitle;

  /// No description provided for @replayHelp.
  ///
  /// In zh, this message translates to:
  /// **'回放说明'**
  String get replayHelp;

  /// No description provided for @replayInitial.
  ///
  /// In zh, this message translates to:
  /// **'初始'**
  String get replayInitial;

  /// No description provided for @replayStepLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {step} 步'**
  String replayStepLabel(int step);

  /// No description provided for @replayProgress.
  ///
  /// In zh, this message translates to:
  /// **'第 {step} 手 / 共 {total} 手'**
  String replayProgress(int step, int total);

  /// No description provided for @moveDescription.
  ///
  /// In zh, this message translates to:
  /// **'{from} → {to}'**
  String moveDescription(String from, String to);

  /// No description provided for @moveDescriptionCapture.
  ///
  /// In zh, this message translates to:
  /// **'{from} → {to}，吃 {count} 子'**
  String moveDescriptionCapture(String from, String to, int count);

  /// No description provided for @replayFirst.
  ///
  /// In zh, this message translates to:
  /// **'第一步'**
  String get replayFirst;

  /// No description provided for @replayPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get replayPrevious;

  /// No description provided for @replayNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get replayNext;

  /// No description provided for @replayLast.
  ///
  /// In zh, this message translates to:
  /// **'最后一步'**
  String get replayLast;

  /// No description provided for @replayControlsHeading.
  ///
  /// In zh, this message translates to:
  /// **'控制说明：'**
  String get replayControlsHeading;

  /// No description provided for @replayHelpSlider.
  ///
  /// In zh, this message translates to:
  /// **'使用滑块可快速跳转到任意步骤'**
  String get replayHelpSlider;

  /// No description provided for @replayHelpButtons.
  ///
  /// In zh, this message translates to:
  /// **'点击按钮可逐步回放'**
  String get replayHelpButtons;

  /// No description provided for @replayHelpHistory.
  ///
  /// In zh, this message translates to:
  /// **'点击历史记录可直接跳转'**
  String get replayHelpHistory;

  /// No description provided for @replayFeaturesHeading.
  ///
  /// In zh, this message translates to:
  /// **'功能说明：'**
  String get replayFeaturesHeading;

  /// No description provided for @replayHelpReadonly.
  ///
  /// In zh, this message translates to:
  /// **'棋盘为只读模式，不可操作'**
  String get replayHelpReadonly;

  /// No description provided for @replayHelpHighlight.
  ///
  /// In zh, this message translates to:
  /// **'高亮显示当前步骤的移动'**
  String get replayHelpHighlight;

  /// No description provided for @replayHelpCapture.
  ///
  /// In zh, this message translates to:
  /// **'带 × 标记表示该步骤有吃子'**
  String get replayHelpCapture;

  /// No description provided for @gotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get gotIt;

  /// No description provided for @statisticsTitle.
  ///
  /// In zh, this message translates to:
  /// **'对局统计'**
  String get statisticsTitle;

  /// No description provided for @statisticsResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置统计'**
  String get statisticsResetTitle;

  /// No description provided for @statisticsResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将清空累计统计和最近 20 局回放。此操作无法撤销，确定继续吗？'**
  String get statisticsResetConfirm;

  /// No description provided for @statisticsResetAction.
  ///
  /// In zh, this message translates to:
  /// **'确认重置'**
  String get statisticsResetAction;

  /// No description provided for @statisticsResetDone.
  ///
  /// In zh, this message translates to:
  /// **'统计与最近对局已重置'**
  String get statisticsResetDone;

  /// No description provided for @statisticsResetFailed.
  ///
  /// In zh, this message translates to:
  /// **'重置失败，请稍后重试'**
  String get statisticsResetFailed;

  /// No description provided for @statisticsHistoryTooltip.
  ///
  /// In zh, this message translates to:
  /// **'最近对局与回放'**
  String get statisticsHistoryTooltip;

  /// No description provided for @statisticsOverviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'棋谱总览'**
  String get statisticsOverviewTitle;

  /// No description provided for @statisticsOverviewDescription.
  ///
  /// In zh, this message translates to:
  /// **'记录走过的每一步，不把不同对局模式混成一项输赢。'**
  String get statisticsOverviewDescription;

  /// No description provided for @statisticsTotalGames.
  ///
  /// In zh, this message translates to:
  /// **'累计对局'**
  String get statisticsTotalGames;

  /// No description provided for @statisticsTotalMoves.
  ///
  /// In zh, this message translates to:
  /// **'累计手数'**
  String get statisticsTotalMoves;

  /// No description provided for @statisticsAverageMoves.
  ///
  /// In zh, this message translates to:
  /// **'平均手数'**
  String get statisticsAverageMoves;

  /// No description provided for @statisticsTotalCaptures.
  ///
  /// In zh, this message translates to:
  /// **'累计吃子'**
  String get statisticsTotalCaptures;

  /// No description provided for @statisticsLastMove.
  ///
  /// In zh, this message translates to:
  /// **'最近落子：{date}'**
  String statisticsLastMove(String date);

  /// No description provided for @statisticsNoRecord.
  ///
  /// In zh, this message translates to:
  /// **'尚无记录'**
  String get statisticsNoRecord;

  /// No description provided for @statisticsRecentTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近对局'**
  String get statisticsRecentTitle;

  /// No description provided for @statisticsRecentEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'近期表现'**
  String get statisticsRecentEyebrow;

  /// No description provided for @statisticsRecentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'完成一局后，将在这里按模式呈现结果。'**
  String get statisticsRecentEmpty;

  /// No description provided for @statisticsRecentDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅基于设备内保留的最近 {count} 局，不与累计数据混算。'**
  String statisticsRecentDescription(int count);

  /// No description provided for @statisticsPvpTitle.
  ///
  /// In zh, this message translates to:
  /// **'本地双人 · 近 20 局'**
  String get statisticsPvpTitle;

  /// No description provided for @statisticsPvpWin.
  ///
  /// In zh, this message translates to:
  /// **'墨方胜'**
  String get statisticsPvpWin;

  /// No description provided for @statisticsPvpLoss.
  ///
  /// In zh, this message translates to:
  /// **'玉方胜'**
  String get statisticsPvpLoss;

  /// No description provided for @statisticsPvpNote.
  ///
  /// In zh, this message translates to:
  /// **'本地双人按双方棋色记录，不计算个人胜率。'**
  String get statisticsPvpNote;

  /// No description provided for @statisticsPveTitle.
  ///
  /// In zh, this message translates to:
  /// **'人机对弈 · 近 20 局'**
  String get statisticsPveTitle;

  /// No description provided for @statisticsPveWin.
  ///
  /// In zh, this message translates to:
  /// **'玩家胜'**
  String get statisticsPveWin;

  /// No description provided for @statisticsPveLoss.
  ///
  /// In zh, this message translates to:
  /// **'AI 胜'**
  String get statisticsPveLoss;

  /// No description provided for @statisticsPveNote.
  ///
  /// In zh, this message translates to:
  /// **'按本机玩家执棋颜色计算。'**
  String get statisticsPveNote;

  /// No description provided for @statisticsLanTitle.
  ///
  /// In zh, this message translates to:
  /// **'局域网 · 近 20 局'**
  String get statisticsLanTitle;

  /// No description provided for @statisticsLanWin.
  ///
  /// In zh, this message translates to:
  /// **'本机胜'**
  String get statisticsLanWin;

  /// No description provided for @statisticsLanLoss.
  ///
  /// In zh, this message translates to:
  /// **'本机负'**
  String get statisticsLanLoss;

  /// No description provided for @statisticsLanNote.
  ///
  /// In zh, this message translates to:
  /// **'按本机在联机对局中的执棋颜色计算。'**
  String get statisticsLanNote;

  /// No description provided for @statisticsDrawCount.
  ///
  /// In zh, this message translates to:
  /// **'和棋 {count}'**
  String statisticsDrawCount(int count);

  /// No description provided for @statisticsUnknownCount.
  ///
  /// In zh, this message translates to:
  /// **'未识别 {count}'**
  String statisticsUnknownCount(int count);

  /// No description provided for @statisticsNoModeRecord.
  ///
  /// In zh, this message translates to:
  /// **'暂无该模式记录。{note}'**
  String statisticsNoModeRecord(String note);

  /// No description provided for @statisticsUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'统计数据暂时无法读取'**
  String get statisticsUnavailable;

  /// No description provided for @reload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get reload;

  /// No description provided for @lanTitle.
  ///
  /// In zh, this message translates to:
  /// **'局域网对战'**
  String get lanTitle;

  /// No description provided for @lanCreateRoomTab.
  ///
  /// In zh, this message translates to:
  /// **'创建房间'**
  String get lanCreateRoomTab;

  /// No description provided for @lanJoinRoomTab.
  ///
  /// In zh, this message translates to:
  /// **'加入房间'**
  String get lanJoinRoomTab;

  /// No description provided for @lanConnectedTitle.
  ///
  /// In zh, this message translates to:
  /// **'已连接到对局'**
  String get lanConnectedTitle;

  /// No description provided for @lanConnectedDescription.
  ///
  /// In zh, this message translates to:
  /// **'正在进入棋局，请稍候。'**
  String get lanConnectedDescription;

  /// No description provided for @lanDisconnect.
  ///
  /// In zh, this message translates to:
  /// **'断开连接'**
  String get lanDisconnect;

  /// No description provided for @lanWaitingTitle.
  ///
  /// In zh, this message translates to:
  /// **'正在等待玩家加入'**
  String get lanWaitingTitle;

  /// No description provided for @lanRoomNameValue.
  ///
  /// In zh, this message translates to:
  /// **'房间名：{name}'**
  String lanRoomNameValue(String name);

  /// No description provided for @lanCancelCreate.
  ///
  /// In zh, this message translates to:
  /// **'取消创建'**
  String get lanCancelCreate;

  /// No description provided for @lanCreateHeading.
  ///
  /// In zh, this message translates to:
  /// **'开一间棋室'**
  String get lanCreateHeading;

  /// No description provided for @lanCreateDescription.
  ///
  /// In zh, this message translates to:
  /// **'同一局域网内的玩家可以发现并加入。'**
  String get lanCreateDescription;

  /// No description provided for @lanRoomNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'房间名称'**
  String get lanRoomNameLabel;

  /// No description provided for @lanDefaultRoomName.
  ///
  /// In zh, this message translates to:
  /// **'我的棋室'**
  String get lanDefaultRoomName;

  /// No description provided for @lanCreateRoom.
  ///
  /// In zh, this message translates to:
  /// **'创建房间'**
  String get lanCreateRoom;

  /// No description provided for @lanNearbyRooms.
  ///
  /// In zh, this message translates to:
  /// **'附近的房间'**
  String get lanNearbyRooms;

  /// No description provided for @lanStopSearch.
  ///
  /// In zh, this message translates to:
  /// **'停止搜索'**
  String get lanStopSearch;

  /// No description provided for @lanSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索附近房间'**
  String get lanSearch;

  /// No description provided for @lanUnnamedRoom.
  ///
  /// In zh, this message translates to:
  /// **'未命名房间'**
  String get lanUnnamedRoom;

  /// No description provided for @lanUnknownAddress.
  ///
  /// In zh, this message translates to:
  /// **'未知地址'**
  String get lanUnknownAddress;

  /// No description provided for @lanJoin.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get lanJoin;

  /// No description provided for @lanSearching.
  ///
  /// In zh, this message translates to:
  /// **'正在搜索附近棋室…'**
  String get lanSearching;

  /// No description provided for @lanNoRooms.
  ///
  /// In zh, this message translates to:
  /// **'暂未发现房间'**
  String get lanNoRooms;

  /// No description provided for @lanSearchingHint.
  ///
  /// In zh, this message translates to:
  /// **'请保持双方设备连接同一网络。'**
  String get lanSearchingHint;

  /// No description provided for @lanSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角搜索按钮开始查找。'**
  String get lanSearchHint;

  /// No description provided for @lanDiscoveryFailed.
  ///
  /// In zh, this message translates to:
  /// **'搜索附近房间失败，请确认已连接同一网络后重试。'**
  String get lanDiscoveryFailed;

  /// No description provided for @lanHostingFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建房间失败，请检查本地网络后重试。'**
  String get lanHostingFailed;

  /// No description provided for @lanConnectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法加入房间，请确认对方房间仍可用。'**
  String get lanConnectionFailed;

  /// No description provided for @lanOpponentLeft.
  ///
  /// In zh, this message translates to:
  /// **'对方已离开游戏'**
  String get lanOpponentLeft;

  /// No description provided for @lanGameError.
  ///
  /// In zh, this message translates to:
  /// **'局域网对局发生错误，请退出后重试。'**
  String get lanGameError;

  /// No description provided for @lanUnknownState.
  ///
  /// In zh, this message translates to:
  /// **'未知状态'**
  String get lanUnknownState;

  /// No description provided for @lanReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'连接中断，正在等待重连…'**
  String get lanReconnecting;

  /// No description provided for @lanSyncing.
  ///
  /// In zh, this message translates to:
  /// **'正在同步主机棋局…'**
  String get lanSyncing;

  /// No description provided for @lanExitTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出游戏？'**
  String get lanExitTitle;

  /// No description provided for @lanExitDescription.
  ///
  /// In zh, this message translates to:
  /// **'这将断开连接。'**
  String get lanExitDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsAudioSection.
  ///
  /// In zh, this message translates to:
  /// **'音频设置'**
  String get settingsAudioSection;

  /// No description provided for @settingsSoundToggle.
  ///
  /// In zh, this message translates to:
  /// **'音效开关'**
  String get settingsSoundToggle;

  /// No description provided for @settingsSoundDescription.
  ///
  /// In zh, this message translates to:
  /// **'移动、吃子等游戏音效'**
  String get settingsSoundDescription;

  /// No description provided for @settingsSoundVolume.
  ///
  /// In zh, this message translates to:
  /// **'音效音量'**
  String get settingsSoundVolume;

  /// No description provided for @settingsMusicToggle.
  ///
  /// In zh, this message translates to:
  /// **'背景音乐'**
  String get settingsMusicToggle;

  /// No description provided for @settingsMusicDescription.
  ///
  /// In zh, this message translates to:
  /// **'游戏背景音乐'**
  String get settingsMusicDescription;

  /// No description provided for @settingsMusicVolume.
  ///
  /// In zh, this message translates to:
  /// **'音乐音量'**
  String get settingsMusicVolume;

  /// No description provided for @settingsHapticsSection.
  ///
  /// In zh, this message translates to:
  /// **'震动设置'**
  String get settingsHapticsSection;

  /// No description provided for @settingsHapticsToggle.
  ///
  /// In zh, this message translates to:
  /// **'震动反馈'**
  String get settingsHapticsToggle;

  /// No description provided for @settingsHapticsDescription.
  ///
  /// In zh, this message translates to:
  /// **'触摸和游戏操作时的震动反馈'**
  String get settingsHapticsDescription;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In zh, this message translates to:
  /// **'切换应用界面语言'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsAiSection.
  ///
  /// In zh, this message translates to:
  /// **'AI 设置'**
  String get settingsAiSection;

  /// No description provided for @settingsDefaultAiDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'默认 AI 难度'**
  String get settingsDefaultAiDifficulty;

  /// No description provided for @settingsDefaultAiDifficultyDescription.
  ///
  /// In zh, this message translates to:
  /// **'新游戏的默认 AI 难度'**
  String get settingsDefaultAiDifficultyDescription;

  /// No description provided for @settingsBoardThemeSection.
  ///
  /// In zh, this message translates to:
  /// **'棋盘主题'**
  String get settingsBoardThemeSection;

  /// No description provided for @settingsModernEasternTheme.
  ///
  /// In zh, this message translates to:
  /// **'现代东方棋艺'**
  String get settingsModernEasternTheme;

  /// No description provided for @settingsModernEasternThemeDescription.
  ///
  /// In zh, this message translates to:
  /// **'一期默认主题；更多主题将在后续版本开放'**
  String get settingsModernEasternThemeDescription;

  /// No description provided for @settingsAnimationToggle.
  ///
  /// In zh, this message translates to:
  /// **'动画效果'**
  String get settingsAnimationToggle;

  /// No description provided for @settingsAnimationDescription.
  ///
  /// In zh, this message translates to:
  /// **'棋子移动和吃子动画'**
  String get settingsAnimationDescription;

  /// No description provided for @settingsParticleToggle.
  ///
  /// In zh, this message translates to:
  /// **'粒子效果'**
  String get settingsParticleToggle;

  /// No description provided for @settingsParticleDescription.
  ///
  /// In zh, this message translates to:
  /// **'吃子与胜负反馈中的装饰效果'**
  String get settingsParticleDescription;

  /// No description provided for @settingsPrivacyPerformanceSection.
  ///
  /// In zh, this message translates to:
  /// **'隐私与性能'**
  String get settingsPrivacyPerformanceSection;

  /// No description provided for @settingsAnonymousDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'匿名诊断'**
  String get settingsAnonymousDiagnostics;

  /// No description provided for @settingsAnonymousDiagnosticsDescription.
  ///
  /// In zh, this message translates to:
  /// **'发送脱敏崩溃与性能信息；不含棋局内容和广告标识'**
  String get settingsAnonymousDiagnosticsDescription;

  /// No description provided for @settingsResourceWarmup.
  ///
  /// In zh, this message translates to:
  /// **'资源预加载'**
  String get settingsResourceWarmup;

  /// No description provided for @settingsResourceWarmupDescription.
  ///
  /// In zh, this message translates to:
  /// **'提前加载棋盘与音频资源，减少首次操作等待'**
  String get settingsResourceWarmupDescription;

  /// No description provided for @settingsAboutSection.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAboutSection;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本号'**
  String get settingsVersion;

  /// No description provided for @settingsReviewGuide.
  ///
  /// In zh, this message translates to:
  /// **'重新查看游戏说明'**
  String get settingsReviewGuide;

  /// No description provided for @settingsReviewGuideDescription.
  ///
  /// In zh, this message translates to:
  /// **'查看新手引导和游戏规则'**
  String get settingsReviewGuideDescription;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get settingsOpenSourceLicenses;

  /// No description provided for @settingsDangerSection.
  ///
  /// In zh, this message translates to:
  /// **'危险操作'**
  String get settingsDangerSection;

  /// No description provided for @settingsClearStatistics.
  ///
  /// In zh, this message translates to:
  /// **'清空统计数据'**
  String get settingsClearStatistics;

  /// No description provided for @settingsClearStatisticsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将清空累计统计和最近 20 局回放。此操作无法撤销。'**
  String get settingsClearStatisticsConfirm;

  /// No description provided for @settingsStatisticsCleared.
  ///
  /// In zh, this message translates to:
  /// **'统计与最近对局已清空'**
  String get settingsStatisticsCleared;

  /// No description provided for @settingsResetAll.
  ///
  /// In zh, this message translates to:
  /// **'重置所有设置'**
  String get settingsResetAll;

  /// No description provided for @settingsResetAllConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置所有设置和数据吗？此操作无法撤销。'**
  String get settingsResetAllConfirm;

  /// No description provided for @settingsResetAllDone.
  ///
  /// In zh, this message translates to:
  /// **'已重置所有设置'**
  String get settingsResetAllDone;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @onlineBattleTitle.
  ///
  /// In zh, this message translates to:
  /// **'在线对战'**
  String get onlineBattleTitle;

  /// No description provided for @onlineIntroTitle.
  ///
  /// In zh, this message translates to:
  /// **'可靠在线对局'**
  String get onlineIntroTitle;

  /// No description provided for @onlineIntroBody.
  ///
  /// In zh, this message translates to:
  /// **'服务器确认后才会更新棋盘。匿名身份仅用于匹配和断线恢复。'**
  String get onlineIntroBody;

  /// No description provided for @onlineFindOpponent.
  ///
  /// In zh, this message translates to:
  /// **'寻找对手'**
  String get onlineFindOpponent;

  /// No description provided for @onlineConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接服务器…'**
  String get onlineConnecting;

  /// No description provided for @onlineSearching.
  ///
  /// In zh, this message translates to:
  /// **'正在寻找对手…'**
  String get onlineSearching;

  /// No description provided for @onlineCancelSearch.
  ///
  /// In zh, this message translates to:
  /// **'取消匹配'**
  String get onlineCancelSearch;

  /// No description provided for @onlineYourTurn.
  ///
  /// In zh, this message translates to:
  /// **'你的回合'**
  String get onlineYourTurn;

  /// No description provided for @onlineOpponentTurn.
  ///
  /// In zh, this message translates to:
  /// **'对手回合'**
  String get onlineOpponentTurn;

  /// No description provided for @onlineWaitingForServer.
  ///
  /// In zh, this message translates to:
  /// **'等待服务器确认…'**
  String get onlineWaitingForServer;

  /// No description provided for @onlineOpponentDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'对手已断线，棋局仍由服务器计时'**
  String get onlineOpponentDisconnected;

  /// No description provided for @onlineReconnectSeconds.
  ///
  /// In zh, this message translates to:
  /// **'对手还可在 {seconds} 秒内重连'**
  String onlineReconnectSeconds(int seconds);

  /// No description provided for @onlineRecovering.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复权威棋局…'**
  String get onlineRecovering;

  /// No description provided for @onlineRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试连接'**
  String get onlineRetry;

  /// No description provided for @onlineLeave.
  ///
  /// In zh, this message translates to:
  /// **'离开对局'**
  String get onlineLeave;

  /// No description provided for @onlineYouWin.
  ///
  /// In zh, this message translates to:
  /// **'你赢了'**
  String get onlineYouWin;

  /// No description provided for @onlineYouLose.
  ///
  /// In zh, this message translates to:
  /// **'你输了'**
  String get onlineYouLose;

  /// No description provided for @onlineGameDraw.
  ///
  /// In zh, this message translates to:
  /// **'本局和棋'**
  String get onlineGameDraw;

  /// No description provided for @onlineFinished.
  ///
  /// In zh, this message translates to:
  /// **'对局已结束'**
  String get onlineFinished;

  /// No description provided for @onlineMoveRejected.
  ///
  /// In zh, this message translates to:
  /// **'服务器未接受这一步，请根据当前棋盘重试'**
  String get onlineMoveRejected;

  /// No description provided for @onlineYourSide.
  ///
  /// In zh, this message translates to:
  /// **'你执 {side}'**
  String onlineYourSide(String side);

  /// No description provided for @onlineFailureConnection.
  ///
  /// In zh, this message translates to:
  /// **'无法连接在线服务'**
  String get onlineFailureConnection;

  /// No description provided for @onlineFailureIdentity.
  ///
  /// In zh, this message translates to:
  /// **'无法准备匿名在线身份'**
  String get onlineFailureIdentity;

  /// No description provided for @onlineFailureRequest.
  ///
  /// In zh, this message translates to:
  /// **'请求未发送，请重试'**
  String get onlineFailureRequest;

  /// No description provided for @onlineFailureMatch.
  ///
  /// In zh, this message translates to:
  /// **'当前无法开始匹配'**
  String get onlineFailureMatch;

  /// No description provided for @onlineFailureResume.
  ///
  /// In zh, this message translates to:
  /// **'原对局已无法恢复'**
  String get onlineFailureResume;

  /// No description provided for @onlineFailureSnapshot.
  ///
  /// In zh, this message translates to:
  /// **'无法取得最新棋局'**
  String get onlineFailureSnapshot;

  /// No description provided for @onlineFailureProtocol.
  ///
  /// In zh, this message translates to:
  /// **'收到无法识别的服务器消息'**
  String get onlineFailureProtocol;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
