import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../widgets/loading_widget.dart';
import '../services/error_handling_service.dart';
import '../services/db_setup.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class ChooseUniversityScreen extends StatefulWidget {
  @override
  _ChooseUniversityScreenState createState() => _ChooseUniversityScreenState();
}

class _ChooseUniversityScreenState extends State<ChooseUniversityScreen> {
  String? selectedUniversity;
  String? selectedCategory;
  String? enteredMajor;
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _mounted = true;
  final _majorController = TextEditingController();
  final ErrorHandlingService _errorService = ErrorHandlingService();

  // Error state variables
  String? _errorMessage;
  bool _hasError = false;


  // Majors data organized by university and category
  final Map<String, Map<String, List<String>>> universitiesMajors = {
    '서울대학교': {
      '12특' : [
        '국어국문학과', '중어중문학과', '영어영문학과', '불어불문학과', '독어독문학과', '노어노문학과',
        '서어서문학과', '언어학과', '아시아언어문명학부', '역사학부', '고고미술사학과', '철학과', '종교학과',
        '미학과', '정치외교학부', '경제학부', '사회학과', '인류학과', '심리학과', '지리학과', '사회복지학과',
        '언론정보학과', '수리과학부', '통계학과', '물리학과', '천문학과', '화학부', '생명과학부', '지구환경과학부',
        '간호학과', '경영학과', '건설환경공학부', '기계공학부', '재료공학부', '전기정보공학부', '컴퓨터공학부', '화학생물공학부',
        '건축학과', '산업공학과', '에너지자원공학과', '원자핵공학과', '조선해양공학과', '항공우주공학과', '농업자원경제학', '지역정보학',
        '작물생명과학', '원예생명공학', '산업인력개발학', '산림환경학', '환경재료과학', '식품생명공학', '동물생명공학', '응용생명화학',
        '응용생물학', '조경학', '지역시스템공학', '바이오시스템공학', '바이오소재공학', '동양화과', '서양화과', '조소과', '공예과',
        '디자인과', '교육학과', '국어교육과', '영어교육과', '독어교육과', '불어교육과', '사회교육과', '역사교육과', '지리교육과',
        '윤리교육과', '수학교육과', '물리교육과', '화학교육과', '생물교육과', '지구과학교육과', '체육교육과', '소비자학과',
        '아동가족학과', '식품영양학과', '의류학과', '수의예과', '성악과', '작곡과', '음악학과', '피아노과', '관현악과',
        '국악과', '의예과', '자유전공학부'
      ]
    },

    '연세대학교': {
      '3특' : [
        '국어국문학과', '중어중문학과', '영어영문학과', '불어불문학과', '독어독문학과', '노어노문학과', '서어서문학과', '사학과',
        '철학과', '문헌정보학과', '심리학과', '경제학부', '응용통계학과', '경영학과', '수학과', '물리학과', '화학과', '지구시스템학과',
        '천문우주학과', '대기과학과', '화공생명공학부', '전기전자공학부', '건축공학과', '도시공학과', '사회환경시스템공학학부', '기계공학부',
        '신소재공학부', '산업공학과', '시스템생물학과', '생화학과', '생명공학과', '첨단컴퓨팅학부', 'IT융합공학전공', '지능형반도체전공',
        '신학과', '정치외교학과', '행정학과', '사회복지학과', '사회학과', '문화인류학과', '언론홍보영상학부', '의류환경학과', '식품영양학과',
        '실내건축학과', '아동가족학과', '통합디자인학과', '교육학부', '체육교육학과', '스포츠응용산업학과', '언더우드학부 (인문,사회)',
        '언더우드학부 (생명과학공학)', '융합인문사회과학부', '융합과학공학부', '의예과', '치의예과', '간호학과', '약학과'
      ],

      '12특' : [
        '국어국문학과', '중어중문학과', '영어영문학과', '불어불문학과', '독어독문학과', '노어노문학과', '서어서문학과', '사학과',
        '철학과', '문헌정보학과', '심리학과', '경제학부', '응용통계학과', '경영학과', '수학과', '물리학과', '화학과', '지구시스템학과',
        '천문우주학과', '대기과학과', '화공생명공학부', '전기전자공학부', '건축공학과', '도시공학과', '사회환경시스템공학학부', '기계공학부',
        '신소재공학부', '산업공학과', '시스템생물학과', '생화학과', '생명공학과', '첨단컴퓨팅학부', 'IT융합공학전공', '지능형반도체전공',
        '신학과', '정치외교학과', '행정학과', '사회복지학과', '사회학과', '문화인류학과', '언론홍보영상학부', '의류환경학과', '식품영양학과',
        '실내건축학과', '아동가족학과', '통합디자인학과', '체육교육학과', '스포츠응용산업학과', '언더우드학부 (인문,사회)',
        '언더우드학부 (생명과학공학)', '융합인문사회과학부', '융합과학공학부', '의예과', '치의예과', '간호학과', '약학과'
      ]
    },


    '고려대학교': {
      '3특': [
        '경영대학', '국어국문학과', '철학과', '한국사학과', '사학과', '사회학과', '한문학과',
        '영어영문학과', '독어독문학과', '불어불문학과', '중어중문학과', '노어노문학과', '일어일문학과',
        '서어서문학과', '언어학과', '생명과학부', '생명공학부', '환경생태공학부', '식품자원경제학과',
        '정치외교학과', '경제학과', '통계학과', '행정학과', '수학과','물리학과', '화학과',
        '지구환경과학과', '화공생명과학', '신소재공학부', '건축사회환경공학부', '건축학과',
        '기계공학부', '산업경영공학부', '전기전자공학', '융합에너공학과', '의과대학', '체육교육과',
        '간호대학', '컴퓨터학과', '데이터과학과', '인공지능학과', '디자인조형학부', '국제학부',
        '글로벌한국융합학부', '미디어학부', '바이오의공학부', '바이오시스템의과학부', '보건환융합과학부',
        '보건정책관학부', '자유전공학부', '스마트보안학부', '심리학부'
      ],

      '12특': [
        '경영대학', '국어국문학과', '철학과', '한국사학과', '사학과', '사회학과', '한문학과',
        '영어영문학과', '독어독문학과', '불어불문학과', '중어중문학과', '노어노문학과', '일어일문학과',
        '서어서문학과', '언어학과', '생명과학부', '생명공학부', '환경생태공학부', '식품자원경제학과',
        '정치외교학과', '경제학과', '통계학과', '행정학과', '수학과','물리학과', '화학과',
        '지구환경과학과', '화공생명과학', '신소재공학부', '건축사회환경공학부', '건축학과',
        '기계공학부', '산업경영공학부', '전기전자공학', '융합에너공학과', '의과대학', '체육교육과',
        '간호대학', '컴퓨터학과', '데이터과학과', '인공지능학과', '디자인조형학부', '국제학부',
        '글로벌한국융합학부', '미디어학부', '바이오의공학부', '바이오시스템의과학부', '보건환융합과학부',
        '보건정책관학부', '자유전공학부', '스마트보안학부', '심리학부'
      ]
    },

    '한양대학교': {
      '3특': [
        '건축학부', '건축공학부', '건설환경공학과', '도시공학과', '자원환경공학과',
        '융합전자공학부', '컴퓨터소프트웨어학부', '전기공학전공', '바이오메디컬공학전공',
        '신소재공학부', '화학공학과', '생명공학과', '유기나노공학과', '에너지공학과',
        '기계공학부', '원자력공학과', '산업공학과', '미래자동차공학과', '데이터사이언스학부',
        '간호학과', '수학과', '물리학과', '화학과', '생명과학과', '의류학과', '식품영양학과',
        '실내건축디자인학과', '정보시스템학과', '국어국문학과', '중어중문학과', '영어영문학과',
        '독어독문학과', '사학과', '철학과', '정치외교학과', '사회학과', '미디어커뮤니케이션학과',
        '관광학부', '정책학과', '행정학과', '경제금융학부', '경영학부', '파이낸스경영학과',
        '스포츠매니지먼트전공', '연극영화학과(영화전공)', '국제학부'
      ],
      '12특': [
        '건축학부', '건축공학부', '건설환경공학과', '도시공학과', '자원환경공학과',
        '융합전자공학부', '컴퓨터소프트웨어학부', '전기공학전공', '바이오메디컬공학전공',
        '신소재공학부', '화학공학과', '생명공학과', '유기나노공학과', '에너지공학과',
        '기계공학부', '원자력공학과', '산업공학과', '미래자동차공학과', '데이터사이언스학부',
        '의예과', '간호학과', '수학과', '물리학과', '화학과', '생명과학과', '의류학과',
        '식품영양학과', '실내건축디자인학과', '정보시스템학과', '국어국문학과', '중어중문학과',
        '영어영문학과', '독어독문학과', '사학과', '철학과', '정치외교학과', '사회학과',
        '미디어커뮤니케이션학과', '관광학부', '정책학과', '행정학과', '경제금융학부', '경영학부',
        '파이낸스경영학과', '스포츠매니지먼트전공', '연극영화학과(영화전공)', '국제학부',
        '글로벌콘텐츠융합학부', '성악과', '작곡과', '피아노과', '관현악과', '국악과', '무용학과'
      ]
    },
    '서강대학교': {
      '3특': [
        '국어국문학과', '사학과', '철학과', '종교학과', '영문학부', '유럽문화학과',
        '중국문화학과', '인문학기반자유전공학부', '사회학과', '정치외교학과', '심리학과',
        '경제학과', '경영학부', '글로벌한국학부', '게페르트국제학부', '신문방송학과',
        '미디어&엔터테인먼트학과', '아트&테크놀로지학과', '수학과', '물리학과', '화학과',
        '생명과학과', 'SCIENCE기반자유전공학부', '전자공학과', '컴퓨터공학과', '화공생명공학과',
        '기계공학과', '인공지능학과', 'AI기반자유전공학부'
      ],
      '12특': [
        '국어국문학과', '사학과', '철학과', '종교학과', '영문학부', '유럽문화학과',
        '중국문화학과', '인문학기반자유전공학부', '사회학과', '정치외교학과', '심리학과',
        '경제학과', '경영학부', '글로벌한국학부', '게페르트국제학부', '신문방송학과',
        '미디어&엔터테인먼트학과', '아트&테크놀로지학과', '수학과', '물리학과', '화학과',
        '생명과학과', 'SCIENCE기반자유전공학부', '전자공학과', '컴퓨터공학과', '화공생명공학과',
        '기계공학과', '인공지능학과', 'AI기반자유전공학부'
      ]

    },
    '성균관대학교': {
      '3특': [
        '유학·동양학과', '국어국문학과', '영어영문학과', '프랑스어문·경제학중문학',
        '중어중문학과', '독어독문학과', '러시아어문학과', '한문학과', '사학과', '철학과',
        '문헌정보학과', '글로벌리더학부', '글로벌경제학과', '행정학과', '정치외교학과',
        '미디어커뮤니케이션학과', '사회학과', '사회복지학과', '심리학과', '소비자학과',
        '아동·청소년학과', '경제학과', '통계학과', '경영학과', '글로벌경영학과', '영상학과',
        '의상학과', '글로벌융합학부', '생명과학과', '수학과', '물리학과', '식품생명공학과',
        '바이오메카트로닉스학과', '융합생명공학과', '전자전기공학부', '소프트웨어학과',
        '반도체응용공학과', '에너지학과', '양자정보공학과', '화학공학과', '신소재공학과',
        '기계공학과', '건설환경공학과', '시스템경영공학과', '나노공학과', '건축학과',
        '스포츠과학과', '의예과', '약학과'
      ],
      '12특': [
        '유학·동양학과', '국어국문학과', '영어영문학과', '프랑스어문·경제학중문학',
        '중어중문학과', '독어독문학과', '러시아어문학과', '한문학과', '사학과', '철학과',
        '문헌정보학과', '글로벌리더학부', '글로벌경제학과', '행정학과', '정치외교학과',
        '미디어커뮤니케이션학과', '사회학과', '사회복지학과', '심리학과', '소비자학과',
        '아동·청소년학과', '경제학과', '통계학과', '경영학과', '글로벌경영학과', '영상학과',
        '의상학과', '글로벌융합학부', '생명과학과', '수학과', '물리학과', '식품생명공학과',
        '바이오메카트로닉스학과', '융합생명공학과', '전자전기공학부', '소프트웨어학과',
        '반도체응용공학과', '에너지학과', '양자정보공학과', '화학공학과', '신소재공학과',
        '기계공학과', '건설환경공학과', '시스템경영공학과', '나노공학과', '건축학과',
        '스포츠과학과', '의예과', '약학과'
      ]
    },

    '중앙대학교' : {
      '3특' : [
        '국어국문학과', '영어영문학과', '독일어문학', '프랑스어문학', '러시아어문학', '일본어문학',
        '중국어문학', '철학과', '역사학과', '정치국제학과', '심리학과', '문헌정보학과', '사회복지학부',
        '사회학과', '도시계획 부동산학과', '공공인재학부', '미디어커뮤니케이션학부', '유아교육과', '영어교육과',
        '체육교육과', '물리학과', '화학과', '생명과학과', '수학과', '건설환경플랜트공학', '도시시스템공학', '건축학부',
        '에너지시스템공학부', '화학공학과', '기계공학부', '전자전기공학부', '융합공학부', '소프트웨어학부', 'AI학과', '경제학부',
        '응용통계학과', '광고홍보학과', '국제물류학과', '산업보안학과', '경영학', '글로벌금융학과', '약학부', '의학부', '간호학과'
      ],

      '12특' : [
        '국어국문학과', '영어영문학과', '독일어문학', '프랑스어문학', '러시아어문학', '일본어문학',
        '중국어문학', '철학과', '역사학과', '정치국제학과', '심리학과', '문헌정보학과', '사회복지학부',
        '사회학과', '도시계획 부동산학과', '공공인재학부', '미디어커뮤니케이션학부', '물리학과', '화학과', '생명과학과',
        '수학과', '건설환경플랜트공학', '도시시스템공학', '건축학부', '에너지시스템공학부', '화학공학과', '기계공학부',
        '전자전기공학부', '융합공학부', '소프트웨어학부', '경제학부',
        '응용통계학과', '광고홍보학과', '국제물류학과', '산업보안학과', '경영학', '글로벌금융학과', '약학부', '의학부', '간호학과'
      ]
    },

    '가천대학교': {
      '3특': [
        '경영학과', '회계세무학과', '금융수학학과', '빅데이터경영학과', '관광경영학과', '의료산업경영학과', '미디어커뮤니케이션학과',
        '경제학과', '응용통계학과', '사회복지학과', '심리학과', '패션산업학과', '한국어문학과', '영미어문학과', '중국어문학과', '일본어문학과',
        '유럽어문학과', '법학과', '경찰행정학과', '행정학과', '도시계획전공학과', '조경학과', '실내건축학과', '건축학과 (5년)', '건축공학과',
        '화공생명공학과', '배터리공학과', '기계공학과', '산업-스마트팩토리공학과', '설비-소방공학과', '신소재공학과', '토목환경공학과', '전기공학과',
        '스마트시티학과', '의공학과', '식품생명공학과', '식품영양학과', '바이오나노학과', '생명과학과', '반도체물리학과', '화학과', '전자공학과',
        '반도체공학과', '차세대반도체설계학과', 'AI학과', '컴퓨터공학과', '스마트보안학과', '시각디자인학과', '산업디자인학과', '간호학과',
        '바이오로직스학과', '치위생학과', '방사선학과', '물리치료학과', '응급구조학과', '운동재활학과', '의예과', '약학과'
      ],
      '12특': [
        '경영학과', '회계세무학과', '금융수학학과', '빅데이터경영학과', '관광경영학과', '의료산업경영학과', '미디어커뮤니케이션학과',
        '경제학과', '응용통계학과', '사회복지학과', '심리학과', '패션산업학과', '한국어문학과', '영미어문학과', '중국어문학과', '일본어문학과',
        '유럽어문학과', '법학과', '경찰행정학과', '행정학과', '도시계획전공학과', '조경학과', '실내건축학과', '건축학과 (5년)', '건축공학과',
        '화공생명공학과', '배터리공학과', '기계공학과', '산업-스마트팩토리공학과', '설비-소방공학과', '신소재공학과', '토목환경공학과', '전기공학과',
        '스마트시티학과', '의공학과', '식품생명공학과', '식품영양학과', '바이오나노학과', '생명과학과', '반도체물리학과', '화학과', '전자공학과',
        '반도체공학과', '차세대반도체설계학과', 'AI학과', '컴퓨터공학과', '스마트보안학과', '시각디자인학과', '산업디자인학과', '간호학과',
        '바이오로직스학과', '치위생학과', '방사선학과', '물리치료학과', '응급구조학과', '운동재활학과', '의예과', '약학과'
      ]
    },

    '경희대학교': {
      '3특' : [
        '국어국문학과', '영여영문학과', '응용영어통번역학과', '사학과', '철학과', '자율전공학과', '정치외교학과', '행정학과',
        '사회학과', '경제학과', '무역학과', '미디어학과', '경영학과', '회계-세무학과', '빅데이터응용학과', 'Hospitality 경영학과',
        '조리&푸드디자인학과', '관광-엔터테인먼트 학과', '글로벌 Hospitality관광학과', '아동가족학과', '주거환경학과', '의상학과',
        '국제학과', '프랑스어학과', '스페인어학과', '러시아어학과', '중국어학과', '일본어학과', '한국어학과', '글로벌커뮤니케이션학과',
        '식품영양학과', '수학과', '물리학과', '화학과', '생물학과', '지리학과', '미래정보디스플레이학과', '한약학과', '약과학과',
        '기계공학과', '산업경영공학과', '원자력공학과', '화학공학과', '신소재공학과', '사회기반시스템공학과', '건축공학과', '환경학및환경공학과',
        '건축학과 (5년)', '전자공학과', '반도체공학과', '생체의공학과', '컴퓨터공학과', '인공지능학과', '소프트웨어융합학과', '응용수학과',
        '응용물리학과', '응용화학과', '우주과학과', '유전생명공학과', '식품생명공학과', '융합바이오-신소재공학과', '스마트팜과학과',
        '산업디자인학과', '시각디자인학과', '환경조경디자인학과', '의류디자인학과', '디지털콘텐츠학과', '도예학과', '연극영화학과',
        'PostModern음악학과', '체육학과', '스포츠의학과', '골프산업학과', '스포츠지도학과', '태권도학과'
      ],
      '12특' : [
        '국어국문학과', '영여영문학과', '응용영어통번역학과', '사학과', '철학과', '자율전공학과', '정치외교학과', '행정학과',
        '사회학과', '경제학과', '무역학과', '미디어학과', '경영학과', '회계-세무학과', '빅데이터응용학과', 'Hospitality 경영학과',
        '조리&푸드디자인학과', '관광-엔터테인먼트 학과', '글로벌 Hospitality관광학과', '아동가족학과', '주거환경학과', '의상학과',
        '국제학과', '프랑스어학과', '스페인어학과', '러시아어학과', '중국어학과', '일본어학과', '한국어학과', '글로벌커뮤니케이션학과',
        '식품영양학과', '수학과', '물리학과', '화학과', '생물학과', '지리학과', '미래정보디스플레이학과', '한약학과', '약과학과',
        '기계공학과', '산업경영공학과', '원자력공학과', '화학공학과', '신소재공학과', '사회기반시스템공학과', '건축공학과', '환경학및환경공학과',
        '건축학과 (5년)', '전자공학과', '반도체공학과', '생체의공학과', '컴퓨터공학과', '인공지능학과', '소프트웨어융합학과', '응용수학과',
        '응용물리학과', '응용화학과', '우주과학과', '유전생명공학과', '식품생명공학과', '융합바이오-신소재공학과', '스마트팜과학과',
        '산업디자인학과', '시각디자인학과', '환경조경디자인학과', '의류디자인학과', '디지털콘텐츠학과', '도예학과', '연극영화학과',
        'PostModern음악학과', '체육학과', '스포츠의학과', '골프산업학과', '스포츠지도학과', '태권도학과', '한의예과'
      ]
    },

    '광운대학교': {
      '3특' : [
        '전자공학과', '전자통신공학과', '전자융합공학과', '전기공학과', '전자재료공학과', '반도체시스템공학과', '컴퓨터정보공학과',
        '소프트웨어학과', '정보융합학과', 'AI로봇학과', '정보제어-지능시스템전공', '건축학과 (5년)', '건축공학과', '화학공학과',
        '환경공학과', '수학과', '전자바이오물리학과', '화학과', '스포츠융합과학과', '국어국문학과', '영어산업학과', '미디어커뮤니케이션학과',
        '산업심리학과', '동북아문화산업학과', '행정학과', '법학과', '국제학과', '경영학과', '빅데이터경영학과', '국제통상학과'
      ],
      '12특' : [
        '전자공학과', '전자통신공학과', '전자융합공학과', '전기공학과', '전자재료공학과', '반도체시스템공학과', '컴퓨터정보공학과',
        '소프트웨어학과', '정보융합학과', 'AI로봇학과', '정보제어-지능시스템전공', '건축학과 (5년)', '건축공학과', '화학공학과',
        '환경공학과', '수학과', '전자바이오물리학과', '화학과', '스포츠융합과학과', '국어국문학과', '영어산업학과', '미디어커뮤니케이션학과',
        '산업심리학과', '동북아문화산업학과', '행정학과', '법학과', '국제학과', '경영학과', '빅데이터경영학과', '국제통상학과'
      ]
    },

    '국민대학교': {
      '3특' : [
        '국어국문학과', '글로벌한국어학과', '영미어문학과', '글로벌커뮤니케이션영어학과', '중국어문학과', '중국정경학과', '한국역사학과',
        '행정학과', '정치외교학과', '사회학과', '미디어학과', '광고홍보학과', '교육학과', '러시아-유라시아학과', '일본학과', '공법학과',
        '사법학과', '경제학과', '국제통상학과', '경영학과', '글로벌경영학과', '회계학과', '재무금융학과', '경영정보학과', 'AI빅데이터융합경영학과',
        'International Business학과', '기계금속재료학과', '전자화학재료학과', '기계공학과', '건설시스템공학과', '지능형반도체융합전자학과',
        '지능형ICT융합학과', '지능전자공학과', '소프트웨어학과', '인공지능학과', '산림환경시스템학과', '임산생명공학과', '나노전자물리학과',
        '나노소재학과', '바이오의약학과', '식품영양학과', '정보보안암호수학과', '바이오발효융합학과', '건축설계학과(5년)', '건축시스템학과 (4년)',
        '공업디자인학과', '시각디자인학과', '금속공예학과', '도자공예학과', '의상디자인학과', '공간디자인학과', '영상디자인학과', '자동차-운송디자인학과',
        'AI디자인학과', '연극전공학과', '스포츠교육학과', '스포츠산업레저학과', '스포츠건강재활학과'
      ],
      '12특' : [
        '국어국문학과', '글로벌한국어학과', '영미어문학과', '글로벌커뮤니케이션영어학과', '중국어문학과', '중국정경학과', '한국역사학과',
        '행정학과', '정치외교학과', '사회학과', '미디어학과', '광고홍보학과', '교육학과', '러시아-유라시아학과', '일본학과', '공법학과',
        '사법학과', '경제학과', '국제통상학과', '경영학과', '글로벌경영학과', '회계학과', '재무금융학과', '경영정보학과', 'AI빅데이터융합경영학과',
        'International Business학과', '기계금속재료학과', '전자화학재료학과', '기계공학과', '건설시스템공학과', '지능형반도체융합전자학과',
        '지능형ICT융합학과', '지능전자공학과', '소프트웨어학과', '인공지능학과', '산림환경시스템학과', '임산생명공학과', '나노전자물리학과',
        '나노소재학과', '바이오의약학과', '식품영양학과', '정보보안암호수학과', '바이오발효융합학과', '건축설계학과(5년)', '건축시스템학과 (4년)',
        '공업디자인학과', '시각디자인학과', '금속공예학과', '도자공예학과', '의상디자인학과', '공간디자인학과', '영상디자인학과', '자동차-운송디자인학과',
        'AI디자인학과', '연극전공학과', '스포츠교육학과', '스포츠산업레저학과', '스포츠건강재활학과'
      ]
    },


    '가톨릭관동대학교': {
      '3특' : [
        '의예과', '간호학과'
      ],
      '12특' : [
        '의예과', '간호학과'
      ]
    },

    '포항공과대학교': {
      '수시' : [
        '무학과 (자유전공)'
      ],
    },

    'KAIST': {
      '외국고전형' : [
        '무학과 (자유전공)'
      ],
    },

    '홍익대학교': {
      '3특' : [
        '전자-전기공학과', '신소재-화공시스템공학과', '컴퓨터공학과', '산업-데이터공학과', '기계-시스템디자인공학과', '건설환경공학과',
        '건축학전공 (5년)', '실내건축학과', '도시공학과', '경영학과', '영어영문학과', '독어독문학과', '불어불문학과', '국어국문학과',
        '법학과', '경제학과', '예술학과', '동양화과', '회화과', '판화과', '조소과', '디자인학과', '금속조형디자인과', '도예-유리과',
        '목조형가구학과', '섬유미술-패션디자인과', '전자전기융합공학과', '소프트웨어융합학과', '나노신소재학과', '건축공학과', '기계정보공학과',
        '조선해양공학과', '바이오화학공학과', '게임소프트웨어학과', '상경학과', '광고홍보학과', '디자인컨버전스학과', '영상-애니메이션학과',
        '게임그래픽디자인학과 (미술계)'
      ],
      '12특' : [
        '전자-전기공학과', '신소재-화공시스템공학과', '컴퓨터공학과', '산업-데이터공학과', '기계-시스템디자인공학과', '건설환경공학과',
        '건축학전공 (5년)', '실내건축학과', '도시공학과', '경영학과', '영어영문학과', '독어독문학과', '불어불문학과', '국어국문학과',
        '법학과', '경제학과', '예술학과', '동양화과', '회화과', '판화과', '조소과', '디자인학과', '금속조형디자인과', '도예-유리과',
        '목조형가구학과', '섬유미술-패션디자인과', '전자전기융합공학과', '소프트웨어융합학과', '나노신소재학과', '건축공학과', '기계정보공학과',
        '조선해양공학과', '바이오화학공학과', '게임소프트웨어학과', '상경학과', '광고홍보학과', '디자인컨버전스학과', '영상-애니메이션학과',
        '게임그래픽디자인학과 (미술계)'
      ]
    }


  };

