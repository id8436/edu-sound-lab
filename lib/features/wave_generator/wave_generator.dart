import 'package:flutter/material.dart';

class WaveGenerator extends StatefulWidget {
  const WaveGenerator({Key? key}) : super(key: key);

  @override
  State<WaveGenerator> createState() => _WaveGeneratorState();
}

class _WaveGeneratorState extends State<WaveGenerator> {
  // 웨이브 파라미터들
  double _frequency = 440.0; // Hz (기본값: A4 음)
  double _amplitude = 0.5;   // 진폭 (0-1)
  String _waveType = 'sine';  // 웨이브 타입
  bool _isPlaying = false;    // 재생 상태
  
  // 프리셋 주파수들 (크로마틱 스케일 - 모든 음)
  final Map<String, double> _presetFrequencies = {
    // 3옥타브
    'C3': 130.81,
    'C#3': 138.59,
    'D3': 146.83,
    'D#3': 155.56,
    'E3': 164.81,
    'F3': 174.61,
    'F#3': 185.00,
    'G3': 196.00,
    'G#3': 207.65,
    'A3': 220.00,
    'A#3': 233.08,
    'B3': 246.94,
    
    // 4옥타브 (기본 옥타브)
    'C4': 261.63,
    'C#4': 277.18,
    'D4': 293.66,
    'D#4': 311.13,
    'E4': 329.63,
    'F4': 349.23,
    'F#4': 369.99,
    'G4': 392.00,
    'G#4': 415.30,
    'A4': 440.00,  // 표준 A4
    'A#4': 466.16,
    'B4': 493.88,
    
    // 5옥타브
    'C5': 523.25,
    'C#5': 554.37,
    'D5': 587.33,
    'D#5': 622.25,
    'E5': 659.25,
    'F5': 698.46,
    'F#5': 739.99,
    'G5': 783.99,
    'G#5': 830.61,
    'A5': 880.00,
    'A#5': 932.33,
    'B5': 987.77,
    
    // 6옥타브 (높은 음역)
    'C6': 1046.50,
    'C#6': 1108.73,
    'D6': 1174.66,
    'D#6': 1244.51,
    'E6': 1318.51,
    'F6': 1396.91,
    'F#6': 1479.98,
    'G6': 1567.98,
  };

  void _playWave() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    // TODO: 실제 오디오 생성 및 재생 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlaying 
          ? '웨이브 생성 시작: ${_frequency.toInt()}Hz ${_waveType} 파형'
          : '웨이브 생성 중지'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _setPresetFrequency(double frequency) {
    setState(() {
      _frequency = frequency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 타이틀 섹션
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 40, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    '웨이브 생성기 🎵',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '사인파, 사각파, 톱니파 등 다양한 파형을 생성합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),

          // 파형 선택 (가장 먼저)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '파형 종류 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.show_chart, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text('사인파', 
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('부드러운 파형', 
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'sine',
                          groupValue: _waveType,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          onChanged: (value) {
                            setState(() {
                              _waveType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.crop_square, size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text('사각파', 
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('날카로운 파형', 
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'square',
                          groupValue: _waveType,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          onChanged: (value) {
                            setState(() {
                              _waveType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.trending_up, size: 16, color: Colors.green),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text('톱니파', 
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('상승/하강', 
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'sawtooth',
                          groupValue: _waveType,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          onChanged: (value) {
                            setState(() {
                              _waveType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(Icons.change_history, size: 16, color: Colors.purple),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text('삼각파', 
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('대칭 파형', 
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'triangle',
                          groupValue: _waveType,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4),
                          onChanged: (value) {
                            setState(() {
                              _waveType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 주파수 조절
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주파수 (Hz)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _frequency,
                    min: 50.0,
                    max: 2000.0,
                    divisions: 195,
                    label: '${_frequency.toInt()} Hz',
                    onChanged: (value) {
                      setState(() {
                        _frequency = value;
                      });
                    },
                  ),
                  
                  // 프리셋 음계 드롭다운
                  Text(
                    '프리셋 음계',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: _presetFrequencies.containsValue(_frequency) 
                            ? _frequency 
                            : null,
                        hint: Text(
                          '음계 선택 (현재: ${_frequency.toInt()} Hz)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        items: _presetFrequencies.entries.map((entry) {
                          return DropdownMenuItem<double>(
                            value: entry.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${entry.value.toInt()} Hz',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setPresetFrequency(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 진폭 조절
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '진폭 (%)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _amplitude,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(_amplitude * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        _amplitude = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 현재 웨이브 정보 표시 (마지막)
          Card(
            color: _isPlaying ? Colors.green[50] : Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    _isPlaying ? Icons.play_circle_filled : Icons.pause_circle_outline,
                    size: 40,
                    color: _isPlaying ? Colors.green[700] : Colors.grey[600],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${_frequency.toInt()} Hz',
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: _isPlaying ? Colors.green[700] : Colors.black87,
                    ),
                  ),
                  Text(
                    '${_waveType.toUpperCase()} 파형',
                    style: TextStyle(
                      fontSize: 16, 
                      color: _isPlaying ? Colors.green[600] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '진폭: ${(_amplitude * 100).toInt()}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (_isPlaying) ...[
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
              onPressed: _playWave,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isPlaying ? '웨이브 중지' : '웨이브 재생',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlaying ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
