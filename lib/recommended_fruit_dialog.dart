import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'food_data.dart';

class RecommendedFruitDialog {
  static final FlutterTts _flutterTts = FlutterTts();

  static void show(
      BuildContext context,
      Map<String, double> accumulatedNutrients,
      Map<String, dynamic> recommendedNutrients,
      String gender,
      String ageGroup,
      String healthCondition,
      String? selectedKidneyDisease,  // ✅ 추가 (신장병 상세 정보)
      ) {
    // ✅ gender 값을 변환
    final String normalizedGender = (gender == "남자") ? "남" : (gender == "여자") ? "여" : gender;

    print("🔍 RecommendedFruitDialog - 전달받은 gender: $gender (변환 후: $normalizedGender), ageGroup: $ageGroup, 신장병 여부: $healthCondition, 질환: $selectedKidneyDisease");

    // ✅ 권장 영양소 가져오기
    final recommendedNutrientsFixed = recommendedIntake[normalizedGender]?[ageGroup];

    if (recommendedNutrientsFixed == null) {
      print("⚠️ ERROR: recommendedIntake에서 ${normalizedGender} - ${ageGroup}에 대한 데이터가 없습니다!");
    } else {
      print("✅ recommendedNutrients 가져오기 성공: $recommendedNutrientsFixed");
    }

    // ✅ 권장 영양소 업데이트 (빈 `{}` 방지)
    final Map<String, dynamic> finalRecommendedNutrients = recommendedNutrients.isNotEmpty
        ? recommendedNutrients
        : recommendedNutrientsFixed ?? {};

    print("🔍 ⏫ 최종 권장 영양소: $finalRecommendedNutrients");

    // ✅ 칼륨 제한 적용 (신장병이 있는 경우)
    if (healthCondition == "예" && selectedKidneyDisease != null) {
      if (diseasePotassiumLimits.containsKey(selectedKidneyDisease)) {
        finalRecommendedNutrients["칼륨"] = diseasePotassiumLimits[selectedKidneyDisease]!;
        print("⚠️ 신장병에 따른 칼륨 제한 적용: ${finalRecommendedNutrients["칼륨"]} mg");
      } else {
        print("⚠️ ERROR: diseasePotassiumLimits에서 $selectedKidneyDisease 대한 값이 없음!");
      }
    }

    // 🔹 타입 변환 (`Map<String, dynamic>` → `Map<String, double>`)
    final Map<String, double> convertedRecommendedNutrients = finalRecommendedNutrients.map(
            (key, value) => MapEntry(key, (value is num) ? value.toDouble() : 0.0) // ✅ int → double 변환
    );

    // ✅ 🚨 섭취한 영양소가 없는 경우 처리
    if (accumulatedNutrients.isEmpty || accumulatedNutrients.values.every((value) => value == 0.0)) {
      print("🚨 섭취한 영양소가 없습니다.");
      _speak("섭취한 영양소가 없습니다.");
      _showDialog(context, "알림 ⚠️", ["섭취한 영양소가 없습니다."]);
      return;
    }

    // ✅ 부족한 영양소 체크 및 추천 과일 찾기
    List<String> recommendedFruits = _getRecommendedFruitCombination(
        accumulatedNutrients, convertedRecommendedNutrients, foodData, healthCondition,selectedKidneyDisease
    );

    // ✅ 팝업 & 음성 안내
    String recommendationText = recommendedFruits.isNotEmpty
        ? recommendedFruits.join(", ") + "를 추천합니다."
        : "현재 부족한 영양소가 없습니다.";

    _speak(recommendationText);
    _showDialog(context, "추천 과일 🍎", recommendedFruits.isNotEmpty ? recommendedFruits : ["현재 부족한 영양소가 없습니다."]);
  }



