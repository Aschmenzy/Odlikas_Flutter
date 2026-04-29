import 'package:odlikas_mobilna/database/api/dio_client.dart';

class PaymentService {
  Future<({String clientSecret, String subscriptionId})> createSubscription() async {
    final response = await DioClient.instance.post('/api/Payment/CreateSubscription');
    return (
      clientSecret: response.data['clientSecret'] as String,
      subscriptionId: response.data['subscriptionId'] as String,
    );
  }

  Future<void> confirm(String subscriptionId) async {
    await DioClient.instance.post('/api/Payment/Confirm', data: {
      'subscriptionId': subscriptionId,
    });
  }

  Future<void> cancelSubscription() async {
    await DioClient.instance.post('/api/Payment/Cancel');
  }
}
