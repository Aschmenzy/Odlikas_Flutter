import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/pages/HomePage/home_page.dart';
import 'package:odlikas_mobilna/utilities/custom_button.dart';
import 'Widgets/numberSelector.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

Future<void> _savePreferences(BuildContext context, int selectedDaysPerWeek,
    int selectedHoursPerDay) async {
  try {
    // dohvacanje emaila iz lokalnog nstorage kako bi mogli spremiti podatke u bazu
    final box = await Hive.openBox('User');
    var email = box.get("email");

    // spremanje podataka u bazu studentProfiles
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef =
        firestore.collection('studentProfiles').doc(email);

    // spremanje podataka u bazu podkolekciju preferences'
    await docRef.set({
      'preferences': {
        'daysLearning': selectedDaysPerWeek,
        'hoursLearning': selectedHoursPerDay
      }
    }, SetOptions(merge: true));

    //promjena stranice
    Navigator.replace(
      context,
      oldRoute: ModalRoute.of(context)!,
      newRoute: MaterialPageRoute(builder: (context) => HomePage()),
    );
  } catch (e) {
    print('Error saving learning metrics: $e');
    //prikazivanje dialoga u slucaju greske
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Failed to save preferences. Please try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

//funkcija za dohvacanje podataka iz baze
//ako nema podataka vraca defaultne vrijednosti
Future<Map<String, int>> _loadInitialPreferences() async {
  try {
    // dohvacanje emaila iz lokalnog storagea
    final email = (await Hive.openBox('User')).get("email");

    // dohvacanje podataka iz baze
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference docRef =
        firestore.collection('studentProfiles').doc(email);

    final DocumentSnapshot doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>?;
    //provjera da li postoje podaci u bazi i ako postoje dohvati ih i vrati ih kao mapu
    if (data != null && data.containsKey('preferences')) {
      final preferences = data['preferences'];
      // dohvacanje podataka iz mape preferences i spremanje u varijable
      // ako podaci ne postoje koristi defaultne vrijednosti
      final daysLearning = preferences['daysLearning'] as int? ?? 1;
      final hoursLearning = preferences['hoursLearning'] as int? ?? 1;

      //ispisi podataka u konzoli radi provjere
      print('Days learning: $daysLearning');
      print('Hours learning: $hoursLearning');

      return {
        'daysLearning': daysLearning,
        'hoursLearning': hoursLearning,
      };
    }
  } catch (e) {
    print('Error loading initial preferences: $e');
  }

  // Return default values if there's an error or no data
  return {
    'daysLearning': 1,
    'hoursLearning': 1,
  };
}

class _PreferencesPageState extends State<PreferencesPage> {
  int selectedDaysPerWeek = 1;
  int selectedHoursPerDay = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  //poziva funkciju za dohvacanje podataka iz baze
  Future<void> _loadPreferences() async {
    final preferences = await _loadInitialPreferences();

    setState(() {
      selectedDaysPerWeek = preferences['daysLearning']!;
      selectedHoursPerDay = preferences['hoursLearning']!;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loadingBird.json',
                width: MediaQuery.of(context).size.width * 0.80,
                height: 120,
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Koliko vi voljeli učiti \ntjedno?",
                    style: GoogleFonts.inter(
                        fontSize: MediaQuery.of(context).size.width * 0.09,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: AppColors.secondary),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    "Može se kasnije promijeniti",
                    style: GoogleFonts.inter(
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                  Text(
                    "Dana u tjednu:",
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                  SizedBox(height: 10),
                  buildNumberSelector(
                    context: context,
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
                  buildNumberSelector(
                    context: context,
                    numbers: [1, 2, 3, 4],
                    selectedValue: selectedHoursPerDay,
                    onSelect: (value) {
                      setState(() {
                        selectedHoursPerDay = value;
                      });
                    },
                  ),
                  Spacer(),
                  MyButton(
                    fontSize: 24,
                    buttonText: "NASTAVI",
                    ontap: () {
                      _savePreferences(
                          context, selectedDaysPerWeek, selectedHoursPerDay);
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
                        newRoute:
                            MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    height: MediaQuery.of(context).size.width * 0.1,
                    width: MediaQuery.of(context).size.width * 1,
                    decorationColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    textColor: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
    );
  }
}
