import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String? _name;
  String? _selectedGender;
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSubdistrict;
  String? _selectedHealthCondition; // ✅ 건강 상태 추가
  String? _selectedKidneyDisease;

  final TextEditingController _nameController = TextEditingController();

  Map<String, dynamic> regions = {};
  List<String> districtList = [];
  List<String> subdistrictList = [];

  final List<String> years = List.generate(100, (index) => (2023 - index).toString());
  final List<String> months = List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> days = List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));


  final Map<String, List<String>> kidneyDiseases = {
    '사구체신염': ['급성', '만성'],
    '신증후군': ['일반'],
    '급성 신손상': ['핍뇨기', '이뇨기, 회복기'],
    '신부전': ['급성', '만성'],
    '혈액투석': ['일반'],
    '복막투석': ['일반'],
    '신장이식': ['이식 직후(~6주)', '이식 후 장기관리'],
  };

  @override
  void initState() {
    super.initState();
    loadRegionsData();
    _loadUserData(); // ✅ 저장된 사용자 데이터 불러오기
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name');
      _selectedGender = prefs.getString('gender');
      _selectedYear = prefs.getString('year');
      _selectedMonth = prefs.getString('month');
      _selectedDay = prefs.getString('day');
      _selectedCity = prefs.getString('city');
      _selectedDistrict = prefs.getString('district');
      _selectedSubdistrict = prefs.getString('subdistrict');
      _selectedHealthCondition = prefs.getString('healthCondition') ?? '아니오';
      _selectedKidneyDisease = prefs.getString('kidneyDisease');

      // ✅ 지역 리스트 업데이트
      districtList = regions[_selectedCity]?.keys.toList() ?? [];
      subdistrictList = regions[_selectedCity]?[_selectedDistrict]?.cast<String>() ?? [];
      // ✅ 입력 필드 자동 완성
      _nameController.text = _name ?? '';
    });
  }

  /// ✅ **입력한 정보를 SharedPreferences에 저장**
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name ?? '');
    await prefs.setString('gender', _selectedGender ?? '');
    await prefs.setString('year', _selectedYear ?? '');
    await prefs.setString('month', _selectedMonth ?? '');
    await prefs.setString('day', _selectedDay ?? '');
    await prefs.setString('city', _selectedCity ?? '');
    await prefs.setString('district', _selectedDistrict ?? '');
    await prefs.setString('subdistrict', _selectedSubdistrict ?? '');
    await prefs.setString('healthCondition', _selectedHealthCondition ?? '아니오');
    // ✅ 신장병 여부에 따른 데이터 저장 추가 (수정된 부분)
    if (_selectedHealthCondition == '예' && _selectedKidneyDisease != null) {
      await prefs.setString('kidneyDisease', _selectedKidneyDisease!);
      print("✅ Register - 저장된 신장병: $_selectedKidneyDisease");
    } else {
      await prefs.remove('kidneyDisease'); // 기존 값 삭제 (예외 방지)
      print("❌ Register - 신장병 정보 없음");
    }


  }


  Future<void> loadRegionsData() async {
    final String response = await rootBundle.loadString('assets/korea_regions.json');
    final data = json.decode(response);
    setState(() {
      regions = data;
    });
  }

  bool _isFormValid() {
    return _name != null && _name!.trim().isNotEmpty &&
        _selectedGender != null &&
        _selectedYear != null &&
        _selectedMonth != null &&
        _selectedDay != null &&
        _selectedHealthCondition != null;
  }

  void _onRegisterPressed() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 필수 정보를 입력해주세요!"), backgroundColor: Colors.red),
      );
      return;
    }
    await _saveUserData(); // ✅ 사용자 정보 저장

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          city: _selectedCity ?? 'Unknown',
          district: _selectedDistrict ?? 'Unknown',
          subdistrict: _selectedSubdistrict ?? 'Unknown',
          healthCondition: _selectedHealthCondition ?? '아니오', // ✅ 건강 상태 전달
          gender: _selectedGender ?? 'Unknown',
          selectedYear: _selectedYear ?? 'Unknown',
          selectedMonth: _selectedMonth ?? 'Unknown',
          selectedDay: _selectedDay ?? 'Unknown',
          selectedKidneyDisease: _selectedHealthCondition == '예' ? _selectedKidneyDisease : null, // ✅ 추가

        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ✅ "이름 입력" 필드 (텍스트 길이 자동 조절)
          _buildTextField('이름', _nameController, (value) {
            setState(() {
              _name = value.trim();
            });
          }, _name == null || _name!.isEmpty ? "이름을 입력해주세요!" : null),

          SizedBox(height: 12),

          // 성별 선택
          Row(
            children: [
              Text('성별', style: TextStyle(fontSize: 16)),
              Spacer(),
              Expanded(child: _buildGenderButton('여자')),
              SizedBox(width: 8),
              Expanded(child: _buildGenderButton('남자')),
            ],
          ),
          if (_selectedGender == null)
            _buildErrorText('성별을 선택해주세요!'),

          SizedBox(height: 12),

          // 생년월일 선택
          // ✅ 생년월일 선택 (Row 내부에서 Expanded 사용)
          Row(
            children: [
              Expanded(child: _buildDropdownField('생년', _selectedYear, years, (value) => setState(() => _selectedYear = value))),
              SizedBox(width: 5),
              Expanded(child: _buildDropdownField('월', _selectedMonth, months, (value) => setState(() => _selectedMonth = value))),
              SizedBox(width: 5),
              Expanded(child: _buildDropdownField('일', _selectedDay, days, (value) => setState(() => _selectedDay = value))),
            ],
          ),
          if (_selectedYear == null || _selectedMonth == null || _selectedDay == null)
            _buildErrorText('생년월일을 선택해주세요!'),

          SizedBox(height: 16),

          // 질병 여부
          Text('신장병 여부', style: TextStyle(fontSize: 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildHealthConditionButton('예'),
              SizedBox(width: 8),
              _buildHealthConditionButton('아니오'),
            ],
          ),

          if (_selectedHealthCondition == '예') ...[
            SizedBox(height: 16),
            _buildDropdownField('신장병 질환 선택', _selectedKidneyDisease, kidneyDiseases.keys.toList(), (value) {
              setState(() {
                _selectedKidneyDisease = value;
              });
            }),

            if (_selectedKidneyDisease == null)
              _buildErrorText('세부사항을 선택해주세요!'),
          ],



          SizedBox(height: 16),

          Text('지역', style: TextStyle(fontSize: 16)),

          SizedBox(height: 8),

          // 시/도, 시/군/구, 읍/면/동 선택
          _buildDropdownField('시/도', _selectedCity, regions.keys.toList(), (value) async {
            setState(() {
              _selectedCity = value;
              _selectedDistrict = null;
              _selectedSubdistrict = null;
              districtList = regions[_selectedCity]?.keys.toList() ?? [];
              subdistrictList = [];
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('city', _selectedCity ?? ''); // ✅ 시/도 선택 시 저장
          }),
          SizedBox(height: 8),

          _buildDropdownField('시/군/구', _selectedDistrict, districtList, (value) async {
            setState(() {
              _selectedDistrict = value;
              _selectedSubdistrict = null;
              subdistrictList = regions[_selectedCity]?[_selectedDistrict]?.cast<String>() ?? [];
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('district', _selectedDistrict ?? ''); // ✅ 시/군/구 선택 시 저장
          }),
          SizedBox(height: 8),
          _buildDropdownField('읍/면/동', _selectedSubdistrict, subdistrictList, (value) async {
            setState(() {
              _selectedSubdistrict = value;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('subdistrict', _selectedSubdistrict ?? ''); // ✅ 읍/면/동 선택 시 저장
          }),

          SizedBox(height: 16),

          Center(
            child: ElevatedButton(
              onPressed: _onRegisterPressed,
              child: Text('다음', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }



  Widget _buildTextField(String label, TextEditingController controller, ValueChanged<String> onChanged, String? errorText) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
        errorText: errorText,
      ),
    );
  }

  Widget _buildGenderButton(String gender) {
    return OutlinedButton(
      onPressed: () => setState(() => _selectedGender = gender),
      style: OutlinedButton.styleFrom(
        backgroundColor: _selectedGender == gender ? Colors.green.withOpacity(0.2) : Colors.transparent,
        side: BorderSide(color: _selectedGender == gender ? Colors.green : Colors.grey),
      ),
      child: Text(gender, style: TextStyle(color: _selectedGender == gender ? Colors.green : Colors.grey)),
    );
  }

  Widget _buildHealthConditionButton(String label) {
    return OutlinedButton(
      onPressed: () => setState(() => _selectedHealthCondition = label),
      style: OutlinedButton.styleFrom(
        backgroundColor: _selectedHealthCondition == label ? Colors.green.withOpacity(0.2) : Colors.transparent,
        side: BorderSide(color: _selectedHealthCondition == label ? Colors.green : Colors.grey),
      ),
      child: Text(label, style: TextStyle(color: _selectedHealthCondition == label ? Colors.green : Colors.grey)),
    );
  }


  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField2(
      isExpanded: true, // ✅ 부모 크기에 맞게 확장되도록 설정
      value: value,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildErrorText(String text) => Padding(padding: EdgeInsets.only(top: 8), child: Text(text, style: TextStyle(color: Colors.red)));
}
