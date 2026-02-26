import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8080',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // 내 정보 조회
  Future<Map<String, dynamic>> getMyInfo() async {
    final res = await _dio.get('/users/me', options: await _authOptions());
    return res.data['data'];
  }

  // 사용자 정보 수정 (name, password, position 중 변경할 항목만 전달)
  // PATCH /users/{userId}
  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch(
      '/users/$userId',
      data: data,
      options: await _authOptions(),
    );
    return res.data['data'];
  }

  // 회원 탈퇴
  // DELETE /users/{userId}
  Future<void> deleteUser(int userId, String reason) async {
    await _dio.delete(
      '/users/$userId',
      data: {'reason': reason},
      options: await _authOptions(),
    );
  }
}
