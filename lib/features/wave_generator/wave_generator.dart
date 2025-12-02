import 'package:flutter/material.dart';
import 'models/wave_config.dart';
import 'services/audio_service.dart';
import 'widgets/guide_card.dart';
import 'widgets/wave_type_selector.dart';
import 'widgets/frequency_controls.dart';
import 'widgets/playback_controls.dart';

class WaveGenerator extends StatefulWidget {
  const WaveGenerator({Key? key}) : super(key: key);

  @override
  State<WaveGenerator> createState() => _WaveGeneratorState();
}

class _WaveGeneratorState extends State<WaveGenerator> {
  final AudioService _audioService = AudioService();
  late WaveConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = WaveConfig(
      frequency: 440.0,
      waveType: WaveConfig.waveTypeSine,
    );
    _audioService.initialize();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
  
  void _updateFrequency(double frequency) {
    setState(() {
      _config = _config.copyWith(frequency: frequency);
    });
  }
  
  void _updateWaveType(String waveType) {
    setState(() {
      _config = _config.copyWith(waveType: waveType);
    });
  }
  
  void _togglePlayback() {
    if (_audioService.isPlaying) {
      _audioService.stop();
    } else {
      _audioService.play(
        _config,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오디오 재생 실패: $error')),
          );
        },
      );
    }
    setState(() {}); // UI 업데이트
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 사용 가이드
          GuideCard(),
          
          SizedBox(height: 20),

          // 타이틀 섹션
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 40, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    '파형 생성기 🎵',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '사인파, 사각파, 톱니파, 삼각파를 실시간으로 생성합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),

          // 파형 선택
          WaveTypeSelector(
            selectedWaveType: _config.waveType,
            onWaveTypeChanged: _updateWaveType,
          ),

          SizedBox(height: 16),

          // 주파수 조절
          FrequencyControls(
            frequency: _config.frequency,
            onFrequencyChanged: _updateFrequency,
          ),

          SizedBox(height: 16),

          // 재생 컨트롤
          PlaybackControls(
            isPlaying: _audioService.isPlaying,
            frequency: _config.frequency,
            waveType: _config.waveType,
            onPlayPause: _togglePlayback,
          ),
        ],
      ),
    );
  }
}
