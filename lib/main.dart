import 'package:flutter/material.dart';
import 'features/decibel_meter/decibel_home.dart';
import 'features/frequency_analyzer/frequency_analyzer_home.dart';
import 'features/wave_generator/wave_home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '에듀 사운드랩',  // 어플 정보임.
      home: const HomePage(),
    );
  }
}

// ① Drawer 메뉴 항목을 구조화
// ───────────────────────────────────────
class MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  MenuItem({
    required this.title,
    required this.icon,
    required this.page,  // 메뉴를 탭하면 넘어갈 페이지를 담는다. 요런식으로 객체화를 준비해서 관리하면 편함.
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // ② 메뉴 데이터를 한 곳에서 정의
  // ───────────────────────────────────────
  late final List<MenuItem> menuItems = [
    MenuItem(
      title: "데시벨 미터",
      icon: Icons.mic,
      page: const DecibelMeterHome(),  // lib/features/decibel_meter/decibel_home.dart 에 정의된 위젯 사용
    ),
    MenuItem(
      title: "주파수 미터",
      icon: Icons.noise_aware,
      page: FrequencyAnalyzerHome(),
    ),    MenuItem(
      title: "푸리에 분석",
      icon: Icons.equalizer,
      page: const Center(child: Text('푸리푸푸푸', style: TextStyle(fontSize: 24))),
    ),    MenuItem(
      title: "주파수 발생기",
      icon: Icons.volume_up,
      page: const WaveGeneratorHome()
    ),    
    MenuItem(
      title: "about",
      icon: Icons.settings,
      page: const Center(child: Text('나중에 관련 설명들 다 여기에?', style: TextStyle(fontSize: 24))),
    ),
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // 최상단이 Drawer라서, Drawer 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(menuItems[_selectedIndex].title),  // 선택된 메뉴의 타이틀을 앱바에 표시
      ),

      // ③ Drawer = ListView.builder로 자동 생성
      // ───────────────────────────────────────
      drawer: Drawer(
        child: ListView(   // 리스트 뷰 안에서 자동생성해서 관리한다.
          children: [
            DrawerHeader(
              child: Text("메뉴", style: TextStyle(fontSize: 24)),
            ),
            ...List.generate(menuItems.length, (index) {  // "..."은 리스트의 원소를 풀어 넣으라는 의미. 익명함수에 정의된 대로 리스트를 만들어 풀어 넣는다.
              final item = menuItems[index];
              return ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () => _selectPage(index),
              );
            }),
          ],
        ),
      ),
      body: menuItems[_selectedIndex].page,  // 위에서 지정한 페이지를 body에 담는다.
    );
  }
}