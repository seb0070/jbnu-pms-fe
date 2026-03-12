import 'package:flutter/material.dart';
import '../../space/services/space_service.dart';

class SpaceEditScreen extends StatefulWidget {
  final int spaceId;
  final Map<String, dynamic> space;
  final int currentUserId;
  const SpaceEditScreen({
    super.key,
    required this.spaceId,
    required this.space,
    required this.currentUserId,
  });

  @override
  State<SpaceEditScreen> createState() => _SpaceEditScreenState();
}

class _SpaceEditScreenState extends State<SpaceEditScreen> {
  final SpaceService _spaceService = SpaceService();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _inviteEmailController;
  bool _isSaving = false;
  List<Map<String, dynamic>> _members = [];
  bool _isMembersLoading = true;

  static const _purple = Color(0xFF6C5CE7);
  static const _inputBg = Color(0xFFF7F5FF);

  bool get _isOwner {
    final ownerId = (widget.space['ownerId'] as num?)?.toInt();
    return ownerId == widget.currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.space['name'] ?? '');
    _descController = TextEditingController(
      text: widget.space['description'] ?? '',
    );
    _inviteEmailController = TextEditingController();
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
      final space = await _spaceService.getSpace(widget.spaceId);
      if (space == null) return;
      final members =
          (space['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _members = members;
        _isMembersLoading = false;
      });
    } catch (e) {
      setState(() => _isMembersLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('스페이스 이름을 입력해주세요');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _spaceService.updateSpace(
        widget.spaceId,
        name,
        _descController.text.trim(),
      );
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
      await _spaceService.inviteMember(widget.spaceId, email, role: 'MEMBER');
      _inviteEmailController.clear();
      _snack('초대했어요 ✓');
      _loadMembers();
    } catch (e) {
      _snack('초대에 실패했어요');
    }
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '';
    final role = member['role'] as String? ?? 'MEMBER';
    final isMe = userId == widget.currentUserId;
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
                if (isLastAdmin)
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: Colors.grey[300],
                    ),
                    title: Text(
                      '멤버로 변경',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    enabled: false,
                  )
                else
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: Colors.grey,
                    ),
                    title: const Text('멤버로 변경'),
                    onTap: () async {
                      try {
                        await _spaceService.updateMemberRole(
                          widget.spaceId,
                          userId,
                          'MEMBER',
                        );
                        if (mounted) {
                          Navigator.pop(context); // 바텀시트
                          Navigator.pop(context, true); // 수정화면
                          _snack('권한을 변경했어요 ✓');
                        }
                      } catch (e) {
                        _snack('권한 변경에 실패했어요');
                      }
                    },
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
                  '스페이스 나가기',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (isAlone) {
                    final spaceName = widget.space['name'] as String? ?? '';
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
                              '스페이스 나가기',
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
                                  '마지막 멤버가 나가면 스페이스가 완전히 삭제돼요.\n아래에 스페이스 이름을 입력해주세요.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  spaceName,
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
                                    hintText: '스페이스 이름 입력',
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
                                onPressed: controller.text == spaceName
                                    ? () => Navigator.pop(ctx, true)
                                    : null,
                                child: Text(
                                  '나가기',
                                  style: TextStyle(
                                    color: controller.text == spaceName
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
                        await _spaceService.deleteSpace(widget.spaceId);
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        _snack('나가기에 실패했어요');
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
                          '스페이스 나가기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: const Text(
                          '스페이스에서 나갈까요?',
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
                        await _spaceService.leaveSpace(widget.spaceId);
                        if (mounted) Navigator.pop(context, true);
                      } catch (e) {
                        _snack('나가기에 실패했어요');
                      }
                    }
                  }
                },
              ),
            ],

            // 다른 사람 항목
            if (!isMe) ...[
              if (role == 'MEMBER')
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: _purple,
                  ),
                  title: const Text('관리자로 변경'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _spaceService.updateMemberRole(
                        widget.spaceId,
                        userId,
                        'ADMIN',
                      );
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
                      await _spaceService.updateMemberRole(
                        widget.spaceId,
                        userId,
                        'MEMBER',
                      );
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
                        '$name 님을 스페이스에서 내보낼까요?',
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
                    await _spaceService.expelMember(widget.spaceId, userId);
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '스페이스 수정',
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
                              _buildLabel('스페이스 이름'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _nameController,
                                '스페이스 이름을 입력하세요',
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('설명'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _descController,
                                '스페이스 설명을 입력하세요',
                                maxLines: 3,
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
    TextInputType? keyboardType,
  }) => TextField(
    controller: ctrl,
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
    final name = member['userName'] as String? ?? '?';
    final role = member['role'] as String? ?? 'MEMBER';
    final profileImage = member['profileImage'] as String?;
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final isOwner = (widget.space['ownerId'] as num?)?.toInt() == userId;
    final isMe = userId == widget.currentUserId;
    final isAdmin = role == 'ADMIN' || isOwner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
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
              if (isOwner)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
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
                  isOwner
                      ? '소유자'
                      : isAdmin
                      ? '관리자'
                      : '멤버',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOwner
                  ? Colors.amber.withOpacity(0.1)
                  : isAdmin
                  ? _purple.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOwner
                  ? 'OWNER'
                  : isAdmin
                  ? 'ADMIN'
                  : 'MEMBER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isOwner
                    ? Colors.amber[700]
                    : isAdmin
                    ? _purple
                    : Colors.grey[500],
              ),
            ),
          ),
          if (!isOwner) ...[
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
}
