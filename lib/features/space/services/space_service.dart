import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpaceService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8080',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 스페이스 목록 조회
  Future<List<Map<String, dynamic>>> getSpaces() async {
    final token = await _getToken();
    final response = await _dio.get(
      '/spaces',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.data['isSuccess'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    }
    return [];
  }

  // 스페이스 단건 조회
  Future<Map<String, dynamic>?> getSpace(int spaceId) async {
    final token = await _getToken();
    final response = await _dio.get(
      '/spaces/$spaceId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.data['isSuccess'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  // 스페이스 수정
  Future<void> updateSpace(int spaceId, String name, String description) async {
    final token = await _getToken();
    await _dio.put(
      '/spaces/$spaceId',
      data: {'name': name, 'description': description},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 스페이스 삭제
  Future<void> deleteSpace(int spaceId) async {
    final token = await _getToken();
    await _dio.delete(
      '/spaces/$spaceId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 스페이스 탈퇴
  Future<void> leaveSpace(int spaceId) async {
    final token = await _getToken();
    await _dio.delete(
      '/spaces/$spaceId/leave',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 멤버 초대
  Future<void> inviteMember(int spaceId, String email, {String? role}) async {
    final token = await _getToken();
    await _dio.post(
      '/spaces/$spaceId/members',
      data: {'email': email, if (role != null) 'role': role},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 멤버 권한 수정
  Future<void> updateMemberRole(
    int spaceId,
    int targetUserId,
    String role,
  ) async {
    final token = await _getToken();
    await _dio.patch(
      '/spaces/$spaceId/members/$targetUserId',
      data: {'role': role},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 멤버 추방 (관리자)
  Future<void> expelMember(int spaceId, int targetUserId) async {
    final token = await _getToken();
    await _dio.delete(
      '/spaces/$spaceId/members/$targetUserId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
