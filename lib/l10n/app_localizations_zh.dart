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
  String get homeTitle => '四子游戏';

  @override
  String get startGame => '开始游戏';

  @override
  String get playerVsPlayer => '双人对战';

  @override
  String get playerVsAI => '人机AI';

  @override
  String get statistics => '战绩统计';

  @override
  String get rules => '游戏规则';

  @override
  String get settings => '设置';

  @override
  String get difficultyEasy => '简单';

  @override
  String get difficultyMedium => '中等';

  @override
  String get difficultyHard => '困难';

  @override
  String get blackPlayer => '黑方';

  @override
  String get whitePlayer => '白方';

  @override
  String get currentTurn => '当前回合';

  @override
  String get moveCount => '移动步数';

  @override
  String get gameOver => '游戏结束';

  @override
  String get blackWins => '黑方胜利！';

  @override
  String get whiteWins => '白方胜利！';

  @override
  String get draw => '平局';

  @override
  String get playAgain => '再来一局';

  @override
  String get backToMenu => '返回主菜单';

  @override
  String get exit => '退出';

  @override
  String get viewReplay => '查看回放';

  @override
  String get undo => '撤销';

  @override
  String get restart => '重新开始';

  @override
  String get pause => '暂停';

  @override
  String get statisticsTitle => '战绩统计';

  @override
  String get totalGames => '总场次';

  @override
  String get wins => '胜场';

  @override
  String get losses => '败场';

  @override
  String get draws => '平局';

  @override
  String get winRate => '胜率';

  @override
  String get maxStreak => '最高连胜';

  @override
  String get avgGameTime => '平均时长';

  @override
  String get totalPlayTime => '总游戏时间';

  @override
  String get rulesTitle => '游戏规则';

  @override
  String get rulesObjective => '游戏目标';

  @override
  String get rulesBasic => '基本规则';

  @override
  String get rulesMovement => '移动规则';

  @override
  String get rulesCapture => '吃子规则';

  @override
  String get settingsTitle => '设置';

  @override
  String get soundEffects => '音效';

  @override
  String get music => '背景音乐';

  @override
  String get vibration => '震动反馈';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get aiDifficulty => 'AI难度';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeDefault => '默认';

  @override
  String get themeClassic => '经典';

  @override
  String get themeNight => '夜间';

  @override
  String get themeColorful => '彩色';

  @override
  String get musicThemeMain => '主菜单';

  @override
  String get musicThemeGameplay => '游戏中';

  @override
  String get musicThemeClassic => '经典';

  @override
  String get musicThemeNight => '夜间';

  @override
  String get musicThemeRelaxing => '轻松';

  @override
  String get replayTitle => '游戏回放';

  @override
  String replayStep(int step, int total) {
    return '第 $step 步 / 共 $total 步';
  }

  @override
  String get initialState => '初始状态';

  @override
  String get moveHistory => '移动历史';

  @override
  String get goToStart => '跳转到开始';

  @override
  String get goToEnd => '跳转到结束';

  @override
  String get stepForward => '前进';

  @override
  String get stepBackward => '后退';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get delete => '删除';

  @override
  String get clear => '清空';

  @override
  String get errorTitle => '错误';

  @override
  String get errorMessage => '发生错误，请重试';

  @override
  String get invalidMove => '非法移动';

  @override
  String get loadingFailed => '加载失败';

  @override
  String get minutes => '分钟';

  @override
  String get seconds => '秒';

  @override
  String get hours => '小时';
}
