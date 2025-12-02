import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/wave_config.dart';

class AudioService {
  FlutterSoundPlayer? _player;
  StreamController<Uint8List>? _streamController;
  StreamSubscription? _streamSubscription;
  Timer? _audioTimer;
  bool _isPlaying = false;
  
  static const int _sampleRate = 44100;
  static const int _bufferSize = 4096;
  
  bool get isPlaying => _isPlaying;
  
  Future<void> initialize() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    await _player!.setLogLevel(Level.nothing); // 디버그 로그 끄기
  }
  
  void dispose() {
    stop();
    _player?.closePlayer();
    _player = null;
  }
  
  // 파형 생성 함수
  Float32List _generateWaveform(WaveConfig config, int numSamples) {
    final data = Float32List(numSamples);
    final cyclesPerBuffer = config.frequency * numSamples / _sampleRate;
    
    for (int i = 0; i < numSamples; i++) {
      final phase = (i / numSamples) * cyclesPerBuffer * 2 * math.pi;
      
      switch (config.waveType) {
        case WaveConfig.waveTypeSine:
          data[i] = math.sin(phase);
          break;
        case WaveConfig.waveTypeSquare:
          data[i] = math.sin(phase) >= 0 ? 1.0 : -1.0;
          break;
        case WaveConfig.waveTypeSawtooth:
          data[i] = 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0;
          break;
        case WaveConfig.waveTypeTriangle:
          final t = (phase / (2 * math.pi)) % 1.0;
          data[i] = 2.0 * (2.0 * (t < 0.5 ? t : 1.0 - t)) - 1.0;
          break;
      }
    }
    return data;
  }
  
  // Float32를 16bit PCM으로 변환
  Uint8List _floatToPCM16(Float32List floatData) {
    final pcm = Uint8List(floatData.length * 2);
    for (int i = 0; i < floatData.length; i++) {
      final sample = (floatData[i] * 32767).clamp(-32768, 32767).toInt();
      pcm[i * 2] = sample & 0xFF;
      pcm[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    return pcm;
  }

  Future<void> play(WaveConfig config, {Function(String)? onError}) async {
    // 이미 재생 중이면 아무것도 하지 않음
    if (_isPlaying) {
      return;
    }
    
    _isPlaying = true;
    
    try {
      _streamController = StreamController<Uint8List>();
      
      _streamSubscription = _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: _sampleRate,
        bufferSize: _bufferSize,
        interleaved: true,
      ).asStream().listen((_) {});
      
      // 오디오 스트림 생성 타이머
      _audioTimer = Timer.periodic(Duration(milliseconds: 50), (timer) async {
        if (!_isPlaying || _streamController == null) {
          timer.cancel();
          return;
        }
        
        final waveData = _generateWaveform(config, _bufferSize);
        final pcmData = _floatToPCM16(waveData);
        
        _streamController!.add(pcmData);
      });
      
      // 스트림 데이터를 플레이어로 전송
      _streamController!.stream.listen((data) async {
        if (_player != null && _isPlaying) {
          await _player!.feedFromStream(data);
        }
      });
      
    } catch (e) {
      debugPrint('파형 재생 오류: $e');
      _isPlaying = false;
      onError?.call(e.toString());
    }
  }

  void stop() {
    if (!_isPlaying) return;
    
    _isPlaying = false;
    _audioTimer?.cancel();
    _audioTimer = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamController?.close();
    _streamController = null;
    _player?.stopPlayer();
  }
}
