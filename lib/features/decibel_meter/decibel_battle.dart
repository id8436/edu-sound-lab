import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class DecibelBattle extends StatefulWidget {
  const DecibelBattle({super.key});

  @override
  State<DecibelBattle> createState() => _DecibelBattleState();
}

class _DecibelBattleState extends State<DecibelBattle> {
  final TextEditingController _nameController = TextEditingController();
  
  double _currentDB = 0.0;
  double _maxDB = 0.0;
  bool _isRecording = false;
  int _countdown = 0;
  
  StreamSubscription<NoiseReading>? _noiseSubscription;
  Timer? _countdownTimer;
  
  // 배틀 기록을 저장할 리스트
  final List<BattleRecord> _battleRecords = [];

  Future<void> _startBattle() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참가자 이름을 입력해주세요!')),
      );
      return;
    }

    // 마이크 권한 요청
    var status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마이크 권한이 필요합니다!')),
      );
      return;
    }

    // 초기화
    setState(() {
      _maxDB = 0.0;
      _currentDB = 0.0;
      _isRecording = true;
      _countdown = 3;
    });

    // 3초 카운트다운 시작
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _startRecording();
      }
    });
  }

  void _startRecording() async {
    _noiseSubscription = NoiseMeter().noise.listen(
      (NoiseReading noiseReading) {
        setState(() {
          _currentDB = noiseReading.meanDecibel;
          if (_currentDB > _maxDB) {
            _maxDB = _currentDB;
          }
        });
      },
      onError: (error) {
        debugPrint('오류: $error');
      },
    );

    // 3초 후 측정 종료
    Timer(Duration(seconds: 3), () {
      _stopRecording();
    });
  }

  void _stopRecording() {
    _noiseSubscription?.cancel();
    
    // 기록 저장
    _battleRecords.add(BattleRecord(
      name: _nameController.text.trim(),
      maxDecibel: _maxDB,
      timestamp: DateTime.now(),
    ));

    // 기록을 데시벨 순으로 정렬
    _battleRecords.sort((a, b) => b.maxDecibel.compareTo(a.maxDecibel));

    setState(() {
      _isRecording = false;
    });

    // 이름 입력창 초기화
    _nameController.clear();
  }

  void _clearRecords() {
    setState(() {
      _battleRecords.clear();
    });
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    _countdownTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 설명 섹션
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '데시벨 배틀 🔥',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '측정 시작 후 3초 동안의 최대 데시벨이 기록됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),

          // 참가자 이름 입력
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '참가자 이름',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            enabled: !_isRecording,
          ),

          SizedBox(height: 20),

          // 현재 상태 표시
          if (_isRecording) ...[
            Card(
              color: _countdown > 0 ? Colors.orange[50] : Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_countdown > 0) ...[
                      Text(
                        '시작까지',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '$_countdown',
                        style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ] else ...[
                      Text(
                        '측정 중... 📢',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '현재: ${_currentDB.toInt()} dB',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(
                        '최고: ${_maxDB.toInt()} dB',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 20),

          // 시작 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRecording ? null : _startBattle,
              icon: Icon(_isRecording ? Icons.mic : Icons.play_arrow),
              label: Text(
                _isRecording ? '측정 중...' : '시작!',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                backgroundColor: _isRecording ? Colors.grey : Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 20),

          // 기록 리스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '배틀 기록 🏆',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_battleRecords.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearRecords,
                        icon: Icon(Icons.clear_all, size: 16),
                        label: Text('삭제'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: _battleRecords.isEmpty
                      ? Center(
                          child: Text(
                            '아직 기록이 없습니다.\n첫 번째 도전자가 되어보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _battleRecords.length,
                          itemBuilder: (context, index) {
                            final record = _battleRecords[index];
                            final isFirst = index == 0;
                            return Card(
                              color: isFirst ? Colors.yellow[50] : null,
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isFirst ? Colors.yellow : Colors.grey[300],
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFirst ? Colors.black : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  record.name,
                                  style: TextStyle(
                                    fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _formatTimestamp(record.timestamp),
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isFirst) 
                                      Icon(Icons.emoji_events, color: Colors.yellow[700], size: 16),
                                    Text(
                                      '${record.maxDecibel.toInt()} dB',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isFirst ? Colors.yellow[700] : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class BattleRecord {
  final String name;
  final double maxDecibel;
  final DateTime timestamp;

  BattleRecord({
    required this.name,
    required this.maxDecibel,
    required this.timestamp,
  });
}
