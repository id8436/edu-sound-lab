import 'package:flutter/material.dart';
import '../models/wave_config.dart';

class FrequencyControls extends StatelessWidget {
  final double frequency;
  final ValueChanged<double> onFrequencyChanged;
  
  const FrequencyControls({
    Key? key,
    required this.frequency,
    required this.onFrequencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주파수 (Hz)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: frequency,
              min: WaveConfig.minFrequency,
              max: WaveConfig.maxFrequency,
              divisions: WaveConfig.frequencyDivisions,
              label: '${frequency.toInt()} Hz',
              onChanged: onFrequencyChanged,
            ),
            
            // 프리셋 음계 드롭다운
            Text(
              '프리셋 음계',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: WaveConfig.presetFrequencies.containsValue(frequency) 
                      ? frequency 
                      : null,
                  hint: Text(
                    '음계 선택 (현재: ${frequency.toInt()} Hz)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  items: WaveConfig.presetFrequencies.entries.map((entry) {
                    return DropdownMenuItem<double>(
                      value: entry.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${entry.value.toInt()} Hz',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onFrequencyChanged(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
