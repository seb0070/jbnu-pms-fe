import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

class UserService {
  // ✅ DioClient - baseUrl + 토큰 자동 주입. _authOptions() 제거
  final Dio _dio = DioClient.create();

  Future<Map<String, dynamic>> getMyInfo() async {
    final res = await _dio.get('/users/me');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final res = await _dio.get('/users/$userId');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/users/$userId', data: data);
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateProfileImage(
    int userId,
    File image,
  ) async {
    // multipart는 인터셉터가 토큰을 주입하므로 별도 헤더 불필요
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });
    final res = await _dio.patch(
      '/users/$userId/profile-image',
      data: formData,
    );
    return res.data['data'];
  }

  Future<void> deleteUser(int userId, String reason) async {
    await _dio.delete('/users/$userId', data: {'reason': reason});
  }
}
