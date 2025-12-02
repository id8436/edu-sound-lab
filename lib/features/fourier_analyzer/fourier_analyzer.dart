import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:typed_data';

class FourierAnalyzer extends StatefulWidget {
  const FourierAnalyzer({super.key});

  @override
  State<FourierAnalyzer> createState() => _FourierAnalyzerState();
}

class _FourierAnalyzerState extends State<FourierAnalyzer> {
  final Recorder _recorder = Recorder.instance;
  bool _isListening = false;
  Timer? _pollTimer;
  static const int _sampleRate = 44100;
  
  // FFT 스펙트럼 데이터
  final List<FlSpot> _spectrumData = [];
  
  // 주요 주파수 피크 저장
  final List<FrequencyPeak> _topPeaks = [];

  Future<void> _startListening() async {
    debugPrint('🎤 Starting Fourier analysis...');
    
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

    try {
      debugPrint('🔧 Initializing recorder...');
      
      await _recorder.init(
        sampleRate: _sampleRate, 
        channels: RecorderChannels.mono
      );
      
      debugPrint('🎛️ Setting FFT smoothing...');
      _recorder.setFftSmoothing(0.3);
      
      debugPrint('▶️ Starting recorder...');
      _recorder.start();
      _recorder.startStreamingData();
      
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
    
    _pollTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      try {
        final fft = _recorder.getFft(alwaysReturnData: true);
        
        if (fft.isEmpty) {
          return;
        }
        
        if (!mounted) return;
        
        setState(() {
          _updateSpectrum(fft);
        });
      } catch (e) {
        debugPrint('❌ FFT polling error: $e');
      }
    });

    setState(() {
      _isListening = true;
      debugPrint('🎯 Fourier analysis started!');
    });
  }

  void _updateSpectrum(Float32List fft) {
    _spectrumData.clear();
    _topPeaks.clear();
    
    final fftLength = fft.length;
    final freqResolution = (_sampleRate / 2.0) / fftLength;
    
    // FFT 데이터를 주파수 스펙트럼으로 변환
    for (int i = 0; i < fftLength; i++) {
      final frequency = i * freqResolution;
      final magnitude = fft[i].abs();
      
      // 20Hz ~ 4000Hz 범위만 표시
      if (frequency >= 20 && frequency <= 4000) {
        _spectrumData.add(FlSpot(frequency, magnitude));
      }
    }
    
    // 상위 5개 피크 찾기
    List<MapEntry<int, double>> peaks = [];
    for (int i = 1; i < fftLength - 1; i++) {
      if (fft[i] > fft[i - 1] && fft[i] > fft[i + 1] && fft[i].abs() > 0.01) {
        peaks.add(MapEntry(i, fft[i].abs()));
      }
    }
    
    // 크기순으로 정렬
    peaks.sort((a, b) => b.value.compareTo(a.value));
    
    // 상위 5개만 저장
    for (int i = 0; i < 5 && i < peaks.length; i++) {
      final index = peaks[i].key;
      final frequency = index * freqResolution;
      final magnitude = peaks[i].value;
      
      if (frequency >= 20 && frequency <= 4000) {
        _topPeaks.add(FrequencyPeak(
          frequency: frequency,
          magnitude: magnitude,
        ));
      }
    }
  }

  void _stopListening() {
    debugPrint('🛑 Stopping Fourier analysis...');
    
    _pollTimer?.cancel();
    _pollTimer = null;
    
    try {
      _recorder.stopStreamingData();
      _recorder.stop();
      _recorder.deinit();
    } catch (e) {
      debugPrint('⚠️ Stop error: $e');
    }
    
    setState(() {
      _isListening = false;
      _spectrumData.clear();
      _topPeaks.clear();
      debugPrint('✅ Fourier analysis stopped');
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 사용 가이드
          Card(
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.purple[700], size: 20),
                      SizedBox(width: 8),
                      Text('사용 가이드', 
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• 푸리에 변환(FFT)으로 소리의 주파수 성분 분석', 
                       style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text('• 그래프는 각 주파수 대역의 강도를 표시합니다', 
                       style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text('• 상위 5개 주파수 피크를 자동으로 감지합니다', 
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
              backgroundColor: _isListening ? Colors.red : Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          SizedBox(height: 20),

          // 주파수 스펙트럼 그래프
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주파수 스펙트럼',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _spectrumData.isEmpty
                        ? Center(
                            child: Text(
                              '분석을 시작하면 주파수 스펙트럼이 표시됩니다.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 0.2,
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
                                    interval: 500,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text('${value.toInt()}Hz',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 0.5,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(value.toStringAsFixed(1),
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
                              minX: 20,
                              maxX: 4000,
                              minY: 0,
                              maxY: 1.5,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _spectrumData,
                                  isCurved: false,
                                  color: Colors.purple,
                                  barWidth: 1,
                                  isStrokeCapRound: false,
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

          SizedBox(height: 20),

          // 상위 주파수 피크 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주요 주파수 성분',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _topPeaks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              '분석 중...',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : Column(
                          children: _topPeaks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final peak = entry.value;
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.purple[100 * (index + 1)],
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[900],
                                  ),
                                ),
                              ),
                              title: Text(
                                '${peak.frequency.toStringAsFixed(1)} Hz',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '강도: ${peak.magnitude.toStringAsFixed(3)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FrequencyPeak {
  final double frequency;
  final double magnitude;

  FrequencyPeak({
    required this.frequency,
    required this.magnitude,
  });
}
