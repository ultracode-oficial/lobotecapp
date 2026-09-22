import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  const AuthRemoteDataSource({required this._client});

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {'login': login, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyMfa({
    required String code,
    required String mfaToken,
  }) async {
    final response = await _client.post(
      ApiConstants.mfaVerify,
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _client.get(ApiConstants.me);
    return UserModel.fromMeJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post(ApiConstants.logout);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _client.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      },
    );
  }

  Future<void> sendResetCode(String email) async {
    await _client.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _client.post(
      ApiConstants.verifyCode,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}
