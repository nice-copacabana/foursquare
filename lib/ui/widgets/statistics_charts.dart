/// Statistics Chart Widgets - 统计图表组件
/// 
/// 职责：
/// - 提供胜率趋势图
/// - 提供时间分布图
/// - 使用fl_chart绘制图表

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 胜率趋势图组件
class WinRateTrendChart extends StatelessWidget {
  /// 历史胜率数据 (日期 -> 胜率)
  final Map<DateTime, double> winRateData;
  
  const WinRateTrendChart({
    super.key,
    required this.winRateData,
  });

  @override
  Widget build(BuildContext context) {
    if (winRateData.isEmpty) {
      return _buildEmptyChart('暂无胜率数据');
    }

    final sortedEntries = winRateData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 转换为图表数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value * 100));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedEntries.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 游戏时间分布图组件
class GameTimeDistributionChart extends StatelessWidget {
  /// 时间段游戏数据 (小时 -> 游戏数)
  final Map<int, int> timeDistribution;
  
  const GameTimeDistributionChart({
    super.key,
    required this.timeDistribution,
  });

  @override
  Widget build(BuildContext context) {
    if (timeDistribution.isEmpty) {
      return _buildEmptyChart('暂无时间分布数据');
    }

    // 转换为柱状图数据
    final barGroups = <BarChartGroupData>[];
    final maxCount = timeDistribution.values.reduce((a, b) => a > b ? a : b);

    for (int hour = 0; hour < 24; hour++) {
      final count = timeDistribution[hour] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: _getColorForHour(hour),
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceilToDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${group.x}:00\n${rod.toY.toInt()}局',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCount > 10 ? (maxCount / 5).ceilToDouble() : 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Color _getColorForHour(int hour) {
    // 早晨 (6-12): 橙色
    if (hour >= 6 && hour < 12) {
      return Colors.orange;
    }
    // 下午 (12-18): 蓝色
    else if (hour >= 12 && hour < 18) {
      return Colors.blue;
    }
    // 晚上 (18-22): 紫色
    else if (hour >= 18 && hour < 22) {
      return Colors.purple;
    }
    // 深夜/凌晨 (22-6): 深蓝色
    else {
      return Colors.indigo;
    }
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 难度战绩饼图组件
class DifficultyPieChart extends StatelessWidget {
  /// 难度战绩数据 (难度 -> 胜利次数)
  final Map<String, int> difficultyWins;
  
  const DifficultyPieChart({
    super.key,
    required this.difficultyWins,
  });

  @override
  Widget build(BuildContext context) {
    if (difficultyWins.isEmpty || difficultyWins.values.every((v) => v == 0)) {
      return _buildEmptyChart('暂无难度战绩数据');
    }

    final total = difficultyWins.values.reduce((a, b) => a + b);
    final sections = <PieChartSectionData>[];
    
    final colors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
    };

    final labels = {
      'easy': '简单',
      'medium': '中等',
      'hard': '困难',
    };

    difficultyWins.forEach((difficulty, wins) {
      if (wins > 0) {
        final percentage = (wins / total * 100).toStringAsFixed(1);
        sections.add(
          PieChartSectionData(
            value: wins.toDouble(),
            title: '$percentage%',
            color: colors[difficulty] ?? Colors.grey,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _Badge(
              labels[difficulty] ?? difficulty,
              size: 40,
              borderColor: colors[difficulty] ?? Colors.grey,
            ),
            badgePositionPercentageOffset: 1.5,
          ),
        );
      }
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 图表徽章组件
class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.25,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}
