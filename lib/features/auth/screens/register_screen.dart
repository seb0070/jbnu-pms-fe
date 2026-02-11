import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isEmailChecked = false;
  bool _isEmailAvailable = false;
  bool _isCheckingEmail = false;

  bool _isCodeSent = false;
  bool _isCodeVerified = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;

  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkEmailAvailability() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 이메일을 입력해주세요')));
      return;
    }

    setState(() {
      _isCheckingEmail = true;
    });

    final result = await _authService.checkEmailAvailable(email);

    setState(() {
      _isCheckingEmail = false;
      _isEmailChecked = true;
      _isEmailAvailable = result['available'] ?? false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '확인 완료'),
          backgroundColor: (result['available'] ?? false)
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if (!_isEmailChecked || !_isEmailAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 중복 확인을 먼저 해주세요')));
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    final result = await _authService.sendVerificationCode(
      email: email,
      type: 'REGISTER',
    );

    setState(() {
      _isSendingCode = false;
      if (result['success'] ?? false) {
        _isCodeSent = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '완료'),
          backgroundColor: (result['success'] ?? false)
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _verificationCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증 코드를 입력해주세요')));
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    final result = await _authService.verifyCode(
      email: email,
      code: code,
      type: 'REGISTER',
    );

    setState(() {
      _isVerifyingCode = false;
      if (result['success'] ?? false) {
        _isCodeVerified = true;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '완료'),
          backgroundColor: (result['success'] ?? false)
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmailChecked || !_isEmailAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 중복 확인을 해주세요')));
      return;
    }

    if (!_isCodeVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 인증을 완료해주세요')));
      return;
    }

    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필수 약관에 동의해주세요')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        verificationCode: _verificationCodeController.text.trim(),
      );

      if ((result['success'] ?? false) && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? '회원가입 완료')));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? '회원가입 실패')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateAgreeAll() {
    setState(() {
      _agreeAll = _agreeTerms && _agreePrivacy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('lib/assets/images/background.png', fit: BoxFit.cover),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    Center(
                      child: Image.asset(
                        'lib/assets/images/logo.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'JBNU PMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '회원정보를 입력해주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),

                    // Name
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '이름을 입력하세요',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: '이메일을 입력하세요',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[400],
                              ),
                              suffixIcon: _isEmailChecked
                                  ? Icon(
                                      _isEmailAvailable
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _isEmailAvailable
                                          ? Colors.green
                                          : Colors.red,
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isEmailChecked = false;
                                _isCodeSent = false;
                                _isCodeVerified = false;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '이메일을 입력해주세요';
                              }
                              if (!value.contains('@')) {
                                return '올바른 이메일 형식이 아닙니다';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF6C5CE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: _isCheckingEmail
                                ? null
                                : _checkEmailAvailability,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            child: _isCheckingEmail
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    '중복확인',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // 중복확인 완료 후 인증번호 발송 버튼
                    if (_isEmailChecked &&
                        _isEmailAvailable &&
                        !_isCodeSent) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF9B8FFF), Color(0xFF6C5CE7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSendingCode
                                ? null
                                : _sendVerificationCode,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: _isSendingCode
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '인증번호 발송',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // 인증번호 입력 필드
                    if (_isCodeSent) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Verification Code',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _verificationCodeController,
                              decoration: InputDecoration(
                                hintText: '인증번호 6자리',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.pin_outlined,
                                  color: Colors.grey[400],
                                ),
                                suffixIcon: _isCodeVerified
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF6C5CE7),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              buildCounter:
                                  (
                                    context, {
                                    required currentLength,
                                    required isFocused,
                                    maxLength,
                                  }) {
                                    return null;
                                  },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: _isCodeVerified
                                  ? Colors.green
                                  : Color(0xFF6C5CE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              onPressed: _isVerifyingCode || _isCodeVerified
                                  ? null
                                  : _verifyCode,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              child: _isVerifyingCode
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isCodeVerified ? '완료' : '확인',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // 재발송 버튼
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSendingCode
                              ? null
                              : _sendVerificationCode,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '인증번호 재발송',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C5CE7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Password
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 입력하세요',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        if (value.length < 8) {
                          return '비밀번호는 8자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: _obscurePasswordConfirm,
                      decoration: InputDecoration(
                        hintText: '비밀번호를 다시 입력하세요',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasswordConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePasswordConfirm =
                                  !_obscurePasswordConfirm;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF6C5CE7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 다시 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 약관 동의
                    CheckboxListTile(
                      value: _agreeAll,
                      onChanged: (value) {
                        setState(() {
                          _agreeAll = value ?? false;
                          _agreeTerms = value ?? false;
                          _agreePrivacy = value ?? false;
                        });
                      },
                      title: const Text(
                        '모든 약관에 동의합니다',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Color(0xFF6C5CE7),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      title: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(text: '이용 약관에 동의합니다 '),
                                  TextSpan(
                                    text: '(필수)',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showTermsDialog('이용 약관', '''JBNU PMS 서비스 이용약관

제1조 (목적)
본 약관은 JBNU PMS(이하 "회사")가 제공하는 프로젝트 관리 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
1. "서비스"란 회사가 제공하는 JBNU PMS 프로젝트 관리 플랫폼 및 관련 제반 서비스를 의미합니다.
2. "회원"이란 본 약관에 동의하고 회사와 서비스 이용계약을 체결한 자를 말합니다.
3. "프로젝트"란 회원이 서비스 내에서 생성하고 관리하는 업무 단위를 의미합니다.
4. "콘텐츠"란 회원이 서비스를 이용하면서 게시, 등록, 저장하는 모든 정보를 의미합니다.

제3조 (약관의 게시 및 변경)
1. 회사는 본 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 초기 화면 또는 연결 화면에 게시합니다.
2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.
3. 회사가 약관을 변경할 경우 적용일자 및 변경사유를 명시하여 현행 약관과 함께 서비스 초기 화면에 그 적용일자 7일 전부터 적용일자 전일까지 공지합니다.
4. 회원은 변경된 약관에 동의하지 않을 권리가 있으며, 변경된 약관에 동의하지 않을 경우 서비스 이용을 중단하고 탈퇴할 수 있습니다.

제4조 (회원가입)
1. 회원가입은 이용자가 약관의 내용에 동의하고, 회사가 정한 가입 양식에 따라 회원정보를 기입하여 가입 신청을 완료함으로써 체결됩니다.
2. 회사는 다음 각 호에 해당하는 신청에 대하여는 승인을 하지 않거나 사후에 이용계약을 해지할 수 있습니다.
   가. 타인의 명의를 사용하여 신청한 경우
   나. 허위의 정보를 기재하거나, 회사가 제시하는 내용을 기재하지 않은 경우
   다. 관련 법령에 위배되거나 사회의 안녕과 질서, 미풍양속을 저해할 목적으로 신청한 경우

제5조 (서비스의 제공)
1. 회사는 다음과 같은 서비스를 제공합니다.
   가. 프로젝트 생성 및 관리 기능
   나. 작업 할당 및 진행 상황 추적 기능
   다. 팀원 간 협업 기능
   라. 일정 관리 기능
   마. 기타 회사가 추가 개발하거나 제휴계약 등을 통해 회원에게 제공하는 서비스
2. 서비스는 연중무휴, 1일 24시간 제공함을 원칙으로 합니다.
3. 회사는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.

제6조 (서비스의 변경 및 중단)
1. 회사는 상당한 이유가 있는 경우 운영상, 기술상의 필요에 따라 제공하고 있는 서비스의 전부 또는 일부를 변경할 수 있습니다.
2. 서비스의 내용, 이용방법, 이용시간에 대하여 변경이 있는 경우 변경사유, 변경될 서비스의 내용 및 제공일자 등을 그 변경 전 7일 이상 해당 서비스 초기화면에 게시합니다.
3. 회사는 다음 각 호에 해당하는 경우 서비스의 전부 또는 일부를 제한하거나 중지할 수 있습니다.
   가. 서비스용 설비의 보수 등 공사로 인한 부득이한 경우
   나. 정전, 제반 설비의 장애 또는 이용량의 폭주 등으로 정상적인 서비스 이용에 지장이 있는 경우
   다. 서비스 제공업자와의 계약 종료 등과 같은 회사의 제반 사정으로 서비스를 유지할 수 없는 경우

제7조 (회원정보의 변경)
1. 회원은 개인정보관리화면을 통하여 언제든지 본인의 개인정보를 열람하고 수정할 수 있습니다.
2. 회원은 회원가입 신청 시 기재한 사항이 변경되었을 경우 온라인으로 수정을 하거나 이메일 기타 방법으로 회사에 대하여 그 변경사항을 알려야 합니다.

제8조 (개인정보보호)
회사는 관련 법령이 정하는 바에 따라 회원의 개인정보를 보호하기 위해 노력합니다. 개인정보의 보호 및 사용에 대해서는 관련 법령 및 회사의 개인정보처리방침이 적용됩니다.

제9조 (회원의 의무)
1. 회원은 다음 행위를 하여서는 안 됩니다.
   가. 신청 또는 변경 시 허위내용의 등록
   나. 타인의 정보 도용
   다. 회사가 게시한 정보의 변경
   라. 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
   마. 회사와 기타 제3자의 저작권 등 지적재산권에 대한 침해
   바. 회사 및 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
   사. 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 서비스에 공개 또는 게시하는 행위
2. 회원은 관계법령, 본 약관의 규정, 이용안내 및 서비스와 관련하여 공지한 주의사항, 회사가 통지하는 사항 등을 준수하여야 합니다.

제10조 (회사의 의무)
1. 회사는 관련 법령과 본 약관이 금지하거나 미풍양속에 반하는 행위를 하지 않으며, 계속적이고 안정적으로 서비스를 제공하기 위하여 최선을 다하여 노력합니다.
2. 회사는 회원이 안전하게 서비스를 이용할 수 있도록 개인정보(신용정보 포함) 보호를 위해 보안시스템을 갖추어야 하며 개인정보처리방침을 공시하고 준수합니다.
3. 회사는 서비스 이용과 관련하여 회원으로부터 제기된 의견이나 불만이 정당하다고 인정할 경우 이를 처리하여야 합니다.

제11조 (콘텐츠의 관리)
1. 회원이 작성한 콘텐츠에 대한 저작권 및 책임은 콘텐츠를 작성한 회원에게 있습니다.
2. 회사는 회원이 작성한 콘텐츠를 서비스 제공 목적 범위 내에서 사용할 수 있습니다.
3. 회사는 다음 각 호에 해당하는 콘텐츠나 자료에 대해서는 사전 통지 없이 삭제하거나 이동 또는 등록 거부를 할 수 있습니다.
   가. 타인을 비방하거나 명예를 손상시키는 내용
   나. 공서양속에 위반되는 내용
   다. 범죄적 행위에 결부된다고 인정되는 내용
   라. 회사의 저작권, 제3자의 저작권 등 기타 권리를 침해하는 내용
   마. 기타 관계 법령에 위배되는 내용

제12조 (계약해지 및 이용제한)
1. 회원이 이용계약을 해지하고자 하는 경우에는 회원 본인이 서비스 내 제공되는 메뉴를 이용하여 해지 신청을 하여야 합니다.
2. 회사는 회원이 다음 각 호에 해당하는 행위를 하였을 경우 사전 통지 없이 이용계약을 해지하거나 또는 기간을 정하여 서비스 이용을 중지할 수 있습니다.
   가. 타인의 서비스 이용을 방해하거나 타인의 개인정보를 도용한 경우
   나. 서비스를 이용하여 법령 또는 본 약관이 금지하는 행위를 하는 경우

제13조 (면책조항)
1. 회사는 천재지변, 전쟁 및 기타 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 대한 책임이 면제됩니다.
2. 회사는 회원의 귀책사유로 인한 서비스 이용의 장애 또는 손해에 대하여 책임을 지지 않습니다.
3. 회사는 회원이 서비스를 이용하여 기대하는 수익을 얻지 못하거나 상실한 것에 대하여 책임을 지지 않습니다.
4. 회사는 회원 상호간 또는 회원과 제3자 간에 서비스를 매개로 발생한 분쟁에 대해서는 개입할 의무가 없으며 이로 인한 손해를 배상할 책임도 없습니다.

제14조 (분쟁해결)
1. 회사와 회원은 서비스와 관련하여 발생한 분쟁을 원만하게 해결하기 위하여 필요한 모든 노력을 하여야 합니다.
2. 본 약관에서 정하지 아니한 사항과 본 약관의 해석에 관하여는 대한민국 법령 또는 상관례에 따릅니다.
3. 서비스 이용으로 발생한 분쟁에 대해 소송이 제기될 경우 회사의 본사 소재지를 관할하는 법원을 관할 법원으로 합니다.

부칙
본 약관은 2026년 1월 1일부터 시행합니다.''');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C5CE7),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Color(0xFF6C5CE7),
                    ),
                    CheckboxListTile(
                      value: _agreePrivacy,
                      onChanged: (value) {
                        setState(() {
                          _agreePrivacy = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      title: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(text: '개인정보 처리방침에 동의합니다 '),
                                  TextSpan(
                                    text: '(필수)',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showTermsDialog(
                                '개인정보 처리방침',
                                '''JBNU PMS 개인정보 처리방침

JBNU PMS(이하 "회사")는 개인정보보호법 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보 처리방침을 수립·공개합니다.

제1조 (개인정보의 처리 목적)
회사는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원 가입 및 관리
회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증, 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지 목적으로 개인정보를 처리합니다.

2. 서비스 제공
프로젝트 관리 서비스 제공, 콘텐츠 제공, 맞춤 서비스 제공을 목적으로 개인정보를 처리합니다.

3. 고충처리
민원인의 신원 확인, 민원사항 확인, 사실조사를 위한 연락·통지, 처리결과 통보의 목적으로 개인정보를 처리합니다.

제2조 (개인정보의 처리 및 보유기간)
1. 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다.
   - 회원 가입 및 관리: 회원 탈퇴 시까지
   - 단, 관계 법령 위반에 따른 수사·조사 등이 진행 중인 경우에는 해당 수사·조사 종료 시까지
   - 서비스 제공: 서비스 이용계약 종료 시까지

제3조 (처리하는 개인정보의 항목)
회사는 다음의 개인정보 항목을 처리하고 있습니다.

1. 필수항목
   - 이메일 주소
   - 이름
   - 비밀번호(암호화 저장)

2. 선택항목
   - 프로필 이미지

3. 서비스 이용 과정에서 자동으로 생성·수집되는 정보
   - IP주소
   - 쿠키
   - 서비스 이용 기록
   - 접속 로그

제4조 (개인정보의 제3자 제공)
회사는 정보주체의 개인정보를 제1조(개인정보의 처리 목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보보호법 제17조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.

제5조 (개인정보처리의 위탁)
회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다.
   - 현재 위탁 업체 없음
   - 위탁업무 발생 시 사전 공지 예정

제6조 (정보주체의 권리·의무 및 행사방법)
1. 정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다.
   가. 개인정보 열람 요구
   나. 오류 등이 있을 경우 정정 요구
   다. 삭제 요구
   라. 처리정지 요구
2. 제1항에 따른 권리 행사는 회사에 대해 서면, 전화, 전자우편 등을 통하여 하실 수 있으며 회사는 이에 대해 지체없이 조치하겠습니다.
3. 정보주체가 개인정보의 오류 등에 대한 정정 또는 삭제를 요구한 경우에는 회사는 정정 또는 삭제를 완료할 때까지 당해 개인정보를 이용하거나 제공하지 않습니다.

제7조 (개인정보의 파기)
1. 회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.
2. 개인정보 파기의 절차 및 방법은 다음과 같습니다.
   가. 파기절차: 불필요한 개인정보 및 개인정보파일은 개인정보책임자의 책임 하에 내부 방침 절차에 따라 파기합니다.
   나. 파기방법: 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용합니다.

제8조 (개인정보의 안전성 확보조치)
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다.
1. 관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육
2. 기술적 조치: 개인정보처리시스템 등의 접근권한 관리, 접근통제시스템 설치, 개인정보의 암호화, 보안프로그램 설치
3. 물리적 조치: 전산실, 자료보관실 등의 접근통제

제9조 (개인정보 보호책임자)
1. 회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.
   - 개인정보 보호책임자: 추후 지정 예정
   - 연락처: support@jbnu-pms.com

2. 정보주체께서는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.

제10조 (개인정보 처리방침 변경)
이 개인정보 처리방침은 2024. 1. 1부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.

부칙
본 방침은 2026년 1월 1일부터 시행합니다.''',
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C5CE7),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Color(0xFF6C5CE7),
                    ),
                    const SizedBox(height: 24),

                    // Sign Up 버튼
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF9B8FFF), Color(0xFF6C5CE7)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleRegister,
                          borderRadius: BorderRadius.circular(28),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 로그인 링크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '이미 계정이 있으신가요? ',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign in here',
                            style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
