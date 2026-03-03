import 'package:flutter/material.dart';
import '../../project/services/project_service.dart';

class TaskEditScreen extends StatefulWidget {
  final int taskId;
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> projectMembers;
  const TaskEditScreen({
    super.key,
    required this.taskId,
    required this.task,
    required this.projectMembers,
  });

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
  late List<int> _assigneeIds;
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
    _assigneeIds = ((widget.task['assignees'] as List?) ?? [])
        .map((a) => (a['userId'] as num?)?.toInt() ?? 0)
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
      final originalIds = ((widget.task['assignees'] as List?) ?? [])
          .map((a) => (a['userId'] as num?)?.toInt() ?? 0)
          .toSet();
      final newIds = _assigneeIds.toSet();
      for (final id in newIds.difference(originalIds)) {
        await _projectService.addAssignee(widget.taskId, id);
      }
      for (final id in originalIds.difference(newIds)) {
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
                        // 담당자
                        if (widget.projectMembers.isNotEmpty)
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('담당자'),
                                const SizedBox(height: 12),
                                ...widget.projectMembers.map((member) {
                                  final userId =
                                      (member['userId'] as num?)?.toInt() ?? 0;
                                  final name =
                                      member['userName'] as String? ?? '?';
                                  final profileImage =
                                      member['profileImage'] as String?;
                                  final isAssigned = _assigneeIds.contains(
                                    userId,
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isAssigned) {
                                          _assigneeIds.remove(userId);
                                        } else {
                                          _assigneeIds.add(userId);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: _purple
                                                .withOpacity(0.15),
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
                                                      color: _purple,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: isAssigned
                                                  ? _purple
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isAssigned
                                                    ? _purple
                                                    : Colors.grey[300]!,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: isAssigned
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 14,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
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
