import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/app_config.dart';

class FileService {
  // ✅ DioClient - baseUrl + 토큰 자동 주입
  final Dio _dio = DioClient.create();

  // ── 다운로드 URL 헬퍼 (DownloadManager 등 외부에서 URL이 필요할 때 사용) ──
  static String projectFileDownloadUrl(int projectId, int fileId) =>
      '${AppConfig.baseUrl}/projects/$projectId/files/$fileId/download';

  static String taskFileDownloadUrl(int taskId, int fileId) =>
      '${AppConfig.baseUrl}/tasks/$taskId/files/$fileId/download';

  // ── 프로젝트 파일 ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProjectFiles(int projectId) async {
    final res = await _dio.get('/projects/$projectId/files');
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAllProjectFiles(int projectId) async {
    final res = await _dio.get('/projects/$projectId/files/all');
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> uploadProjectFile(int projectId, File file) async {
    // multipart: Content-Type을 직접 지정해야 하므로 Options 추가
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    await _dio.post(
      '/projects/$projectId/files',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteProjectFile(int projectId, int fileId) async {
    await _dio.delete('/projects/$projectId/files/$fileId');
  }

  Future<void> downloadProjectFile(
    int projectId,
    int fileId,
    String fileName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$fileName';
    await _dio.download(
      '/projects/$projectId/files/$fileId/download',
      savePath,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    await OpenFilex.open(savePath);
  }

  // ── 태스크 파일 ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTaskFiles(int taskId) async {
    final res = await _dio.get('/tasks/$taskId/files');
    final List data = res.data['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> uploadTaskFile(int taskId, File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    await _dio.post(
      '/tasks/$taskId/files',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteTaskFile(int taskId, int fileId) async {
    await _dio.delete('/tasks/$taskId/files/$fileId');
  }

  Future<void> downloadTaskFile(int taskId, int fileId, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$fileName';
    await _dio.download(
      '/tasks/$taskId/files/$fileId/download',
      savePath,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    await OpenFilex.open(savePath);
  }
}
