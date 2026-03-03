import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectService {
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

  Future<int> createProject(
    int spaceId,
    String name,
    String description, {
    bool isPublic = true,
    DateTime? dueDate,
  }) async {
    final res = await _dio.post(
      '/projects',
      data: {
        'spaceId': spaceId,
        'name': name,
        'description': description,
        'isPublic': isPublic,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
      options: await _authOptions(),
    );
    return res.data['data'];
  }

  Future<List<Map<String, dynamic>>> getProjects(int spaceId) async {
    final res = await _dio.get(
      '/projects',
      queryParameters: {'spaceId': spaceId},
      options: await _authOptions(),
    );
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, dynamic>> getProject(int projectId) async {
    final res = await _dio.get(
      '/projects/$projectId',
      options: await _authOptions(),
    );
    return res.data['data'];
  }

  Future<List<Map<String, dynamic>>> getTasks(int projectId) async {
    final res = await _dio.get(
      '/tasks',
      queryParameters: {'projectId': projectId},
      options: await _authOptions(),
    );
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, dynamic>> getTask(int taskId) async {
    final res = await _dio.get('/tasks/$taskId', options: await _authOptions());
    return res.data['data'];
  }

  Future<void> updateProject(int projectId, Map<String, dynamic> data) async {
    await _dio.patch(
      '/projects/$projectId',
      data: data,
      options: await _authOptions(),
    );
  }

  Future<void> deleteProject(int projectId) async {
    await _dio.delete('/projects/$projectId', options: await _authOptions());
  }

  Future<void> updateTask(int taskId, Map<String, dynamic> data) async {
    await _dio.put('/tasks/$taskId', data: data, options: await _authOptions());
  }

  Future<void> deleteTask(int taskId) async {
    await _dio.delete('/tasks/$taskId', options: await _authOptions());
  }

  Future<void> addAssignee(int taskId, int assigneeId) async {
    await _dio.post(
      '/tasks/$taskId/assignees',
      queryParameters: {'assigneeId': assigneeId},
      options: await _authOptions(),
    );
  }

  Future<void> removeAssignee(int taskId, int assigneeId) async {
    await _dio.delete(
      '/tasks/$taskId/assignees/$assigneeId',
      options: await _authOptions(),
    );
  }

  Future<void> inviteMember(int projectId, String email, String role) async {
    await _dio.post(
      '/projects/$projectId/members',
      data: {'email': email, 'role': role},
      options: await _authOptions(),
    );
  }

  Future<void> updateMemberRole(
    int projectId,
    int targetUserId,
    String role,
  ) async {
    await _dio.patch(
      '/projects/$projectId/members/$targetUserId',
      data: {'role': role},
      options: await _authOptions(),
    );
  }

  Future<void> expelMember(int projectId, int targetUserId) async {
    await _dio.delete(
      '/projects/$projectId/members/$targetUserId',
      options: await _authOptions(),
    );
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(int projectId) async {
    final res = await _dio.get(
      '/projects/$projectId/members',
      options: await _authOptions(),
    );
    return List<Map<String, dynamic>>.from(res.data['data']);
  }
}
