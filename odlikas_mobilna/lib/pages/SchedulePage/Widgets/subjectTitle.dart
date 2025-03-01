import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:provider/provider.dart';

class SubjectTile extends StatelessWidget {
  final int periodNumber;
  final String subject;
  final bool isFirst;
  final bool isLast;
  final bool isEditMode;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const SubjectTile({
    super.key,
    required this.periodNumber,
    required this.subject,
    required this.isFirst,
    required this.isLast,
    required this.isEditMode,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontService = Provider.of<FontService>(context);
    return ListTile(
      leading: Container(
        width: screenWidth * 0.25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? Radius.circular(15) : Radius.zero,
            bottomLeft: isLast ? Radius.circular(15) : Radius.zero,
          ),
          border: Border.all(
            color: AppColors.background,
            width: 0.5,
          ),
        ),
        child: Text(
          '$periodNumber.sat',
          style: fontService.font(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.05,
          ),
        ),
      ),
      title: Text(
        subject,
        overflow: TextOverflow.ellipsis,
        style: fontService.font(
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.04,
        ),
      ),
      trailing: isEditMode
          ? IconButton(
              icon: Icon(
                subject.isEmpty ? Icons.add : Icons.remove,
                color: AppColors.secondary,
                size: screenWidth * 0.08,
              ),
              onPressed: subject.isEmpty ? onAdd : onRemove,
            )
          : null,
    );
  }
}
