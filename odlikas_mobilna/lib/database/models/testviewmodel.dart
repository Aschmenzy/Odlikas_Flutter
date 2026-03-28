import 'package:flutter/material.dart';
import 'package:odlikas_mobilna/database/api/api_services.dart';
import 'package:odlikas_mobilna/database/models/tests.dart';

class TestViewmodel extends ChangeNotifier {
  final ApiService _apiService;

  TestViewmodel(this._apiService);

  bool _isLoading = false;
  Tests? _tests;

  Tests? get tests => _tests;
  bool get isLoading => _isLoading;

  Future<void> fetchTests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tests = await _apiService.fetchTestsDetails();
    } catch (e) {
      debugPrint('Error fetching tests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
