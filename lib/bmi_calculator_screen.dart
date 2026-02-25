import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';



class BmiCalculatorScreen extends StatefulWidget {
  final List<BmiRecord> bmiHistory;
  final Function(List<BmiRecord>) onUpdate;

  BmiCalculatorScreen({
    required this.bmiHistory,
    required this.onUpdate,
  });

  @override
  _BmiCalculatorScreenState createState() => _BmiCalculatorScreenState();
}
class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double? _bmi;
  String _bmiStatus = "";
  double? _minHealthyWeight;
  double? _maxHealthyWeight;

  void _calculateBMI() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      setState(() {
        _bmi = weight / ((height / 100) * (height / 100));
        _bmiStatus = _determineBmiStatus(_bmi!);
        _minHealthyWeight = 18.5 * ((height / 100) * (height / 100));
        _maxHealthyWeight = 24.9 * ((height / 100) * (height / 100));

        // Add BMI record to the history list passed from MainScreen or MyPageScreen
        widget.bmiHistory.add(BmiRecord(
          date: DateTime.now(),
          bmi: _bmi!,
          height: height,
          weight: weight,
        ));
      });
    }
  }

  String _determineBmiStatus(double bmi) {
    if (bmi < 18.5) return "저체중";
    if (bmi >= 18.5 && bmi < 24.9) return "정상";
    if (bmi >= 25 && bmi < 29.9) return "과체중";
    return "비만";
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi >= 18.5 && bmi < 24.9) return Colors.green;
    if (bmi >= 25 && bmi < 29.9) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BMI 분석",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField("키 (cm)", _heightController),
            SizedBox(height: 10),
            _buildInputField("몸무게 (kg)", _weightController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: Text("BMI 계산", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_bmi != null) _buildBmiGauge(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }

  Widget _buildBmiGauge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                startAngle: 180,
                endAngle: 0,
                minimum: 15,
                maximum: 35,
                interval: 5,
                ranges: <GaugeRange>[
                  GaugeRange(startValue: 15, endValue: 18.5, color: Colors.blue),
                  GaugeRange(startValue: 18.5, endValue: 24.9, color: Colors.green),
                  GaugeRange(startValue: 24.9, endValue: 29.9, color: Colors.orange),
                  GaugeRange(startValue: 29.9, endValue: 35, color: Colors.red),
                ],
                pointers: <GaugePointer>[
                  MarkerPointer(
                      value: _bmi!,
                      enableDragging: true,
                      markerWidth: 12,
                      markerHeight: 12,
                      markerOffset: -15,
                      color: Colors.indigo),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Container(
                      child: Text(
                        _bmi!.toStringAsFixed(1),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.8,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: _getBmiColor(_bmi!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _bmiStatus,
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        SizedBox(height: 10),
        Text(
          '권장 체중 범위 (${_heightController.text}cm 기준):',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          '${_minHealthyWeight!.toStringAsFixed(1)} kg - ${_maxHealthyWeight!.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

// BMI 기록을 저장할 클래스
class BmiRecord {
  final DateTime date;
  final double bmi;
  final double height;
  final double weight;

  BmiRecord({
    required this.date,
    required this.bmi,
    required this.height,
    required this.weight,
  });
}
