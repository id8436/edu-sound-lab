import 'package:flutter/material.dart';
import 'wave_generator.dart';

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

class WaveGeneratorHome extends StatefulWidget {
  const WaveGeneratorHome({super.key});
  @override
  State<WaveGeneratorHome> createState() => _WaveGeneratorHomeState();
}

class _WaveGeneratorHomeState extends State<WaveGeneratorHome> {
  int _selectedIndex = 0; // 현재 선택된 탭

  // ② 탭 데이터를 한 곳에서 정의 (main.dart의 menuItems와 유사)
  // ───────────────────────────────────────
  late final List<TabItem> tabItems = [
    TabItem(
      label: "웨이브 생성기",
      icon: Icons.graphic_eq,
      page: const WaveGenerator(),
    ),
    TabItem(
      label: "설정",
      icon: Icons.settings,
      page: const Center(
        child: Text('설정 화면\n(추후 구현)', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24)),
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