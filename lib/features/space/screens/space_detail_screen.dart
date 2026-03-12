import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../file/services/file_service.dart';
import '../../../shared/widgets/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/app_config.dart';
import '../services/space_service.dart';
import '../../project/services/project_service.dart';
import '../../project/screens/project_list_screen.dart';
import '../../project/screens/project_create_screen.dart';
import '../../project/screens/project_detail_screen.dart';
import 'space_edit_screen.dart';

class SpaceDetailScreen extends StatefulWidget {
  final int spaceId;
  const SpaceDetailScreen({super.key, required this.spaceId});

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  final SpaceService _spaceService = SpaceService();
  final ProjectService _projectService = ProjectService();
  Map<String, dynamic>? _space;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  int? _currentUserId;
  List<Map<String, dynamic>> _allFiles = [];
  bool _isFilesLoading = true;
  bool _isUploading = false;
  final FileService _fileService = FileService();

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);

  bool get _isAdmin {
    final members = (_space?['members'] as List?) ?? [];
    final me = members.firstWhere(
      (m) => (m['userId'] as num?)?.toInt() == _currentUserId,
      orElse: () => <String, dynamic>{},
    );
    return (me['role'] as String? ?? '') == 'ADMIN';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadFiles(List<Map<String, dynamic>> projects) async {
    try {
      final List<Map<String, dynamic>> allFiles = [];
      for (final project in projects) {
        final files = await _fileService.getAllProjectFiles(
          project['id'] as int,
        );
        for (final file in files) {
          allFiles.add({
            ...file,
            'projectName': project['name'],
            'projectId': project['id'],
          });
        }
      }
      setState(() {
        _allFiles = allFiles;
        _isFilesLoading = false;
      });
    } catch (e) {
      setState(() => _isFilesLoading = false);
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getInt('user_id');
      final space = await _spaceService.getSpace(widget.spaceId);
      final projects = await _projectService.getProjects(widget.spaceId);
      setState(() {
        _space = space;
        _projects = projects;
        _isLoading = false;
      });
      _loadFiles(projects);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _sortedMembers() {
    final members = ((_space?['members'] as List?) ?? [])
        .map((m) => m as Map<String, dynamic>)
        .toList();
    members.sort((a, b) {
      final ra = a['role'] as String? ?? 'MEMBER';
      final rb = b['role'] as String? ?? 'MEMBER';
      if (ra == rb) return 0;
      return ra == 'ADMIN' ? -1 : 1;
    });
    return members;
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '멤버 초대',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: '초대할 이메일을 입력하세요',
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
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
                await _spaceService.inviteMember(
                  widget.spaceId,
                  emailController.text.trim(),
                );
                _loadData();
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('멤버를 초대했어요')));
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('초대에 실패했어요')));
              }
            },
            child: const Text(
              '초대',
              style: TextStyle(color: _purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(text: _space?['name']);
    final descController = TextEditingController(
      text: _space?['description'] ?? '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '스페이스 수정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '이름',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _spaceService.updateSpace(
                widget.spaceId,
                nameController.text.trim(),
                descController.text.trim(),
              );
              _loadData();
            },
            child: const Text(
              '저장',
              style: TextStyle(color: _purple, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleLeave() async {
    final members = (_space?['members'] as List?) ?? [];
    final adminCount = members.where((m) => m['role'] == 'ADMIN').length;
    final isAlone = members.length <= 1;

    if (isAlone) {
      // 혼자 남았을 때 → 이름 입력 후 삭제
      final spaceName = _space?['name'] as String? ?? '';
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '마지막 멤버가 나가면 스페이스가 완전히 삭제돼요.\n아래에 스페이스 이름을 입력해주세요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
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
          if (mounted) _snack('나가기에 실패했어요');
        }
      }
    } else if (_isAdmin && adminCount <= 1) {
      // 마지막 관리자
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
            '스페이스 나가기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            '스페이스에서 나갈까요?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
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
          if (mounted) _snack('나가기에 실패했어요');
        }
      }
    }
  }

  void _showMemberOptions(BuildContext sheetCtx, Map<String, dynamic> member) {
    final userId = (member['userId'] as num?)?.toInt() ?? 0;
    final name = member['userName'] as String? ?? '';
    final role = member['role'] as String? ?? 'MEMBER';
    final isMe = userId == _currentUserId;
    final members = (_space?['members'] as List?) ?? [];
    final adminCount = members.where((m) => m['role'] == 'ADMIN').length;
    final isLastAdmin = role == 'ADMIN' && adminCount <= 1;
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
                      Navigator.pop(context);
                      Navigator.pop(sheetCtx);
                      try {
                        await _spaceService.updateMemberRole(
                          widget.spaceId,
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
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(sheetCtx);
                  _handleLeave();
                },
              ),
            ],

            // 다른 사람 항목 (관리자만)
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
                    Navigator.pop(sheetCtx);
                    try {
                      await _spaceService.updateMemberRole(
                        widget.spaceId,
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
                      await _spaceService.updateMemberRole(
                        widget.spaceId,
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

  void _showAllMembersModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final members = _sortedMembers();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
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
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: members.length,
                  itemBuilder: (_, index) {
                    final member = members[index];
                    final name = member['userName'] as String? ?? '?';
                    final isMe =
                        (member['userId'] as num?)?.toInt() == _currentUserId;
                    final role = member['role'] as String? ?? 'MEMBER';
                    final isAdmin = role == 'ADMIN';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: _buildAvatar(member, radius: 22),
                      title: Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '(나)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        isAdmin ? '관리자' : '멤버',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAdmin ? _purple : Colors.grey,
                        ),
                      ),
                      trailing: (_isAdmin || isMe)
                          ? GestureDetector(
                              onTap: () => _showMemberOptions(ctx, member),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 20,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
            if (_isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF1A1A2E),
                ),
                title: const Text('스페이스 수정'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpaceEditScreen(
                        spaceId: widget.spaceId,
                        space: _space!,
                        currentUserId: _currentUserId ?? 0,
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF1A1A2E)),
              title: const Text('스페이스 나가기'),
              onTap: () {
                Navigator.pop(context);
                _handleLeave();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberGrid(List<Map<String, dynamic>> members) {
    final previewMembers = members.take(4).toList();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isAdmin)
              Expanded(
                child: GestureDetector(
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
                ),
              ),
            if (previewMembers.isNotEmpty)
              Expanded(child: _buildMemberTile(previewMembers[0])),
          ],
        ),
        for (int i = 1; i < previewMembers.length; i += 2) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMemberTile(previewMembers[i])),
              if (i + 1 < previewMembers.length)
                Expanded(child: _buildMemberTile(previewMembers[i + 1]))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final name = member['userName'] as String? ?? '?';
    final isMe = (member['userId'] as num?)?.toInt() == _currentUserId;
    final role = member['role'] as String? ?? 'MEMBER';
    final isAdmin = role == 'ADMIN';

    return Row(
      children: [
        _buildAvatar(member, radius: 20),
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
                isAdmin ? '관리자' : '멤버',
                style: TextStyle(
                  fontSize: 11,
                  color: isAdmin ? _purple : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Map<String, dynamic> member, {double radius = 22}) {
    final name = member['userName'] as String? ?? '?';
    final profileImage = member['profileImage'] as String?;

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
                      : _space == null
                      ? const Center(child: Text('스페이스를 불러올 수 없어요'))
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
    final members = _sortedMembers();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _space?['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if ((_space?['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _space?['description'],
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
                      GestureDetector(
                        onTap: _showAllMembersModal,
                        child: const Row(
                          children: [
                            Text(
                              '모두 보기',
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
                  child: _buildMemberGrid(members),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '프로젝트',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectListScreen(spaceId: widget.spaceId),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '모두 보기',
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
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProjectCreateScreen(spaceId: widget.spaceId),
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
                              '새 프로젝트',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_projects.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '프로젝트가 없어요',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._projects.take(5).map((project) {
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailScreen(
                                  projectId: project['id'],
                                ),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ),
                                  // TODO: dueDate 추가되면 D-day 표시
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
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
    // 프로젝트별 그룹핑
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final file in _allFiles) {
      final projectName = file['projectName'] as String? ?? '알 수 없음';
      grouped.putIfAbsent(projectName, () => []).add(file);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '첨부파일 (${_allFiles.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
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
        else if (_allFiles.isEmpty)
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
          ...grouped.entries.map(
            (entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_rounded,
                        size: 14,
                        color: Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C5CE7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map((file) => _buildFileCard(file)),
                const SizedBox(height: 8),
              ],
            ),
          ),
      ],
    );
  }

  void _downloadFile(Map<String, dynamic> file) {
    final fileName = file['fileName'] as String? ?? '';
    final fileId = file['id'] as int;
    final projectId = file['projectId'] as int?;
    final taskId = file['taskId'] as int?;

    String downloadUrl;
    if (taskId != null) {
      downloadUrl = '${AppConfig.baseUrl}/tasks/$taskId/files/$fileId/download';
    } else if (projectId != null) {
      downloadUrl =
          '${AppConfig.baseUrl}/projects/$projectId/files/$fileId/download';
    } else
      return;

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
    final createdAt = file['createdAt'] as String?;

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
}
