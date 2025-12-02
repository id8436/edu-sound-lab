import 'package:flutter/material.dart';
import 'fourier_analyzer.dart';

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

class FourierAnalyzerHome extends StatefulWidget {
  const FourierAnalyzerHome({super.key});

  @override
  State<FourierAnalyzerHome> createState() => _FourierAnalyzerHomeState();
}

class _FourierAnalyzerHomeState extends State<FourierAnalyzerHome> {
  int _selectedIndex = 0; // 현재 선택된 탭

  // ② 탭 데이터를 한 곳에서 정의 (main.dart의 menuItems와 유사)
  // ───────────────────────────────────────
  late final List<TabItem> tabItems = [
    TabItem(
      label: "푸리에 분석기",
      icon: Icons.mic,
      page: const FourierAnalyzer(),
    ),
    TabItem(
      label: "나중에 구현.",
      icon: Icons.mic,
      page: const FourierAnalyzer(),
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