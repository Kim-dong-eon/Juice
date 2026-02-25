import 'package:flutter/material.dart';

class FruitAnalysisHistoryScreen extends StatelessWidget {
  final Map<String, Map<String, int>> fruitAnalysisHistory; // 날짜별 과일 분석 기록

  FruitAnalysisHistoryScreen({required this.fruitAnalysisHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('과채류 분석 내역'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: fruitAnalysisHistory.length,
        itemBuilder: (context, index) {
          final date = fruitAnalysisHistory.keys.elementAt(index);
          final fruitData = fruitAnalysisHistory[date]!;

          return Card(
            margin: EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...fruitData.entries.map((entry) {
                    return Text('${entry.key}: ${entry.value}개');
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
