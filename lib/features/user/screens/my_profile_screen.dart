import 'package:flutter/material.dart';
import '../../../features/user/services/user_service.dart';
import 'my_profile_edit_screen.dart';

class MyProfileScreen extends StatefulWidget {
  /// 조회할 유저 ID. null이면 내 프로필로 동작.
  final int? userId;

  const MyProfileScreen({super.key, this.userId});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isMe = false;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final myInfo = await _userService.getMyInfo();
      final myId = myInfo['id'];

      Map<String, dynamic> user;
      if (widget.userId == null || widget.userId == myId) {
        user = myInfo;
        _isMe = true;
      } else {
        user = await _userService.getUserById(widget.userId!);
        _isMe = false;
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
                          '프로필',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      // 내 프로필일 때만 수정 버튼 표시
                      if (_isMe)
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF1A1A2E),
                            size: 20,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyProfileEditScreen(),
                            ),
                          ).then((_) => _loadProfile()),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : _user == null
                      ? const Center(child: Text('프로필을 불러올 수 없어요'))
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 32),

                              // 프로필 사진
                              _buildAvatar(88),
                              const SizedBox(height: 16),

                              // 이름
                              Text(
                                _user?['name'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // 직책 배지
                              if ((_user?['position'] as String?)?.isNotEmpty ==
                                  true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purple.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _user!['position'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _purple,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 32),

                              // 정보 카드
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
                                      _buildInfoRow(
                                        icon: Icons.person_outline,
                                        label: '이름',
                                        value: _user?['name'] ?? '-',
                                      ),
                                      const Divider(
                                        height: 1,
                                        indent: 20,
                                        color: Color(0xFFF0F0F0),
                                      ),
                                      _buildInfoRow(
                                        icon: Icons.email_outlined,
                                        label: '이메일',
                                        value: _user?['email'] ?? '-',
                                      ),
                                      if ((_user?['position'] as String?)
                                              ?.isNotEmpty ==
                                          true) ...[
                                        const Divider(
                                          height: 1,
                                          indent: 20,
                                          color: Color(0xFFF0F0F0),
                                        ),
                                        _buildInfoRow(
                                          icon: Icons.work_outline,
                                          label: '직책',
                                          value: _user!['position'],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                    ],
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

  Widget _buildAvatar(double size) {
    final profileImage = _user?['profileImage'] as String?;
    final name = _user?['name'] as String? ?? '?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: profileImage != null && profileImage.isNotEmpty
          ? Image.network(
              profileImage,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultAvatar(size, name),
            )
          : _defaultAvatar(size, name),
    );
  }

  Widget _defaultAvatar(double size, String name) {
    return Container(
      width: size,
      height: size,
      color: _lightPurple,
      alignment: Alignment.center,
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _purple),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
