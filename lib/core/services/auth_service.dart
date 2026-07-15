import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Handles authentication via Google Sign-In → Supabase idToken exchange.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// NOTE: For Web, `serverClientId` is not supported and will throw an assertion error
  /// in `google_sign_in_web`. We pass `clientId` for Web and `serverClientId` for Android/iOS.
  static const String _webClientId =
      '164238123736-b3cfkqmtsdckq88gidcvgmvfjcigl46u.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    clientId: _webClientId,
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: ['email', 'profile'],
  );

  // ─── Getters ──────────────────────────────────────────────

  /// The currently signed-in Supabase user, or null if not signed in.
  User? get currentUser => supabase.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes (login, logout, token refresh).
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // ─── Google Sign-In ───────────────────────────────────────

  /// Native Google Sign-In dialog (Android/iOS) or OAuth Redirect (Web).
  ///
  /// Throws if sign-in is cancelled or idToken is unavailable.
  Future<AuthResponse?> signInWithGoogle() async {
    if (kIsWeb) {
      // Pada Flutter Web, google_sign_in terbaru tidak mengembalikan idToken
      // melalui metode signIn() biasa (hanya mengembalikan accessToken).
      // Pendekatan resmi dan terbaik dari Supabase untuk Web adalah signInWithOAuth.
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:5000',
      );
      // Karena signInWithOAuth di Web melakukan redirect halaman,
      // kita return null. Supabase otomatis menyimpan sesi saat kembali.
      return null;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign-in dibatalkan');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception(
        'Tidak dapat memperoleh ID token dari Google.\n'
        'Pastikan serverClientId di auth_service.dart adalah '
        'Web Client ID yang terdaftar di Supabase Dashboard → Auth → Providers → Google.',
      );
    }

    return await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // ─── Sign Out ─────────────────────────────────────────────

  /// Sign out from Google and Supabase.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await supabase.auth.signOut();
  }
}
