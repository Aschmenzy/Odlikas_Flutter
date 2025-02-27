import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:odlikas_mobilna/pages/JobDetailsPage/job_details_page.dart';
import 'package:provider/provider.dart';

class ExclusiveJobs extends StatelessWidget {
  const ExclusiveJobs({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.jobData,
    required this.jobId,
  });

  final double screenWidth;
  final double screenHeight;
  final Map<String, dynamic> jobData;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    JobDetailsPage(jobId: jobId, jobData: jobData)));
      },
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tražimo ${jobData['title']}",
                    style: fontService.font(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "na lokaciji ${jobData['location']}",
                    style: fontService.font(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    jobData['description'] ?? 'No Description',
                    style: fontService.font(
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
                    style: fontService.font(
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
  }
}
