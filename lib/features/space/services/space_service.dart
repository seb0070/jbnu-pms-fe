import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class SpaceService {
  // ✅ DioClient - baseUrl + 토큰 자동 주입. _getToken() 제거
  final Dio _dio = DioClient.create();

  Future<List<Map<String, dynamic>>> getSpaces() async {
    final response = await _dio.get('/spaces');
    if (response.data['isSuccess'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getSpace(int spaceId) async {
    final response = await _dio.get('/spaces/$spaceId');
    if (response.data['isSuccess'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  Future<void> createSpace(String name, String description) async {
    await _dio.post(
      '/spaces',
      data: {'name': name, 'description': description},
    );
  }

  Future<void> updateSpace(int spaceId, String name, String description) async {
    await _dio.put(
      '/spaces/$spaceId',
      data: {'name': name, 'description': description},
    );
  }

  Future<void> deleteSpace(int spaceId) async {
    await _dio.delete('/spaces/$spaceId');
  }

  Future<void> leaveSpace(int spaceId) async {
    await _dio.delete('/spaces/$spaceId/leave');
  }

  Future<void> inviteMember(int spaceId, String email, {String? role}) async {
    await _dio.post(
      '/spaces/$spaceId/members',
      data: {'email': email, if (role != null) 'role': role},
    );
  }

  Future<void> updateMemberRole(
    int spaceId,
    int targetUserId,
    String role,
  ) async {
    await _dio.patch(
      '/spaces/$spaceId/members/$targetUserId',
      data: {'role': role},
    );
  }

  Future<void> expelMember(int spaceId, int targetUserId) async {
    await _dio.delete('/spaces/$spaceId/members/$targetUserId');
  }
}
