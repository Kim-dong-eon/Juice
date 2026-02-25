import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'food_data.dart';
import 'fruit_analysis_screen.dart';
import 'recommended_fruit_dialog.dart';

class DailyIntakeScreen extends StatefulWidget {
  final Map<String, int> consumedFood;
  final Map<String, Map<String, int>> fruitAnalysisHistory;
  final String gender;
  final String ageGroup;
  final String healthCondition; // ✅ 추가 (사용자의 건강 상태)
  final String? selectedKidneyDisease; // ✅ 선택한 신장병 추가
  final Function(Map<String, int>) onUpdateConsumedFood;

  DailyIntakeScreen({
    Key? key,
    required this.consumedFood,
    required this.fruitAnalysisHistory,
    required this.gender,
    required this.ageGroup,
    required this.onUpdateConsumedFood,
    required this.healthCondition, // ✅ 생성자에 추가
    this.selectedKidneyDisease, // ✅ 선택한 신장병 추가 (null 가능)

  }) : super(key: key);

  @override
  _DailyIntakeScreenState createState() => _DailyIntakeScreenState();
}

class _DailyIntakeScreenState extends State<DailyIntakeScreen> {
  late Map<String, int> _localConsumedFood;
  Map<String, double> accumulatedNutrients = {
    "칼로리": 0.0,
    "수분": 0.0,
    "탄수화물": 0.0,
    "당류": 0.0,
    "지방": 0.0,
    "단백질": 0.0,
    "회분": 0.0,
    "식이섬유": 0.0,
    "비타민A": 0.0,
    "비타민B6": 0.0,
    "비타민C": 0.0,
    "칼륨": 0.0,
    "마그네슘": 0.0,
  };

  void _showRecommendedFruits() {
    // ✅ gender 값을 recommendedIntake 키와 일치하도록 변환
    final String normalizedGender = widget.gender == "남자" ? "남" : "여";

    print("🔍 현재 gender: ${widget.gender} (변환 후: $normalizedGender), ageGroup: ${widget.ageGroup}");
    print("🔍 recommendedIntake 전체 데이터: $recommendedIntake"); // 전체 데이터 출력

    // ✅ recommendedIntake에서 gender 키 확인
    if (!recommendedIntake.containsKey(normalizedGender)) {
      print("⚠️ ERROR: recommendedIntake에 ${normalizedGender} 키가 없습니다!");
    } else {
      print("✅ recommendedIntake에 ${normalizedGender} 키 존재");
    }

    // ✅ 변환된 gender로 recommendedIntake 조회
    final recommendedNutrients = recommendedIntake[normalizedGender]?[widget.ageGroup];

    if (recommendedNutrients == null) {
      print("⚠️ ERROR: recommendedIntake에서 ${normalizedGender} - ${widget.ageGroup}에 대한 데이터가 없습니다!");
    } else {
      print("✅ recommendedNutrients 가져오기 성공: $recommendedNutrients");
    }

    RecommendedFruitDialog.show(
      context,
      accumulatedNutrients,
      recommendedNutrients ?? {},  // ✅ null 방지
      normalizedGender,  // ✅ 변환된 gender 전달
      widget.ageGroup,
      widget.healthCondition, // ✅ healthCondition 추가
      widget.selectedKidneyDisease, // ✅ selectedKidneyDisease 추가

    );
  }




  @override
  void initState() {
    super.initState();

    // ✅ gender 값을 recommendedIntake 키와 일치하도록 변환
    final String normalizedGender = widget.gender == "남자" ? "남" : "여";

    print("🔍 DailyIntakeScreen - 전달받은 gender: ${widget.gender} (변환 후: $normalizedGender), ageGroup: ${widget.ageGroup}");

    // ✅ 변환된 gender로 recommendedIntake 조회
    final recommendedNutrients = recommendedIntake[normalizedGender]?[widget.ageGroup];

    if (recommendedNutrients == null) {
      print("⚠️ ERROR: recommendedIntake에서 해당 gender($normalizedGender)와 ageGroup(${widget.ageGroup})에 대한 데이터를 찾을 수 없습니다!");
    } else {
      print("✅ recommendedIntake에서 해당 데이터 찾음: $recommendedNutrients");
    }

    // ✅ 초기 섭취 데이터 반영
    _localConsumedFood = Map.from(widget.consumedFood);
    _updateAccumulatedNutrients();  // 🚀 데이터 업데이트
  }

