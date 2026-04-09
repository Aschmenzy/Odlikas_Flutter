import 'package:odlikas_mobilna/database/api/dio_client.dart';

class AccountService {
  Future<bool> getIsOdlikasPlus() async {
    final response = await DioClient.instance.get('/api/Account/Status');
    return response.data['isOdlikasPlus'] as bool;
  }
}
