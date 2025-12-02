import 'package:flutter/material.dart';

class GuideCard extends StatelessWidget {
  const GuideCard({Key? key}) : super(key: key);
  
  Widget _buildGuideItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Text(
                  '사용 가이드 및 제한사항',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildGuideItem('📱 지원 플랫폼', 'Android / iOS 전용 (모바일 기기만 작동)'),
            _buildGuideItem('🎵 주파수 범위', '50Hz ~ 2,000Hz (스마트폰 스피커 최적 범위)'),
            _buildGuideItem('🔊 스피커 한계', '기기마다 재생 가능한 주파수 범위가 다를 수 있습니다'),
            _buildGuideItem('📻 저음역 제한', '100Hz 이하는 작은 스피커에서 잘 들리지 않을 수 있습니다'),
            _buildGuideItem('🎼 프리셋 음계', 'C3(130Hz) ~ G6(1567Hz) 음계를 쉽게 선택 가능'),
          ],
        ),
      ),
    );
  }
}