  @override
  void didUpdateWidget(DailyIntakeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.consumedFood != oldWidget.consumedFood) {
      _localConsumedFood = Map.from(widget.consumedFood);
      _updateAccumulatedNutrients();  // 🚀 데이터 업데이트
      print('🔄 DailyIntakeScreen - Widget updated with new data: ${widget.consumedFood}');
    }
  }

  void onFruitDetected(Map<String, Map<String, int>> detectedFruits) {
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (detectedFruits.containsKey(today)) {
      setState(() {
        detectedFruits[today]!.forEach((fruitName, count) {
          print("🟠 DailyIntakeScreen - 기존 개수: $fruitName = ${_localConsumedFood[fruitName]}"); // ✅ 디버깅 로그 추가
          if (count < 0) {
            if (_localConsumedFood.containsKey(fruitName)) {
              _localConsumedFood.update(
                fruitName,
                    (existingCount) => (existingCount + count).clamp(0, double.infinity).toInt(),
              );
            }
          } else {
            _localConsumedFood.update(
              fruitName,
                  (existingCount) => existingCount + count,
              ifAbsent: () => count,
            );
          }
          print("🟠 DailyIntakeScreen - 업데이트 후: $fruitName = ${_localConsumedFood[fruitName]} (count: $count)"); // ✅ 디버깅 로그 추가
        });

        _localConsumedFood.removeWhere((key, value) => value <= 0);

        widget.onUpdateConsumedFood(_localConsumedFood);
        _updateAccumulatedNutrients();
        print('🔄 최종 업데이트된 데이터: $_localConsumedFood');
      });
    }
  }




  Map<String, int> detectedClassCounts = {};  // 탐지된 과일 임시 저장소


  void _updateAccumulatedNutrients() {
    print('🔄 Updating accumulated nutrients...');
    setState(() {
      accumulatedNutrients = {
        "칼로리": 0.0,
        "수분": 0.0,
        "탄수화물": 0.0,
        "당류": 0.0,
        "지방": 0.0,
        "단백질": 0.0,
        "회분": 0.0,
        "식이섬유": 0.0,
        "비타민A": 0.0,
        "비타민B6": 0.0,
        "비타민C": 0.0,
        "칼륨": 0.0,
        "마그네슘": 0.0,
      };

      _localConsumedFood.forEach((foodName, count) {
        final foodNutrients = foodData.firstWhere(
              (item) => item['name'].toString().toLowerCase() == foodName.toLowerCase(),
          orElse: () => {},
        );

        if (foodNutrients.isNotEmpty) {
          accumulatedNutrients.update("칼로리", (value) => value + (foodNutrients['energy'] ?? 0) * count);
          accumulatedNutrients.update("수분", (value) => value + (foodNutrients['water'] ?? 0) * count);
          accumulatedNutrients.update("탄수화물", (value) => value + (foodNutrients['carbs'] ?? 0) * count);
          accumulatedNutrients.update("당류", (value) => value + (foodNutrients['sugar'] ?? 0) * count);
          accumulatedNutrients.update("지방", (value) => value + (foodNutrients['fat'] ?? 0) * count);
          accumulatedNutrients.update("단백질", (value) => value + (foodNutrients['protein'] ?? 0) * count);
          accumulatedNutrients.update("회분", (value) => value + (foodNutrients['ash'] ?? 0) * count);
          accumulatedNutrients.update("식이섬유", (value) => value + (foodNutrients['dietaryFiber'] ?? 0) * count);
          accumulatedNutrients.update("비타민A", (value) => value + (foodNutrients['vitaminA'] ?? 0) * count);
          accumulatedNutrients.update("비타민B6", (value) => value + (foodNutrients['vitaminB6'] ?? 0) * count);
          accumulatedNutrients.update("비타민C", (value) => value + (foodNutrients['vitaminC'] ?? 0) * count);
          accumulatedNutrients.update("칼륨", (value) => value + (foodNutrients['potassium'] ?? 0) * count);
          accumulatedNutrients.update("마그네슘", (value) => value + (foodNutrients['magnesium'] ?? 0) * count);
        }
      });

      print('🔄 Updated nutrients: $accumulatedNutrients');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('일일 섭취량 분석'),
            ),

            // ✅ 신장병이 있는 경우, 오른쪽 상단에 버튼 스타일의 경고 표시
            if (widget.selectedKidneyDisease != null)
              Align(
                alignment: Alignment.centerRight, // 항상 오른쪽 상단 고정
                child: OutlinedButton(
                  onPressed: () => _showKidneyDiseaseWarningDialog(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // 둥근 모서리
                    side: BorderSide(color: Colors.amber[800]!, width: 1.5), // 노란색 테두리 추가
                    backgroundColor: Colors.amber[50], // 🔥 부드러운 노란색 배경
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 패딩 조정
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // 최소 크기만 차지하도록 설정
                    children: [
                      Icon(
                        Icons.warning_amber_rounded, // ⚠️ 삼각형 경고 아이콘
                        color: Colors.amber[800], // 🔥 진한 노란색
                        size: 24, // 크기 조정
                      ),
                      SizedBox(width: 6), // 아이콘과 텍스트 사이 간격 추가
                      Text(
                        "경고",
                        style: TextStyle(
                          fontSize: 16, // 텍스트 크기 증가
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900], // 텍스트 색상 (진한 노란색)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '섭취된 영양소 그래프',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    RecommendedFruitDialog.show(context, accumulatedNutrients, recommendedIntake[widget.gender]?[widget.ageGroup] ?? {}, widget.gender,                               // ✅ 성별 추가
                      widget.ageGroup,widget.healthCondition,   widget.selectedKidneyDisease, // ✅ selectedKidneyDisease 추가
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("추천과일! 🍊"),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildCircularIndicators(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConsumedFoodDetails() {
    return _localConsumedFood.entries.map((entry) {
      final foodName = entry.key;
      final count = entry.value;
      final foodNutrients = foodData.firstWhere(
            (item) => item['name'].toString().toLowerCase() == foodName.toLowerCase(),
        orElse: () => {},
      );

      if (foodNutrients.isNotEmpty) {
        final totalEnergy = (foodNutrients['energy'] ?? 0) * count;
        final totalWater = (foodNutrients['water'] ?? 0) * count;
        final totalProtein = (foodNutrients['protein'] ?? 0) * count;
        final totalFat = (foodNutrients['fat'] ?? 0) * count;
        final totalCarbs = (foodNutrients['carbs'] ?? 0) * count;
        final totalSugar = (foodNutrients['sugar'] ?? 0) * count;
        final totalAsh = (foodNutrients['ash'] ?? 0) * count;
        final totalFiber = (foodNutrients['dietaryFiber'] ?? 0) * count;
        final totalVitaminA = (foodNutrients['vitaminA'] ?? 0) * count;
        final totalVitaminB6 = (foodNutrients['vitaminB6'] ?? 0) * count;
        final totalVitaminC = (foodNutrients['vitaminC'] ?? 0) * count;
        final totalPotassium = (foodNutrients['potassium'] ?? 0) * count;
        final totalMagnesium = (foodNutrients['magnesium'] ?? 0) * count;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$foodName: $count개'),
            Text('  칼로리: ${totalEnergy.toStringAsFixed(1)} kcal'),
            Text('  수분: ${totalWater.toStringAsFixed(1)} g'),
            Text('  단백질: ${totalProtein.toStringAsFixed(2)} g'),
            Text('  지방: ${totalFat.toStringAsFixed(2)} g'),
            Text('  탄수화물: ${totalCarbs.toStringAsFixed(2)} g'),
            Text('  당류: ${totalSugar.toStringAsFixed(2)} g'),
            Text('  식이섬유: ${totalFiber.toStringAsFixed(2)} g'),
            Text('  회분: ${totalAsh.toStringAsFixed(2)} g'),
            Text('  비타민 A: ${totalVitaminA.toStringAsFixed(1)} μg'),
            Text('  비타민 B6: ${totalVitaminB6.toStringAsFixed(3)} mg'),
            Text('  비타민 C: ${totalVitaminC.toStringAsFixed(1)} mg'),
            Text('  칼륨: ${totalPotassium.toStringAsFixed(1)} mg'),
            Text('  마그네슘: ${totalMagnesium.toStringAsFixed(1)} mg'),
            SizedBox(height: 10),
          ],
        );
      } else {
        return Text('$foodName: $count개');
      }
    }).toList();
  }

  // 질병별 칼륨 기준치
  final Map<String, int> diseasePotassiumLimits = {
    "사구체신염": 1000, // 핍뇨기 기준
    "신증후군": 2000, // 제한 없음 (일반적으로)
    "급성 신손상": 1200, // 1200~2000 사이
    "신부전": 2000, // 고칼륨혈증 없을 시 제한 없음
    "혈액투석": 2000, // 2000~3000
    "복막투석": 3000, // 3000~4000
    "신장이식": 2000, // 초기 2000~4000
  };
  final Map<String, Map<String, dynamic>> recommendedIntake = {
    "남": {
      "6~8": {"칼로리": 1600, "탄수화물": 130, "지방": 70, "단백질": 35, "수분": 1700, "비타민A": 450, "비타민B6": 0.9, "비타민C": 50, "칼륨": 2900, "마그네슘": 150, "식이섬유": 25},
      "9~11": {"칼로리": 1900, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 2000, "비타민A": 600, "비타민B6": 1.1, "비타민C": 70, "칼륨": 3400, "마그네슘": 220, "식이섬유": 25},
      "12~14": {"칼로리": 2400, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2400, "비타민A": 750, "비타민B6": 1.5, "비타민C": 90, "칼륨": 3500, "마그네슘": 320, "식이섬유": 30},
      "15~19": {"칼로리": 2700, "탄수화물": 130, "지방": 135, "단백질": 65, "수분": 2700, "비타민A": 850, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 410, "식이섬유": 30},
      "20~29": {"칼로리": 2600, "탄수화물": 130, "지방": 130, "단백질": 65, "수분": 2700, "비타민A": 800, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 360, "식이섬유": 30},
      "30~49": {"칼로리": 2400, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2500, "비타민A": 800, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 370, "식이섬유": 30},
      "50~64": {"칼로리": 2200, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2300, "비타민A": 750, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 370, "식이섬유": 30},
      "65~74": {"칼로리": 2000, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2100, "비타민A": 700, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 370, "식이섬유": 25},
      "75 이상": {"칼로리": 2000, "탄수화물": 130, "지방": 120, "단백질": 60, "수분": 2100, "비타민A": 700, "비타민B6": 1.5, "비타민C": 100, "칼륨": 3500, "마그네슘": 370, "식이섬유": 25}
    },
    "여": {
      "6~8": {"칼로리": 1500, "탄수화물": 130, "지방": 70, "단백질": 35, "수분": 1600, "비타민A": 400, "비타민B6": 0.9, "비타민C": 50, "칼륨": 2900, "마그네슘": 150, "식이섬유": 20},
      "9~11": {"칼로리": 1700, "탄수화물": 130, "지방": 90, "단백질": 45, "수분": 1800, "비타민A": 550, "비타민B6": 1.1, "비타민C": 70, "칼륨": 3400, "마그네슘": 220, "식이섬유": 25},
      "12~14": {"칼로리": 2000, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2000, "비타민A": 650, "비타민B6": 1.4, "비타민C": 90, "칼륨": 3500, "마그네슘": 220, "식이섬유": 25},
      "15~19": {"칼로리": 2000, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2100, "비타민A": 650, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 330, "식이섬유": 25},
      "20~29": {"칼로리": 2100, "탄수화물": 130, "지방": 110, "단백질": 55, "수분": 2100, "비타민A": 650, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 320, "식이섬유": 25},
      "30~49": {"칼로리": 1900, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 2000, "비타민A": 650, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 320, "식이섬유": 20},
      "50~64": {"칼로리": 1800, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1800, "비타민A": 650, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 320, "식이섬유": 20},
      "65~74": {"칼로리": 1600, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1700, "비타민A": 600, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 320, "식이섬유": 20},
      "75 이상": {"칼로리": 1600, "탄수화물": 130, "지방": 100, "단백질": 50, "수분": 1700, "비타민A": 600, "비타민B6": 1.4, "비타민C": 100, "칼륨": 3500, "마그네슘": 320, "식이섬유": 20}
    }

  };

  Widget _buildCircularIndicators() {
    // ✅ gender 값을 recommendedIntake 키와 일치하도록 변환
    final String normalizedGender = widget.gender == "남자" ? "남" : "여";

    final recommended = recommendedIntake[normalizedGender]?[widget.ageGroup] ?? {};

// 🛠️ 사용자의 건강 상태를 고려하여 칼륨 값 수정
    int basePotassium = recommendedIntake[normalizedGender]?[widget.ageGroup]?["칼륨"] ?? 3500;
    int adjustedPotassium = basePotassium;

    if (widget.selectedKidneyDisease != null && diseasePotassiumLimits.containsKey(widget.selectedKidneyDisease)) {
      adjustedPotassium = diseasePotassiumLimits[widget.selectedKidneyDisease]!;
    }

    print("🔍 DailyIntakeScreen - 적용된 칼륨 제한값: $adjustedPotassium (질병: ${widget.selectedKidneyDisease})");




    // ✅ 만약 데이터가 없으면 기본값 설정 (예외 방지)
    if (recommended == null) {
      print("⚠️ ERROR: recommendedIntake에서 데이터를 찾을 수 없음! gender: $normalizedGender, ageGroup: ${widget.ageGroup}");
      return Center(child: Text("권장 영양소 데이터를 찾을 수 없습니다."));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildCircularIndicator(
                '칼로리',
                accumulatedNutrients['칼로리'] ?? 0,
                (recommended['칼로리'] ?? 2000).toDouble(), // 🔥 int -> double 변환
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildCircularIndicator(
                '단백질',
                accumulatedNutrients['단백질'] ?? 0,
                (recommended['단백질'] ?? 50).toDouble(), // 🔥 int -> double 변환
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildCircularIndicator(
                '탄수화물',
                accumulatedNutrients['탄수화물'] ?? 0,
                (recommended['탄수화물'] ?? 300).toDouble(), // 🔥 int -> double 변환
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildCircularIndicator(
                '지방',
                accumulatedNutrients['지방'] ?? 0,
                (recommended['지방'] ?? 70).toDouble(), // 🔥 int -> double 변환
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildCircularIndicator(
                '식이섬유',
                accumulatedNutrients['식이섬유'] ?? 0,
                (recommended['식이섬유'] ?? 25).toDouble(), // 🔥 int -> double 변환
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildCircularIndicator(
                '비타민A',
                accumulatedNutrients['비타민A'] ?? 0,
                (recommended['비타민A'] ?? 700).toDouble(), // 🔥 int -> double 변환
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildCircularIndicator(
                '비타민C',
                accumulatedNutrients['비타민C'] ?? 0,
                (recommended['비타민C'] ?? 100).toDouble(), // 🔥 int -> double 변환
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildCircularIndicator(
                '칼륨',
                accumulatedNutrients['칼륨'] ?? 0,
                adjustedPotassium.toDouble(), // 🔥 수정된 칼륨 값 반영
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildCircularIndicator(
                '마그네슘',
                accumulatedNutrients['마그네슘'] ?? 0,
                (recommended['마그네슘'] ?? 370).toDouble(), // 🔥 int -> double 변환
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildCircularIndicator(
                '수분',
                accumulatedNutrients['수분'] ?? 0,
                (recommended['수분'] ?? 3000).toDouble(), // 🔥 int -> double 변환
              ),
            ),
          ],
        ),
      ],
    );
  }
  final List<String> kidneyDiseaseRestrictedFruits = [
    "곶감", "멜론", "바나나", "앵두", "참외", "키위", "천도복숭아", "토마토", "방울토마토"
  ];

  Widget _buildCircularIndicator(String nutrient, double consumed, double recommended) {
    double percentage = (consumed / recommended).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$nutrient: ${consumed.toStringAsFixed(1)} / ${recommended.toStringAsFixed(1)}'),
        SizedBox(height: 10),
        Center(
          child: CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 13.0,
            animation: true,
            percent: percentage,
            center: Text(
              "${(percentage * 100).toStringAsFixed(1)}%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: _getColorForPercentage(percentage),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _showKidneyDiseaseWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // 🔥 배경을 하얀색으로 변경
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // 둥근 모서리 적용
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 30), // ⚠️ 강조된 경고 아이콘
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "신장병 환자 주의 과일",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView( // ✅ 스크롤 가능하도록 변경
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                // ✅ 신장이식 후 칼륨 제한 설명 (예쁜 스타일 적용)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: "신장이식 후에는 신장 기능이 정상이면 칼륨 제한이 필요하지 않지만, ",
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: "칼륨 수치가 높아지면 주의해야 합니다.\n",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        TextSpan(
                          text: "칼륨 수치를 조절하여 신부전으로 인한 증상이 악화되는 것을 방지합니다.",
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ 구분선 추가
                Divider(thickness: 1.5, color: Colors.grey[300]),

                // ✅ 과일 리스트 (1. 2. 3. 형식으로 정렬)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "⚠ 피해야 할 고칼륨 과일 목록:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(kidneyDiseaseRestrictedFruits.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "${index + 1}. ${kidneyDiseaseRestrictedFruits[index]}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    );
                  }),
                ),

                SizedBox(height: 12), // 여백 추가

                // ✅ 마지막 경고 문구 추가
                Text(
                  "⚠ 이 과일들은 고칼륨 과일이므로 섭취 시 주의가 필요합니다!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("확인", style: TextStyle(color: Colors.green[700], fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }




  Color _getColorForPercentage(double percentage) {
    int red = (255 * (1 - percentage)).toInt();
    int green = (255 * percentage).toInt();
    return Color.fromARGB(255, red, green, 0);
  }
}