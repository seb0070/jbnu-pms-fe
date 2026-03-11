import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ProjectService {
  // ✅ DioClient - baseUrl + 토큰 자동 주입. _authOptions() 제거
  final Dio _dio = DioClient.create();

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
    );
    return res.data['data'];
  }

  Future<List<Map<String, dynamic>>> getProjects(int spaceId) async {
    final res = await _dio.get(
      '/projects',
      queryParameters: {'spaceId': spaceId},
    );
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, dynamic>> getProject(int projectId) async {
    final res = await _dio.get('/projects/$projectId');
    return res.data['data'];
  }

  Future<void> updateProject(int projectId, Map<String, dynamic> data) async {
    await _dio.patch('/projects/$projectId', data: data);
  }

  Future<void> deleteProject(int projectId) async {
    await _dio.delete('/projects/$projectId');
  }

  Future<List<Map<String, dynamic>>> getTasks(int projectId) async {
    final res = await _dio.get(
      '/tasks',
      queryParameters: {'projectId': projectId},
    );
    return List<Map<String, dynamic>>.from(res.data['data']);
  }

  Future<Map<String, dynamic>> getTask(int taskId) async {
    final res = await _dio.get('/tasks/$taskId');
    return res.data['data'];
  }

  Future<void> createTask({
    required int projectId,
    required String title,
    String description = '',
    String priority = 'MEDIUM',
    DateTime? dueDate,
    int? parentTaskId,
  }) async {
    await _dio.post(
      '/tasks',
      data: {
        'projectId': projectId,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        'priority': priority,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (parentTaskId != null) 'parentId': parentTaskId,
      },
    );
  }

  Future<void> updateTask(int taskId, Map<String, dynamic> data) async {
    await _dio.put('/tasks/$taskId', data: data);
  }

  Future<void> deleteTask(int taskId) async {
    await _dio.delete('/tasks/$taskId');
  }

  Future<void> addAssignee(int taskId, int assigneeId) async {
    await _dio.post(
      '/tasks/$taskId/assignees',
      queryParameters: {'assigneeId': assigneeId},
    );
  }

  Future<void> removeAssignee(int taskId, int assigneeId) async {
    await _dio.delete('/tasks/$taskId/assignees/$assigneeId');
  }

  Future<void> inviteMember(int projectId, String email, String role) async {
    await _dio.post(
      '/projects/$projectId/members',
      data: {'email': email, 'role': role},
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
    );
  }

  Future<void> expelMember(int projectId, int targetUserId) async {
    await _dio.delete('/projects/$projectId/members/$targetUserId');
  }

  Future<void> leaveProject(int projectId) async {
    await _dio.delete('/projects/$projectId/leave');
  }

  Future<List<Map<String, dynamic>>> getProjectMembers(int projectId) async {
    final res = await _dio.get('/projects/$projectId/members');
    return List<Map<String, dynamic>>.from(res.data['data']);
  }
}
