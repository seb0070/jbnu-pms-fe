import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  final Dio _dio = Dio();
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // 프로젝트 전체 파일 조회 (프로젝트 파일 + 태스크 파일)
  Future<List<Map<String, dynamic>>> getAllProjectFiles(int projectId) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '$baseUrl/projects/$projectId/files/all',
      options: options,
    );
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // 프로젝트 파일만 조회
  Future<List<Map<String, dynamic>>> getProjectFiles(int projectId) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '$baseUrl/projects/$projectId/files',
      options: options,
    );
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // 프로젝트 파일 업로드
  Future<void> uploadProjectFile(int projectId, File file) async {
    final token = await _getToken();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    await _dio.post(
      '$baseUrl/projects/$projectId/files',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 프로젝트 파일 삭제
  Future<void> deleteProjectFile(int projectId, int fileId) async {
    final options = await _authOptions();
    await _dio.delete(
      '$baseUrl/projects/$projectId/files/$fileId',
      options: options,
    );
  }

  // 태스크 파일 조회
  Future<List<Map<String, dynamic>>> getTaskFiles(int taskId) async {
    final options = await _authOptions();
    final res = await _dio.get(
      '$baseUrl/tasks/$taskId/files',
      options: options,
    );
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // 태스크 파일 업로드
  Future<void> uploadTaskFile(int taskId, File file) async {
    final token = await _getToken();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    await _dio.post(
      '$baseUrl/tasks/$taskId/files',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // 태스크 파일 삭제
  Future<void> deleteTaskFile(int taskId, int fileId) async {
    final options = await _authOptions();
    await _dio.delete('$baseUrl/tasks/$taskId/files/$fileId', options: options);
  }
}
