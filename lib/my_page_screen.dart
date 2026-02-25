import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'bmi_calculator_screen.dart';
import 'fruit_analysis_history_screen.dart';
import 'daily_intake_screen.dart';
import 'bmi_history_screen.dart';


class MyPageScreen extends StatefulWidget {
  final String city;
  final String district;
  final String subdistrict;
  final String name; // ✅ 이름 필드 추가
  final String gender;
  final String ageGroup;
  final List<BmiRecord> bmiHistory;
  final Map<String, Map<String, int>> fruitAnalysisHistory;
  final Map<String, int> consumedFood;
  final Function(Map<String, int>) onUpdateConsumedFood;
  final String? selectedKidneyDisease; // ✅ 신장병 관련 정보 추가


  MyPageScreen({
    required this.city,
    required this.district,
    required this.subdistrict,
    required this.name, // ✅ 생성자에 추가
    required this.gender,
    required this.ageGroup,
    required this.bmiHistory,
    required this.fruitAnalysisHistory,
    required this.consumedFood,
    required this.onUpdateConsumedFood,
    this.selectedKidneyDisease, // ✅ 신장병 정보 추가

  });

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _name = "홍길동"; // 기본값 설정
  String? _selectedHealthCondition; // ✅ 건강 상태 (예/아니오)
  String? _selectedKidneyDisease;   // ✅ 선택한 신장 질환 (사구체신염 등)



  @override
  void initState() {
    super.initState();
    _loadUserName(); // 저장된 사용자 이름 불러오기
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? widget.name;
    });
  }

  void _navigateToRegister() async {
    // 회원가입 페이지로 이동 후, 새로운 데이터를 받아와 화면 갱신
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Register()),
    );
    _loadUserName(); // Register에서 변경된 이름을 다시 불러오기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _name, // 저장된 이름을 표시
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _navigateToRegister, // 연필 아이콘 클릭 시 Register로 이동
                      child: Icon(Icons.edit, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.city}, ${widget.district}, ${widget.subdistrict}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('섭취량 분석 기록'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyIntakeScreen(
                    gender: widget.gender,
                    ageGroup: widget.ageGroup,
                    consumedFood: widget.consumedFood,
                    fruitAnalysisHistory: widget.fruitAnalysisHistory,
                    onUpdateConsumedFood: widget.onUpdateConsumedFood,
                    healthCondition: _selectedHealthCondition == '예' ? _selectedKidneyDisease ?? "일반" : "일반", // ✅ 기존 healthCondition 전달
                    selectedKidneyDisease: _selectedHealthCondition == '예' ? _selectedKidneyDisease : null, // ✅ 선택된 신장병 전달

                  ),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('과채류 분석 내역'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FruitAnalysisHistoryScreen(
                    fruitAnalysisHistory: widget.fruitAnalysisHistory,
                  ),
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.fitness_center),
            title: Text('BMI 변화 기록'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BmiHistoryScreen(bmiHistory: widget.bmiHistory),
                ),
              );
            },
          ),
          Divider(),

          SizedBox(height: 20),
          Text('설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('알림 설정'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('테마 설정'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('언어 설정'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(),

          SizedBox(height: 20),
          Text('기타', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('도움말 및 고객지원'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('약관 및 개인정보처리방침'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          Divider(),

          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('계정 탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
