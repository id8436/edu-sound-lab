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

  TableRow _buildTableRow(String db, String description, Color? bgColor) {
    return TableRow(
      decoration: BoxDecoration(color: bgColor),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            db,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            description,
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 사용 가이드
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Text('이용 가이드', 
                             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• 기기 한계: 마이크 하드웨어 제한으로 스마트폰마다 측정 한계가 다릅니다.', 
                         style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    Text('• 정밀도: 교육용으론 충분하지만, 연구용으론 전문 장비를 구하시기 바랍니다.', 
                         style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
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

            SizedBox(height: 16),


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
          Card(
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
                  SizedBox(
                    height: 300,
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

          
          SizedBox(height: 20),

          // 데시벨 기준표
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '데시벨 기준표',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Table(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      _buildTableRow('30dB', '속삭임, 조용한 도서관', Colors.green[50]),
                      _buildTableRow('40dB', '냉장고 소음, 조용한 사무실', Colors.green[100]),
                      _buildTableRow('50dB', '조용한 거리, 에어컨 소리', Colors.lightGreen[100]),
                      _buildTableRow('60dB', '일반 대화, 레스토랑', Colors.yellow[100]),
                      _buildTableRow('70dB', '청소기, 전화벨 소리', Colors.orange[100]),
                      _buildTableRow('80dB', '시끄러운 거리, 알람시계', Colors.orange[200]),
                      _buildTableRow('90dB', '지하철, 오토바이 소리', Colors.deepOrange[200]),
                      _buildTableRow('100dB', '공사장, 전동 공구', Colors.red[200]),
                      _buildTableRow('110dB', '록 콘서트, 클럽 음악', Colors.red[300]),
                      _buildTableRow('120dB', '제트기 이륙, 사이렌', Colors.red[400]),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '※ 85dB 이상은 장시간 노출 시 청력 손상 위험',
                    style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}