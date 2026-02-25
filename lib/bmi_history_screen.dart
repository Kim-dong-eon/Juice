import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'bmi_calculator_screen.dart'; // BmiRecord 클래스 가져오기

class BmiHistoryScreen extends StatelessWidget {
  final List<BmiRecord> bmiHistory;

  BmiHistoryScreen({required this.bmiHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI 변화 기록"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'BMI 기록 그래프',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 16),
            _buildBmiChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiChart() {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 15, // BMI 그래프의 최소 Y값
          maxY: 35, // BMI 그래프의 최대 Y값
          lineBarsData: [
            LineChartBarData(
              spots: bmiHistory.asMap().entries.map((entry) {
                int idx = entry.key;
                BmiRecord record = entry.value;
                return FlSpot(idx.toDouble(), record.bmi);
              }).toList(),
              isCurved: true,
              color: Colors.green[700],
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, _) {
                  int idx = value.toInt();
                  if (idx < bmiHistory.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        bmiHistory[idx].date.toString().split(' ')[0],
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    );
                  } else {
                    return Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 40,
                getTitlesWidget: (value, _) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
        ),
      ),
    );
  }
}
