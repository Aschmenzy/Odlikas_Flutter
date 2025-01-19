import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  int selectedDaysPerWeek = 1;
  int selectedHoursPerDay = 1;

  Widget _buildNumberSelector({
    required List<int> numbers,
    required int selectedValue,
    required Function(int) onSelect,
  }) {
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
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? Radius.circular(15) : Radius.zero,
                  right: isLast ? Radius.circular(15) : Radius.zero,
                ),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 26,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Koliko vi voljeli učiti \ntjedno?",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.09,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              "Može se kasnije promijeniti",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w800,
                color: AppColors.tertiary,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.025),
            Text(
              "Dana u tjednu:",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: MediaQuery.of(context).size.width * 0.05,
              ),
            ),
            SizedBox(height: 10),
            _buildNumberSelector(
              numbers: [1, 2, 3, 4, 5, 6, 7],
              selectedValue: selectedDaysPerWeek,
              onSelect: (value) {
                setState(() {
                  selectedDaysPerWeek = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              "Sati u danu:",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: MediaQuery.of(context).size.width * 0.05,
              ),
            ),
            SizedBox(height: 10),
            _buildNumberSelector(
              numbers: [1, 2, 3, 4],
              selectedValue: selectedHoursPerDay,
              onSelect: (value) {
                setState(() {
                  selectedHoursPerDay = value;
                });
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            MyButton(
              fontSize: 24,
              buttonText: "NASTAVI",
              ontap: () {
                Navigator.replace(
                  context,
                  oldRoute: ModalRoute.of(context)!,
                  newRoute: MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              height: MediaQuery.of(context).size.width * 0.175,
              width: MediaQuery.of(context).size.width * 1,
              decorationColor: AppColors.primary,
              borderColor: AppColors.primary,
              textColor: AppColors.background,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            MyButton(
              fontSize: 15,
              buttonText: "PRESKOČI",
              ontap: () {
                Navigator.replace(
                  context,
                  oldRoute: ModalRoute.of(context)!,
                  newRoute: MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              height: MediaQuery.of(context).size.width * 0.1,
              width: MediaQuery.of(context).size.width * 1,
              decorationColor: Colors.transparent,
              borderColor: Colors.transparent,
              textColor: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
