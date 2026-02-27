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
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);
  static const _inputBorder = Color(0xFFE0DAFF);

  final _statuses = [
    {'value': 'NOT_STARTED', 'label': '시작 전'},
    {'value': 'IN_PROGRESS', 'label': '진행 중'},
    {'value': 'DONE', 'label': '완료'},
  ];

  final _priorities = [
    {'value': 'LOW', 'label': '낮음', 'color': const Color(0xFF19B36E)},
    {'value': 'MEDIUM', 'label': '중간', 'color': const Color(0xFFF79009)},
    {'value': 'HIGH', 'label': '높음', 'color': const Color(0xFFF95555)},
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
        .map((a) => (a['userId'] as int))
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
      _showSnackBar('태스크 제목을 입력해주세요');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'title': title,
        'description': _descController.text.trim(),
        'status': _status,
        'priority': _priority,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
      };
      await _projectService.updateTask(widget.taskId, data);

      // 담당자 동기화
      final originalIds = ((widget.task['assignees'] as List?) ?? [])
          .map((a) => a['userId'] as int)
          .toSet();
      final newIds = _assigneeIds.toSet();
      for (final id in newIds.difference(originalIds)) {
        await _projectService.addAssignee(widget.taskId, id);
      }
      for (final id in originalIds.difference(newIds)) {
        await _projectService.removeAssignee(widget.taskId, id);
      }

      if (mounted) {
        _showSnackBar('저장했어요 ✓');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('저장에 실패했어요');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                          '태스크 수정',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('제목'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _titleController,
                                  hint: '태스크 제목',
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('설명'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _descController,
                                  hint: '설명을 입력해주세요 (선택)',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('마감일'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickDueDate,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _inputBorder,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          color: _purple,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _dueDate != null
                                              ? '${_dueDate!.year}. ${_dueDate!.month}. ${_dueDate!.day}.'
                                              : '마감일을 선택해주세요 (선택)',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _dueDate != null
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.grey[400],
                                          ),
                                        ),
                                        const Spacer(),
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
                                const SizedBox(height: 20),
                                _buildLabel('상태'),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _inputBorder),
                                  ),
                                  child: Row(
                                    children: _statuses.map((s) {
                                      final isSelected = _status == s['value'];
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () =>
                                                _status = s['value'] as String,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? _purple
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              s['label'] as String,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildLabel('우선순위'),
                                const SizedBox(height: 8),
                                Row(
                                  children: _priorities.map((p) {
                                    final isSelected = _priority == p['value'];
                                    final color = p['color'] as Color;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () =>
                                              _priority = p['value'] as String,
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color
                                                : _inputBg,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? color
                                                  : _inputBorder,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            p['label'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : color,
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
                          const SizedBox(height: 16),

                          // 담당자
                          if (widget.projectMembers.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('담당자'),
                                  const SizedBox(height: 12),
                                  ...widget.projectMembers.map((member) {
                                    final userId = member['userId'] as int;
                                    final name =
                                        member['userName'] as String? ?? '?';
                                    final isAssigned = _assigneeIds.contains(
                                      userId,
                                    );
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isAssigned) {
                                            _assigneeIds.remove(userId);
                                          } else {
                                            _assigneeIds.add(userId);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: isAssigned
                                                    ? _purple
                                                    : _lightPurple,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
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
                                            if (isAssigned)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: _purple,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _lightPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      '저장하기',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
