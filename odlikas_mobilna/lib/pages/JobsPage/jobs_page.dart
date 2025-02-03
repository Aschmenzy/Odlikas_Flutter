// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odlikas_mobilna/pages/JobsPage/Widgets/nonExclusiveJobs.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getJobs() {
    return _firestore.collection('Jobs').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: StreamBuilder<QuerySnapshot>(
            stream: getJobs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Separate jobs into exclusive and non-exclusive
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
                    style: GoogleFonts.inter(
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
                        final jobData = job.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Card(
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                    image: AssetImage('assets/images/job.png'),
                                    fit: BoxFit.cover,
                                    onError: (exception, stackTrace) {
                                      print('Error loading image: $exception');
                                    },
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.2),
                                    ],
                                  )),
                              width: screenWidth * 0.8,
                              height: screenHeight * 0.2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.black.withOpacity(0.4),
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Tražimo ${jobData['title']}",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "na lokaciji ${jobData['location']}",
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            height: 0.6),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        jobData['description'] ??
                                            'No Description',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                        jobData['catchPhrase'],
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  Text(
                    "Izdvojeni poslovi: ",
                    style: GoogleFonts.inter(
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
                                  width: screenWidth * 0.8,
                                  height: screenHeight * 0.135,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: NonExclusiveJob(
                                      jobData: jobData,
                                      screenHeight: screenHeight,
                                      screenWidth: screenWidth,
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
