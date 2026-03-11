import 'package:flutter/material.dart';
import '../../project/services/project_service.dart';

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic> task;
  const TaskEditScreen({super.key, required this.taskId, required this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final ProjectService _projectService = ProjectService();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _dueDate;
  String _status = 'NOT_STARTED';
  String _priority = 'MEDIUM';

  late List<Map<String, dynamic>> _assignees;
  Map<String, dynamic>? _manager;
  List<Map<String, dynamic>> _projectMembers = [];
  bool _isMembersLoading = false;
  bool _isSaving = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _inputBg = Color(0xFFF7F5FF);

  final _statusOptions = [
    {'value': 'NOT_STARTED', 'label': '시작 전', 'color': Color(0xFF9E9E9E)},
    {'value': 'IN_PROGRESS', 'label': '진행 중', 'color': Color(0xFF6C5CE7)},
    {'value': 'DONE', 'label': '완료', 'color': Color(0xFF00B894)},
  ];

  final _priorityOptions = [
    {'value': 'LOW', 'label': 'LOW', 'color': Color(0xFF00B894)},
    {'value': 'MEDIUM', 'label': 'MEDIUM', 'color': Color(0xFFF39C12)},
    {'value': 'HIGH', 'label': 'HIGH', 'color': Color(0xFFE74C3C)},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task['title'] ?? '');
    _descController = TextEditingController(
      text: widget.task['description'] ?? '',
    );
    _status = widget.task['status'] as String? ?? 'NOT_STARTED';
    _priority = widget.task['priority'] as String? ?? 'MEDIUM';
    final dueDateStr = widget.task['dueDate'] as String?;
    if (dueDateStr != null) _dueDate = DateTime.tryParse(dueDateStr);

    _assignees = List<Map<String, dynamic>>.from(
      (widget.task['assignees'] as List? ?? []).map(
        (a) => Map<String, dynamic>.from(a as Map),
      ),
    );
    final managers = widget.task['managers'] as List?;
    if (managers != null && managers.isNotEmpty) {
      _manager = Map<String, dynamic>.from(managers[0] as Map);
    }
    _loadProjectMembers();
  }

  Future<void> _loadProjectMembers() async {
    setState(() => _isMembersLoading = true);
    try {
      final projectId = widget.task['projectId'] as int;
      final members = await _projectService.getProjectMembers(projectId);
      if (mounted) setState(() => _projectMembers = members);
    } catch (e) {
      // 멤버 로드 실패 시 빈 목록 유지
    } finally {
      if (mounted) setState(() => _isMembersLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int _memberId(Map<String, dynamic> m) =>
      (m['id'] as num?)?.toInt() ?? (m['userId'] as num?)?.toInt() ?? 0;

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _purple)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _showAddAssigneeSheet() {
    final assigneeIds = _assignees.map(_memberId).toSet();
    final managerId = _manager != null ? _memberId(_manager!) : null;
    final available = _projectMembers.where((m) {
      final uid = (m['userId'] as num?)?.toInt() ?? 0;
      return !assigneeIds.contains(uid) && uid != managerId;
    }).toList();

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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '담당자 추가',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isMembersLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: _purple)),
              )
            else if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '추가할 수 있는 멤버가 없어요',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...available.map((m) {
                final uid = (m['userId'] as num?)?.toInt() ?? 0;
                final name = m['userName'] as String? ?? '?';
                final profileImage = m['profileImage'] as String?;
                return ListTile(
                  leading: _buildAvatar(name, profileImage),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _assignees.add({
                        'userId': uid,
                        'name': name,
                        'profileImage': profileImage,
                      }),
                    );
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSetManagerSheet() {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '관리자 지정',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isMembersLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: _purple)),
              )
            else if (_projectMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '프로젝트 멤버가 없어요',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._projectMembers.map((m) {
                final uid = (m['userId'] as num?)?.toInt() ?? 0;
                final name = m['userName'] as String? ?? '?';
                final profileImage = m['profileImage'] as String?;
                final isCurrent =
                    _manager != null && _memberId(_manager!) == uid;
                return ListTile(
                  leading: _buildAvatar(name, profileImage),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: _purple, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(
                      () => _manager = {
                        'userId': uid,
                        'name': name,
                        'profileImage': profileImage,
                      },
                    );
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAssigneeOptions(Map<String, dynamic> assignee) {
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
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text('담당자 제거', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                final uid = _memberId(assignee);
                setState(
                  () => _assignees.removeWhere((a) => _memberId(a) == uid),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showManagerOptions() {
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
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: _purple),
              title: const Text('다른 멤버로 변경'),
              onTap: () {
                Navigator.pop(context);
                _showSetManagerSheet();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text('관리자 해제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _manager = null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _snack('제목을 입력해주세요');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'title': title,
        'status': _status,
        'priority': _priority,
      };
      final desc = _descController.text.trim();
      if (desc.isNotEmpty) data['description'] = desc;
      if (_dueDate != null) data['dueDate'] = _dueDate!.toIso8601String();
      await _projectService.updateTask(widget.taskId, data);

      // 담당자 동기화
      final originalAssigneeIds = ((widget.task['assignees'] as List?) ?? [])
          .map(
            (a) =>
                (a['id'] as num?)?.toInt() ??
                (a['userId'] as num?)?.toInt() ??
                0,
          )
          .toSet();
      final newAssigneeIds = _assignees.map(_memberId).toSet();
      for (final id in newAssigneeIds.difference(originalAssigneeIds)) {
        await _projectService.addAssignee(widget.taskId, id, role: 'ASSIGNEE');
      }
      for (final id in originalAssigneeIds.difference(newAssigneeIds)) {
        await _projectService.removeAssignee(widget.taskId, id);
      }

      // 관리자 동기화
      final originalManagerIds = ((widget.task['managers'] as List?) ?? [])
          .map(
            (a) =>
                (a['id'] as num?)?.toInt() ??
                (a['userId'] as num?)?.toInt() ??
                0,
          )
          .toSet();
      final newManagerId = _manager != null ? _memberId(_manager!) : null;
      final newManagerIds = newManagerId != null ? {newManagerId} : <int>{};
      for (final id in newManagerIds.difference(originalManagerIds)) {
        await _projectService.addAssignee(widget.taskId, id, role: 'MANAGER');
      }
      for (final id in originalManagerIds.difference(newManagerIds)) {
        await _projectService.removeAssignee(widget.taskId, id);
      }

      if (mounted) {
        _snack('저장했어요 ✓');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('저장에 실패했어요');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 20,
                          color: Color(0xFF1A1A2E),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '태스크 수정',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기본 정보
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('제목'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _titleController,
                                '태스크 제목을 입력하세요',
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('설명'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _descController,
                                '태스크 설명을 입력하세요',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 마감일
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('마감일'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDueDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: _purple,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _dueDate != null
                                              ? '${_dueDate!.year}. ${_dueDate!.month}. ${_dueDate!.day}.'
                                              : '마감일을 선택하세요',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _dueDate != null
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                      if (_dueDate != null)
                                        GestureDetector(
                                          onTap: () =>
                                              setState(() => _dueDate = null),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.grey[400],
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
                        // 상태 + 우선순위
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('상태'),
                              const SizedBox(height: 8),
                              Row(
                                children: _statusOptions.map((opt) {
                                  final isSelected = _status == opt['value'];
                                  final color = opt['color'] as Color;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _status = opt['value'] as String,
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withOpacity(0.12)
                                              : _inputBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? color
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? color
                                                    : Colors.grey[300],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              opt['label'] as String,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? color
                                                    : Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('우선순위'),
                              const SizedBox(height: 8),
                              Row(
                                children: _priorityOptions.map((opt) {
                                  final isSelected = _priority == opt['value'];
                                  final color = opt['color'] as Color;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _priority = opt['value'] as String,
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? color.withOpacity(0.12)
                                              : _inputBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? color
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            opt['label'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey[500],
                                            ),
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
                        const SizedBox(height: 12),
                        // 관리자
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('관리자'),
                                  if (_manager == null)
                                    GestureDetector(
                                      onTap: _showSetManagerSheet,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _inputBg,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: _purple,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (_manager == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    '관리자가 없어요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              else
                                _buildMemberTile(
                                  _manager!['name'] as String? ?? '?',
                                  _manager!['profileImage'] as String?,
                                  onOptions: _showManagerOptions,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 담당자
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('담당자'),
                                  GestureDetector(
                                    onTap: _showAddAssigneeSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _inputBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: _purple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_assignees.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    '담당자가 없어요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              else
                                ..._assignees.map(
                                  (a) => _buildMemberTile(
                                    a['name'] as String? ?? '?',
                                    a['profileImage'] as String?,
                                    onOptions: () => _showAssigneeOptions(a),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isSaving ? Colors.grey[300] : _purple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    String name,
    String? profileImage, {
    required VoidCallback onOptions,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        _buildAvatar(name, profileImage),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        GestureDetector(
          onTap: onOptions,
          child: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
        ),
      ],
    ),
  );

  Widget _buildAvatar(String name, String? profileImage, {double radius = 18}) {
    if (profileImage != null && profileImage.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(profileImage),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _purple.withOpacity(0.15),
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: _purple,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A2E),
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: _inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
