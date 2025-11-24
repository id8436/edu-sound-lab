import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class DecibelMeter extends StatefulWidget {
  @override
  _DecibelMeterState createState() => _DecibelMeterState();
}

class _DecibelMeterState extends State<DecibelMeter> {
  double _currentDB = 0.0;
  bool _isListening = false;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  Future<void> _startListening() async {
    // 마이크 권한 요청
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _noiseSubscription = NoiseMeter().noise.listen(
        (NoiseReading noiseReading) {
          setState(() {
            _currentDB = noiseReading.meanDecibel;
          });
        },
        onError: (error) {
          print('오류: $error');
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() {
    _noiseSubscription?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentDB.toInt()} dB',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? '정지' : '시작'),
            ),
          ],
        ),
      );
  }
}