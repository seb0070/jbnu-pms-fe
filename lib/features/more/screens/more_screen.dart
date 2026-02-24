import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../user/services/user_service.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  static const _purple = Color(0xFF6C5CE7);

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

  Future<void> _logout() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text('정말 로그아웃 할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              '로그아웃',
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: 내 정보 화면으로 이동
                        },
                        child: const Text(
                          '내 정보 →',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                              // 프로필 섹션
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Column(
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
                                              color: const Color(0xFFA89AF7),
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
                                    const SizedBox(height: 14),
                                    Text(
                                      _user?['name'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '-',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _purple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _user?['email'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 흰색 카드 영역
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    24,
                                    20,
                                    40,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 앱 설정
                                      _buildSectionTitle('앱 설정'),
                                      const SizedBox(height: 8),
                                      _buildMenuCard([
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_notification.svg',
                                          title: '알림 설정',
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_darkmode.svg',
                                          title: '다크모드',
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_global.svg',
                                          title: '언어',
                                          onTap: () {},
                                          isLast: true,
                                        ),
                                      ]),
                                      const SizedBox(height: 20),

                                      // 지원
                                      _buildSectionTitle('지원'),
                                      const SizedBox(height: 8),
                                      _buildMenuCard([
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_info_circle.svg',
                                          title: '도움말',
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_question.svg',
                                          title: '문의하기',
                                          onTap: () {},
                                          isLast: true,
                                        ),
                                      ]),
                                      const SizedBox(height: 20),

                                      // 더보기
                                      _buildSectionTitle('더보기'),
                                      const SizedBox(height: 8),
                                      _buildMenuCard([
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_ToS.svg',
                                          title: '이용약관',
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_personal_doc.svg',
                                          title: '개인정보 처리방침',
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_version.svg',
                                          title: '버전정보',
                                          trailing: const Text(
                                            '1.0.0',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          onTap: () {},
                                        ),
                                        _buildMenuItem(
                                          iconPath:
                                              'lib/assets/icons/more_logout.svg',
                                          title: 'Logout',
                                          isLogout: true,
                                          onTap: _logout,
                                          isLast: true,
                                          showArrow: false,
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isLast = false,
    bool isLogout = false,
    bool showArrow = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isLogout ? Colors.red : _purple,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? Colors.red : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                trailing ??
                    (showArrow
                        ? const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 20,
                          )
                        : const SizedBox()),
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, indent: 52, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}
