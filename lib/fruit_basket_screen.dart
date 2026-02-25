import 'package:flutter/material.dart';

class FruitBasketScreen extends StatefulWidget {
  @override
  _FruitBasketScreenState createState() => _FruitBasketScreenState();
}

class _FruitBasketScreenState extends State<FruitBasketScreen> {
  List<String> selectedFruits = [];

  final List<String> fruits = [
    '사과', '바나나', '오렌지', '딸기', '포도', '수박', '망고', '파인애플'
  ];

  void _toggleFruitSelection(String fruit) {
    setState(() {
      if (selectedFruits.contains(fruit)) {
        selectedFruits.remove(fruit);
      } else {
        selectedFruits.add(fruit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("내가 원하는 과일바구니")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "원하는 과일을 선택하세요!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fruits.map((fruit) {
                bool isSelected = selectedFruits.contains(fruit);
                return ChoiceChip(
                  label: Text(fruit),
                  selected: isSelected,
                  selectedColor: Colors.green.shade300,
                  onSelected: (selected) {
                    _toggleFruitSelection(fruit);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              "선택한 과일: ${selectedFruits.join(", ")}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
