import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/user/services/user_service.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getMyInfo();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 이름 수정
  Future<void> _showEditNameDialog() async {
    final nameController = TextEditingController(
      text: _user?['name'] as String? ?? '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '이름 수정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _userService.updateUser(_user!['id'], {
                  'name': nameController.text.trim(),
                });
                _loadUser();
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('이름을 수정했어요')));
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
    );
  }

  // 직책 수정
  Future<void> _showEditPositionDialog() async {
    final positionController = TextEditingController(
      text: _user?['position'] as String? ?? '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '직책 수정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: positionController,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: '직책',
            hintText: 'ex) 풀스택 개발자, 디자이너',
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
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
                await _userService.updateUser(_user!['id'], {
                  'position': positionController.text.trim(),
                });
                _loadUser();
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('직책을 수정했어요')));
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
    );
  }

  // 비밀번호 변경
  Future<void> _showEditPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
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
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
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
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않아요')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await _userService.updateUser(_user!['id'], {
                  'password': passwordController.text.trim(),
                });
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('비밀번호를 변경했어요')));
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('변경에 실패했어요')));
              }
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

  // 회원 탈퇴
  Future<void> _confirmDeleteAccount() async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없어요. 정말 탈퇴할까요?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: '탈퇴 사유 (선택)',
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
              try {
                final userId = _user?['id'];
                await _userService.deleteUser(
                  userId,
                  reasonController.text.trim(),
                );
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('탈퇴에 실패했어요')));
              }
            },
            child: const Text(
              '탈퇴',
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
                // 앱바
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
                          '내 정보',
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              // 프로필 사진
                              const SizedBox(height: 24),
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: _user?['profileImage'] != null
                                        ? Image.network(
                                            _user!['profileImage'],
                                            width: 88,
                                            height: 88,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 88,
                                            height: 88,
                                            color: _lightPurple,
                                            child: Center(
                                              child: Text(
                                                (_user?['name'] as String? ??
                                                        '?')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: _purple,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // 기본 정보 카드 (이름, 이메일, 직책)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      _buildInfoItem(
                                        label: '이름',
                                        value: _user?['name'] ?? '-',
                                        onTap: _showEditNameDialog,
                                      ),
                                      const Divider(
                                        height: 1,
                                        indent: 20,
                                        color: Color(0xFFF0F0F0),
                                      ),
                                      _buildInfoItem(
                                        label: '이메일',
                                        value: _user?['email'] ?? '-',
                                      ),
                                      const Divider(
                                        height: 1,
                                        indent: 20,
                                        color: Color(0xFFF0F0F0),
                                      ),
                                      _buildInfoItem(
                                        label: '직책',
                                        value:
                                            (_user?['position'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? _user!['position']
                                            : '직책을 입력해주세요',
                                        valueColor:
                                            (_user?['position'] as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? Colors.grey
                                            : Colors.grey[400],
                                        onTap: _showEditPositionDialog,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 비밀번호 카드
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      _buildInfoItem(
                                        label: '비밀번호',
                                        value: '••••••••',
                                        onTap:
                                            _user?['provider']?.contains(
                                                  'EMAIL',
                                                ) ==
                                                true
                                            ? _showEditPasswordDialog
                                            : null,
                                        subLabel:
                                            _user?['provider']?.contains(
                                                  'EMAIL',
                                                ) ==
                                                true
                                            ? null
                                            : '소셜 로그인 사용자',
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 회원 탈퇴 카드
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: _buildInfoItem(
                                    label: '회원 탈퇴',
                                    value: '',
                                    labelColor: Colors.red,
                                    onTap: _confirmDeleteAccount,
                                    showArrow: false,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
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

  Widget _buildInfoItem({
    required String label,
    required String value,
    VoidCallback? onTap,
    String? subLabel,
    Color? labelColor,
    Color? valueColor,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor ?? const Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            if (subLabel != null)
              Text(
                subLabel,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.grey,
                ),
              ),
            if (onTap != null && showArrow)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
