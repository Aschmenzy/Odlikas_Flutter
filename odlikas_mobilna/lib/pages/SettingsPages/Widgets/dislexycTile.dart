import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:provider/provider.dart';

class DislexycTile extends StatelessWidget {
  final String label;
  final String path;
  final bool value;
  final Function(bool)? onChanged;
  final bool isLast;

  const DislexycTile({
    Key? key,
    required this.label,
    required this.path,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: size.height * 0.035,
          child: Row(
            children: [
              Image.asset(path,
                  height: MediaQuery.of(context).size.width * 0.1),

              SizedBox(width: 18),

              // Label
              Expanded(
                child: Text(
                  label,
                  style: fontService.font(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),

              // Switch

              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.accent,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[350],
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),

        SizedBox(height: size.height * 0.01),

        // Divider (if not the last item)
        if (!isLast) ...[
          Divider(
            color: AppColors.tertiary,
            thickness: 0.5, // Thinner divider
            height: 8, // Reduced space around divider
          ),
          SizedBox(height: size.height * 0.01),
        ]
      ],
    );
  }
}
