import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class DecibelAlert extends StatefulWidget {
  const DecibelAlert({super.key});

  @override
  State<DecibelAlert> createState() => _DecibelAlertState();
}

class _DecibelAlertState extends State<DecibelAlert> {
  double _currentDB = 0.0;
  double _alertThreshold = 50.0;
  bool _isListening = false;
  bool _isAlertTriggered = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  Timer? _beepTimer;
  
  // 그래프용 데이터 저장
  List<FlSpot> _dbHistory = [];
  int _dataPointIndex = 0;
  static const int _maxDataPoints = 50; // 최대 표시할 데이터 포인트 수
  
  final TextEditingController _thresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _thresholdController.text = _alertThreshold.toInt().toString();
  }

  Future<void> _startListening() async {
    // 마이크 권한 요청
    var status = await Permission.microphone.request();
    if (!mounted) return;
    
    if (status.isGranted) {
      // 경고 상태 초기화
      setState(() {
        _isAlertTriggered = false;
        _currentDB = 0.0;
        // 그래프 데이터 초기화
        _dbHistory.clear();
        _dataPointIndex = 0;
      });
      
      _noiseSubscription = NoiseMeter().noise.listen(
        (NoiseReading noiseReading) {
          if (!mounted) return;
          
          setState(() {
            _currentDB = noiseReading.meanDecibel;
            _addDataPoint(_currentDB);
          });
          
          // 임계값을 초과하면 경고 발동
          if (_currentDB > _alertThreshold && !_isAlertTriggered) {
            _triggerAlert();
          }
        },
        onError: (error) {
          debugPrint('오류: $error');
        },
      );
      
      setState(() {
        _isListening = true;
      });
    } else {
      _showPermissionDialog();
    }
  }

  void _addDataPoint(double dbValue) {
    // 새로운 데이터 포인트 추가
    _dbHistory.add(FlSpot(_dataPointIndex.toDouble(), dbValue));
    _dataPointIndex++;
    
    // 최대 포인트 수를 초과하면 오래된 데이터 제거
    if (_dbHistory.length > _maxDataPoints) {
      _dbHistory.removeAt(0);
      // X축 인덱스 조정
      for (int i = 0; i < _dbHistory.length; i++) {
        _dbHistory[i] = FlSpot(i.toDouble(), _dbHistory[i].y);
      }
      _dataPointIndex = _dbHistory.length;
    }
  }

  void _triggerAlert() {
    setState(() {
      _isAlertTriggered = true;
    });
    
    // 측정 중지
    _stopListening();
    
    // 진동 및 경고음
    _playBeepSound();
    
    // 경고 다이얼로그 표시
    _showAlertDialog();
  }

  void _playBeepSound() {
    // 시스템 알림음 재생
    SystemSound.play(SystemSoundType.alert);
    
    // 추가적으로 반복 비프음 재생 (3회)
    int beepCount = 0;
    _beepTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (beepCount < 3) {
        SystemSound.play(SystemSoundType.click);
        beepCount++;
      } else {
        timer.cancel();
      }
    });
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('소리 경고!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '설정된 임계값을 초과했습니다!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                '임계값: ${_alertThreshold.toInt()} dB',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '측정값: ${_currentDB.toInt()} dB',
                style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetAlert();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _resetAlert() {
    setState(() {
      _isAlertTriggered = false;
      _currentDB = 0.0;
    });
  }

  void _stopListening() {
    _noiseSubscription?.cancel();
    _beepTimer?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  void _updateThreshold() {
    final newThreshold = double.tryParse(_thresholdController.text);
    if (newThreshold != null && newThreshold > 0 && newThreshold <= 120) {
      setState(() {
        _alertThreshold = newThreshold;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('임계값이 ${newThreshold.toInt()} dB로 설정되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 값을 입력하세요 (1-120 dB)'),
          backgroundColor: Colors.red,
        ),
      );
      _thresholdController.text = _alertThreshold.toInt().toString();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('마이크 권한 필요'),
          content: const Text('소리 경고 기능을 사용하려면 마이크 권한이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 임계값 설정 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '경고 임계값 설정',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _thresholdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '임계값 (dB)',
                            hintText: '1-120',
                            border: OutlineInputBorder(),
                            suffixText: 'dB',
                          ),
                          onSubmitted: (_) => _updateThreshold(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _updateThreshold,
                        child: const Text('설정'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '현재 임계값: ${_alertThreshold.toInt()} dB',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 현재 데시벨 표시
          Card(
            color: _isAlertTriggered ? Colors.red[50] : null,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    '${_currentDB.toInt()} dB',
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold,
                      color: _isAlertTriggered ? Colors.red : null,
                    ),
                  ),
                  Text(
                    _isAlertTriggered 
                        ? '경고 발동됨!' 
                        : _isListening 
                            ? '모니터링 중...' 
                            : '모니터링 중지됨',
                    style: TextStyle(
                      fontSize: 16, 
                      color: _isAlertTriggered 
                          ? Colors.red 
                          : Colors.grey[600],
                      fontWeight: _isAlertTriggered 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  
                  // 모니터링 중일 때만 표시되는 프로그레스 바
                  if (_isListening) 
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: (_currentDB / _alertThreshold).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentDB > _alertThreshold ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '임계값까지: ${(_alertThreshold - _currentDB).toInt()} dB',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 컨트롤 버튼
          ElevatedButton.icon(
            onPressed: _isAlertTriggered 
                ? null 
                : (_isListening ? _stopListening : _startListening),
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            label: Text(_isListening ? '모니터링 중지' : '모니터링 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          // 리셋 버튼 (경고 발동 시에만 표시)
          if (_isAlertTriggered) 
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton.icon(
                onPressed: _resetAlert,
                icon: const Icon(Icons.refresh),
                label: const Text('리셋'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // 실시간 그래프
          SizedBox(
            height: 400, // 고정 높이 설정
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '실시간 데시벨 그래프',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _dbHistory.isEmpty
                          ? Center(
                              child: Text(
                                '모니터링을 시작하면 실시간 그래프가 표시됩니다.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 10,
                                  verticalInterval: 5,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[300]!,
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[300]!,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 10,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            '${value.toInt()}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 20,
                                      reservedSize: 50,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            '${value.toInt()}dB',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                minX: 0,
                                maxX: _maxDataPoints.toDouble(),
                                minY: 0,
                                maxY: 120,
                                lineBarsData: [
                                  // 데시벨 데이터 라인
                                  LineChartBarData(
                                    spots: _dbHistory,
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withOpacity(0.2),
                                    ),
                                  ),
                                  // 임계값 직선
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(0, _alertThreshold),
                                      FlSpot(_maxDataPoints.toDouble(), _alertThreshold),
                                    ],
                                    isCurved: false,
                                    color: Colors.red,
                                    barWidth: 2,
                                    dotData: FlDotData(show: false),
                                    dashArray: [5, 5], // 점선 효과
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    _beepTimer?.cancel();
    _thresholdController.dispose();
    super.dispose();
  }
}