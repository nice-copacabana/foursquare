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

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'四子游戏'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'四子游戏'**
  String get homeTitle;

  /// No description provided for @startGame.
  ///
  /// In zh, this message translates to:
  /// **'开始游戏'**
  String get startGame;

  /// No description provided for @playerVsPlayer.
  ///
  /// In zh, this message translates to:
  /// **'双人对战'**
  String get playerVsPlayer;

  /// No description provided for @playerVsAI.
  ///
  /// In zh, this message translates to:
  /// **'人机AI'**
  String get playerVsAI;

  /// No description provided for @statistics.
  ///
  /// In zh, this message translates to:
  /// **'战绩统计'**
  String get statistics;

  /// No description provided for @rules.
  ///
  /// In zh, this message translates to:
  /// **'游戏规则'**
  String get rules;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @difficultyEasy.
  ///
  /// In zh, this message translates to:
  /// **'简单'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In zh, this message translates to:
  /// **'中等'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In zh, this message translates to:
  /// **'困难'**
  String get difficultyHard;

  /// No description provided for @blackPlayer.
  ///
  /// In zh, this message translates to:
  /// **'黑方'**
  String get blackPlayer;

  /// No description provided for @whitePlayer.
  ///
  /// In zh, this message translates to:
  /// **'白方'**
  String get whitePlayer;

  /// No description provided for @currentTurn.
  ///
  /// In zh, this message translates to:
  /// **'当前回合'**
  String get currentTurn;

  /// No description provided for @moveCount.
  ///
  /// In zh, this message translates to:
  /// **'移动步数'**
  String get moveCount;

  /// No description provided for @gameOver.
  ///
  /// In zh, this message translates to:
  /// **'游戏结束'**
  String get gameOver;

  /// No description provided for @blackWins.
  ///
  /// In zh, this message translates to:
  /// **'黑方胜利！'**
  String get blackWins;

  /// No description provided for @whiteWins.
  ///
  /// In zh, this message translates to:
  /// **'白方胜利！'**
  String get whiteWins;

  /// No description provided for @draw.
  ///
  /// In zh, this message translates to:
  /// **'平局'**
  String get draw;

  /// No description provided for @playAgain.
  ///
  /// In zh, this message translates to:
  /// **'再来一局'**
  String get playAgain;

  /// No description provided for @backToMenu.
  ///
  /// In zh, this message translates to:
  /// **'返回主菜单'**
  String get backToMenu;

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @viewReplay.
  ///
  /// In zh, this message translates to:
  /// **'查看回放'**
  String get viewReplay;

  /// No description provided for @undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get undo;

  /// No description provided for @restart.
  ///
  /// In zh, this message translates to:
  /// **'重新开始'**
  String get restart;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @statisticsTitle.
  ///
  /// In zh, this message translates to:
  /// **'战绩统计'**
  String get statisticsTitle;

  /// No description provided for @totalGames.
  ///
  /// In zh, this message translates to:
  /// **'总场次'**
  String get totalGames;

  /// No description provided for @wins.
  ///
  /// In zh, this message translates to:
  /// **'胜场'**
  String get wins;

  /// No description provided for @losses.
  ///
  /// In zh, this message translates to:
  /// **'败场'**
  String get losses;

  /// No description provided for @draws.
  ///
  /// In zh, this message translates to:
  /// **'平局'**
  String get draws;

  /// No description provided for @winRate.
  ///
  /// In zh, this message translates to:
  /// **'胜率'**
  String get winRate;

  /// No description provided for @maxStreak.
  ///
  /// In zh, this message translates to:
  /// **'最高连胜'**
  String get maxStreak;

  /// No description provided for @avgGameTime.
  ///
  /// In zh, this message translates to:
  /// **'平均时长'**
  String get avgGameTime;

  /// No description provided for @totalPlayTime.
  ///
  /// In zh, this message translates to:
  /// **'总游戏时间'**
  String get totalPlayTime;

  /// No description provided for @rulesTitle.
  ///
  /// In zh, this message translates to:
  /// **'游戏规则'**
  String get rulesTitle;

  /// No description provided for @rulesObjective.
  ///
  /// In zh, this message translates to:
  /// **'游戏目标'**
  String get rulesObjective;

  /// No description provided for @rulesBasic.
  ///
  /// In zh, this message translates to:
  /// **'基本规则'**
  String get rulesBasic;

  /// No description provided for @rulesMovement.
  ///
  /// In zh, this message translates to:
  /// **'移动规则'**
  String get rulesMovement;

  /// No description provided for @rulesCapture.
  ///
  /// In zh, this message translates to:
  /// **'吃子规则'**
  String get rulesCapture;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @soundEffects.
  ///
  /// In zh, this message translates to:
  /// **'音效'**
  String get soundEffects;

  /// No description provided for @music.
  ///
  /// In zh, this message translates to:
  /// **'背景音乐'**
  String get music;

  /// No description provided for @vibration.
  ///
  /// In zh, this message translates to:
  /// **'震动反馈'**
  String get vibration;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @aiDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'AI难度'**
  String get aiDifficulty;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get themeDefault;

  /// No description provided for @themeClassic.
  ///
  /// In zh, this message translates to:
  /// **'经典'**
  String get themeClassic;

  /// No description provided for @themeNight.
  ///
  /// In zh, this message translates to:
  /// **'夜间'**
  String get themeNight;

  /// No description provided for @themeColorful.
  ///
  /// In zh, this message translates to:
  /// **'彩色'**
  String get themeColorful;

  /// No description provided for @musicThemeMain.
  ///
  /// In zh, this message translates to:
  /// **'主菜单'**
  String get musicThemeMain;

  /// No description provided for @musicThemeGameplay.
  ///
  /// In zh, this message translates to:
  /// **'游戏中'**
  String get musicThemeGameplay;

  /// No description provided for @musicThemeClassic.
  ///
  /// In zh, this message translates to:
  /// **'经典'**
  String get musicThemeClassic;

  /// No description provided for @musicThemeNight.
  ///
  /// In zh, this message translates to:
  /// **'夜间'**
  String get musicThemeNight;

  /// No description provided for @musicThemeRelaxing.
  ///
  /// In zh, this message translates to:
  /// **'轻松'**
  String get musicThemeRelaxing;

  /// No description provided for @replayTitle.
  ///
  /// In zh, this message translates to:
  /// **'游戏回放'**
  String get replayTitle;

  /// 回放步骤描述
  ///
  /// In zh, this message translates to:
  /// **'第 {step} 步 / 共 {total} 步'**
  String replayStep(int step, int total);

  /// No description provided for @initialState.
  ///
  /// In zh, this message translates to:
  /// **'初始状态'**
  String get initialState;

  /// No description provided for @moveHistory.
  ///
  /// In zh, this message translates to:
  /// **'移动历史'**
  String get moveHistory;

  /// No description provided for @goToStart.
  ///
  /// In zh, this message translates to:
  /// **'跳转到开始'**
  String get goToStart;

  /// No description provided for @goToEnd.
  ///
  /// In zh, this message translates to:
  /// **'跳转到结束'**
  String get goToEnd;

  /// No description provided for @stepForward.
  ///
  /// In zh, this message translates to:
  /// **'前进'**
  String get stepForward;

  /// No description provided for @stepBackward.
  ///
  /// In zh, this message translates to:
  /// **'后退'**
  String get stepBackward;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @errorTitle.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In zh, this message translates to:
  /// **'发生错误，请重试'**
  String get errorMessage;

  /// No description provided for @invalidMove.
  ///
  /// In zh, this message translates to:
  /// **'非法移动'**
  String get invalidMove;

  /// No description provided for @loadingFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadingFailed;

  /// No description provided for @minutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get seconds;

  /// No description provided for @hours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get hours;
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
