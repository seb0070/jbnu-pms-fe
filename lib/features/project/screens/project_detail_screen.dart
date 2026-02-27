import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../file/services/file_service.dart';
import '../services/project_service.dart';
import '../../task/screens/task_create_screen.dart';
import '../../task/screens/task_list_screen.dart';
import '../../task/screens/task_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  int? _currentUserId;
  bool _isViewer = false;
  List<Map<String, dynamic>> _files = [];
  bool _isFilesLoading = true;
  bool _isUploading = false;
  final FileService _fileService = FileService();

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final project = await _projectService.getProject(widget.projectId);
      final tasks = await _projectService.getTasks(widget.projectId);
      setState(() {
        _project = project;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await _fileService.getProjectFiles(widget.projectId);
      setState(() {
        _files = files;
        _isFilesLoading = false;
      });
    } catch (e) {
      setState(() => _isFilesLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    setState(() => _isUploading = true);
    try {
      await _fileService.uploadProjectFile(
        widget.projectId,
        File(result.files.single.path!),
      );
      await _loadFiles();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('업로드에 실패했어요')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '파일을 삭제할까요?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          file['fileName'] ?? '',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _fileService.deleteProjectFile(widget.projectId, file['id'] as int);
      await _loadFiles();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Color(0xFF1A1A2E),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF1A1A2E),
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : _project == null
                      ? const Center(child: Text('프로젝트를 불러올 수 없어요'))
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final progress = (_project?['progress'] as num?)?.toDouble() ?? 0.0;
    final previewTasks = _tasks.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project?['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if ((_project?['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _project?['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // 진행률
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '진행률',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '${progress.toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: const Color(0xFFEEEEEE),
                          color: _purple,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 관리자 & 마감일
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _lightPurple,
                              child: const Text(
                                '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '관리자',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '-', // TODO: 백엔드 관리자 이름으로 교체
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EEFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: _purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '마감일',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '-', // TODO: 백엔드 dueDate 추가되면 교체
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 멤버 섹션 (TODO: 백엔드 멤버 정보 추가되면 활성화)

                // 작업 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '작업 (${_tasks.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (_tasks.length > 5)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskListScreen(
                                projectId: widget.projectId,
                                projectName: _project?['name'] ?? '',
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                '더보기',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TaskCreateScreen(projectId: widget.projectId),
                        ),
                      );
                      if (result == true) _loadData();
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/assets/images/AddButton.png',
                          width: 40,
                          height: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          '작업 추가',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '작업이 없어요',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ...previewTasks.map((task) => _buildTaskItem(task)),
                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),
                _buildFileSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '첨부 파일 (\${_files.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (!_isViewer)
                GestureDetector(
                  onTap: _isUploading ? null : _uploadFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7),
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            children: [
                              Icon(
                                Icons.upload_rounded,
                                size: 14,
                                color: Color(0xFF6C5CE7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '업로드',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isFilesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          )
        else if (_files.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '첨부된 파일이 없어요',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ..._files.map((file) => _buildFileCard(file)),
      ],
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    final fileName = file['fileName'] as String? ?? '';
    final fileId = file['id'] as int;
    try {
      await _fileService.downloadProjectFile(
        widget.projectId,
        fileId,
        fileName,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('다운로드에 실패했어요')));
    }
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileName = file['fileName'] as String? ?? '';
    final fileSize = file['fileSize'] as int? ?? 0;
    final uploaderName = file['uploaderName'] as String? ?? '';
    final uploaderId = file['uploaderId'];
    final createdAt = file['createdAt'] as String?;
    final isMyFile = uploaderId != null && uploaderId == _currentUserId;

    return GestureDetector(
      onTap: () => _downloadFile(file),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fileIconColor(fileName).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _fileIcon(fileName),
                color: _fileIconColor(fileName),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$uploaderName · \${_formatDate(createdAt)} · \${_formatFileSize(fileSize)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            if (isMyFile && !_isViewer)
              GestureDetector(
                onTap: () => _deleteFile(file),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileIconColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const Color(0xFF43A047);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFFF9800);
      case 'doc':
      case 'docx':
        return const Color(0xFF1565C0);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF2E7D32);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFD84315);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '\${bytes}B';
    if (bytes < 1024 * 1024) return '\${(bytes / 1024).toStringAsFixed(1)}KB';
    return '\${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '\${date.month}/\${date.day}';
    if (diff.inDays >= 1) return '\${diff.inDays}일 전';
    if (diff.inHours >= 1) return '\${diff.inHours}시간 전';
    return '방금 전';
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? '';
    final assignees = (task['assignees'] as List?) ?? [];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task['id'])),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (assignees.isEmpty)
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFEEEEEE),
                child: Icon(Icons.person, size: 16, color: Colors.grey),
              )
            else
              SizedBox(
                width: assignees.take(3).length * 22.0,
                height: 28,
                child: Stack(
                  children: assignees.take(3).toList().asMap().entries.map((e) {
                    final assignee = e.value as Map<String, dynamic>;
                    final name = assignee['name'] as String? ?? '?';
                    final profileImage = assignee['profileImage'] as String?;
                    return Positioned(
                      left: e.key * 16.0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: _lightPurple,
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage == null
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
