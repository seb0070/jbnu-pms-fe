import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/app_config.dart';
import '../../file/services/file_service.dart';
import '../../../shared/widgets/download_manager.dart';
import '../services/project_service.dart';
import '../../space/services/space_service.dart';
import '../../task/screens/task_create_screen.dart';
import '../../task/screens/task_list_screen.dart';
import '../../task/screens/task_detail_screen.dart';
import 'project_edit_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final SpaceService _spaceService = SpaceService();
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  int? _currentUserId;
  bool _isViewer = false;
  bool _isAdmin = false;
  String _myRole = 'MEMBER';
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
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final project = await _projectService.getProject(widget.projectId);
      final tasks = await _projectService.getTasks(widget.projectId);
      // 현재 유저 역할 파악
      final members = (project['members'] as List?) ?? [];
      final myMember = members.firstWhere(
        (m) => (m['userId'] as num?)?.toInt() == _currentUserId,
        orElse: () => <String, dynamic>{},
      );
      final myRole = myMember['role'] as String? ?? 'MEMBER';

      setState(() {
        _project = project;
        _tasks = tasks;
        _myRole = myRole;
        _isViewer = myRole == 'VIEWER';
        _isAdmin = myRole == 'ADMIN';
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

  void _showBottomSheet() {
    final members = ((_project?['members'] as List?) ?? []);
    final isAlone = members.length <= 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (_isAdmin)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: _purple),
                title: const Text(
                  '프로젝트 수정',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectEditScreen(
                        projectId: widget.projectId,
                        project: _project!,
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
            // 나가기 - 모든 경우에 표시
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                '프로젝트 나가기',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final adminCount = members
                    .where((m) => m['role'] == 'ADMIN')
                    .length;

                if (isAlone) {
                  // 나 혼자 → 이름 입력 후 삭제
                  final projectName = _project?['name'] as String? ?? '';
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return StatefulBuilder(
                        builder: (ctx, setState) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            '프로젝트 나가기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '마지막 멤버가 나가면 프로젝트가 완전히 삭제돼요.\n아래에 프로젝트 이름을 입력해주세요.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                projectName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '프로젝트 이름 입력',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F5FF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: controller.text == projectName
                                  ? () => Navigator.pop(ctx, true)
                                  : null,
                              child: Text(
                                '나가기',
                                style: TextStyle(
                                  color: controller.text == projectName
                                      ? Colors.red
                                      : Colors.grey[300],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (confirmed == true) {
                    try {
                      await _projectService.deleteProject(widget.projectId);
                      if (mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) _snack('나가기에 실패했어요');
                    }
                  }
                } else if (_isAdmin && adminCount <= 1) {
                  // 마지막 관리자 → 토스트
                  _snack('관리자 권한을 다른 멤버에게 부여한 후 나가세요');
                } else {
                  // 일반 나가기
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        '프로젝트 나가기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: const Text(
                        '프로젝트에서 나갈까요?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            '나가기',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      await _projectService.leaveProject(widget.projectId);
                      if (mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) _snack('나가기에 실패했어요');
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
                        icon: Icon(
                          Icons.more_vert,
                          color: _isAdmin
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey[300],
                          size: 22,
                        ),
                        onPressed: (_project == null || !_isAdmin)
                            ? null
                            : _showBottomSheet,
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
    final status = _project?['status'] as String? ?? 'NOT_STARTED';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'IN_PROGRESS':
        statusColor = _purple;
        statusLabel = '진행중';
        break;
      case 'DONE':
        statusColor = Colors.green;
        statusLabel = '완료';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '시작전';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                            () {
                              final members =
                                  (_project?['members'] as List?) ?? [];
                              final admins = members
                                  .where((m) => m['role'] == 'ADMIN')
                                  .toList();
                              if (admins.isEmpty) {
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: _lightPurple,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          '관리자',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  SizedBox(
                                    width: admins.take(3).length * 22.0 + 14,
                                    height: 36,
                                    child: Stack(
                                      children: admins
                                          .take(3)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((e) {
                                            final profileImage =
                                                e.value['profileImage']
                                                    as String?;
                                            final name =
                                                e.value['userName']
                                                    as String? ??
                                                '?';
                                            return Positioned(
                                              left: e.key * 16.0,
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor: _lightPurple,
                                                backgroundImage:
                                                    profileImage != null &&
                                                        profileImage.isNotEmpty
                                                    ? NetworkImage(profileImage)
                                                    : null,
                                                child:
                                                    profileImage == null ||
                                                        profileImage.isEmpty
                                                    ? Text(
                                                        name[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '관리자',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        admins.length == 1
                                            ? (admins[0]['userName']
                                                      as String? ??
                                                  '-')
                                            : '${admins[0]['userName']} 외 ${admins.length - 1}명',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }(),
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
                              children: [
                                const Text(
                                  '마감일',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _project?['dueDate'] != null
                                      ? () {
                                          final d = DateTime.tryParse(
                                            _project!['dueDate'] as String,
                                          );
                                          return d != null
                                              ? '${d.year}. ${d.month}. ${d.day}.'
                                              : '-';
                                        }()
                                      : '-',
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

                // 멤버 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "멤버 (${((_project?['members'] as List?) ?? []).length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAllMembersSheet,
                        child: const Row(
                          children: [
                            Text(
                              '모두보기',
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
                  child: _buildMemberGrid(),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 28),

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
                '첨부 파일 (${_files.length})',
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

  void _downloadFile(Map<String, dynamic> file) {
    final fileName = file['fileName'] as String? ?? '';
    final fileId = file['id'] as int;
    final downloadUrl =
        '${AppConfig.baseUrl}/projects/${widget.projectId}/files/$fileId/download';
    DownloadManager().download(
      context: context,
      fileName: fileName,
      downloadUrl: downloadUrl,
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final fileName = file['fileName'] as String? ?? '';
    final fileSize = file['fileSize'] as int? ?? 0;
    final uploaderName = file['uploaderName'] as String? ?? '';
    final uploaderId = file['uploaderId'];
    final createdAt = file['createdAt'] as String?;
    final isMyFile = uploaderId != null && uploaderId == _currentUserId;
    final isTaskFile = file['taskFileId'] != null;

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
              isTaskFile
                  ? Tooltip(
                      message: '태스크에서 삭제해주세요',
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.grey[200],
                        ),
                      ),
                    )
                  : GestureDetector(
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

  // ── 멤버 그리드 (4명까지 미리보기) ──────────────────────────────
  Widget _buildMemberGrid() {
    final members = ((_project?['members'] as List?) ?? [])
        .map((m) => m as Map<String, dynamic>)
        .toList();
    members.sort((a, b) {
      final ra = a['role'] as String? ?? 'MEMBER';
      final rb = b['role'] as String? ?? 'MEMBER';
      if (ra == rb) return 0;
      return ra == 'ADMIN' ? -1 : 1;
    });

    // 초대 버튼 포함해서 슬롯 구성
    // _isAdmin이면 첫 슬롯에 초대 버튼, 나머지 슬롯에 멤버 (최대 3명 미리보기)
    // 아니면 멤버 4명 미리보기
    final preview = _isAdmin
        ? members.take(3).toList()
        : members.take(4).toList();

    if (!_isAdmin && preview.isEmpty) {
      return Text(
        '멤버가 없어요',
        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
      );
    }

    // 슬롯 리스트 구성
    final List<Widget> slots = [];
    if (_isAdmin) {
      slots.add(_buildInviteButton());
    }
    slots.addAll(preview.map((m) => _buildMemberTile(m)));

    return Column(
      children: [
        for (int i = 0; i < slots.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: slots[i]),
              if (i + 1 < slots.length)
                Expanded(child: slots[i + 1])
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInviteButton() {
    return GestureDetector(
      onTap: _showInviteDialog,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'lib/assets/images/AddButton_circle.png',
            width: 40,
            height: 40,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          const Text(
            '멤버 초대',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final name = member['userName'] as String? ?? '?';
    final isMe = member['userId'] == _currentUserId;
    final role = member['role'] as String? ?? 'MEMBER';
    final isAdmin = role == 'ADMIN';
    final profileImage = member['profileImage'] as String?;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _lightPurple,
          backgroundImage: profileImage != null && profileImage.isNotEmpty
              ? NetworkImage(profileImage)
              : null,
          child: profileImage == null || profileImage.isEmpty
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMe)
                    const Text(
                      ' (나)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
              Text(
                role == 'ADMIN'
                    ? '관리자'
                    : role == 'VIEWER'
                    ? '뷰어'
                    : '멤버',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 모두보기 바텀시트 ──────────────────────────────────────────
  void _showAllMembersSheet() {
    final members = ((_project?['members'] as List?) ?? [])
        .map((m) => m as Map<String, dynamic>)
        .toList();
    members.sort((a, b) {
      final ra = a['role'] as String? ?? 'MEMBER';
      final rb = b['role'] as String? ?? 'MEMBER';
      if (ra == rb) return 0;
      return ra == 'ADMIN' ? -1 : 1;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '멤버 (${members.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (_isAdmin)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showInviteDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          size: 18,
                          color: _purple,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final name = m['userName'] as String? ?? '?';
                  final userId = (m['userId'] as num?)?.toInt() ?? 0;
                  final isMe = userId == _currentUserId;
                  final role = m['role'] as String? ?? 'MEMBER';
                  final isAdmin = role == 'ADMIN';
                  final profileImage = m['profileImage'] as String?;
                  final adminCount = members
                      .where((m) => m['role'] == 'ADMIN')
                      .length;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: _lightPurple,
                      backgroundImage:
                          profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null || profileImage.isEmpty
                          ? Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe)
                          const Text(
                            ' (나)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      role == 'ADMIN'
                          ? '관리자'
                          : role == 'VIEWER'
                          ? '뷰어'
                          : '멤버',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdmin ? _purple : Colors.grey,
                      ),
                    ),
                    trailing: (_isAdmin || isMe)
                        ? GestureDetector(
                            onTap: () =>
                                _showMemberOptionsFromSheet(ctx, m, adminCount),
                            child: Icon(
                              Icons.more_vert,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptionsFromSheet(
    BuildContext sheetCtx,
    Map<String, dynamic> member,
    int adminCount,
  ) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '';
    final role = member['role'] as String? ?? 'MEMBER';
    final isMe = userId == _currentUserId;
    final isLastAdmin = role == 'ADMIN' && adminCount <= 1;
    final allMembers = ((_project?['members'] as List?) ?? []);
    final isAlone = allMembers.length <= 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // 내 항목일 때
            if (isMe) ...[
              if (role == 'ADMIN') ...[
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.grey[300]),
                  title: Text(
                    '멤버로 변경',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  enabled: false,
                ),
                ListTile(
                  leading: Icon(
                    Icons.visibility_outlined,
                    color: Colors.grey[300],
                  ),
                  title: Text(
                    '뷰어로 변경',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  enabled: false,
                ),
                if (isLastAdmin && !isAlone)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '마지막 관리자는 권한을 변경할 수 없어요',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  '프로젝트 나가기',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(sheetCtx);
                  if (isAlone) {
                    final projectName = _project?['name'] as String? ?? '';
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final controller = TextEditingController();
                        return StatefulBuilder(
                          builder: (ctx, setState) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              '프로젝트 나가기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '마지막 멤버가 나가면 프로젝트가 완전히 삭제돼요.\n아래에 프로젝트 이름을 입력해주세요.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  projectName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: controller,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '프로젝트 이름 입력',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF7F5FF),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: controller.text == projectName
                                    ? () => Navigator.pop(ctx, true)
                                    : null,
                                child: Text(
                                  '나가기',
                                  style: TextStyle(
                                    color: controller.text == projectName
                                        ? Colors.red
                                        : Colors.grey[300],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (confirmed == true) {
                      try {
                        await _projectService.deleteProject(widget.projectId);
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) _snack('나가기에 실패했어요');
                      }
                    }
                  } else if (isLastAdmin) {
                    _snack('관리자 권한을 다른 멤버에게 부여한 후 나가세요');
                  } else {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          '프로젝트 나가기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: const Text(
                          '프로젝트에서 나갈까요?',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              '취소',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              '나가기',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await _projectService.leaveProject(widget.projectId);
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) _snack('나가기에 실패했어요');
                      }
                    }
                  }
                },
              ),
            ],

            // 다른 사람 항목일 때 (관리자만 볼 수 있음)
            if (!isMe) ...[
              if (role == 'MEMBER' || role == 'VIEWER')
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: _purple,
                  ),
                  title: const Text('관리자로 변경'),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(sheetCtx);
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'ADMIN',
                      );
                      _snack('권한을 변경했어요 ✓');
                      _loadData();
                    } catch (e) {
                      _snack('권한 변경에 실패했어요');
                    }
                  },
                ),
              if (role == 'ADMIN' && adminCount > 1)
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.grey),
                  title: const Text('멤버로 변경'),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(sheetCtx);
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'MEMBER',
                      );
                      _snack('권한을 변경했어요 ✓');
                      _loadData();
                    } catch (e) {
                      _snack('권한 변경에 실패했어요');
                    }
                  },
                ),
              if (role == 'VIEWER')
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.grey),
                  title: const Text('멤버로 변경'),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(sheetCtx);
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'MEMBER',
                      );
                      _snack('권한을 변경했어요 ✓');
                      _loadData();
                    } catch (e) {
                      _snack('권한 변경에 실패했어요');
                    }
                  },
                ),
              if (role == 'MEMBER')
                ListTile(
                  leading: const Icon(
                    Icons.visibility_outlined,
                    color: Colors.blueGrey,
                  ),
                  title: const Text('뷰어로 변경'),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(sheetCtx);
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'VIEWER',
                      );
                      _snack('권한을 변경했어요 ✓');
                      _loadData();
                    } catch (e) {
                      _snack('권한 변경에 실패했어요');
                    }
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: Colors.red,
                ),
                title: const Text('내보내기', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(sheetCtx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        '멤버 내보내기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: Text(
                        '$name 님을 프로젝트에서 내보낼까요?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            '내보내기',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    await _projectService.expelMember(widget.projectId, userId);
                    _snack('$name 님을 내보냈어요');
                    _loadData();
                  } catch (e) {
                    _snack('내보내기에 실패했어요');
                  }
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── 멤버 초대 다이얼로그 ────────────────────────────────────────
  void _showInviteDialog() async {
    final spaceId = _project?['spaceId'] as int?;
    if (spaceId == null) {
      _snack('스페이스 정보를 불러올 수 없어요');
      return;
    }

    // 이미 프로젝트에 있는 멤버 userId 목록
    final projectMemberIds = ((_project?['members'] as List?) ?? [])
        .map((m) => (m['userId'] as num?)?.toInt() ?? 0)
        .toSet();

    // 스페이스 멤버 로드
    List<Map<String, dynamic>> spaceMembers = [];
    try {
      final space = await _spaceService.getSpace(spaceId);
      spaceMembers = ((space?['members'] as List?) ?? [])
          .map((m) => m as Map<String, dynamic>)
          .where(
            (m) =>
                !projectMemberIds.contains((m['userId'] as num?)?.toInt() ?? 0),
          )
          .toList();
    } catch (e) {
      _snack('멤버 목록을 불러올 수 없어요');
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '멤버 추가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (spaceMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '추가할 수 있는 멤버가 없어요',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: spaceMembers.length,
                  itemBuilder: (_, i) {
                    final m = spaceMembers[i];
                    final name = m['userName'] as String? ?? '?';
                    final profileImage = m['profileImage'] as String?;
                    final email = m['email'] as String? ?? '';
                    return ListTile(
                      leading: profileImage != null && profileImage.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(profileImage),
                              radius: 20,
                            )
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor: _lightPurple,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showRolePickerAndInvite(name, email);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRolePickerAndInvite(String name, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name 님을 초대',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '권한을 선택해주세요',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: _purple,
              ),
              title: const Text(
                '관리자',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                '프로젝트 수정, 멤버 관리 가능',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _projectService.inviteMember(
                    widget.projectId,
                    email,
                    'ADMIN',
                  );
                  _snack('$name 님을 관리자로 초대했어요 ✓');
                  _loadData();
                } catch (e) {
                  _snack('초대에 실패했어요');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.grey),
              title: const Text(
                '멤버',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                '태스크 생성 및 수정 가능',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _projectService.inviteMember(
                    widget.projectId,
                    email,
                    'MEMBER',
                  );
                  _snack('$name 님을 멤버로 초대했어요 ✓');
                  _loadData();
                } catch (e) {
                  _snack('초대에 실패했어요');
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.visibility_outlined,
                color: Colors.blueGrey,
              ),
              title: const Text(
                '뷰어',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                '읽기 전용 (참관자)',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await _projectService.inviteMember(
                    widget.projectId,
                    email,
                    'VIEWER',
                  );
                  _snack('$name 님을 뷰어로 초대했어요 ✓');
                  _loadData();
                } catch (e) {
                  _snack('초대에 실패했어요');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
