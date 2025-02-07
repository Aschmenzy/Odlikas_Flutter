import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/pages/SchedulePage/Widgets/timeButton.dart';

class TimeSelector extends StatelessWidget {
  final bool isMorning;
  final ValueChanged<bool> onChanged;

  const TimeSelector({
    super.key,
    required this.isMorning,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 80.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          TimeButton(
            title: 'UJUTRO',
            isSelected: isMorning,
            onTap: () => onChanged(true),
          ),
          TimeButton(
            title: 'POPODNE',
            isSelected: !isMorning,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}
