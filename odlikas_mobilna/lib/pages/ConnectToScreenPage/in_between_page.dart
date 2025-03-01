import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/ConnectToScreenPage/connect_screen.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'package:provider/provider.dart';

class InBetweenPage extends StatelessWidget {
  const InBetweenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final fontService = Provider.of<FontService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Container(
              width: screenSize.width,
              height: screenSize.height * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/pozadina.png"),
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                          "Tražite rješenje kako bi "
                          "mogli učit učinkovitije?",
                          style: fontService.font(
                            fontSize: screenSize.width * 0.07,
                            fontWeight: FontWeight.w800,
                            color: AppColors.background,
                          )),
                      SizedBox(height: screenSize.height * 0.02),
                      Text(
                        "ODLIKAŠ+ je tablet dizajniran za"
                        "učenike koji žele unaprijediti svoje"
                        "učenje i organizaciju! S jedinstvenim"
                        "Pomodoro timerom, pomoći će vam"
                        "da bolje upravljate vremenom "
                        "i održite fokus, povećavajući "
                        "produktivnost u učenju.",
                        style: fontService.font(
                          fontSize: screenSize.width * 0.04,
                          fontWeight: FontWeight.w600,
                          color: AppColors.background,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            //znanstvene biljeske video i tekst, tipka za qr kod
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Znanstvene bilješke",
                      style: fontService.font(
                        fontSize: screenSize.width * 0.065,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      )),

                  SizedBox(height: screenSize.height * 0.02),

                  //video i tekst

                  Container(
                    width: screenSize.width * 0.9,
                    height: screenSize.height * 0.225,
                    child: Image.asset(
                      'assets/images/znanstveneBiljeske.png',
                      fit: BoxFit.fill,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  RichText(
                    text: TextSpan(
                      style: fontService.font(
                        color: AppColors.secondary,
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'prepoznaju vaš rukopis i koriste ',
                          style: fontService.font(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize.width * 0.045),
                        ),
                        TextSpan(
                          text: 'umjetnu inteligenciju',
                          style: fontService.font(
                              color: AppColors.accent, fontSize: 16),
                        ),
                        TextSpan(
                          text: ' za rješavanje zadataka, prikazujući ',
                          style: fontService.font(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize.width * 0.045),
                        ),
                        TextSpan(
                          text: 'korake rješenja',
                          style: fontService.font(
                              color: AppColors.accent, fontSize: 16),
                        ),
                        TextSpan(
                          text: ' na jednostavan način.',
                          style: fontService.font(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize.width * 0.045),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Second paragraph with blue highlight
                  RichText(
                    text: TextSpan(
                      style: fontService.font(
                        color: AppColors.secondary,
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Uz dodatne alate za praćenje napretka i organizaciju zadataka, ',
                        ),
                        TextSpan(
                          text: 'ODLIKAŠ+',
                          style: fontService.font(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize.width * 0.045),
                        ),
                        TextSpan(
                          text:
                              ' je vaš savršeni pomoćnik za bolje rezultate u školi.',
                          style: fontService.font(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: screenSize.width * 0.045),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.02),
                  // Bottom text

                  Text(
                    'Biti organiziran, učinkovit i uspješan nikada nije bilo lakše!',
                    style: fontService.font(
                      color: AppColors.primary,
                      fontSize: screenSize.width * 0.045,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.045),

                  MyButton(
                      buttonText: "QR kod skener",
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectScreen(),
                          ),
                        );
                      },
                      height: screenSize.height * 0.07,
                      width: screenSize.width * 0.9,
                      decorationColor: AppColors.primary,
                      borderColor: AppColors.primary,
                      textColor: AppColors.background,
                      fontWeight: FontWeight.w700,
                      fontSize: screenSize.width * 0.06),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
