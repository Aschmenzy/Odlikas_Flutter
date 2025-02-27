// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:provider/provider.dart';

class MyButton extends StatelessWidget {
  const MyButton(
      {super.key,
      required this.buttonText,
      required this.ontap,
      required this.height,
      required this.width,
      required this.decorationColor,
      required this.borderColor,
      required this.textColor,
      required this.fontWeight,
      this.icon,
      required this.fontSize});

  final Function()? ontap;
  final String buttonText;
  final double height;
  final double width;
  final Color decorationColor;
  final Color borderColor;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;

  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);
    return GestureDetector(
      onTap: ontap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(15),
          color: decorationColor,
        ),
        alignment: Alignment.center,
        height: height,
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: icon),
            Text(
              buttonText,
              style: fontService.font(
                  color: textColor, fontWeight: fontWeight, fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }
}
