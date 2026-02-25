# 🍎 Smart Fruit Nutrition App

> 과채류 분석 기반 개인 맞춤 영양 관리 및  
> 신장질환 맞춤 과일 추천 Flutter 애플리케이션

사용자의 **성별 · 연령 · 건강 상태(신장질환 여부)**에 따라  
섭취 영양소를 분석하고 부족한 영양소를 보완할 수 있는  
과일을 추천하는 개인 맞춤형 영양 관리 앱입니다.

---

## 📸 App Preview

<p align="center">
  <img src="assets/juice 예시사진.png" width="850"/>
</p>

<p align="center">
  <img src="assets/juice.png" width="250"/>
  <img src="assets/juice2.png" width="250"/>
  <img src="assets/juice3.png" width="250"/>
</p>

---

## 📌 Project Overview

본 시스템은 다음 기능을 제공합니다:

- 👤 회원 등록 및 건강 정보 입력 (신장질환 포함)
- 📊 섭취 영양소 자동 분석
- 🍎 부족 영양소 기반 과일 추천 알고리즘
- 🧠 질환별 칼륨 제한 반영 로직
- 🎙️ TTS 음성 안내 기능
- 🥗 과일 분석 기록 저장
- 🧴 과일 부산물 기반 마스크팩 레시피 제공
- 📈 BMI 기록 관리

---

## 🧠 System Architecture

본 프로젝트는 단순 UI 앱이 아닌,

> **상태 기반 데이터 흐름 + 영양소 분석 엔진 + 조건 분기 추천 알고리즘**

구조로 설계되었습니다.

---

## 1️⃣ User Registration & Health Profiling

사용자 정보를 기반으로 맞춤 영양 기준을 설정합니다.

### 입력 정보
- 이름
- 성별
- 생년월일
- 지역
- 신장질환 여부
- 세부 질환 선택

### 기술 요소
- `SharedPreferences` 기반 로컬 데이터 저장
- 연령대 자동 계산 로직
- 성별 normalization 처리 ("남자" → "남")

---

## 2️⃣ Nutrient Analysis Engine

사용자가 섭취한 과일 데이터를 기반으로  
누적 영양소를 계산합니다.

### 주요 영양소
- 비타민 A
- 비타민 B6
- 비타민 C
- 칼륨
- 식이섬유
- 탄수화물
- 단백질
- 수분

### 핵심 특징
- 성별 · 연령대별 권장 섭취량 테이블 내장
- 섭취량 대비 부족 영양소 자동 계산
- 슬라이더 기반 시각화 UI 제공

---

## 3️⃣ Disease-Aware Fruit Recommendation Algorithm

단순 추천이 아닌  
**조건 기반 조합 최적화 방식**으로 설계되었습니다.

### 알고리즘 흐름

1. 부족한 영양소 계산
2. 각 과일의 영양 점수 산출
3. 최적 과일 탐색
4. 누적 칼륨 제한 초과 여부 검사
5. 반복 탐색 기반 조합 생성

### 신장질환 대응 칼륨 제한

| 질환 | 칼륨 제한 (mg) |
|------|---------------|
| 사구체신염 | 1000 |
| 급성 신손상 | 1200 |
| 신부전 | 2000 |
| 혈액투석 | 2000 |
| 복막투석 | 3000 |

> 제한 초과 과일은 자동 제외 처리됩니다.

---

## 4️⃣ Mask Pack Recommendation System

오늘 분석된 과일을 기반으로  
착즙 후 부산물 마스크팩 레시피를 제공합니다.

- 과일 한글/영문 매핑 처리
- 레시피 / 효과 / 주의사항 제공
- 기록 삭제 시 데이터 동기화

---

## 5️⃣ Voice Feedback System

- `flutter_tts` 활용
- 추천 과일 음성 안내
- 부족 영양소 없음 안내

---

## ⚙️ Data Flow Pipeline

User Registration  
→ MainScreen 초기화  
→ 과일 섭취 기록 누적  
→ 영양소 누적 계산  
→ 권장 섭취량 비교  
→ 부족 영양소 산출  
→ 질환 조건 반영  
→ 과일 조합 탐색  
→ TTS 음성 출력 + 팝업 표시  

---

## 📁 Project Structure

```bash
Smart-Fruit-Nutrition-App/
├── lib/
│   ├── main.dart
│   ├── home_screen.dart
│   ├── main_screen.dart
│   ├── register.dart
│   ├── my_page_screen.dart
│   ├── fruit_analysis_screen.dart
│   ├── fruit_analysis_history_screen.dart
│   ├── mask_pack_recipe_screen.dart
│   ├── daily_intake_screen.dart
│   ├── bmi_calculator_screen.dart
│   ├── bmi_history_screen.dart
│   ├── recommended_fruit_dialog.dart
│   ├── result_screen.dart
│   └── food_data.dart
├── assets/
│   ├── juice 예시사진.png
│   ├── juice.png
│   ├── juice2.png
│   ├── juice3.png
│   ├── korea_regions.json
│   ├── NanumGothic.ttf
│   ├── 온글잎 누가.ttf
│   ├── Facebook.png
│   ├── Google.png
│   ├── Kakao.png
│   ├── Naver.png
│   ├── labels.txt
│   └── labels1.txt
├── pubspec.yaml
├── pubspec.lock
└── README.md
```
---
👨‍💻 My Role

AI Logic & Flutter System Design

영양소 누적 계산 로직 설계

조건 기반 과일 추천 알고리즘 구현

신장질환 제한 로직 설계

TTS 음성 피드백 기능 구현

전체 상태 관리 구조 설계

UI/UX 플로우 설계

수행자 [김동언]


