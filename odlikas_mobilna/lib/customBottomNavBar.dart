import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/AiChatbotPage/ai_chatbot_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(500, 60),
          topRight: Radius.elliptical(500, 60),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16, top: 20, bottom: 3),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  enableDrag: false,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
                  builder: (ctx) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(ctx).size.height,
                      child: const AiChatbotPage(),
                    ),
                  ),
                ).then((route) {
                  if (route != null && context.mounted) {
                    Navigator.of(context).pushReplacementNamed(route);
                  }
                });
              },
              child: SizedBox(
                height: 35,
                child: IgnorePointer(
                  child: TextField(
                    style: GoogleFonts.inter(height: 1, fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Pitajte naš AI ako imate pitanja oko nečega...',
                      hintStyle:
                          GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(
                            'assets/icon/ai.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Navigation Icons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, 'assets/icon/home.svg', '/home'),
                _buildNavItem(
                    context, 1, 'assets/icon/pomodoro.png', '/pomodoro'),
                _buildNavItem(
                    context, 2, 'assets/icon/leaderboard.png', '/leaderboard'),
                _buildNavItem(
                    context, 3, 'assets/icon/settings.png', '/settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, String assetPath, String route) {
    final bool isActive = currentIndex == index;
    final bool isSvg = assetPath.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.of(context).pushReplacementNamed(
            route,
            result: PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  Container(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSvg
              ? SvgPicture.asset(
                  assetPath,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    isActive ? Colors.white : Colors.white70,
                    BlendMode.srcIn,
                  ),
                )
              : Image.asset(
                  assetPath,
                  height: 37,
                  color: isActive ? Colors.white : Colors.white70,
                ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