  final List<Map<String, String>> universities = [
    {"name": "가천대학교", "image": "assets/universities/gacheon.png"},
    {"name": "가톨릭관동대학교", "image": "assets/universities/catholic_kwan.png"},
    {"name": "가톨릭대학교", "image": "assets/universities/catholic.png"},
    {"name": "건국대학교", "image": "assets/universities/gunguk.png"},
    {"name": "건양대학교", "image": "assets/universities/gunyang.png"},
    {"name": "경희대학교", "image": "assets/universities/kyunghee.png"},
    {"name": "고려대학교", "image": "assets/universities/korea.png"},
    {"name": "광운대학교", "image": "assets/universities/gwangwoon.png"},
    {"name": "국민대학교", "image": "assets/universities/kookmin.png"},
    {"name": "단국대학교", "image": "assets/universities/danguk.png"},
    {"name": "동국대학교 (경주)", "image": "assets/universities/dongguk.png"},
    {"name": "대전대학교", "image": "assets/universities/daejeon_univ.png"},
    {"name": "대구가톨릭대학교", "image": "assets/universities/daegu_catholic.png"},
    {"name": "상지대학교", "image": "assets/universities/shangji.png"},
    {"name": "서강대학교", "image": "assets/universities/seogang.png"},
    {"name": "서울대학교", "image": "assets/universities/seoul.png"},
    {"name": "성균관대학교", "image": "assets/universities/sungkunkwan.png"},
    {"name": "숙명여자대학교", "image": "assets/universities/sookmyung.png"},
    {"name": "순천향대학교", "image": "assets/universities/soonchun.png"},
    {"name": "아주대학교", "image": "assets/universities/aju.png"},
    {"name": "연세대학교", "image": "assets/universities/yonsei.png"},
    {"name": "우석대학교", "image": "assets/universities/woosuk.png"},
    {"name": "을지대학교", "image": "assets/universities/eulji.png"},
    {"name": "이화여자대학교", "image": "assets/universities/ewha.png"},
    {"name": "인제대학교", "image": "assets/universities/inje.png"},
    {"name": "인하대학교", "image": "assets/universities/inha.png"},
    {"name": "제주대학교", "image": "assets/universities/jejuuniv.png"},
    {"name": "중앙대학교", "image": "assets/universities/joongang.png"},
    {"name": "차의과대학교", "image": "assets/universities/cha_medical.png"},
    {"name": "충북대학교", "image": "assets/universities/chungbook.png"},
    {"name": "포항공과대학교", "image": "assets/universities/postech.png"},
    {"name": "KAIST", "image": "assets/universities/kaist.png"},
    {"name": "한림대학교", "image": "assets/universities/hanlim.png"},
    {"name": "한양대학교", "image": "assets/universities/hanyang.png"},
    {"name": "홍익대학교", "image": "assets/universities/hongik.png"},
  ];

