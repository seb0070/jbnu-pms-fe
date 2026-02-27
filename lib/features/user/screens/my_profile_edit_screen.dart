import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/user/services/user_service.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

class MyProfileEditScreen extends StatefulWidget {
  const MyProfileEditScreen({super.key});

  @override
  State<MyProfileEditScreen> createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _positionController = TextEditingController();

  bool _isEmailUser = false;
  File? _pickedImage;

  static const _purple = Color(0xFF6C5CE7);
  static const _lightPurple = Color(0xFFA89AF7);
  static const _inputBg = Color(0xFFF0EEFF);
  static const _inputBorder = Color(0xFFE0DAFF);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getMyInfo();
      setState(() {
        _user = user;
        _nameController.text = user['name'] ?? '';
        _positionController.text = user['position'] ?? '';
        _isEmailUser = (user['provider'] as String? ?? '').contains('EMAIL');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('이름을 입력해주세요');
      return;
    }
    if (name.length < 2) {
      _showSnackBar('이름은 2자 이상이어야 해요');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_pickedImage != null) {
        await _userService.updateProfileImage(_user!['id'], _pickedImage!);
      }
      await _userService.updateUser(_user!['id'], {
        'name': name,
        'position': position,
      });
      if (mounted) {
        _showSnackBar('프로필을 저장했어요 ✓');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('저장에 실패했어요');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                          '프로필 수정',
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
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            children: [
                              const SizedBox(height: 28),

                              // ── 프로필 사진 ──
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    _buildAvatar(96),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: _purple,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _purple.withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── 입력 폼 카드 ──
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    24,
                                    20,
                                    24,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('이름'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _nameController,
                                        hint: '이름을 입력해주세요',
                                      ),
                                      const SizedBox(height: 20),

                                      _buildLabel('직책'),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        controller: _positionController,
                                        hint: '직책을 입력해주세요 (선택)',
                                        maxLength: 100,
                                      ),
                                      const SizedBox(height: 20),

                                      // 이메일 (읽기 전용)
                                      _buildLabel('이메일'),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F7F7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEEEEEE),
                                          ),
                                        ),
                                        child: Text(
                                          _user?['email'] ?? '-',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── 저장 버튼 ──
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _purple,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: _lightPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            '저장하기',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── 계정 관리 카드 ──
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
                                      // 비밀번호 변경
                                      _buildAccountMenuItem(
                                        icon: Icons.lock_outline,
                                        label: '비밀번호 변경',
                                        disabled: !_isEmailUser,
                                        onTap: !_isEmailUser
                                            ? null
                                            : () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ChangePasswordScreen(
                                                        userId: _user!['id'],
                                                      ),
                                                ),
                                              ),
                                      ),
                                      const Divider(
                                        height: 1,
                                        indent: 20,
                                        color: Color(0xFFF0F0F0),
                                      ),

                                      // 회원 탈퇴
                                      _buildAccountMenuItem(
                                        icon: Icons.delete_outline,
                                        label: '회원 탈퇴',
                                        isDestructive: true,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DeleteAccountScreen(
                                              userId: _user!['id'],
                                            ),
                                          ),
                                        ),
                                      ),
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

  Widget _buildAccountMenuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool disabled = false,
  }) {
    final color = disabled
        ? Colors.grey[400]!
        : isDestructive
        ? Colors.red
        : const Color(0xFF1A1A2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: _inputBg,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    final profileImage = _user?['profileImage'] as String?;
    final name = _user?['name'] as String? ?? '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: _pickedImage != null
          ? Image.file(
              _pickedImage!,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : profileImage != null && profileImage.isNotEmpty
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
}
