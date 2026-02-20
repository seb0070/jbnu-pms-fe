import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCreateScreen extends StatefulWidget {
  final int projectId;
  final int? parentTaskId;
  final String? parentTaskTitle;

  const TaskCreateScreen({
    super.key,
    required this.projectId,
    this.parentTaskId,
    this.parentTaskTitle,
  });

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  final List<Map<String, dynamic>> _assignees = [];
  bool _isLoading = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);

  final _priorities = [
    {'value': 'LOW', 'label': '낮음', 'color': const Color(0xFF19B36E)},
    {'value': 'MEDIUM', 'label': '중간', 'color': const Color(0xFFF79009)},
    {'value': 'HIGH', 'label': '높음', 'color': const Color(0xFFF95555)},
  ];

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8080',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _purple)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      await _dio.post(
        '/tasks',
        data: {
          'projectId': widget.projectId,
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'priority': _priority,
          if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
          if (widget.parentTaskId != null) 'parentId': widget.parentTaskId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('작업 생성에 실패했어요')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 콘텐츠
          SafeArea(
            child: Column(
              children: [
                // 앱바 (배경 비침)
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
                          '작업 생성',
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
                // 흰색 카드 콘텐츠
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // 스크롤 영역
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 상위 태스크 표시
                                  if (widget.parentTaskId != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _purple.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _purple.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.account_tree_rounded,
                                            color: _purple,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '상위 작업: ${widget.parentTaskTitle ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: _purple,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  _buildLabel('제목', required: true),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _titleController,
                                    hint: '작업 제목을 입력하세요',
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? '제목은 필수입니다'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),

                                  _buildLabel('설명'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _descController,
                                    hint: '작업에 대한 설명을 입력하세요',
                                    minLines: 4,
                                    maxLines: null,
                                  ),
                                  const SizedBox(height: 20),

                                  // 우선순위
                                  _buildLabel('우선순위'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: _priorities.map((p) {
                                      final isSelected =
                                          _priority == p['value'];
                                      final color = p['color'] as Color;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _priority =
                                                p['value'] as String,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  p['label'] as String,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),

                                  // 마감일
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
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: _dueDate != null
                                                ? _purple
                                                : const Color(0xFFB0A8D9),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _dueDate != null
                                                ? '${_dueDate!.year}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.day.toString().padLeft(2, '0')}'
                                                : '마감일을 선택하세요 (선택)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _dueDate != null
                                                  ? const Color(0xFF1A1A2E)
                                                  : const Color(0xFFB0A8D9),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_dueDate != null)
                                            GestureDetector(
                                              onTap: () => setState(
                                                () => _dueDate = null,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 담당자
                                  _buildLabel('담당자'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // 선택된 담당자 아바타
                                      ...List.generate(_assignees.length, (
                                        index,
                                      ) {
                                        final a = _assignees[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor: _purple
                                                    .withOpacity(0.15),
                                                child: Text(
                                                  (a['name'] as String)[0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    color: _purple,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: -2,
                                                right: -2,
                                                child: GestureDetector(
                                                  onTap: () => setState(
                                                    () => _assignees.removeAt(
                                                      index,
                                                    ),
                                                  ),
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.grey,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      // 담당자 추가 버튼
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: 멤버 목록 모달 연결
                                        },
                                        child: Image.asset(
                                          'lib/assets/images/ProfileCircle.png', // 원하는 PNG 경로
                                          width: 40,
                                          height: 40,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          // 하단 고정 버튼
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            child: _buildSubmitButton('작업 생성하기'),
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

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0A8D9), fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_lightPurple, _purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: MaterialButton(
          onPressed: _isLoading ? null : _submit,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