  static List<String> _getRecommendedFruitCombination(
      Map<String, double> accumulatedNutrients,
      Map<String, double> recommendedNutrients,
      List<Map<String, dynamic>> foodData,
      String healthCondition,
      String? selectedKidneyDisease
      ) {
    final List<String> kidneyDiseaseRestrictedFruits = [
      "곶감", "멜론", "Banana", "앵두", "참외", "Kiwi", "천도복숭아", "토마토", "방울토마토"
    ];

    List<String> targetNutrients = ["비타민A", "비타민B6", "비타민C", "칼륨", "식이섬유"];

    Map<String, String> nutrientTranslation = {
      "칼로리": "energy",
      "탄수화물": "carbs",
      "지방": "fat",
      "단백질": "protein",
      "수분": "water",
      "비타민A": "vitaminA",
      "비타민B6": "vitaminB6",
      "비타민C": "vitaminC",
      "칼륨": "potassium",
      "마그네슘": "magnesium",
      "식이섬유": "dietaryFiber"
    };

    // ✅ 현재까지 추천된 과일들의 총 칼륨량 추적
    double totalPotassium = 0.0;

    // ✅ 부족한 영양소 찾기
    Map<String, double> nutrientDeficit = {};
    for (var nutrient in targetNutrients) {
      if (!recommendedNutrients.containsKey(nutrient)) continue;
      double recommendedValue = (recommendedNutrients[nutrient] ?? 0).toDouble();
      double consumedValue = (accumulatedNutrients[nutrient] ?? 0).toDouble();

      if (consumedValue < recommendedValue) {
        nutrientDeficit[nutrient] = recommendedValue - consumedValue;
      }
    }

    print("📌 부족한 영양소 목록: $nutrientDeficit");

    // ✅ 최적의 과일 조합 찾기
    Map<String, int> fruitCombination = {};
    List<String> triedFruits = []; // ❗️ 이미 추천 시도한 과일 목록 추가

    while (nutrientDeficit.isNotEmpty) {
      String bestFruit = "";
      double bestScore = 0;
      double requiredCount = 1.0;

      for (var food in foodData) {
        String fruitName = food["name"] ?? "";

        // ✅ 이미 시도한 과일이면 제외
        if (triedFruits.contains(fruitName)) continue;

        // ✅ 신장병 환자의 경우 제한 과일 제외
        if (healthCondition == "예" && kidneyDiseaseRestrictedFruits.contains(fruitName)) {
          continue;
        }

        double score = 0;
        for (var nutrient in nutrientDeficit.keys) {
          String? englishNutrient = nutrientTranslation[nutrient];
          if (englishNutrient != null && food.containsKey(englishNutrient) && food[englishNutrient] != null) {
            score += (food[englishNutrient] as num).toDouble(); // ✅ int → double 변환
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestFruit = fruitName;
        }
      }

      if (bestFruit.isEmpty) break; // ❗️ 추천할 과일이 없으면 종료 (무한 루프 방지)

      // ✅ 현재 추천하려는 과일의 칼륨량 가져오기 (null 체크 및 변환)
      double fruitPotassium = (foodData.firstWhere(
              (fruit) => fruit["name"] == bestFruit, orElse: () => {})["potassium"] ?? 0.0)
          .toDouble();

      // ✅ 칼륨 제한을 초과하는지 확인
      if (selectedKidneyDisease != null &&
          totalPotassium + (fruitPotassium * requiredCount) > (diseasePotassiumLimits[selectedKidneyDisease] ?? 0).toDouble()) {
        triedFruits.add(bestFruit); // ❗️ 제외된 과일을 목록에 추가
        continue; // ❗️ continue로 다음 과일 탐색
      }

      int neededAmount = requiredCount.ceil();
      fruitCombination[bestFruit] = (fruitCombination[bestFruit] ?? 0) + neededAmount;

      // ✅ 현재까지 추천된 과일들의 칼륨 총합 업데이트
      totalPotassium += fruitPotassium * neededAmount;

      // ✅ 부족한 영양소 업데이트
      for (var nutrient in nutrientDeficit.keys.toList()) {
        String? englishNutrient = nutrientTranslation[nutrient];

        if (englishNutrient != null &&
            foodData.firstWhere(
                    (fruit) => fruit["name"] == bestFruit, orElse: () => {})[englishNutrient] != null) {

          double currentDeficit = (nutrientDeficit[nutrient] ?? 0).toDouble();
          double reductionAmount = ((foodData.firstWhere(
                  (fruit) => fruit["name"] == bestFruit, orElse: () => {})[englishNutrient] ?? 0.0) as num)
              .toDouble() * neededAmount;

          nutrientDeficit[nutrient] = currentDeficit - reductionAmount;

          if ((nutrientDeficit[nutrient] ?? 0.0) <= 0) {
            nutrientDeficit.remove(nutrient);
          }
        }
      }
    }

    List<String> result = fruitCombination.entries.map((e) => "${e.key} ${e.value}개").toList();
    print("🍎 추천 과일 조합: $result");
    return result;
  }





  /// 🔹 음성 출력
  static Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("ko-KR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }


  /// 🔹 팝업 다이얼로그 표시
  static void _showDialog(BuildContext context, String title, List<String> contentList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: contentList.map((text) => Text(text)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("닫기"),
            ),
          ],
        );

      },
    );
  }
  static final Map<String, int> diseasePotassiumLimits = {
    "사구체신염": 1000,
    "신증후군": 2000,
    "급성 신손상": 1200,
    "신부전": 2000,
    "혈액투석": 2000,
    "복막투석": 3000,
    "신장이식": 2000,
  };


  static final Map<String, Map<String, dynamic>> recommendedIntake = {
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

}
