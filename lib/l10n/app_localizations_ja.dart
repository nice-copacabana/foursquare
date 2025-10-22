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
  String get homeTitle => '四子ゲーム';

  @override
  String get startGame => 'ゲーム開始';

  @override
  String get playerVsPlayer => '対人戦';

  @override
  String get playerVsAI => 'AI対戦';

  @override
  String get statistics => '統計';

  @override
  String get rules => 'ルール';

  @override
  String get settings => '設定';

  @override
  String get difficultyEasy => '簡単';

  @override
  String get difficultyMedium => '普通';

  @override
  String get difficultyHard => '難しい';

  @override
  String get blackPlayer => '黒';

  @override
  String get whitePlayer => '白';

  @override
  String get currentTurn => '現在のターン';

  @override
  String get moveCount => '手数';

  @override
  String get gameOver => 'ゲーム終了';

  @override
  String get blackWins => '黒の勝利！';

  @override
  String get whiteWins => '白の勝利！';

  @override
  String get draw => '引き分け';

  @override
  String get playAgain => 'もう一度';

  @override
  String get backToMenu => 'メニューへ';

  @override
  String get exit => '終了';

  @override
  String get viewReplay => 'リプレイ';

  @override
  String get undo => '元に戻す';

  @override
  String get restart => '再開';

  @override
  String get pause => '一時停止';

  @override
  String get statisticsTitle => '統計';

  @override
  String get totalGames => '総ゲーム数';

  @override
  String get wins => '勝利';

  @override
  String get losses => '敗北';

  @override
  String get draws => '引き分け';

  @override
  String get winRate => '勝率';

  @override
  String get maxStreak => '最高連勝';

  @override
  String get avgGameTime => '平均時間';

  @override
  String get totalPlayTime => '総プレイ時間';

  @override
  String get rulesTitle => 'ゲームルール';

  @override
  String get rulesObjective => '目的';

  @override
  String get rulesBasic => '基本ルール';

  @override
  String get rulesMovement => '移動ルール';

  @override
  String get rulesCapture => '取るルール';

  @override
  String get settingsTitle => '設定';

  @override
  String get soundEffects => '効果音';

  @override
  String get music => '音楽';

  @override
  String get vibration => '振動';

  @override
  String get theme => 'テーマ';

  @override
  String get language => '言語';

  @override
  String get aiDifficulty => 'AI難易度';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeDefault => 'デフォルト';

  @override
  String get themeClassic => 'クラシック';

  @override
  String get themeNight => 'ナイト';

  @override
  String get themeColorful => 'カラフル';

  @override
  String get musicThemeMain => 'メインメニュー';

  @override
  String get musicThemeGameplay => 'ゲームプレイ';

  @override
  String get musicThemeClassic => 'クラシック';

  @override
  String get musicThemeNight => 'ナイト';

  @override
  String get musicThemeRelaxing => 'リラックス';

  @override
  String get replayTitle => 'ゲームリプレイ';

  @override
  String replayStep(int step, int total) {
    return '$step手目 / 全$total手';
  }

  @override
  String get initialState => '初期状態';

  @override
  String get moveHistory => '手の履歴';

  @override
  String get goToStart => '最初へ';

  @override
  String get goToEnd => '最後へ';

  @override
  String get stepForward => '次へ';

  @override
  String get stepBackward => '前へ';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get delete => '削除';

  @override
  String get clear => 'クリア';

  @override
  String get errorTitle => 'エラー';

  @override
  String get errorMessage => 'エラーが発生しました。もう一度お試しください';

  @override
  String get invalidMove => '無効な移動';

  @override
  String get loadingFailed => '読み込み失敗';

  @override
  String get minutes => '分';

  @override
  String get seconds => '秒';

  @override
  String get hours => '時間';
}
