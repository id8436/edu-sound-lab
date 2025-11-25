import 'package:edu_sound_lab/features/frequency_analyzer/frequency_meter.dart';
import 'package:flutter/material.dart';


// ① BottomNavigationBar 메뉴 항목을 구조화 (Drawer MenuItem과 유사)
// ───────────────────────────────────────
class TabItem {
  final String label;
  final IconData icon;
  final Widget page;

  TabItem({
    required this.label,
    required this.icon,
    required this.page,
  });
}

class FrequencyAnalyzerHome extends StatefulWidget {
  const FrequencyAnalyzerHome({super.key});
  @override
  State<FrequencyAnalyzerHome> createState() => _FrequencyAnalyzerHomeState();
}

class _FrequencyAnalyzerHomeState extends State<FrequencyAnalyzerHome> {
  int _selectedIndex = 0; // 현재 선택된 탭

  // ② 탭 데이터를 한 곳에서 정의 (main.dart의 menuItems와 유사)
  // ───────────────────────────────────────
  late final List<TabItem> tabItems = [
    TabItem(
      label: "Frequency Meter",
      icon: Icons.mic,
      page: const FrequencyMeter(),
    ),
    TabItem(
      label: "배틀!!",
      icon: Icons.whatshot,
      page: const Center(
        child: Text('추후 만들자.', style: TextStyle(fontSize: 24)),
      ),
    ),
    TabItem(
      label: "미정.",
      icon: Icons.settings,
      page: const Center(
        child: Text('설정 화면', style: TextStyle(fontSize: 24)),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 탭 선택 시 상태 변경
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabItems[_selectedIndex].page, // 현재 선택된 화면 표시
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // 탭 클릭 시 호출
        // ③ BottomNavigationBar = List.generate로 자동 생성
        // ───────────────────────────────────────
        items: List.generate(tabItems.length, (index) {
          final item = tabItems[index];
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }),
      ),
    );
  }
}