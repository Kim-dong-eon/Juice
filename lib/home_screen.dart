import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration(); // ✅ 앱 실행 시 회원가입 여부 확인
  }

  /// ✅ **회원가입 여부 확인**
  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isRegistered = prefs.getString('name') != null &&
          prefs.getString('gender') != null &&
          prefs.getString('year') != null &&
          prefs.getString('month') != null &&
          prefs.getString('day') != null &&
          prefs.getString('city') != null &&
          prefs.getString('district') != null &&
          prefs.getString('subdistrict') != null &&
          prefs.getString('healthCondition') != null; // ✅ 변경된 부분
    });
  }

  void _onStartPressed() {
    if (isRegistered) {
      _navigateToMainScreen();
    } else {
      _navigateToRegister();
    }
  }

  void _navigateToMainScreen() async {
    final prefs = await SharedPreferences.getInstance();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          city: prefs.getString('city') ?? 'Unknown',
          district: prefs.getString('district') ?? 'Unknown',
          subdistrict: prefs.getString('subdistrict') ?? 'Unknown',
          healthCondition: prefs.getString('healthCondition') ?? '없음', // ✅ 수정된 부분
          gender: prefs.getString('gender') ?? 'Unknown',
          selectedYear: prefs.getString('year') ?? 'Unknown',
          selectedMonth: prefs.getString('month') ?? 'Unknown',
          selectedDay: prefs.getString('day') ?? 'Unknown',
        ),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Register(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/juice3.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '신선한 과일과 채소로 만든 건강 주스로\n삶의 활력을 더하세요!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 하단 버튼 및 소셜 로그인 아이콘
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: [
                // 시작하기 버튼
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _onStartPressed, // ✅ 회원가입 여부에 따라 이동할 페이지 결정
                    child: Text(
                      '시작하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '또는',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIconButton('assets/kakao.png', () {
                      // 카카오톡 로그인 기능 추가
                    }),
                    _buildSocialIconButton('assets/google.png', () {
                      // 구글 로그인 기능 추가
                    }),
                    _buildSocialIconButton('assets/facebook.png', () {
                      // 페이스북 로그인 기능 추가
                    }),
                    _buildSocialIconButton('assets/naver.png', () {
                      // 네이버 로그인 기능 추가
                    }),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconButton(String assetPath, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: 35,
        height: 35,
        child: IconButton(
          icon: Image.asset(assetPath),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
