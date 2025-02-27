// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:provider/provider.dart';

Widget buildNumberSelector({
  required BuildContext context,
  required List<int> numbers,
  required int selectedValue,
  required Function(int) onSelect,
}) {
  final fontService = Provider.of<FontService>(context);
  return Container(
    height: 50,
    child: Row(
      children: numbers.asMap().entries.map((entry) {
        final index = entry.key;
        final number = entry.value;
        final isSelected = number <= selectedValue;
        final isFirst = index == 0;
        final isLast = index == numbers.length - 1;

        return GestureDetector(
          onTap: () {
            onSelect(number);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: MediaQuery.of(context).size.width * 0.128,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.horizontal(
                left: isFirst ? Radius.circular(15) : Radius.zero,
                right: isLast ? Radius.circular(15) : Radius.zero,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: fontService.font(
                  color: isSelected ? Colors.white : AppColors.secondary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
