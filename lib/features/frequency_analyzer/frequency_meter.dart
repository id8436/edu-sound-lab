import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:fl_chart/fl_chart.dart';

class FrequencyMeter extends StatefulWidget {
  const FrequencyMeter({super.key});

  @override
  State<FrequencyMeter> createState() => _FrequencyMeterState();
}

class _FrequencyMeterState extends State<FrequencyMeter> {
  final Recorder _recorder = Recorder.instance;
  bool _isListening = false;
  double _currentHz = 0.0;
  Timer? _pollTimer;
  static const int _sampleRate = 44100;
  
  // 그래프용 데이터
  List<FlSpot> _hzHistory = [];
  int _dataPointIndex = 0;
  static const int _maxDataPoints = 50;
  
  // 디버깅용 - FFT 데이터 상태
  String _debugInfo = '';

  Future<void> _startListening() async {
    debugPrint('🎤 Starting frequency analysis...');
    
    final status = await Permission.microphone.request();
    if (!mounted) return;
    
    if (!status.isGranted) {
      debugPrint('❌ Microphone permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마이크 권한이 필요합니다!')),
      );
      return;
    }
    
    debugPrint('✅ Microphone permission granted');

    // 그래프 데이터 초기화
    _hzHistory.clear();
    _dataPointIndex = 0;

    try {
      debugPrint('🔧 Initializing recorder...');
      
      // 기본 설정으로 초기화
      await _recorder.init(
        sampleRate: _sampleRate, 
        channels: RecorderChannels.mono
      );
      
      debugPrint('🎛️ Setting FFT smoothing...');
      _recorder.setFftSmoothing(0.1); // 거의 스무딩 없이 실시간 반응
      
      debugPrint('▶️ Starting recorder...');
      _recorder.start();
      _recorder.startStreamingData();
      
      debugPrint('⏳ Waiting for stabilization...');
      // 좀 더 긴 대기 시간
      await Future.delayed(Duration(milliseconds: 500));
      
      debugPrint('✅ Recorder initialized successfully');
    } catch (e) {
      debugPrint('❌ Recorder init error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레코더 초기화 실패: $e')),
      );
      return;
    }

    _pollTimer?.cancel();
    debugPrint('🔄 Starting FFT polling...');
    
    int pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 150), (_) { // 좀 더 여유있게
      try {
        pollCount++;
        debugPrint('🔁 Poll attempt #$pollCount');
        
        final fft = _recorder.getFft(alwaysReturnData: true);
        
        if (fft.isEmpty) {
          debugPrint('⚠️ Empty FFT data on poll #$pollCount');
          return;
        }
        
        debugPrint('📊 FFT data received: ${fft.length} bins (poll #$pollCount)');
        
        // FFT 데이터 범위 확인
        double maxVal = fft.isNotEmpty ? fft.reduce(math.max) : 0;
        double minVal = fft.isNotEmpty ? fft.reduce(math.min) : 0;
        debugPrint('📈 FFT range: $minVal ~ $maxVal');
        
        // 만약 모든 값이 0이면 마이크에서 실제 소리를 받지 못하고 있음
        bool allZero = fft.every((value) => value.abs() < 0.0001);
        if (allZero) {
          debugPrint('🔇 All FFT values are near zero - check microphone!');
          debugPrint('💡 Try speaking directly into the microphone or make a louder sound');
          debugPrint('🔧 Check if other apps can access the microphone');
        }
        
        // FFT 데이터 샘플 출력 (처음 10개 값)
        if (fft.length >= 10) {
          List<String> sampleValues = fft.take(10).map((v) => v.toStringAsFixed(6)).toList();
          debugPrint('🔢 FFT sample values: ${sampleValues.join(", ")}');
        }
        
        debugPrint('🚀 About to call _dominantFrequency...');
        final hz = _dominantFrequency(fft, _sampleRate);
        debugPrint('🎵 Frequency detected: $hz Hz (poll #$pollCount)');
        
        if (!mounted) return;
        
        // 변화가 있는 경우만 업데이트
        final debugInfo = 'Poll #$pollCount, FFT: ${fft.length}, Range: ${minVal.toStringAsFixed(3)} ~ ${maxVal.toStringAsFixed(3)}';
        
        setState(() {
          _currentHz = hz;
          _debugInfo = debugInfo;
          if (hz > 0) { // 0이 아닌 경우만 그래프에 추가
            _addDataPoint(hz);
            debugPrint('📈 Added frequency point: ${hz.toStringAsFixed(1)} Hz to graph');
          } else {
            debugPrint('🚫 Frequency is 0, not adding to graph');
          }
        });
      } catch (e) {
        debugPrint('❌ FFT polling error on poll #$pollCount: $e');
        debugPrint('❌ Error type: ${e.runtimeType}');
      }
    });

    setState(() {
      _isListening = true;
      debugPrint('🎯 Frequency analysis started!');
    });
  }

  void _addDataPoint(double hzValue) {
    // 새로운 데이터 포인트 추가
    _hzHistory.add(FlSpot(_dataPointIndex.toDouble(), hzValue));
    _dataPointIndex++;
    
    // 최대 포인트 수를 초과하면 오래된 데이터 제거
    if (_hzHistory.length > _maxDataPoints) {
      _hzHistory.removeAt(0);
      // X축 인덱스 조정
      for (int i = 0; i < _hzHistory.length; i++) {
        _hzHistory[i] = FlSpot(i.toDouble(), _hzHistory[i].y);
      }
      _dataPointIndex = _hzHistory.length;
    }
  }

  void _stopListening() {
    debugPrint('🛑 Stopping frequency analysis...');
    
    _pollTimer?.cancel();
    _pollTimer = null;
    
    try {
      _recorder.stopStreamingData();
      debugPrint('📡 Streaming stopped');
      
      _recorder.stop();
      debugPrint('⏹️ Recorder stopped');
      
      _recorder.deinit();
      debugPrint('🔧 Recorder deinitialized');
      
    } catch (e) {
      debugPrint('⚠️ Stop error: $e');
    }
    
    setState(() {
      _isListening = false;
      debugPrint('✅ Frequency analysis stopped');
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      if (_isListening) {
        _recorder.stopStreamingData();
        _recorder.stop();
        _recorder.deinit();
      }
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
    super.dispose();
  }

  double _dominantFrequency(Float32List fft, int sampleRate) {
    debugPrint('🧮 _dominantFrequency called with FFT length: ${fft.length}, sampleRate: $sampleRate');
    
    if (fft.isEmpty || fft.length < 8) {
      debugPrint('⚠️ FFT data too short or empty: ${fft.length}');
      return 0.0;
    }
    
    // FFT 데이터 길이와 주파수 해상도 계산
    final fftLength = fft.length;
    final nyquistFreq = sampleRate / 2.0;
    final freqResolution = nyquistFreq / fftLength;
    
    debugPrint('📐 Frequency resolution: $freqResolution Hz/bin, Nyquist: $nyquistFreq Hz');
    
    // 전체 스펙트럼에서 최대값 찾기
    double maxMagnitude = 0.0;
    int maxIndex = 0;
    
    // 20Hz ~ 4000Hz 범위만 검색 (너무 낮거나 높은 주파수 제외)
    final minIndex = (20.0 / freqResolution).round().clamp(1, fftLength - 1);
    final maxFreqIndex = (4000.0 / freqResolution).round().clamp(minIndex, fftLength - 1);
    
    debugPrint('🔍 Searching frequency range: bin $minIndex to $maxFreqIndex (${(minIndex * freqResolution).toStringAsFixed(1)}Hz - ${(maxFreqIndex * freqResolution).toStringAsFixed(1)}Hz)');
    
    for (int i = minIndex; i < maxFreqIndex; i++) {
      final magnitude = fft[i].abs();
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
        maxIndex = i;
      }
    }
    
    debugPrint('🎯 Max magnitude: $maxMagnitude at bin $maxIndex (${(maxIndex * freqResolution).toStringAsFixed(1)}Hz)');
    
    // 신호가 너무 약하면 0 반환 (임계값을 매우 낮춤)
    const threshold = 0.000001; // 이전보다 10배 낮춤
    if (maxMagnitude < threshold) {
      debugPrint('🚫 Signal too weak (${maxMagnitude} < $threshold), returning 0');
      return 0.0;
    }
    
    debugPrint('✅ Signal strong enough (${maxMagnitude} >= $threshold), proceeding with interpolation...');
    
    // 🎯 2차 보간법으로 정확한 주파수 계산
    double interpolatedIndex = _parabolicInterpolation(fft, maxIndex);
    final frequency = interpolatedIndex * freqResolution;
    
    debugPrint('✨ Peak at bin $maxIndex, interpolated: ${interpolatedIndex.toStringAsFixed(2)}, freq: ${frequency.toStringAsFixed(1)} Hz');
    
    return frequency;
  }

  // 🧮 2차 보간법: 피크 주변의 3개 점으로 실제 피크 위치 계산
  double _parabolicInterpolation(Float32List fft, int maxIndex) {
    // 경계 체크: 양쪽에 데이터가 있어야 보간 가능
    if (maxIndex <= 0 || maxIndex >= fft.length - 1) {
      return maxIndex.toDouble();
    }
    
    // 피크와 양옆 bin의 값
    final y1 = fft[maxIndex - 1].abs();  // 왼쪽
    final y2 = fft[maxIndex].abs();      // 중앙 (최대값)
    final y3 = fft[maxIndex + 1].abs();  // 오른쪽
    
    // 2차 보간 공식: x_peak = x2 + (y1 - y3) / (2 * (y1 - 2*y2 + y3))
    final denominator = 2.0 * (y1 - 2.0 * y2 + y3);
    
    if (denominator.abs() < 1e-10) {
      // 분모가 0에 가까우면 보간 불가능 → 원래 인덱스 반환
      return maxIndex.toDouble();
    }
    
    final fractionalShift = (y1 - y3) / denominator;
    final interpolatedIndex = maxIndex + fractionalShift;
    
    // 보간 결과가 합리적인 범위에 있는지 확인 (±0.5 bin 내외)
    if ((interpolatedIndex - maxIndex).abs() > 0.5) {
      return maxIndex.toDouble();
    }
    
    return interpolatedIndex;
  }

  String _noteName(double hz) {
    if (hz <= 0) return '-';
    final noteNumber = (69 + 12 * (math.log(hz / 440.0) / math.ln2));
    final rounded = noteNumber.round();
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final name = names[rounded % 12];
    final octave = (rounded ~/ 12) - 1;
    return '$name$octave';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 현재 주파수 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text('${_currentHz.toStringAsFixed(1)} Hz', 
                       style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                  Text('Note: ${_noteName(_currentHz)}', 
                       style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  if (_isListening) ...[
                    SizedBox(height: 8),
                    Text(_debugInfo, 
                         style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 사용 가이드
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Text('사용 가이드', 
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• 마이크에 가까이서 명확한 소리를 내주세요', 
                       style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text('• 2차 보간법으로 세밀한 주파수 감지 (±1Hz 정확도)', 
                       style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text('• 권장: 휘파람, 허밍, 악기 단일음', 
                       style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // 컨트롤 버튼
          ElevatedButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            label: Text(_isListening ? '정지' : '시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          if (_isListening) ...[
            SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '측정 중... 소리를 내보세요!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 20),

          // 실시간 주파수 그래프
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '실시간 주파수 그래프',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: _hzHistory.isEmpty
                          ? Center(
                              child: Text(
                                '측정을 시작하면 실시간 주파수 그래프가 표시됩니다.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 500,
                                  verticalInterval: 5,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: 10,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text('${value.toInt()}',
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1000,
                                      reservedSize: 60,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text('${value.toInt()}Hz',
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 10)),
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
                                maxY: 4000,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _hzHistory,
                                    isCurved: true,
                                    color: Colors.purple,
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.purple.withOpacity(0.2),
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