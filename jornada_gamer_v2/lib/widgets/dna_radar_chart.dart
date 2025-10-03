import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DnaRadarChart extends StatelessWidget {
  final Map<String, double> chartData;

  const DnaRadarChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor = const Color(0xFFA0A0A0);
    final titles = chartData.keys.toList();
    final values = chartData.values.toList();

    return RadarChart(
      RadarChartData(
        getTitle: (index, angle) {
          if (index < titles.length) {
            return RadarChartTitle(text: titles[index], angle: angle);
          }
          return const RadarChartTitle(text: '');
        },
        titleTextStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
        gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.4), width: 2),
        tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        borderData: FlBorderData(show: false),
        dataSets: [
          RadarDataSet(
            dataEntries: values.map((value) => RadarEntry(value: value)).toList(),
            borderColor: primaryColor,
            fillColor: primaryColor.withOpacity(0.3),
            borderWidth: 3,
          ),
        ],
      ),
    );
  }
}