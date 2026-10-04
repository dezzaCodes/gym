import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../theme.dart';

/// Plots one line per time this exercise was completed: set number on the
/// x-axis, weight (or reps, for exercises with no weight logged) on the
/// y-axis, so progress across sessions is visible set by set. Doing the
/// exercise more than once on the same day gets its own line rather than
/// merging into (or overwriting) the earlier one.
class ExerciseChart extends StatelessWidget {
  final List<ExerciseHistoryInstance> history;
  const ExerciseChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    // Sort by date, breaking ties by original order so same-day entries
    // (e.g. an earlier completed session plus today's in-progress one)
    // keep a stable, predictable order rather than an arbitrary one.
    final indexed = List.generate(history.length, (i) => (i, history[i]));
    indexed.sort((a, b) {
      final cmp = a.$2.date.compareTo(b.$2.date);
      return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
    });
    final sorted = indexed.map((e) => e.$2).toList();

    // Cap to the most recent occurrences so each gets its own distinct
    // color from the fixed palette rather than colors repeating.
    final recent = sorted.length > AppColors.setColors.length
        ? sorted.sublist(sorted.length - AppColors.setColors.length)
        : sorted;

    final allSets = recent.expand((inst) => inst.sets).toList();
    final usesWeight = allSets.any((s) => s.weight != null);
    final yLabel = usesWeight ? 'Weight' : 'Reps';

    final Map<int, List<FlSpot>> valueByInstance = {};
    for (var i = 0; i < recent.length; i++) {
      for (final s in recent[i].sets) {
        final value = usesWeight ? s.weight : s.reps?.toDouble();
        if (value == null) continue;
        valueByInstance.putIfAbsent(i, () => []).add(FlSpot(s.setNumber.toDouble(), value));
      }
    }
    for (final spots in valueByInstance.values) {
      spots.sort((a, b) => a.x.compareTo(b.x));
    }

    if (valueByInstance.isEmpty) {
      return const Text(
        'No weight or reps logged for this exercise yet.',
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      );
    }

    final instances = valueByInstance.keys.toList()..sort();
    final instanceColor = <int, Color>{
      for (var j = 0; j < instances.length; j++) instances[j]: AppColors.setColors[j % AppColors.setColors.length],
    };

    // Same-day repeats get a "#2", "#3", ... suffix so the legend and
    // tooltips can still tell them apart; a date that only occurs once
    // stays as plain "01-08".
    final dateOccurrences = <String, int>{};
    for (final idx in instances) {
      final date = recent[idx].date;
      dateOccurrences[date] = (dateOccurrences[date] ?? 0) + 1;
    }
    final dateRunningCount = <String, int>{};
    final labels = <int, String>{};
    for (final idx in instances) {
      final date = recent[idx].date;
      final short = _shortDate(date);
      if (dateOccurrences[date]! <= 1) {
        labels[idx] = short;
      } else {
        final n = (dateRunningCount[date] ?? 0) + 1;
        dateRunningCount[date] = n;
        labels[idx] = '$short #$n';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              gridData: _grid,
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              titlesData: _titlesData(yLabel),
              lineTouchData: _touchData(instances.map((idx) => labels[idx]!).toList(), yLabel),
              lineBarsData: instances.map((idx) {
                return LineChartBarData(
                  spots: valueByInstance[idx]!,
                  isCurved: true,
                  color: instanceColor[idx],
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: instances.map((idx) => _legendItem(instanceColor[idx]!, labels[idx]!)).toList(),
        ),
      ],
    );
  }

  static FlGridData get _grid => FlGridData(
        show: true,
        getDrawingHorizontalLine: (v) => const FlLine(color: AppColors.border, strokeWidth: 1),
        getDrawingVerticalLine: (v) => const FlLine(color: AppColors.border, strokeWidth: 1),
      );

  static FlTitlesData _titlesData(String yLabel) => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          axisNameWidget: Text(yLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          axisNameSize: 18,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text('Set number', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          axisNameSize: 18,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final n = value.round();
              if (n < 1 || (value - n).abs() > 0.01) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$n', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              );
            },
          ),
        ),
      );

  static LineTouchData _touchData(List<String> labels, String yLabel) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => AppColors.panelAlt,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              '$yLabel: ${formatNumber(spot.y)}\n',
              const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Set ${spot.x.toInt()} · ${labels[spot.barIndex]}',
                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal, fontSize: 11),
                ),
              ],
            );
          }).toList();
        },
      ),
    );
  }

  static const _monthAbbrevs = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Australian-style day-month, e.g. "25-Sep" — [date] is stored as
  // "YYYY-MM-DD".
  static String _shortDate(String date) {
    if (date.length < 10) return date;
    final month = int.tryParse(date.substring(5, 7));
    final day = date.substring(8, 10);
    if (month == null || month < 1 || month > 12) return date.substring(5);
    return '$day-${_monthAbbrevs[month - 1]}';
  }

  static Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
