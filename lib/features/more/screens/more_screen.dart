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

  // ✅ 보라색 영역: "중간 정도" (너 화면 기준 이 값이 자리낭비 줄이면서도 자연스럽게 보임)
  static const double _headerHeight = 350;

  // ✅ 아바타 더 크게
  static const double _avatarSize = 112;

  // ✅ 카드가 보라색을 얼마나 덮을지(클수록 카드/아바타가 위로 올라감)
  static const double _overlap = 220; // 60~95 사이에서 취향 조절

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getMyInfo();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
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
    // 카드가 보라색을 덮는 시작 위치 (더 위로 올리고 싶으면 _overlap 키우면 됨)
    final double cardTop = _headerHeight - _overlap;

    // 아바타가 카드에 "1/4만" 걸치게: 아래로 내려가는 길이 = size*0.25
    final double avatarTop = cardTop - (_avatarSize * 0.5);

    final String name = _isLoading ? '' : (_user?['name'] ?? '-');
    final String role = _isLoading
        ? ''
        : (_user?['role'] ?? 'Junior Full Stack Developer');
    final String email = _isLoading ? '' : (_user?['email'] ?? '-');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            // ===== 보라 헤더 =====
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: _headerHeight,
                decoration: const BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(25),
                  ),
                ),
              ),
            ),

            // ===== 상단바 + 본문 =====
            Column(
              children: [
                // 상단바 (고정)
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Colors.white,
                        ),
                        splashRadius: 22,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          '내 정보 →',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 본문
                Expanded(
                  child: Stack(
                    children: [
                      // ===== 흰 카드 =====
                      Positioned.fill(
                        top: cardTop,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // ✅ 위에만 둥글게
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(26),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // ✅ 아바타 크기(112) 기준으로 여백 조금 넉넉히
                                const SizedBox(height: 64),

                                // ===== 내 정보 (고정) =====
                                Text(
                                  name.isEmpty ? ' ' : name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.isEmpty ? ' ' : role,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _purple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 15,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      email.isEmpty ? ' ' : email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFF0F0F0),
                                ),

                                // ===== 여기부터 스크롤 (앱 설정부터) =====
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 16),

                                        _section(
                                          title: '앱 설정',
                                          children: [
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_notification.svg',
                                              title: '알림 설정',
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_darkmode.svg',
                                              title: '다크모드',
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_global.svg',
                                              title: '언어',
                                              onTap: () {},
                                              isLast: true,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),

                                        _section(
                                          title: '지원',
                                          children: [
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_info_circle.svg',
                                              title: '도움말',
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_question.svg',
                                              title: '문의하기',
                                              onTap: () {},
                                              isLast: true,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),

                                        _section(
                                          title: '더보기',
                                          children: [
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_ToS.svg',
                                              title: '이용약관',
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_personal_doc.svg',
                                              title: '개인정보 처리방침',
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_version.svg',
                                              title: '버전정보',
                                              trailing: const Text(
                                                '1.0.0',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              onTap: () {},
                                            ),
                                            _menuItem(
                                              iconPath:
                                                  'lib/assets/icons/more_logout.svg',
                                              title: 'Logout',
                                              isLogout: true,
                                              showArrow: false,
                                              onTap: _logout,
                                              isLast: true,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ===== 아바타 (고정) =====
                      Positioned(
                        top: avatarTop,
                        left: 0,
                        right: 0,
                        child: Center(child: _profileAvatar(size: _avatarSize)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====== UI Helpers ======

  Widget _profileAvatar({required double size}) {
    final String? img = _user?['profileImage'] as String?;
    final String name = (_user?['name'] as String? ?? '?');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: img != null && img.isNotEmpty
            ? Image.network(img, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFFA89AF7),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required String iconPath,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isLast = false,
    bool isLogout = false,
    bool showArrow = true,
  }) {
    final Color iconColor = isLogout ? Colors.grey : _purple;
    final Color textColor = isLogout ? Colors.grey : const Color(0xFF1A1A2E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
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
                        : const SizedBox.shrink()),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              color: Color(0xFFE9E9EE),
            ),
        ],
      ),
    );
  }
}
