import 'package:flutter/material.dart';
import '../services/project_service.dart';

class ProjectEditScreen extends StatefulWidget {
  final int projectId;
  final Map<String, dynamic> project;
  const ProjectEditScreen({
    super.key,
    required this.projectId,
    required this.project,
  });

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final ProjectService _projectService = ProjectService();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _inviteEmailController;
  DateTime? _dueDate;
  String _status = 'NOT_STARTED';
  bool _isSaving = false;
  late bool _isPublic;
  List<Map<String, dynamic>> _members = [];
  bool _isMembersLoading = true;

  static const _purple = Color(0xFF6C5CE7);
  static const _inputBg = Color(0xFFF7F5FF);
  static const _cardBg = Colors.white;

  final _statusOptions = [
    {'value': 'NOT_STARTED', 'label': '시작 전', 'color': Color(0xFF9E9E9E)},
    {'value': 'IN_PROGRESS', 'label': '진행 중', 'color': Color(0xFF6C5CE7)},
    {'value': 'DONE', 'label': '완료', 'color': Color(0xFF00B894)},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project['name'] ?? '');
    _descController = TextEditingController(
      text: widget.project['description'] ?? '',
    );
    _inviteEmailController = TextEditingController();
    _status = widget.project['status'] as String? ?? 'NOT_STARTED';
    final dueDateStr = widget.project['dueDate'] as String?;
    if (dueDateStr != null) _dueDate = DateTime.tryParse(dueDateStr);
    _isPublic = widget.project['isPublic'] as bool? ?? true;
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _projectService.getProjectMembers(widget.projectId);
      setState(() {
        _members = members;
        _isMembersLoading = false;
      });
    } catch (e) {
      setState(() => _isMembersLoading = false);
    }
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('프로젝트 이름을 입력해주세요');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'name': name,
        'status': _status,
        'isPublic': _isPublic,
      };
      final desc = _descController.text.trim();
      if (desc.isNotEmpty) data['description'] = desc;
      if (_dueDate != null) data['dueDate'] = _dueDate!.toIso8601String();
      await _projectService.updateProject(widget.projectId, data);
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

  Future<void> _inviteMember() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;
    try {
      await _projectService.inviteMember(widget.projectId, email, 'MEMBER');
      _inviteEmailController.clear();
      _snack('초대했어요 ✓');
      _loadMembers();
    } catch (e) {
      _snack('초대에 실패했어요');
    }
  }

  Future<void> _updateRole(int userId, String role) async {
    try {
      await _projectService.updateMemberRole(widget.projectId, userId, role);
      _snack('권한을 변경했어요 ✓');
      _loadMembers();
    } catch (e) {
      _snack('권한 변경에 실패했어요');
    }
  }

  Future<void> _expelMember(int userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '멤버 내보내기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text('$name 님을 프로젝트에서 내보낼까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('내보내기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _projectService.expelMember(widget.projectId, userId);
      _snack('내보냈어요');
      _loadMembers();
    } catch (e) {
      _snack('내보내기에 실패했어요');
    }
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '';
    final role = member['role'] as String? ?? 'MEMBER';

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
            if (role == 'MEMBER')
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF6C5CE7),
                ),
                title: const Text('관리자로 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRole(userId, 'ADMIN');
                },
              ),
            if (role == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.grey),
                title: const Text('멤버로 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _updateRole(userId, 'MEMBER');
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_outlined,
                color: Colors.red,
              ),
              title: const Text('내보내기', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _expelMember(userId, name);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
                // 앱바
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
                          '프로젝트 수정',
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
                // 스크롤 컨텐츠
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기본 정보 카드
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('프로젝트 이름'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _nameController,
                                '프로젝트 이름을 입력하세요',
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('설명'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _descController,
                                '프로젝트 설명을 입력하세요',
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 마감일 + 상태 카드
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
                              const SizedBox(height: 16),
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
                                                fontSize: 12,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 공개여부
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 멤버 카드
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildLabel('멤버'),
                                  const Spacer(),
                                  if (!_isMembersLoading)
                                    Text(
                                      '${_members.length}명',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isMembersLoading)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: _purple,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                ..._members.map(
                                  (member) => _buildMemberTile(member),
                                ),
                              const SizedBox(height: 16),
                              _buildLabel('멤버 초대'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      _inviteEmailController,
                                      '이메일로 초대',
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _inviteMember,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _purple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_add_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
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
                ),
              ],
            ),
          ),
          // 저장 버튼
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
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
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final name = member['userName'] as String? ?? '?';
    final role = member['role'] as String? ?? 'MEMBER';
    final profileImage = member['profileImage'] as String?;
    final isAdmin = role == 'ADMIN';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _purple.withOpacity(0.15),
            backgroundImage: profileImage != null && profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : null,
            child: profileImage == null || profileImage.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  isAdmin ? '관리자' : '멤버',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAdmin ? _purple.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isAdmin ? 'ADMIN' : 'MEMBER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isAdmin ? _purple : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onPressed: () => _showMemberOptions(member),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