  @override
  void dispose() {
    _mounted = false;
    _majorController.dispose();
    super.dispose();
  }
  // Enhanced with proper error handling
  Future<void> saveUniversityAndMajorSelection() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      print("No authenticated user found.");
      if (_mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Authentication error: No user logged in";
        });
      }
      return;
    }

    try {
      // Show loading dialog
      if (context.mounted) {
        LoadingWidget.show(context, message: "Saving your preferences...");
      }

      // Use our enhanced DBSetup utility that handles missing column issues
      final success = await DBSetup.saveUserSelectionWithFallback(
        userId: user.id,
        university: selectedUniversity,
        major: enteredMajor,
        category: selectedCategory,
      );

      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success) {
        print("University & Major saved: $selectedUniversity, $enteredMajor, Category: $selectedCategory");

        if (_mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        // Navigate to main page after successful save
        if (context.mounted) {
          proceedToMainPage();
        }
      } else {
        throw Exception("Failed to save user selection");
      }
    } catch (error) {
      // Hide loading dialog on error
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print("Error saving university & major: $error");

      // Handle the error gracefully
      String userFriendlyMessage = "Failed to save preferences";

      if (error is PostgrestException) {
        // Handle specific Postgres errors
        userFriendlyMessage = _errorService.handleDatabaseError(error);
      }

      if (_mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = userFriendlyMessage;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Skip',
              textColor: Colors.white,
              onPressed: () {
                // Allow user to skip and go to main page anyway
                proceedToMainPage();
              },
            ),
          ),
        );
      }
    }
  }

  void showMajorSelectionDialog() {
    // If the university has predetermined majors
    if (selectedUniversity == "포항공과대학교" || selectedUniversity == "KAIST") {
      // Show special message for POSTECH and KAIST
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: kPearl,
            title: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: kPaynesGrey,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Special Notice",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPaynesGrey,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedUniversity == "포항공과대학교"
                      ? "POSTECH has a unique admission process focused on science and engineering excellence."
                      : "KAIST has a special admission process focused on scientific and technological innovation.",
                  style: TextStyle(
                    fontSize: 16,
                    color: kPaynesGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "For detailed information about the admission process, please visit the official university website or contact the admissions office directly.",
                  style: TextStyle(
                    fontSize: 14,
                    color: kPaynesGrey.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Continue to major selection
                  if (universitiesMajors.containsKey(selectedUniversity)) {
                    showCategorySelectionDialog();
                  } else {
                    showModernMajorInputDialog();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: kPaynesGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // If the university has predetermined majors
      if (universitiesMajors.containsKey(selectedUniversity)) {
        showCategorySelectionDialog();
      } else {
        // For universities without predetermined majors, show the text input dialog
        showModernMajorInputDialog();
      }
    }
  }

  void showCategorySelectionDialog() {
    final categories = universitiesMajors[selectedUniversity]?.keys.toList() ?? [];

    if (categories.length == 1) {
      // If there's only one category, select it automatically and proceed to major selection
      selectedCategory = categories.first;
      showMajorListDialog();
      return;
    }

    // Show category selection dialog if there are multiple categories
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: kPearl,
          title: Text(
            "Select Category",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPaynesGrey,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(categories[index]),
                  onTap: () {
                    setState(() {
                      selectedCategory = categories[index];
                    });
                    Navigator.pop(context);
                    showMajorListDialog();
                  },
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: kPaynesGrey,
              ),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void showMajorListDialog() {
    final majors = universitiesMajors[selectedUniversity]?[selectedCategory!] ?? [];
    final TextEditingController searchController = TextEditingController();
    List<String> filteredMajors = List.from(majors);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: kPearl,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Your Major",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPaynesGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Search box
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search majors...",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.search, color: kPaynesGrey),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredMajors = majors
                            .where((major) =>
                            major.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // Made taller to accommodate grid view
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5, // Adjusted for better button proportions
                  ),
                  itemCount: filteredMajors.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          enteredMajor = filteredMajors[index];
                        });
                        Navigator.pop(context);
                        saveUniversityAndMajorSelection();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: kPaynesGrey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              filteredMajors[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kPaynesGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: kPaynesGrey,
                  ),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showModernMajorInputDialog() {
    _majorController.clear(); // Clear previous input

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: kPearl,
          title: Text(
            "Enter Your Major",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPaynesGrey,
            ),
          ),
          content: TextField(
            controller: _majorController,
            decoration: InputDecoration(
              hintText: "예: 컴퓨터공학",
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close pop-up
              },
              style: TextButton.styleFrom(
                foregroundColor: kPaynesGrey,
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_mounted) {
                  setState(() {
                    enteredMajor = _majorController.text;
                  });
                }

                Navigator.pop(context); // Close pop-up

                await saveUniversityAndMajorSelection(); // Save to Supabase
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPaynesGrey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void proceedToMainPage() {
    // Show loading dialog
    if (context.mounted) {
      LoadingWidget.show(context, message: "Preparing your dashboard...");
    }

    // Add a small delay for better UX
    Future.delayed(const Duration(seconds: 1), () {
      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Navigate to main page
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPageUI()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPearl,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPaynesGrey,
        centerTitle: true,
        title: const Text(
          "Choose Your University",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Skip button to let users bypass this step if they're having issues
          TextButton(
            onPressed: _isLoading ? null : () => proceedToMainPage(),
            child: const Text(
              "Skip",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select your dream university",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPaynesGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose the university you want to attend",
                  style: TextStyle(
                    fontSize: 16,
                    color: kPaynesGrey.withOpacity(0.7),
                  ),
                ),

                // Error message if any
                if (_hasError && _errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _hasError = false),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: universities.length,
                    itemBuilder: (context, index) {
                      String universityName = universities[index]['name']!;
                      String universityImage = universities[index]['image']!;

                      return GestureDetector(
                        onTap: !_isLoading ? () {
                          setState(() {
                            selectedUniversity = universityName;
                            _hasError = false; // Clear any error when making a new selection
                          });

                          showMajorSelectionDialog(); // Show major selection flow
                        } : null,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: selectedUniversity == universityName ?
                                Border.all(color: kPaynesGrey, width: 2) : null,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      universityImage,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.school, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  if (selectedUniversity == universityName)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: kPaynesGrey,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              universityName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selectedUniversity == universityName ?
                                kPaynesGrey : kPaynesGrey.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Overlay loading indicator when processing
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const LoadingWidget(
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
                message: "Processing...",
              ),
            ),
        ],
      ),
    );
  }
}