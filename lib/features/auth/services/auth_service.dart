import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../../core/network/dio_client.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // ✅ DioClient 사용 - baseUrl, 타임아웃, 토큰 인터셉터 자동 적용
  final Dio _dio = DioClient.create();

  static const String authBaseUrl = '/auth';

  // ── 내부 헬퍼 ──────────────────────────────────────────

  /// 로그인 성공 후 토큰 저장 + user_id 조회/저장
  Future<void> _saveTokensAndUserId(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['accessToken']);
    if (data['refreshToken'] != null) {
      await prefs.setString('refresh_token', data['refreshToken']);
    }

    try {
      // 인터셉터가 이미 토큰을 주입하지만, 여기서는 방금 받은 토큰을
      // 명시적으로 넘겨야 prefs 저장 전 타이밍 문제가 없음
      final userRes = await _dio.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer ${data['accessToken']}'},
        ),
      );
      final userId = userRes.data['data']?['id'];
      if (userId != null) {
        await prefs.setInt('user_id', (userId as num).toInt());
      }
    } catch (e) {
      _logger.w('user_id 저장 실패: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────

  Future<Map<String, dynamic>> checkEmailAvailable(String email) async {
    try {
      _logger.d('이메일 중복 확인 시작: $email');
      final response = await _dio.get(
        '$authBaseUrl/check-email',
        queryParameters: {'email': email},
      );
      _logger.d('이메일 확인 응답: ${response.data}');
      return {
        'success': response.data['isSuccess'] ?? false,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      _logger.e('이메일 확인 DioException');
      _logger.e('상태코드: ${e.response?.statusCode}');
      _logger.e('응답 데이터: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? '이메일 확인 실패',
      };
    } catch (e) {
      _logger.e('이메일 확인 예외: $e');
      return {'success': false, 'message': '이메일 확인 중 오류 발생'};
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '$authBaseUrl/verification/send',
        data: {'email': email, 'type': type},
      );
      return {
        'success': response.data['isSuccess'] ?? false,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      _logger.e('인증 코드 발송 에러', error: e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? '인증 코드 발송 실패',
      };
    }
  }

  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '$authBaseUrl/verification/verify',
        data: {'email': email, 'code': code, 'type': type},
      );
      return {
        'success': response.data['isSuccess'] ?? false,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      _logger.e('인증 코드 확인 에러', error: e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? '인증 실패',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String verificationCode,
  }) async {
    try {
      final response = await _dio.post(
        '$authBaseUrl/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'verificationCode': verificationCode,
        },
      );
      _logger.i('회원가입 성공');
      return {
        'success': response.data['isSuccess'] ?? false,
        'data': response.data['data'],
        'message': '회원가입 성공',
      };
    } on DioException catch (e) {
      _logger.e('회원가입 에러', error: e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? '회원가입 실패',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.d('로그인 시도: $email');
      final response = await _dio.post(
        '$authBaseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.data['isSuccess'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['accessToken'] == null) {
          return {'success': false, 'message': 'accessToken이 없습니다'};
        }
        // ✅ 중복 제거 - 공통 헬퍼 사용
        await _saveTokensAndUserId(data);
        _logger.i('로그인 성공');
        return {'success': true, 'message': '로그인 성공'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? '로그인 실패',
        };
      }
    } on DioException catch (e) {
      _logger.e('로그인 실패', error: e.response?.data);
      final errorMessage = (e.response?.data is Map)
          ? e.response!.data['message'] ?? '로그인 실패'
          : '로그인 실패';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      _logger.e('로그인 예외', error: e);
      return {'success': false, 'message': '로그인 중 오류 발생'};
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      _logger.d('구글 로그인 시작');
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('구글 로그인 취소됨');
        return {'success': false, 'message': '로그인이 취소되었습니다'};
      }

      _logger.d('구글 사용자 정보 획득: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        _logger.e('accessToken이 null');
        return {'success': false, 'message': '구글 인증 실패'};
      }

      _logger.d('백엔드 호출 준비');
      _logger.d('accessToken 길이: ${accessToken.length}');

      final response = await _dio.post(
        '$authBaseUrl/oauth2/login',
        data: {'provider': 'GOOGLE', 'accessToken': accessToken},
      );

      _logger.d('백엔드 응답 받음: ${response.statusCode}');

      if (response.data['isSuccess'] == true && response.data['data'] != null) {
        final data = response.data['data'];
        if (data['accessToken'] == null) {
          return {'success': false, 'message': 'accessToken이 없습니다'};
        }
        // ✅ 중복 제거 - 공통 헬퍼 사용
        await _saveTokensAndUserId(data);
        _logger.i('구글 로그인 성공');
        return {'success': true, 'message': '로그인 성공'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? '구글 로그인 실패',
        };
      }
    } on DioException catch (e) {
      _logger.e('구글 로그인 DioException');
      _logger.e('타입: ${e.type}');
      _logger.e('URL: ${e.requestOptions.uri}');
      _logger.e('상태코드: ${e.response?.statusCode}');
      _logger.e('응답: ${e.response?.data}');
      final errorMessage = (e.response?.data is Map)
          ? e.response!.data['message'] ?? '구글 로그인 실패'
          : '구글 로그인 실패';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      _logger.e('구글 로그인 예외', error: e);
      return {'success': false, 'message': '구글 로그인 중 오류 발생'};
    }
  }

  Future<void> signOut() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      _logger.e('서버 로그아웃 에러', error: e);
    } finally {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _logger.i('로그아웃 완료');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      _logger.d('비밀번호 재설정 시도: $email');
      final response = await _dio.post(
        '$authBaseUrl/password/reset',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      _logger.i('비밀번호 재설정 성공');
      return {
        'success': response.data['isSuccess'] ?? false,
        'message': '비밀번호가 재설정되었습니다',
      };
    } on DioException catch (e) {
      _logger.e('비밀번호 재설정 실패', error: e.response?.data);
      final errorMessage = (e.response?.data is Map)
          ? e.response!.data['message'] ?? '비밀번호 재설정 실패'
          : '비밀번호 재설정 실패';
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      _logger.e('비밀번호 재설정 예외', error: e);
      return {'success': false, 'message': '비밀번호 재설정 중 오류 발생'};
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey('access_token');
      _logger.d('로그인 상태: $hasToken');
      return hasToken;
    } catch (e) {
      _logger.e('로그인 상태 확인 에러', error: e);
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      _logger.e('토큰 가져오기 에러', error: e);
      return null;
    }
  }
}
