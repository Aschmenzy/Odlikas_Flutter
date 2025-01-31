import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';

class DescriptionModal extends StatelessWidget {
  final Function(String)? onSave;
  final String? initialValue;

  const DescriptionModal({
    super.key,
    this.onSave,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller =
        TextEditingController(text: initialValue);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
                Text(
                  'Opis profila',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Recite nam malo o sebi, kako bi vas vaši budući poslodavci mogli bolje upoznati.',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MyButton(
                buttonText: "Spremi",
                ontap: onSave?.call(_controller.text),
                height: MediaQuery.of(context).size.height * 0.07,
                width: MediaQuery.of(context).size.width,
                decorationColor: AppColors.primary,
                borderColor: AppColors.primary,
                textColor: AppColors.background,
                fontWeight: FontWeight.w700,
                fontSize: 16)
          ],
        ),
      ),
    );
  }
}
