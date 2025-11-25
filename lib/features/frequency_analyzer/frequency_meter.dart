import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_recorder/flutter_recorder.dart';

class FrequencyMeter extends StatefulWidget {
  const FrequencyMeter({super.key});

  @override
  State<FrequencyMeter> createState() => _FrequencyMeterState();
}

class _FrequencyMeterState extends State<FrequencyMeter> {
  final Recorder _recorder = Recorder.instance;
  bool _isListening = false;
  double _currentHz = 0.0;
  double _currentDb = -100.0; // optional display
  Timer? _pollTimer;
  static const int _fftBins = 256; // per flutter_recorder docs
  static const int _sampleRate = 44100;

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) return;

    await _recorder.init(sampleRate: _sampleRate, channels: RecorderChannels.mono);
    _recorder.setFftSmoothing(0.7);
    _recorder.start();
    _recorder.startStreamingData();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      try {
        final fft = _recorder.getFft(alwaysReturnData: true);
        final vol = _recorder.getVolumeDb();
        final hz = _dominantFrequency(fft, _sampleRate);
        if (!mounted) return;
        setState(() {
          _currentHz = hz;
          _currentDb = vol;
        });
      } catch (e) {
        debugPrint('FFT polling error: $e');
      }
    });

    setState(() => _isListening = true);
  }

  void _stopListening() {
    _pollTimer?.cancel();
    _recorder.stopStreamingData();
    _recorder.stop();
    _recorder.deinit();
    setState(() => _isListening = false);
  }

  double _dominantFrequency(Float32List fft, int sampleRate) {
    if (fft.isEmpty) return 0.0;
    // magnitude spectrum (ignore DC bin 0)
    int maxIndex = 1;
    double maxMag = fft[1].abs();
    for (int i = 2; i < math.min(fft.length, _fftBins); i++) {
      final m = fft[i].abs();
      if (m > maxMag) {
        maxMag = m;
        maxIndex = i;
      }
    }
    // bins likely span 0..Nyquist across 256 values
    final binWidth = sampleRate / 2 / _fftBins; // Hz per bin
    return maxIndex * binWidth;
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('주파수 분석기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('${_currentHz.toStringAsFixed(1)} Hz', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Note: ${_noteName(_currentHz)}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Level: ${_currentDb.toStringAsFixed(1)} dB', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.play_arrow),
            label: Text(_isListening ? '정지' : '시작'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }
}