import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_mobilna/services/payment_service.dart';

void main() {
  test('PaymentService exposes createSubscription and confirm', () {
    final service = PaymentService();
    expect(service.createSubscription, isA<Function>());
    expect(service.confirm, isA<Function>());
  });
}
