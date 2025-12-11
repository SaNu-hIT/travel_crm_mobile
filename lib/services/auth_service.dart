import '../config/app_config.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      AppConfig.loginEndpoint,
      body: {
        'email': email,
        'password': password,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      // Save token and user data
      final token = response.data!['token'] as String;
      final userData = response.data!['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _storageService.saveToken(token);
      await _storageService.saveUser(user);
    }

    return response;
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    final response = await _apiService.get<User>(
      AppConfig.meEndpoint,
      fromJson: (data) => User.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await _storageService.saveUser(response.data!);
    }

    return response;
  }

  // Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null;
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    return await _storageService.getUser();
  }
}
