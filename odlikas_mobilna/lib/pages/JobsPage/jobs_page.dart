// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odlikas_mobilna/pages/JobsPage/Widgets/exclusiveJobs.dart';
import 'package:odlikas_mobilna/pages/JobsPage/Widgets/nonExclusiveJobs.dart';
import 'package:provider/provider.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //funkcija koja dohvaca sve promjene u Jobs collectionu
  Stream<QuerySnapshot> getJobs() {
    return _firestore.collection('Jobs').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontService = Provider.of<FontService>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: StreamBuilder<QuerySnapshot>(
            //stream builder koji se update kada funkcija getJobs vrati da je snapshot promijenjen
            stream: getJobs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // provjeravanje je li neki posalo exclusive ili nije
              //ako ima boolean exclusive true onda je ako nema onda nije
              final exclusiveJobs = snapshot.data!.docs
                  .where((doc) => doc['exclusive'] == true)
                  .toList();
              final nonExclusiveJobs = snapshot.data!.docs
                  .where((doc) => doc['exclusive'] == false)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.04),
                  Text(
                    "Eksluzivni poslovi:",
                    style: fontService.font(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // Exclusive jobs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: exclusiveJobs.map((job) {
                        //spremanje podataka jobData u mapu i onda passanje tih podataka u widgete
                        final jobData = job.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: ExclusiveJobs(
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            jobData: jobData,
                            jobId: job.id,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Text(
                    "Izdvojeni poslovi: ",
                    style: fontService.font(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // Non-exclusive jobs
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: nonExclusiveJobs.map((job) {
                          //spremanje podataka jobData u mapu i onda passanje tih podataka u widgete
                          final jobData = job.data() as Map<String, dynamic>;
                          return Column(
                            children: [
                              Card(
                                elevation: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.tertiary,
                                        blurRadius: 7,
                                        blurStyle: BlurStyle.inner,
                                        offset: const Offset(0, 0.5),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(15),
                                    color: AppColors.background,
                                  ),
                                  width: screenWidth * 0.9,
                                  height: screenHeight * 0.15,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8.0, top: 8),
                                    child: NonExclusiveJob(
                                      jobData: jobData,
                                      screenHeight: screenHeight,
                                      screenWidth: screenWidth,
                                      jobId: job.id,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
      ),
    );
  }
}
