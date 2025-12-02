class WaveConfig {
  final double frequency;
  final String waveType;
  
  const WaveConfig({
    required this.frequency,
    required this.waveType,
  });
  
  WaveConfig copyWith({
    double? frequency,
    String? waveType,
  }) {
    return WaveConfig(
      frequency: frequency ?? this.frequency,
      waveType: waveType ?? this.waveType,
    );
  }
  
  // 프리셋 주파수 맵 (크로마틱 스케일 - 모든 음)
  static const Map<String, double> presetFrequencies = {
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
  
  // 주파수 범위 상수
  static const double minFrequency = 50.0;
  static const double maxFrequency = 2000.0;
  static const int frequencyDivisions = 195;
  
  // 파형 타입 상수
  static const String waveTypeSine = 'sine';
  static const String waveTypeSquare = 'square';
  static const String waveTypeSawtooth = 'sawtooth';
  static const String waveTypeTriangle = 'triangle';
  
  static const List<String> waveTypes = [
    waveTypeSine,
    waveTypeSquare,
    waveTypeSawtooth,
    waveTypeTriangle,
  ];
}
