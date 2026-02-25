import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'food_data.dart';

class FruitAnalysisScreen extends StatefulWidget {
  final Function(Map<String, Map<String, int>>) onUpdateHistory;
  late String healthCondition; // ✅ 변수 추가
  final String? selectedKidneyDisease; // ✅ 추가
  final Function(double) onUpdatePotassiumIntake;  // 칼륨 섭취량 업데이트 콜백 함수
  final List<double> dailyPotassiumIntake; // ✅ MainScreen에서 전달받기 추가


  FruitAnalysisScreen({
    required this.onUpdateHistory,
    required this.onUpdatePotassiumIntake, // ✅ 추가
    required this.dailyPotassiumIntake,  // ✅ 추가
    required this.healthCondition,
    this.selectedKidneyDisease,
  });

  @override
  _FruitAnalysisScreenState createState() => _FruitAnalysisScreenState();
}

class _FruitAnalysisScreenState extends State<FruitAnalysisScreen> {
  late FlutterVision vision;
  late FlutterTts flutterTts;
  String result = '결과 없음';
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageData;
  bool isLoading = false;


  late String _selectedHealthCondition; // ✅ 클래스 멤버 변수 선언
  late String? _selectedKidneyDisease; // ✅ 추가



  Map<String, int> classCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedHealthCondition = widget.healthCondition; // ✅ healthCondition 값을 받아오기\
    _selectedKidneyDisease = widget.selectedKidneyDisease; // ✅ 추가
    initVision();
    flutterTts = FlutterTts();

  }

  double _calculatePotassium(String fruit) {
    double potassiumAmount = 0.0;

    // foodData에서 해당 과일의 정보를 찾음
    final fruitData = foodData.firstWhere(
          (item) => item['name'].toString().toLowerCase() == fruit.toLowerCase(),
      orElse: () => {},
    );

    int count = classCounts[fruit] ?? 1; // 기본값을 1로 설정

    // 과일이 존재하면 칼륨 값을 가져옴
    if (fruitData.isNotEmpty) {
      potassiumAmount = (fruitData['potassium'] ?? 0.0).toDouble() * count;  // 명시적으로 double로 변환
    }

    print("🔍 $fruit 의 칼륨 섭취량: $potassiumAmount"); // 디버깅 로그 추가
    return potassiumAmount;
  }


  Future<void> initVision() async {
    vision = FlutterVision();
    await vision.loadYoloModel(
      labels: 'assets/labels1.txt',
      modelPath: 'assets/best_float32.tflite',
      modelVersion: "yolov8seg",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  Future<void> runModelOnImage(Uint8List byteData) async {
    setState(() {
      isLoading = true;
      result = 'Loading...';
    });

    final image = img.decodeImage(byteData)!;
    final results = await vision.yoloOnImage(
      bytesList: byteData,
      imageHeight: 640,
      imageWidth: 640,
      iouThreshold: 0.7,
      //confThreshold: 0.6,
      classThreshold: 0.6,
    );

    Map<String, int> detectedClassCounts = {};
    for (var result in results) {
      String detectedClass = result['tag'];
      detectedClassCounts.update(
        detectedClass,
            (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    setState(() {
      _imageData = byteData;
      classCounts = detectedClassCounts;
      result = detectedClassCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      isLoading = false;
    });

    _checkForRestrictedFruits(detectedClassCounts);

    String today = DateTime.now().toIso8601String().split('T')[0];
    print('Detected fruits: $detectedClassCounts');
    widget.onUpdateHistory({today: detectedClassCounts});
  }

  void _checkForRestrictedFruits(Map<String, int> detectedClassCounts) {
    print("🟢 탐지된 과일 개수 확인: $detectedClassCounts"); // ✅ 디버깅 로그 추가
    for (var fruit in detectedClassCounts.keys) {
      final potassiumAmount = _calculatePotassium(fruit);
      widget.onUpdatePotassiumIntake(potassiumAmount); // ✅ MainScreen 값 업데이트

      print("🔍 $fruit 의 칼륨 섭취량: $potassiumAmount (탐지 개수: ${detectedClassCounts[fruit]})"); // ✅ 디버깅 로그 추가

      // ✅ MainScreen의 최신 dailyPotassiumIntake[0] 값 가져오기
      double totalPotassium = widget.dailyPotassiumIntake.isNotEmpty
          ? widget.dailyPotassiumIntake[0]
          : 0.0;

      if (kidneyDiseaseRestrictedFruits.contains(fruit) || totalPotassium > _getPotassiumLimit()) {
        _showWarningDialog(fruit, "칼륨 섭취가 제한을 초과할 수 있습니다.");
      }
    }
  }


  int _getPotassiumLimit() {
    return _selectedKidneyDisease != null
        ? (diseasePotassiumLimits[_selectedKidneyDisease] ?? 99999)
        : 99999;
  }




  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List byteData = await image.readAsBytes();
      await runModelOnImage(byteData);
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final Uint8List byteData = await image.readAsBytes();
      await runModelOnImage(byteData);
    }
  }

  Future<void> readNutritionInfo(String nutritionInfo) async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(nutritionInfo);
  }

  void showClassWiseFoodDataDialog() async {
    final nutritionText = StringBuffer('탐지된 과일의 영양 성분을 알려드리겠습니다. ');

    await flutterTts.setLanguage("ko-KR");
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    for (var entry in classCounts.entries) {
      final foodName = entry.key;
      final count = entry.value;
      final foodNutrients = foodData.firstWhere(
            (item) => item['name'].toString().toLowerCase() == foodName.toLowerCase(),
        orElse: () => {},
      );

      if (foodNutrients.isNotEmpty) {
        final totalEnergy = (foodNutrients['energy'] ?? 0) * count;
        final totalProtein = (foodNutrients['protein'] ?? 0) * count;
        final totalCarbs = (foodNutrients['carbs'] ?? 0) * count;
        final totalFat = (foodNutrients['fat'] ?? 0) * count;
        final totalWater = (foodNutrients['water'] ?? 0) * count;
        final totalSugar = (foodNutrients['sugar'] ?? 0) * count;
        final totalVitaminA = (foodNutrients['vitaminA'] ?? 0) * count;
        final totalVitaminB6 = (foodNutrients['vitaminB6'] ?? 0) * count;
        final totalVitaminC = (foodNutrients['vitaminC'] ?? 0) * count;
        final totalPotassium = (foodNutrients['potassium'] ?? 0) * count;
        final totalMagnesium = (foodNutrients['magnesium'] ?? 0) * count;
        final totalDietaryFiber = (foodNutrients['dietaryFiber'] ?? 0) * count;
        final totalAsh = (foodNutrients['ash'] ?? 0) * count;

        nutritionText.write('$foodName ${count}개의 영양 성분은 ');
        nutritionText.write('칼로리 ${totalEnergy.toStringAsFixed(1)} 킬로칼로리, ');
        nutritionText.write('수분 ${totalWater.toStringAsFixed(1)} 그램, ');
        nutritionText.write('단백질 ${totalProtein.toStringAsFixed(1)} 그램, ');
        nutritionText.write('지방 ${totalFat.toStringAsFixed(1)} 그램, ');
        nutritionText.write('탄수화물 ${totalCarbs.toStringAsFixed(1)} 그램, ');
        nutritionText.write('당류 ${totalSugar.toStringAsFixed(1)} 그램, ');
        nutritionText.write('식이섬유 ${totalDietaryFiber.toStringAsFixed(1)} 그램, ');
        nutritionText.write('비타민 A ${totalVitaminA.toStringAsFixed(1)} 마이크로그램, ');
        nutritionText.write('비타민 B6 ${totalVitaminB6.toStringAsFixed(3)} 밀리그램, ');
        nutritionText.write('비타민 C ${totalVitaminC.toStringAsFixed(1)} 밀리그램, ');
        nutritionText.write('칼륨 ${totalPotassium.toStringAsFixed(1)} 밀리그램, ');
        nutritionText.write('마그네슘 ${totalMagnesium.toStringAsFixed(1)} 밀리그램, ');
        nutritionText.write('회분 ${totalAsh.toStringAsFixed(1)} 그램입니다. ');
      }
    }

    await flutterTts.speak(nutritionText.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('과채류별 영양 성분 정보'),
          content: SingleChildScrollView(
            child: ListBody(
              children: classCounts.entries.map((entry) {
                final foodName = entry.key;
                final count = entry.value;
                final foodNutrients = foodData.firstWhere(
                      (item) => item['name'].toString().toLowerCase() == foodName.toLowerCase(),
                  orElse: () => {},
                );

                if (foodNutrients.isNotEmpty) {
                  final totalEnergy = (foodNutrients['energy'] ?? 0) * count;
                  final totalProtein = (foodNutrients['protein'] ?? 0) * count;
                  final totalCarbs = (foodNutrients['carbs'] ?? 0) * count;
                  final totalFat = (foodNutrients['fat'] ?? 0) * count;
                  final totalWater = (foodNutrients['water'] ?? 0) * count;
                  final totalSugar = (foodNutrients['sugar'] ?? 0) * count;
                  final totalVitaminA = (foodNutrients['vitaminA'] ?? 0) * count;
                  final totalVitaminB6 = (foodNutrients['vitaminB6'] ?? 0) * count;
                  final totalVitaminC = (foodNutrients['vitaminC'] ?? 0) * count;
                  final totalPotassium = (foodNutrients['potassium'] ?? 0) * count;
                  final totalMagnesium = (foodNutrients['magnesium'] ?? 0) * count;
                  final totalDietaryFiber = (foodNutrients['dietaryFiber'] ?? 0) * count;
                  final totalAsh = (foodNutrients['ash'] ?? 0) * count;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$foodName:'),
                      Text('  칼로리: ${totalEnergy.toStringAsFixed(1)} kcal'),
                      Text('  수분: ${totalWater.toStringAsFixed(1)} g'),
                      Text('  단백질: ${totalProtein.toStringAsFixed(2)} g'),
                      Text('  지방: ${totalFat.toStringAsFixed(2)} g'),
                      Text('  탄수화물: ${totalCarbs.toStringAsFixed(2)} g'),
                      Text('  당류: ${totalSugar.toStringAsFixed(2)} g'),
                      Text('  식이섬유: ${totalDietaryFiber.toStringAsFixed(2)} g'),
                      Text('  비타민 A: ${totalVitaminA.toStringAsFixed(1)} μg'),
                      Text('  비타민 B6: ${totalVitaminB6.toStringAsFixed(3)} mg'),
                      Text('  비타민 C: ${totalVitaminC.toStringAsFixed(1)} mg'),
                      Text('  칼륨: ${totalPotassium.toStringAsFixed(1)} mg'),
                      Text('  마그네슘: ${totalMagnesium.toStringAsFixed(1)} mg'),
                      Text('  회분: ${totalAsh.toStringAsFixed(2)} g'),
                      SizedBox(height: 10),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }).toList(),
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text('닫기'),
              onPressed: () {
                flutterTts.stop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('다시 듣기'),
              onPressed: () async {
                await flutterTts.stop();
                await flutterTts.speak(nutritionText.toString());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_imageData != null)
            Expanded(
              flex: 3,
              child: Image.memory(
                _imageData!,
                fit: BoxFit.contain,
              ),
            )
          else
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[100],
                child: Center(child: Text('이미지를 선택하거나 촬영하세요')),
              ),
            ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLoading ? 'Loading...' : result,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: pickImageFromGallery,
                        child: Text('이미지 선택', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: pickImageFromCamera,
                        child: Text('카메라 촬영', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  if (_imageData != null) ...[
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: showClassWiseFoodDataDialog,
                      child: Text('영양성분 보기', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<String> kidneyDiseaseRestrictedFruits = [
    "곶감", "멜론", "Banana", "앵두", "참외", "Kiwi", "천도복숭아", "토마토", "방울토마토"
  ];

  double totalPotassiumIntake = 0.0;

// ✅ 신장병별 칼륨 섭취 제한 값
  final Map<String, int> diseasePotassiumLimits = {
    "사구체신염": 1000,
    "신증후군": 2000,
    "급성 신손상": 1200,
    "신부전": 2000,
    "혈액투석": 2000,
    "복막투석": 3000,
    "신장이식": 2000,
  };




  void _showWarningDialog(String fruit, String reason) async {
    print("🟠 경고창 실행: $fruit");

    final foodNutrients = foodData.firstWhere(
          (item) => item['name'].toString().toLowerCase() == fruit.toLowerCase(),
      orElse: () => {},
    );

    int count = classCounts[fruit] ?? 1;
    double potassiumAmount = (foodNutrients['potassium'] ?? 0.0) * count.toDouble();

    // ✅ MainScreen에서 전달받은 최신 칼륨 섭취량 사용 (비어있는 경우 0.0)
    double currentTotalPotassium = widget.dailyPotassiumIntake.isNotEmpty
        ? widget.dailyPotassiumIntake[0]
        : 0.0;

    double newTotalPotassium = currentTotalPotassium; // ✅ 최신 값으로 업데이트

    print('New total potassium intake: $newTotalPotassium');

    int potassiumLimit = widget.selectedKidneyDisease != null
        ? (diseasePotassiumLimits[widget.selectedKidneyDisease] ?? 99999)
        : 99999;

    print('Potassium limit: $potassiumLimit');

    // ✅ [변경] 신장병이 "예"로 설정된 경우에만 위험 과일 체크 (신장병이 아니면 체크 안 함)
    bool isRestrictedFruit = widget.selectedKidneyDisease != null &&
        kidneyDiseaseRestrictedFruits.contains(fruit);

    bool isPotassiumOverLimit = newTotalPotassium > potassiumLimit;

    print("🟡 과일: $fruit, 위험 과일 여부: $isRestrictedFruit, 칼륨 초과 여부: $isPotassiumOverLimit");

    // ✅ [변경] 신장병이 없고, 칼륨 초과도 없으면 경고창 표시 안 함
    if (!isRestrictedFruit && !isPotassiumOverLimit) {
      print("✅ 위험 과일도 아니고 칼륨 초과도 아님. 경고창 표시 안함.");
      return;
    }

    String warningMessage = "";
    List<Widget> warningTexts = [];

    // ✅ [변경] 신장병이 있는 경우에만 위험 과일 경고 메시지 추가
    if (isRestrictedFruit) {
      warningMessage += "$fruit은 신장병 환자에게 위험할 수 있습니다. ";
      warningTexts.add(
        Text("⚠️ $fruit은 신장병 환자에게 위험할 수 있습니다!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
      );
    }

    warningMessage += "이 과일에는 칼륨이 ${potassiumAmount.toStringAsFixed(1)}mg 포함되어 있으며, "
        "총 섭취량은 ${newTotalPotassium.toStringAsFixed(1)}mg 입니다.";

    warningTexts.add(
      Text("이 과일에는 칼륨이 ${potassiumAmount.toStringAsFixed(1)}mg 포함되어 있습니다.",
          style: TextStyle(fontSize: 14)),
    );
    warningTexts.add(
      Text("현재 총 섭취량: ${newTotalPotassium.toStringAsFixed(1)}mg / 제한: ${potassiumLimit}mg",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPotassiumOverLimit ? Colors.red : Colors.black)),
    );

    if (isPotassiumOverLimit) {
      warningMessage += " ⚠️ 하지만, 칼륨 섭취 한도(${potassiumLimit}mg)를 초과하므로 주의하세요!";
      warningTexts.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text("⚠️ 칼륨 섭취 한도를 초과했습니다! 추가 섭취를 주의하세요.",
              style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }

    warningMessage += " 이 과일을 섭취하시겠습니까?";

    await flutterTts.speak(warningMessage);

    showDialog(
      context: context,
      barrierDismissible: false, // 창을 닫기 전까지 대기
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("🚨 섭취 주의: $fruit"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...warningTexts,
              SizedBox(height: 10),
              Text("이 과일을 섭취하시겠습니까?", style: TextStyle(fontSize: 14)),
            ],
          ),
          actions: [
            // ✅ "섭취" 버튼 (이제야 onUpdatePotassiumIntake 호출!)
            TextButton(
              onPressed: () {
                flutterTts.speak("$fruit을 섭취합니다.");
                Navigator.of(context).pop();
              },
              child: Text("섭취", style: TextStyle(fontSize: 16, color: Colors.green)),
            ),

            // ✅ "섭취하지 않음" 버튼 (칼륨량 업데이트 안 함)
            TextButton(
              onPressed: () {
                flutterTts.speak("$fruit을 섭취하지 않습니다.");
                int detectedCount = classCounts[fruit] ?? 1;
                setState(() {
                  classCounts.remove(fruit);
                });

                // ✅ [변경] 섭취하지 않으면 이미 증가한 칼륨량을 빼준다
                widget.onUpdatePotassiumIntake(-potassiumAmount);
                if (widget.dailyPotassiumIntake.isNotEmpty) {
                  widget.dailyPotassiumIntake[0] = 0.0;
                }
                String today = DateTime.now().toIso8601String().split('T')[0];
                widget.onUpdateHistory({today: {fruit: -detectedCount}}); // ✅ 탐지 개수만큼 감소

                Navigator.of(context).pop();
              },
              child: Text("섭취하지 않음", style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ],
        );
      },
    );
  }









  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}