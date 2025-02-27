import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_mobilna/FontService.dart';
import 'package:provider/provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  late Box box;

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    box = await Hive.openBox('User');
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleQRCodeDetected(String? uid) async {
    if (!isScanning || uid == null) return;

    setState(() => isScanning = false);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Connecting...'),
        content: Center(
          child: Lottie.asset(
            'assets/animations/loadingBird.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(uid)
          .get();

      if (doc.exists) {
        final box = await Hive.openBox('User');
        final email = await box.get('email');
        final password = await box.get('password');

        box.put('screenConnected', true);

        // updejt screen collection sa email sifrom i promjenom connected na true
        await FirebaseFirestore.instance
            .collection('CreatedScreens')
            .doc(uid)
            .update(
                {'linkedUser': email, 'password': password, 'connected': true});

        navigator.pop();
        navigator.pop();

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Successfully connected to screen!')),
        );
      } else {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Screen not found')),
        );
        setState(() => isScanning = true);
      }
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => isScanning = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontService = Provider.of<FontService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  _handleQRCodeDetected(barcode.rawValue);
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Scan the QR code displayed on your tablet screen',
              textAlign: TextAlign.center,
              style: fontService.font(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
