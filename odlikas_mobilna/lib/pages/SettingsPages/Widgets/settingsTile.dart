import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:provider/provider.dart';

class SettingsTile extends StatelessWidget {
  final bool isLast;
  final String label;
  final String path;

  final Function()? onTap;
  final bool switchValue;
  final Function(bool)? onSwitchChanged;

  SettingsTile({
    super.key,
    required this.label,
    this.isLast = false,
    required this.path,
    this.onTap,
    this.switchValue = false,
    this.onSwitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                path,
                height: MediaQuery.of(context).size.width * 0.09,
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Text(
                label,
                style: fontService.font(
                  color: AppColors.secondary,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            Divider(
              color: AppColors.tertiary,
              thickness: 0.5,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          ],
        ],
      ),
    );
  }
}
