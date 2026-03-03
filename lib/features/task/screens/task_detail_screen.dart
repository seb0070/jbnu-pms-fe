import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../file/services/file_service.dart';
import '../../../shared/widgets/download_manager.dart';
import 'task_edit_screen.dart';
import '../../../features/project/services/project_service.dart';
import 'task_create_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  Map<String, dynamic>? _task;
  bool _isLoading = true;
  int? _currentUserId;
  bool _isViewer = false;
  List<Map<String, dynamic>> _files = [];
  bool _isFilesLoading = true;
  bool _isUploading = false;
  final FileService _fileService = FileService();

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);

  @override
  void initState() {
    super.initState();
    _loadTask();
    _commentFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final task = await _projectService.getTask(widget.taskId);
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await _fileService.getTaskFiles(widget.taskId);
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
      await _fileService.uploadTaskFile(
        widget.taskId,
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
      await _fileService.deleteTaskFile(widget.taskId, file['id'] as int);
      await _loadFiles();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요')));
    }
  }

  void _showMoreMenu() {
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
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1A1A2E),
              ),
              title: const Text('태스크 수정'),
              onTap: () async {
                Navigator.pop(context);
                final members = await _projectService.getProjectMembers(
                  _task!['projectId'] as int,
                );
                if (!mounted) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskEditScreen(
                      taskId: widget.taskId,
                      task: _task!,
                      projectMembers: members,
                    ),
                  ),
                );
                if (result == true) _loadTask();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('태스크 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: _task?['title']);
    final descController = TextEditingController(
      text: _task?['description'] ?? '',
    );
    String status = _task?['status'] as String? ?? 'NOT_STARTED';
    String priority = _task?['priority'] as String? ?? 'MEDIUM';

    final statuses = [
      {'value': 'NOT_STARTED', 'label': '시작전'},
      {'value': 'IN_PROGRESS', 'label': '진행중'},
      {'value': 'DONE', 'label': '완료'},
    ];

    final priorities = [
      {'value': 'LOW', 'label': '낮음', 'color': const Color(0xFF19B36E)},
      {'value': 'MEDIUM', 'label': '중간', 'color': const Color(0xFFF79009)},
      {'value': 'HIGH', 'label': '높음', 'color': const Color(0xFFF95555)},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '태스크 수정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '제목',
                    filled: true,
                    fillColor: _inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '설명',
                    filled: true,
                    fillColor: _inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '상태',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: statuses.map((s) {
                    final isSelected = status == s['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => status = s['value'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? _purple : _inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  '우선순위',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: priorities.map((p) {
                    final isSelected = priority == p['value'];
                    final color = p['color'] as Color;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(
                          () => priority = p['value'] as String,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color : _inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _projectService.updateTask(widget.taskId, {
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'status': status,
                    'priority': priority,
                  });
                  _loadTask();
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('태스크를 수정했어요')));
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('수정에 실패했어요')));
                }
              },
              child: const Text(
                '저장',
                style: TextStyle(color: _purple, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '태스크 삭제',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text('태스크를 삭제하면 복구할 수 없어요. 정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _projectService.deleteTask(widget.taskId);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요')));
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
                      const Expanded(
                        child: Text(
                          '작업 상세보기',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF1A1A2E),
                          size: 22,
                        ),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : _task == null
                      ? const Center(child: Text('작업을 불러올 수 없어요'))
                      : Column(
                          children: [
                            Expanded(child: _buildContent()),
                            _buildCommentInput(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _commentFocusNode.hasFocus
                      ? _purple
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            opacity: _commentController.text.isNotEmpty ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _commentController.text.isNotEmpty
                  ? () {
                      // TODO: 댓글 전송 API 연동
                      _commentController.clear();
                      setState(() {});
                    }
                  : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final title = _task?['title'] as String? ?? '';
    final description = _task?['description'] as String? ?? '';
    final status = _task?['status'] as String? ?? 'NOT_STARTED';
    final priority = _task?['priority'] as String? ?? 'MEDIUM';
    final progress = (_task?['progress'] as num?)?.toDouble() ?? 0.0;
    final dueDate = _task?['dueDate'] as String?;
    final creator = _task?['creator'] as Map<String, dynamic>?;
    final assignees = (_task?['assignees'] as List?) ?? [];
    final children = (_task?['children'] as List?) ?? [];

    // 우선순위
    Color priorityColor;
    String priorityLabel;
    switch (priority) {
      case 'HIGH':
        priorityColor = const Color(0xFFF95555);
        priorityLabel = 'High';
        break;
      case 'LOW':
        priorityColor = const Color(0xFF19B36E);
        priorityLabel = 'Low';
        break;
      default:
        priorityColor = const Color(0xFFF79009);
        priorityLabel = 'Medium';
    }

    // 상태
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

    // 마감일
    String dueDateLabel = '-';
    Color dueDateColor = Colors.grey;
    if (dueDate != null) {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final diff = due
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (diff < 0) {
        dueDateLabel = 'D+${diff.abs()}';
        dueDateColor = Colors.red;
      } else if (diff == 0) {
        dueDateLabel = 'D-day';
        dueDateColor = Colors.red;
      } else if (diff <= 30) {
        dueDateLabel = 'D-$diff';
        dueDateColor = diff <= 7 ? Colors.orange : Colors.grey;
      } else {
        dueDateLabel = '${due.month}/${due.day}';
        dueDateColor = Colors.grey;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더: 제목 + 설명 + 상태/우선순위 배지
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        priorityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // 흰색 카드
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
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),

                // 담당자 & 마감일
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildAvatar(
                              assignees.isEmpty
                                  ? null
                                  : assignees[0] as Map<String, dynamic>,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '담당자',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  assignees.isEmpty
                                      ? '-'
                                      : (assignees[0]
                                                as Map<
                                                  String,
                                                  dynamic
                                                >)['name'] ??
                                            '-',
                                  style: const TextStyle(
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
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: dueDateColor,
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
                                  dueDateLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: dueDateColor,
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
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),

                // 하위 작업
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '하위 작업 (${children.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskCreateScreen(
                                projectId: _task?['projectId'],
                                parentTaskId: widget.taskId,
                                parentTaskTitle: _task?['title'],
                              ),
                            ),
                          );
                          if (result == true) _loadTask();
                        },
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF1A1A2E),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (children.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '하위 작업이 없어요',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                else
                  ...children.map((child) {
                    final c = child as Map<String, dynamic>;
                    final childStatus = c['status'] as String? ?? 'NOT_STARTED';
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(
                        children: [
                          Icon(
                            childStatus == 'DONE'
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: childStatus == 'DONE'
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c['title'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: childStatus == 'DONE'
                                    ? Colors.grey
                                    : const Color(0xFF1A1A2E),
                                decoration: childStatus == 'DONE'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),

                // 첨부 파일
                _buildFileSection(),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 24),

                // 댓글
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '댓글',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '댓글이 없어요',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                // TODO: 댓글 목록 (API 연동 후 활성화)
                const SizedBox(height: 80),
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
        'http://10.0.2.2:8080/tasks/${widget.taskId}/files/$fileId/download';
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
                    '$uploaderName · ${_formatDate(createdAt)} · ${_formatFileSize(fileSize)}',
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
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '${date.month}/${date.day}';
    if (diff.inDays >= 1) return '${diff.inDays}일 전';
    if (diff.inHours >= 1) return '${diff.inHours}시간 전';
    return '방금 전';
  }

  Widget _buildAvatar(Map<String, dynamic>? user, {double radius = 18}) {
    final name = user?['name'] as String? ?? '?';
    final profileImage = user?['profileImage'] as String?;

    if (profileImage != null && profileImage.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profileImage),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _lightPurple,
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
