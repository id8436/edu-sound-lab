import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class DecibelMeter extends StatefulWidget {
  const DecibelMeter({super.key});

  @override
  State<DecibelMeter> createState() => _DecibelMeterState();
}

class _DecibelMeterState extends State<DecibelMeter> {
  double _currentDB = 0.0;
  bool _isListening = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  
  // 그래프용 데이터 저장
  List<FlSpot> _dbHistory = [];
  int _dataPointIndex = 0;
  static const int _maxDataPoints = 50; // 최대 표시할 데이터 포인트 수
  Timer? _updateTimer;

  Future<void> _startListening() async {
    // 마이크 권한 요청
    var status = await Permission.microphone.request();
    if (!mounted) return;
    if (status.isGranted) {
      // 그래프 데이터 초기화
      _dbHistory.clear();
      _dataPointIndex = 0;
      
      _noiseSubscription = NoiseMeter().noise.listen(
        (NoiseReading noiseReading) {
          setState(() {
            _currentDB = noiseReading.meanDecibel;
            _addDataPoint(_currentDB);
          });
        },
        onError: (error) {
          debugPrint('오류: $error');
        },
      );
      setState(() {
        _isListening = true;
      });
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

  void _stopListening() {
    _noiseSubscription?.cancel();
    _updateTimer?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 현재 데시벨 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    '${_currentDB.toInt()} dB',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isListening ? '측정 중...' : '측정 중지됨',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // 컨트롤 버튼
          ElevatedButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            label: Text(_isListening ? '측정 중지' : '측정 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          SizedBox(height: 20),

          // 실시간 그래프
          Expanded(
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
                    SizedBox(height: 16),
                    Expanded(
                      child: _dbHistory.isEmpty
                          ? Center(
                              child: Text(
                                '측정을 시작하면 실시간 그래프가 표시됩니다.',
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
}