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
  final String classroom;

  const SubjectTile({
    super.key,
    required this.periodNumber,
    required this.subject,
    required this.isFirst,
    required this.isLast,
    required this.isEditMode,
    required this.onAdd,
    required this.onRemove,
    required this.classroom,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontService = Provider.of<FontService>(context);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.tertiary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Period number box (left side)
          Container(
            width: screenWidth * 0.2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: isFirst ? Radius.circular(15) : Radius.zero,
                bottomLeft: isLast ? Radius.circular(15) : Radius.zero,
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

          // Subject and classroom info (middle)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subject,
                    overflow: TextOverflow.ellipsis,
                    style: fontService.font(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  if (classroom.isNotEmpty)
                    Text(
                      classroom,
                      overflow: TextOverflow.ellipsis,
                      style: fontService.font(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.035, // Slightly smaller
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Edit button (right side)
          if (isEditMode)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  subject.isEmpty ? Icons.add : Icons.remove,
                  color: AppColors.secondary,
                  size: screenWidth * 0.06, // Reduced size
                ),
                onPressed: subject.isEmpty ? onAdd : onRemove,
              ),
            ),
        ],
      ),
    );
  }
}
