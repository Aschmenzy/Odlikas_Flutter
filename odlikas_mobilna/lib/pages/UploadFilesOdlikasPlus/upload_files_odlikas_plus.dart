import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odlikas_mobilna/pages/UploadFilesOdlikasPlus/Widgets/uploaded_file.dart';

class UploadFilesOdlikasPlus extends StatefulWidget {
  const UploadFilesOdlikasPlus({super.key});

  @override
  State<UploadFilesOdlikasPlus> createState() => _UploadFilesOdlikasPlusState();
}

class _UploadFilesOdlikasPlusState extends State<UploadFilesOdlikasPlus> {
  List<UploadedFile> uploadedFiles = [];
  bool isLoading = false;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    // Dohvati email iz lokalnog spremišta pomoću Hive-a.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = await Hive.openBox('User');
      final email = box.get('email');
      if (email != null) {
        setState(() {
          userEmail = email;
        });
        await loadFiles();
      } else {
        // Ako email nije pronađen, korisnik nije prijavljen.
        print("Email nije pronađen. Korisnik nije prijavljen.");
      }
    });
  }

  /// Učitava postojeće podatke o datotekama iz Firestore-a.
  Future<void> loadFiles() async {
    if (userEmail == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("odlikasFiles")
          .doc(userEmail)
          .get();
      if (doc.exists) {
        List filesData = doc.get("files") ?? [];
        List<UploadedFile> filesList = filesData.map((file) {
          return UploadedFile(
            name: file["name"],
            url: file["url"],
            extension: file["extension"],
          );
        }).toList();
        setState(() {
          uploadedFiles = filesList;
        });
      }
    } catch (e) {
      print("Greška pri učitavanju datoteka: $e");
    }
  }

  /// Omogućuje korisniku odabir datoteke i učitava ju u Firebase Storage.
  /// Metapodaci o datoteci se spremaju u Firestore u dokument s korisnikovim emailom.
  Future<void> uploadFile() async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Korisnik nije prijavljen.")),
      );
      return;
    }
    // Omogući korisniku odabir datoteke.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      // Ograniči veličinu datoteke na 5 MB.
      const int maxFileSize = 5 * 1024 * 1024; // 5 MB u bajtovima.
      int fileSize = result.files.single.size;
      if (fileSize > maxFileSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Datoteka je prevelika. Maksimalna dozvoljena veličina je 5 MB.")),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;
      String fileExtension = fileName.split('.').last;

      try {
        // Kreiraj referencu u Firebase Storage koristeći korisnikov email.
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child("user_files/$userEmail/$fileName");

        // Učitaj datoteku.
        UploadTask uploadTask = storageRef.putFile(File(filePath));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Pripremi metapodatke o datoteci.
        UploadedFile newFile = UploadedFile(
          name: fileName,
          url: downloadUrl,
          extension: fileExtension,
        );

        // Spremi metapodatke u Firestore.
        DocumentReference docRef = FirebaseFirestore.instance
            .collection("odlikasFiles")
            .doc(userEmail);
        DocumentSnapshot docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.update({
            "files": FieldValue.arrayUnion([
              {
                "name": fileName,
                "url": downloadUrl,
                "extension": fileExtension,
              }
            ])
          });
        } else {
          await docRef.set({
            "files": [
              {
                "name": fileName,
                "url": downloadUrl,
                "extension": fileExtension,
              }
            ]
          });
        }

        // Ažuriraj lokalni popis datoteka.
        setState(() {
          uploadedFiles.add(newFile);
          isLoading = false;
        });
      } catch (e) {
        print("Učitavanje nije uspjelo: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Vraća widget s pregledom datoteke.
  Widget buildFilePreview(UploadedFile file) {
    if (["png", "jpg", "jpeg"].contains(file.extension.toLowerCase())) {
      // Za slikovne datoteke, prikaži pregled slike.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            file.url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          Text(
            file.name,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // Za ostale tipove datoteka, prikaži generičku ikonu.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 100,
          ),
          const SizedBox(height: 8),
          Text(
            file.name,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Files"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : uploadedFiles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Molimo vas da prenesete datoteke koje želite koristiti u Znanstvenim Bilješkama Odlikaša+.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: uploadedFiles.length,
                  itemBuilder: (context, index) {
                    return buildFilePreview(uploadedFiles[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadFile,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
