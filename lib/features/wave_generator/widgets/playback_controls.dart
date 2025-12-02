import 'package:flutter/material.dart';

class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final double frequency;
  final String waveType;
  final VoidCallback onPlayPause;
  
  const PlaybackControls({
    Key? key,
    required this.isPlaying,
    required this.frequency,
    required this.waveType,
    required this.onPlayPause,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 볼륨 안내
        Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(Icons.volume_up, color: Colors.amber[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '음량(진폭)은 기기 볼륨으로 조절하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // 현재 웨이브 정보 표시
        Card(
          color: isPlaying ? Colors.green[50] : Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  isPlaying ? Icons.play_circle_filled : Icons.pause_circle_outline,
                  size: 40,
                  color: isPlaying ? Colors.green[700] : Colors.grey[600],
                ),
                SizedBox(height: 12),
                Text(
                  '${frequency.toInt()} Hz',
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: isPlaying ? Colors.green[700] : Colors.black87,
                  ),
                ),
                Text(
                  '${waveType.toUpperCase()} 파형',
                  style: TextStyle(
                    fontSize: 16, 
                    color: isPlaying ? Colors.green[600] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isPlaying) ...[
                  SizedBox(height: 8),
                  Text(
                    '재생 중...',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.green[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // 재생/중지 버튼
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPlayPause,
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(
              isPlaying ? '웨이브 중지' : '웨이브 재생',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPlaying ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
