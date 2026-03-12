import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/project_service.dart';
import '../../space/services/space_service.dart';

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
  final SpaceService _spaceService = SpaceService();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  DateTime? _dueDate;
  String _status = 'NOT_STARTED';
  late bool _isPublic;
  bool _isSaving = false;
  bool _hasChanges = false;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _spaceMembers = [];
  bool _isMembersLoading = true;
  int? _currentUserId;
  bool _isAdmin = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _inputBg = Color(0xFFF7F5FF);

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
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final members = await _projectService.getProjectMembers(widget.projectId);
      final myMember = members.firstWhere(
        (m) => (m['userId'] as num?)?.toInt() == _currentUserId,
        orElse: () => <String, dynamic>{},
      );
      final myRole = myMember['role'] as String? ?? 'MEMBER';

      // 스페이스 멤버 로드 (이미 프로젝트에 있는 멤버 제외)
      final spaceId = (widget.project['spaceId'] as num?)?.toInt();
      List<Map<String, dynamic>> spaceMembers = [];
      if (spaceId != null) {
        final space = await _spaceService.getSpace(spaceId);
        final allSpaceMembers = (space?['members'] as List? ?? [])
            .map((m) => m as Map<String, dynamic>)
            .toList();
        final projectMemberIds = members
            .map((m) => (m['userId'] as num?)?.toInt() ?? 0)
            .toSet();
        spaceMembers = allSpaceMembers
            .where(
              (m) => !projectMemberIds.contains(
                (m['userId'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
      }

      setState(() {
        _members = members;
        _spaceMembers = spaceMembers;
        _isAdmin = myRole == 'ADMIN';
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

  void _showInviteSheet() {
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
                  '멤버 추가',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_spaceMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '추가할 수 있는 스페이스 멤버가 없어요',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._spaceMembers.map((m) {
                final name = m['userName'] as String? ?? '?';
                final profileImage = m['profileImage'] as String?;
                final email = m['email'] as String? ?? '';
                return ListTile(
                  leading: _buildAvatarFromData(name, profileImage),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    m['role'] == 'ADMIN' ? '관리자' : '멤버',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRolePickerAndInvite(name, email);
                  },
                );
              }),
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
                color: Color(0xFF6C5CE7),
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
                  _hasChanges = true;
                  _snack('$name 님을 관리자로 초대했어요 ✓');
                  _loadMembers();
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
                  _hasChanges = true;
                  _snack('$name 님을 멤버로 초대했어요 ✓');
                  _loadMembers();
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
                  _hasChanges = true;
                  _snack('$name 님을 뷰어로 초대했어요 ✓');
                  _loadMembers();
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

  void _showMemberOptions(Map<String, dynamic> member) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '';
    final role = member['role'] as String? ?? 'MEMBER';
    final isMe = userId == _currentUserId;
    final adminCount = _members.where((m) => m['role'] == 'ADMIN').length;
    final isLastAdmin = role == 'ADMIN' && adminCount <= 1;
    final isAlone = _members.length <= 1;

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

            // 내 항목
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
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (isAlone) {
                    final projectName = widget.project['name'] as String? ?? '';
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
                        _snack('나가기에 실패했어요');
                      }
                    }
                  } else if (isLastAdmin) {
                    _snack('관리자 권한을 다른 멤버에게 부여한 후 나가세요');
                  } else {
                    try {
                      await _projectService.leaveProject(widget.projectId);
                      if (mounted) Navigator.pop(context, true);
                    } catch (e) {
                      _snack('나가기에 실패했어요');
                    }
                  }
                },
              ),
            ],

            // 다른 사람 항목 (관리자만)
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
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'ADMIN',
                      );
                      _hasChanges = true;
                      _snack('권한을 변경했어요 ✓');
                      _loadMembers();
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
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'MEMBER',
                      );
                      _hasChanges = true;
                      _snack('권한을 변경했어요 ✓');
                      _loadMembers();
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
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'MEMBER',
                      );
                      _hasChanges = true;
                      _snack('권한을 변경했어요 ✓');
                      _loadMembers();
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
                    try {
                      await _projectService.updateMemberRole(
                        widget.projectId,
                        userId,
                        'VIEWER',
                      );
                      _hasChanges = true;
                      _snack('권한을 변경했어요 ✓');
                      _loadMembers();
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
                    _hasChanges = true;
                    _snack('$name 님을 내보냈어요');
                    _loadMembers();
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
                        onPressed: () => Navigator.pop(context, _hasChanges),
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
                        // 마감일 + 상태
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
                        // 공개 설정
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
                        // 멤버
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
                                  if (_isAdmin) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showInviteSheet,
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
                                ..._members.map((m) => _buildMemberTile(m)),
                              if (_isAdmin) ...[const SizedBox(height: 4)],
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
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '?';
    final role = member['role'] as String? ?? 'MEMBER';
    final profileImage = member['profileImage'] as String?;
    final isMe = userId == _currentUserId;
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
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (isMe)
                      Text(
                        ' (나)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                  ],
                ),
                Text(
                  role == 'ADMIN'
                      ? '관리자'
                      : role == 'VIEWER'
                      ? '뷰어'
                      : '멤버',
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
          if (_isAdmin || isMe) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onPressed: () => _showMemberOptions(member),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFromData(
    String name,
    String? profileImage, {
    double radius = 18,
  }) {
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
}
