import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Dio _dio = Dio();

  // API 베이스 URL (나중에 백엔드 URL로 변경)
  static const String baseUrl = 'http://your-backend-api.com';

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      // 1. 구글 로그인 팝업
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 취소함
        return false;
      }

      // 2. 구글 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return false;
      }

      // 3. 백엔드 API로 토큰 전송
      final response = await _dio.post(
        '$baseUrl/auth/social-login',
        data: {
          'provider': 'google',
          'token': idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
        },
      );

      // 4. JWT 토큰 저장
      if (response.statusCode == 200) {
        final String jwtToken = response.data['accessToken'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', jwtToken);
        return true;
      }

      return false;
    } catch (e) {
      print('구글 로그인 에러: $e');
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('jwt_token');
  }
}
