import 'package:flutter/material.dart';
import '../models/wave_config.dart';

class WaveTypeSelector extends StatelessWidget {
  final String selectedWaveType;
  final ValueChanged<String> onWaveTypeChanged;
  
  const WaveTypeSelector({
    Key? key,
    required this.selectedWaveType,
    required this.onWaveTypeChanged,
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
              '파형 종류 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.waves, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '사인파',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '부드러운 파형',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: WaveConfig.waveTypeSine,
                    groupValue: selectedWaveType,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    onChanged: (value) => onWaveTypeChanged(value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.crop_square, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '사각파',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '날카로운 파형',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: WaveConfig.waveTypeSquare,
                    groupValue: selectedWaveType,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    onChanged: (value) => onWaveTypeChanged(value!),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '톱니파',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '상승/하강',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: WaveConfig.waveTypeSawtooth,
                    groupValue: selectedWaveType,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    onChanged: (value) => onWaveTypeChanged(value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(Icons.change_history, size: 16, color: Colors.purple),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '삼각파',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '대칭 파형',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: WaveConfig.waveTypeTriangle,
                    groupValue: selectedWaveType,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    onChanged: (value) => onWaveTypeChanged(value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
