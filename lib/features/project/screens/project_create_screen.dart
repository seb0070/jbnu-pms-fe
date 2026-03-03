import 'package:flutter/material.dart';
import '../services/project_service.dart';

class ProjectCreateScreen extends StatefulWidget {
  final int spaceId;
  const ProjectCreateScreen({super.key, required this.spaceId});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = true;
  DateTime? _dueDate;
  bool _isLoading = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);

  final ProjectService _projectService = ProjectService();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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
      await _projectService.createProject(
        widget.spaceId,
        _nameController.text.trim(),
        _descController.text.trim(),
        isPublic: _isPublic,
        dueDate: _dueDate,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로젝트 생성에 실패했어요')));
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
                          '프로젝트 생성',
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
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('프로젝트 이름', required: true),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _nameController,
                                    hint: '프로젝트 이름을 입력하세요',
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? '이름은 필수입니다'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildLabel('설명'),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _descController,
                                    hint: '프로젝트에 대한 설명을 입력하세요',
                                    minLines: 4,
                                    maxLines: null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildLabel('공개 설정'),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildToggleButton(
                                          'Public',
                                          Icons.public_rounded,
                                          true,
                                        ),
                                        _buildToggleButton(
                                          'Private',
                                          Icons.lock_rounded,
                                          false,
                                        ),
                                      ],
                                    ),
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
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            child: _buildSubmitButton('프로젝트 생성하기'),
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

  Widget _buildToggleButton(String label, IconData icon, bool value) {
    final isSelected = _isPublic == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPublic = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _purple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFB0A8D9),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFFB0A8D9),
                ),
              ),
            ],
          ),
        ),
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
