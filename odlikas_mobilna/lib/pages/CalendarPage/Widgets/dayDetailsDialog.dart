import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class DayDetailsDialog extends StatefulWidget {
  final DateTime date;
  final List<Map<String, String>> tests;
  final Future<List<Map<String, String>>> Function(DateTime) fetchEvents;
  final Future<void> Function({
    required String title,
    required String description,
    required DateTime date,
  }) saveEvent;

  const DayDetailsDialog({
    super.key,
    required this.date,
    required this.tests,
    required this.fetchEvents,
    required this.saveEvent,
  });

  @override
  State<DayDetailsDialog> createState() => _DayDetailsDialogState();
}

class _DayDetailsDialogState extends State<DayDetailsDialog> {
  bool isAddingEvent = false;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: widget.fetchEvents(widget.date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              'assets/animations/error.json',
              height: MediaQuery.of(context).size.width * 0.3,
            ),
          );
        }

        final events = snapshot.data ?? [];

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildContent(events),
                  _buildAddEventSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(113, 113, 113, 0.2),
            width: 1,
          ),
        ),
      ),
      child: Text(
        "${widget.date.day}.${widget.date.month}.",
        style: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, String>> events) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildTestsList(),
              ...events.map((event) => _buildEventItem(event)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTestsList() {
    return widget.tests.map((test) => _buildTestItem(test)).toList();
  }

  Widget _buildTestItem(Map<String, String> test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          test['name']!,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          test['description']!,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEventItem(Map<String, String> event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event['title']!,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        Text(
          event['description']!,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAddEventSection() {
    return Column(
      children: [
        _buildAddEventButton(),
        if (isAddingEvent) _buildAddEventForm(),
      ],
    );
  }

  Widget _buildAddEventButton() {
    return GestureDetector(
      onTap: () => setState(() => isAddingEvent = !isAddingEvent),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color.fromRGBO(113, 113, 113, 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAddingEvent ? Icons.remove : Icons.add,
              color: Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              "Dodaj događaj u kalendar",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEventForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Naslov",
              hintStyle: GoogleFonts.inter(
                color: const Color.fromRGBO(113, 113, 113, 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            maxLength: 30,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Opis (maksimalno 30 znakova)",
              hintStyle: GoogleFonts.inter(
                color: const Color.fromRGBO(113, 113, 113, 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => isAddingEvent = false),
                child: Text(
                  "Odustani",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.saveEvent(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    date: widget.date,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "Spremi",
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
