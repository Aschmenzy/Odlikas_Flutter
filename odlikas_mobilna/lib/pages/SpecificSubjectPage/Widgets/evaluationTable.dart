import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/database/models/viewmodel.dart';

class EvaluationTable extends StatelessWidget {
  const EvaluationTable({super.key, required this.viewModel});

  final HomePageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Months header table
        Table(
          border: TableBorder.all(
            color: const Color.fromRGBO(113, 113, 113, 1),
            width: 0.4,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(1),
            7: FlexColumnWidth(1),
            8: FlexColumnWidth(1),
            9: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              children: [
                _buildTableHeaderCell("IX"),
                _buildTableHeaderCell("X"),
                _buildTableHeaderCell("XI"),
                _buildTableHeaderCell("XI"),
                _buildTableHeaderCell("I"),
                _buildTableHeaderCell("II"),
                _buildTableHeaderCell("III"),
                _buildTableHeaderCell("IV"),
                _buildTableHeaderCell("V"),
                _buildTableHeaderCell("VI"),
              ],
            ),
          ],
        ),

        // Individual category sections without spacing
        ...viewModel.evaluationElements!.map((element) => Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(113, 113, 113, 1),
                      width: 0.4,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    element.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Table(
                  border: TableBorder.all(
                    color: const Color.fromRGBO(113, 113, 113, 1),
                    width: 0.4,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                    6: FlexColumnWidth(1),
                    7: FlexColumnWidth(1),
                    8: FlexColumnWidth(1),
                    9: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      children: element.gradesByMonth.map((grade) {
                        return _buildTableCell(grade.isNotEmpty ? grade : "");
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ))
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      height: 45, // Fixed height to make cells more square
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text.replaceAll('\n', ', '), // Replace newlines with commas
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: Colors.black,
          fontSize: 14,
        ),
        overflow: TextOverflow.visible,
        maxLines: 1, // Force single line
      ),
    );
  }
}
