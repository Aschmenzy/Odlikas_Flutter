import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:provider/provider.dart';

class StudentIdModal extends StatefulWidget {
  final Function(Map<String, String>)? onSubmit;

  const StudentIdModal({Key? key, this.onSubmit}) : super(key: key);

  @override
  _StudentIdModalState createState() => _StudentIdModalState();
}

class _StudentIdModalState extends State<StudentIdModal> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final Map<String, TextEditingController> controllers = {
    'oib': TextEditingController(),
    'address': TextEditingController(),
    'postalCode': TextEditingController(),
    'city': TextEditingController(),
  };

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final formData = {
        'oib': controllers['oib']?.text ?? '',
        'address': controllers['address']?.text ?? '',
        'postalCode': controllers['postalCode']?.text ?? '',
        'city': controllers['city']?.text ?? '',
      };
      widget.onSubmit?.call(formData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  size: size.width * 0.08,
                  color: AppColors.secondary,
                  weight: 200,
                ),
              ),
              SizedBox(height: size.width * 0.02),
              Text(
                'Učenička iskaznica',
                style: fontService.font(
                    fontSize: size.width * 0.055,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary),
              ),
              SizedBox(height: size.width * 0.02),
              Text(
                'Unesite podatke kako bi dobili iskaznicu.',
                style: fontService.font(
                    fontSize: size.width * 0.035,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: size.width * 0.04),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CustomTextField(
                      lableText: "OIB:",
                      controller: controllers['oib']!,
                      hintText: '12345678...',
                      isNumberOnly: true,
                      maxLength: 11,
                      onTap: () => _scrollToField(0),
                    ),
                    SizedBox(height: size.width * 0.02),
                    _CustomTextField(
                      lableText: "Adresa:",
                      controller: controllers['address']!,
                      hintText: 'Ante Matušića 19K',
                      isNumberOnly: false,
                      onTap: () => _scrollToField(1),
                    ),
                    SizedBox(height: size.width * 0.02),
                    _CustomTextField(
                      lableText: "Poštanski broj:",
                      controller: controllers['postalCode']!,
                      hintText: '40000',
                      isNumberOnly: true,
                      maxLength: 5,
                      onTap: () => _scrollToField(2),
                    ),
                    SizedBox(height: size.width * 0.02),
                    _CustomTextField(
                      lableText: "Grad:",
                      controller: controllers['city']!,
                      hintText: 'Čakovec',
                      isNumberOnly: false,
                      onTap: () => _scrollToField(3),
                    ),
                    SizedBox(height: size.width * 0.1),
                    MyButton(
                      buttonText: "Spremi",
                      ontap: _handleSubmit,
                      height: size.height * 0.065,
                      width: size.width * 0.9,
                      decorationColor: AppColors.primary,
                      borderColor: AppColors.primary,
                      textColor: AppColors.background,
                      fontWeight: FontWeight.w600,
                      fontSize: size.width * 0.05,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToField(int index) {
    // Add a small delay to ensure the keyboard is shown before scrolling
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 100.0, // Approximate height of each field
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String lableText;
  final String hintText;
  final bool isNumberOnly;
  final int? maxLength;
  final VoidCallback? onTap;

  const _CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isNumberOnly = false,
    this.maxLength,
    required this.lableText,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lableText,
          style: fontService.font(
            fontSize: screenSize.width * 0.05,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        TextFormField(
          controller: controller,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: fontService.font(
              fontSize: screenSize.width * 0.035,
              color: AppColors.tertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: AppColors.secondary,
              ),
            ),
            counterText: '',
            isDense: true,
          ),
          keyboardType:
              isNumberOnly ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumberOnly
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ]
              : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ovo polje je obavezno';
            }
            if (isNumberOnly &&
                maxLength != null &&
                value.length != maxLength) {
              return 'Mora sadržavati točno $maxLength znamenki';
            }
            return null;
          },
        ),
      ],
    );
  }
}
