import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // If you also want to support Web, you must pass the Web Client ID here
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '164238123736-b3cfkqmtsdckq88gidcvgmvfjcigl46u.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Sign in with Google OAuth (Direct via GCP, no Firebase)
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
      }
      return _currentUser;
    } catch (e) {
      // Silently handle sign-in errors
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Check if previously signed in (silent sign-in)
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
      }
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Get Google Auth headers for API requests
  Future<Map<String, String>?> getAuthHeaders() async {
    if (_currentUser == null) return null;
    return await _currentUser!.authHeaders;
  }
}
