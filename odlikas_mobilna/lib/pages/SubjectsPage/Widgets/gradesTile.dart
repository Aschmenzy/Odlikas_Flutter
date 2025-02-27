import 'package:flutter/material.dart';

import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/SpecificSubjectPage/secific_subject_page.dart';
import 'package:provider/provider.dart';

class GradeTile extends StatelessWidget {
  final String subjectName;
  final String professor;
  final String grade;
  final String subjectId;

  const GradeTile({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.professor,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SubjectDetailsPage(
              subjectId: subjectId,
            ),
          ),
        );
      },
      child: Container(
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(234, 234, 234, 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Text Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: screenWidth * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subject Name

                    Text(
                      subjectName,
                      style: fontService.font(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: screenHeight * 0.002),
                    // Professor Name

                    Text(
                      professor,
                      style: fontService.font(
                        fontSize: screenWidth * 0.04,
                        color: const Color.fromRGBO(113, 113, 113, 1),
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Grade Box
            Container(
              width: screenWidth * 0.15,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                grade,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
