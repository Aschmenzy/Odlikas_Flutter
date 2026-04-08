import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Ljestvica',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text('Ljestvica — coming soon'),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}
