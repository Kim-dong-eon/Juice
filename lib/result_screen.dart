// result_screen.dart
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String gender;
  final String ageGroup;
  final Map<String, int> consumedFood;

  ResultScreen({required this.gender, required this.ageGroup, required this.consumedFood});

  final Map<String, Map<String, dynamic>> recommendedIntake = {
    "남": {
      "6~8": {"칼로리": 1600, "탄수화물": 130, "지방": 70, "단백질": 35, "수분": 1700},
      "9~11": {"칼로리": 1900, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 2000},
      "12~14": {"칼로리": 2400, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2400},
      "15~19": {"칼로리": 2700, "탄수화물": 130, "지방": 135, "단백질": 65, "수분": 2700},
      "20~29": {"칼로리": 2600, "탄수화물": 130, "지방": 130, "단백질": 65, "수분": 2700},
      "30~49": {"칼로리": 2400, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2500},
      "50~64": {"칼로리": 2200, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2300},
      "65~74": {"칼로리": 2000, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2100},
      "75 이상": {"칼로리": 2000, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2100},
    },
    "여": {
      "6~8": {"칼로리": 1500, "탄수화물": 130, "지방": 70, "단백질": 35, "수분": 1600},
      "9~11": {"칼로리": 1700, "탄수화물": 130, "지방": 90, "단백질": 45, "수분": 1800},
      "12~14": {"칼로리": 2000, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2000},
      "15~19": {"칼로리": 2000, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2100},
      "20~29": {"칼로리": 2100, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2100},
      "30~49": {"칼로리": 1900, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 2000},
      "50~64": {"칼로리": 1800, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1800},
      "65~74": {"칼로리": 1600, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1700},
      "75 이상": {"칼로리": 1600, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1700},
    }
  };

  final List<Map<String, dynamic>> foodData = [
    {
      "name": "Apple",
      "energy": 52,
      "water": 85.5,
      "protein": 0.26,
      "fat": 0.07,
      "ash": 0.22,
      "carbs": 13.96,
      "sugar": 10.62
    },
    // Add more foods as needed
  ];

  @override
  Widget build(BuildContext context) {
    final recommended = recommendedIntake[gender]?[ageGroup] ?? {};
    final Map<String, double> consumed = {
      "칼로리": 0.0,
      "탄수화물": 0.0,
      "지방": 0.0,
      "단백질": 0.0,
      "수분": 0.0,
    };

    consumedFood.forEach((food, quantity) {
      final foodNutrients = foodData.firstWhere(
            (item) => item['name'].toString().toLowerCase() == food.toLowerCase().trim(),
        orElse: () => <String, dynamic>{},
      );

      if (foodNutrients.isNotEmpty) {
        consumed['칼로리'] = (consumed['칼로리'] ?? 0) + (foodNutrients['energy'] ?? 0) * quantity;
        consumed['탄수화물'] = (consumed['탄수화물'] ?? 0) + (foodNutrients['carbs'] ?? 0) * quantity;
        consumed['지방'] = (consumed['지방'] ?? 0) + (foodNutrients['fat'] ?? 0) * quantity;
        consumed['단백질'] = (consumed['단백질'] ?? 0) + (foodNutrients['protein'] ?? 0) * quantity;
        consumed['수분'] = (consumed['수분'] ?? 0) + (foodNutrients['water'] ?? 0) * quantity;
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('섭취량 분석결과', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              '권장 섭취량 대비 결과',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildSlider(context, '칼로리', consumed['칼로리'] ?? 0, recommended['칼로리'] ?? 1),
            _buildSlider(context, '탄수화물', consumed['탄수화물'] ?? 0, recommended['탄수화물'] ?? 1),
            _buildSlider(context, '지방', consumed['지방'] ?? 0, recommended['지방'] ?? 1),
            _buildSlider(context, '단백질', consumed['단백질'] ?? 0, recommended['단백질'] ?? 1),
            _buildSlider(context, '수분', consumed['수분'] ?? 0, recommended['수분'] ?? 1),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back, color: Colors.white),
              label: Text('Back', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(BuildContext context, String nutrient, num consumed, num recommended) {
    num percentage = (consumed / recommended).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$nutrient: ${consumed.toStringAsFixed(1)}g / ${recommended.toStringAsFixed(1)}g',
          style: TextStyle(fontSize: 18),
        ),
        Slider(
          value: percentage.toDouble(),
          onChanged: (value) {},
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: (percentage * 100).toStringAsFixed(0) + '%',
          activeColor: Colors.green,
          inactiveColor: Colors.green[100],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
