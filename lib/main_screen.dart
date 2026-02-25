import 'package:flutter/material.dart';
import 'my_page_screen.dart';
import 'bmi_calculator_screen.dart';
import 'fruit_analysis_screen.dart';
import 'mask_pack_recipe_screen.dart';
import 'daily_intake_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final String? city; // nullable
  final String gender;
  final String selectedYear;
  final String selectedMonth;
  final String selectedDay;
  final String? district; // nullable
  final String? subdistrict; // nullable
  final String healthCondition; // ✅ 추가된 부분
  final String? selectedKidneyDisease; // ✅ 추가



  MainScreen({
    this.city, // 선택적 필드
    this.district, // 선택적 필드
    this.subdistrict, // 선택적 필드
    required this.gender, // 필수 필드
    required this.selectedYear, // 필수 필드
    required this.selectedMonth, // 필수 필드
    required this.selectedDay, // 필수 필드
    this.healthCondition = '아니오', // ✅ 기본값 설정
    this.selectedKidneyDisease, // ✅ 추가


  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> consumedFoodData = {};
  List<BmiRecord> bmiHistory = [];
  Map<String, Map<String, int>> fruitAnalysisHistory = {};
  int _dailyIntakeKey = 0;
  String? _selectedKidneyDisease; // ✅ 상태 변수로 선언
  double totalPotassiumIntake = 0.0;  // 칼륨 섭취량을 MainScreen에서 상태로 관리
  List<double> dailyPotassiumIntake = [];  // 🚀 칼륨 섭취량을 리스트로 저장

  void _updatePotassiumIntake(double potassiumAmount) {
    setState(() {
      if (dailyPotassiumIntake.isEmpty) {
        dailyPotassiumIntake.add(potassiumAmount); // 🚀 리스트가 비어 있으면 첫 번째 값 추가
      } else {
        dailyPotassiumIntake[0] += potassiumAmount; // 🚀 기존 값에 더하기
      }
    });

    print('✅ Updated dailyPotassiumIntake: ${dailyPotassiumIntake[0]}');
  }



  @override
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _loadStoredData(); // 🛠 변경됨: SharedPreferences에서 selectedKidneyDisease 불러오기
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKidneyDisease = prefs.getString('kidneyDisease'); // 🛠 변경됨: 저장된 신장병 데이터 불러오기

    setState(() {
      _selectedKidneyDisease = storedKidneyDisease ?? widget.selectedKidneyDisease; // 🛠 변경됨: SharedPreferences 값이 있으면 사용
    });

    print("🔍 MainScreen - 불러온 selectedKidneyDisease: $_selectedKidneyDisease");
  }


  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {  // DailyIntakeScreen의 탭 인덱스
          _dailyIntakeKey++;
          print('Tab changed to DailyIntakeScreen, new key: $_dailyIntakeKey');
        }
      });
    }
  }

  void _updateConsumedFood(Map<String, int> updatedFood) {
    setState(() {
      consumedFoodData = updatedFood;
      _dailyIntakeKey++;
      print('MainScreen - Updated consumedFood: $consumedFoodData');
      print('MainScreen - New daily intake key: $_dailyIntakeKey');
    });
  }

  void _updateFruitAnalysisHistory(Map<String, Map<String, int>> newHistory) {
    String today = DateTime.now().toIso8601String().split('T')[0];

    print("🔵 MainScreen - 업데이트된 fruitAnalysisHistory: $newHistory"); // ✅ 디버깅 로그 추가

    setState(() {
      newHistory.forEach((key, value) {
        if (fruitAnalysisHistory.containsKey(key)) {
          fruitAnalysisHistory[key]!.addAll(value);
        } else {
          fruitAnalysisHistory[key] = value;
        }

        if (key == today) {
          value.forEach((fruitName, count) {
            print("🔵 MainScreen - 업데이트 전: $fruitName = ${consumedFoodData[fruitName]}"); // ✅ 디버깅 로그 추가
            if (count < 0) {
              consumedFoodData.update(
                fruitName,
                    (existingCount) {
                  int newCount = existingCount + count;
                  print("🟡 MainScreen - 업데이트 후: $fruitName = $newCount (count: $count)"); // ✅ 디버깅 로그 추가
                  return newCount > 0 ? newCount : 0;
                },
                ifAbsent: () => 0,
              );
            } else {
              consumedFoodData.update(
                fruitName,
                    (existingCount) => existingCount + count,
                ifAbsent: () => count,
              );
            }
          });
        }
      });

      consumedFoodData.removeWhere((key, value) => value <= 0);
      _dailyIntakeKey++;

      print('🔵 MainScreen - 최종 consumedFoodData: $consumedFoodData');
    });
  }




  void _updateBmiHistory(List<BmiRecord> updatedHistory) {
    setState(() {
      bmiHistory = updatedHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ageGroup = _calculateAgeGroup(widget.selectedYear);


    // ✅ gender 값을 recommendedIntake 키와 일치하도록 변환
    final String normalizedGender = widget.gender == "남자" ? "남" : "여";

    print("🔍 MainScreen - 전달할 gender: ${widget.gender}, ageGroup: $ageGroup");
    print("🟢 MainScreen - 전달된 healthCondition: ${widget.healthCondition}");
    print("🟢 MainScreen - 전달된 selectedKidneyDisease: $_selectedKidneyDisease"); // 🛠 변경됨: 상태 변수를 출력

    final dailyIntakeScreen = DailyIntakeScreen(
      key: ValueKey('daily-intake-$_dailyIntakeKey'),
      consumedFood: Map<String, int>.from(consumedFoodData),
      fruitAnalysisHistory: Map<String, Map<String, int>>.from(fruitAnalysisHistory),
      gender: widget.gender,
      ageGroup: ageGroup,
      healthCondition: widget.healthCondition ?? "일반", // ✅ prefs 제거하고 직접 전달
      selectedKidneyDisease: _selectedKidneyDisease, // 🛠 변경됨: selectedKidneyDisease 유지
      onUpdateConsumedFood: _updateConsumedFood,

    );

    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          dailyIntakeScreen,
          MaskPackRecipeScreen(
            fruitAnalysisHistory: fruitAnalysisHistory,
            onUpdateFruitAnalysis: (newHistory) {
              _updateFruitAnalysisHistory(newHistory);
            },
          ),
          FruitAnalysisScreen(
            onUpdateHistory: (newHistory) {
              _updateFruitAnalysisHistory(newHistory);
              setState(() {
                _dailyIntakeKey++;
              });
            },
            healthCondition: widget.healthCondition, // ✅ widget.healthCondition으로 변경
            selectedKidneyDisease: _selectedKidneyDisease, // 🛠 변경됨: selectedKidneyDisease 유지
            onUpdatePotassiumIntake: _updatePotassiumIntake, // ✅ 함수 전달
            dailyPotassiumIntake: dailyPotassiumIntake, // ✅ 리스트 전달이트 함수 전달
          ),
          MyPageScreen(
            city: widget.city ?? 'Unknown', // 기본값 제공
            district: widget.district ?? 'Unknown', // 기본값 제공
            subdistrict: widget.subdistrict ?? 'Unknown', // 기본값 제공
            gender: widget.gender,
            ageGroup: ageGroup,
            name: '홍길동',
            bmiHistory: bmiHistory,
            fruitAnalysisHistory: fruitAnalysisHistory,
            consumedFood: consumedFoodData,
            onUpdateConsumedFood: _updateConsumedFood,
            selectedKidneyDisease: _selectedKidneyDisease, // 🛠 변경됨: selectedKidneyDisease 유지

          ),
          BmiCalculatorScreen(
            bmiHistory: List.from(bmiHistory),
            onUpdate: _updateBmiHistory,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.green,
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelPadding: EdgeInsets.symmetric(horizontal: 0),
          tabs: [
            Tab(icon: Icon(Icons.bar_chart, size: 24), text: '섭취량'),
            Tab(icon: Icon(Icons.spa, size: 24), text: '팩레시피'),
            Tab(icon: Icon(Icons.analytics, size: 24), text: '분석'),
            Tab(icon: Icon(Icons.person, size: 24), text: 'MY'),
            Tab(icon: Icon(Icons.fitness_center, size: 24), text: 'BMI'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
}

String _calculateAgeGroup(String birthYear) {
  final currentYear = DateTime.now().year;
  final age = currentYear - int.parse(birthYear);

  print("📌 연령 계산: birthYear=$birthYear, 현재 연령=$age");

  if (age < 10) return '6~8';   // 예제와 맞추기 위해 수정
  if (age < 12) return '9~11';
  if (age < 15) return '12~14';
  if (age < 20) return '15~19';
  if (age < 30) return '20~29';
  if (age < 50) return '30~49';
  if (age < 65) return '50~64';
  if (age < 75) return '65~74';
  return '75 이상';
}