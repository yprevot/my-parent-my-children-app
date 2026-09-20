import 'dart:async';

/// Usuario autenticado (lo que devuelve el backend).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.idToken,
    this.isGoogle = false,
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? idToken;
  final bool isGoogle;
  final bool isGuest;
}

/// Datos extraídos tras autenticar con Google.
class GoogleSignInPayload {
  const GoogleSignInPayload({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.idToken,
    this.serverAuthCode,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String idToken;
  final String? serverAuthCode;
}

/// Adaptador para desacoplar el plugin `google_sign_in` de la lógica de negocio.
abstract class GoogleSignInAdapter {
  Future<GoogleSignInPayload?> signIn();
  Future<void> signOut();
}

/// Error de autenticación con mensaje listo para mostrar en español.
class AuthException implements Exception {
  const AuthException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Contrato del backend de autenticación.
///
/// Hoy lo implementa [FakeInternetAuthService] (simula latencia de red y
/// guarda usuarios en memoria). Cuando exista el backend real, se sustituye
/// por una implementación HTTP con la misma firma, sin tocar las pantallas.
abstract class AuthService {
  Stream<AuthUser?> get userChanges;
  AuthUser? get currentUser;

  /// Obtiene el token de sesión o idToken para llamadas autenticadas al backend.
  Future<String?> getIdToken();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Inicia sesión con Google. La implementación real debe usar
  /// `google_sign_in` (obtener `idToken`) y verificarlo en el backend.
  Future<AuthUser> signInWithGoogle();

  /// Vincula la sesión actual (por ej. un invitado local) con una cuenta
  /// de Google para iniciar sincronización en la nube.
  Future<AuthUser> linkWithGoogle();

  /// Permite usar la app en modo local / sin conexión (invitado)
  /// sin requerir registro ni backend.
  Future<AuthUser> signInLocally();

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();
}

/// Implementación temporal que simula un backend en internet.
///
/// - Latencia artificial de ~800 ms por llamada.
/// - Usuarios en memoria (se pierden al reiniciar).
/// - Google devuelve un usuario demo; TODO: google_sign_in + verificación
///   del idToken en el backend real.
class FakeInternetAuthService implements AuthService {
  FakeInternetAuthService();

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  // email normalizado -> (nombre, contraseña, id)
  final Map<String, ({String name, String password, String id})> _users = {};

  @override
  Stream<AuthUser?> get userChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<String?> getIdToken() async => _user?.idToken;

  Future<T> _network<T>(FutureOr<T> Function() work) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return work();
  }

  Never _fail(String code, String message) => throw AuthException(code, message);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _network(() {
    final key = email.trim().toLowerCase();
    final record = _users[key];
    if (record == null) {
      _fail(
        'user-not-found',
        'No hay una cuenta con ese correo. Revisa el correo o crea una cuenta.',
      );
    }
    if (record.password != password) {
      _fail('wrong-password', 'La contraseña no es correcta. Inténtalo de nuevo.');
    }
    _user = AuthUser(
      id: record.id,
      name: record.name,
      email: key,
      idToken: 'jwt_token_${record.id}',
    );
    _controller.add(_user);
    return _user!;
  });

  @override
  Future<AuthUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _network(() {
    final key = email.trim().toLowerCase();
    if (_users.containsKey(key)) {
      _fail(
        'email-in-use',
        'Ese correo ya tiene una cuenta. Inicia sesión o recupera tu contraseña.',
      );
    }
    final user = AuthUser(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: key,
      idToken: 'jwt_token_new_user',
    );
    _users[key] = (name: user.name, password: password, id: user.id);
    _user = user;
    _controller.add(_user);
    return user;
  });

  @override
  Future<AuthUser> signInWithGoogle() => _network(() {
    // TODO(backend): sustituir por google_sign_in real. Flujo esperado:
    // 1. GoogleSignIn().signIn() -> GoogleSignInAccount
    // 2. account.authentication -> idToken
    // 3. POST backend /auth/google {idToken} -> verifica firma/audience
    // 4. backend crea/vincula usuario y devuelve sesión (AuthUser + token).
    _user = const AuthUser(
      id: 'google_demo',
      name: 'Cuenta de Google',
      email: 'usuario@gmail.com',
      idToken: 'google_id_token_demo',
      isGoogle: true,
    );
    _controller.add(_user);
    return _user!;
  });

  @override
  Future<AuthUser> linkWithGoogle() => _network(() {
    _user = AuthUser(
      id: _user?.isGuest == true
          ? 'u_${DateTime.now().microsecondsSinceEpoch}'
          : (_user?.id ?? 'google_linked'),
      name: 'Cuenta de Google Vinculada',
      email: 'usuario.vinculado@gmail.com',
      idToken: 'google_id_token_linked_${DateTime.now().millisecondsSinceEpoch}',
      isGoogle: true,
      isGuest: false,
    );
    _controller.add(_user);
    return _user!;
  });

  @override
  Future<AuthUser> signInLocally() async {
    _user = const AuthUser(
      id: 'local_guest',
      name: 'Invitado Local',
      email: 'local@device',
      isGuest: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordReset({required String email}) => _network(() {
    final key = email.trim().toLowerCase();
    if (!_users.containsKey(key)) {
      _fail(
        'user-not-found',
        'No hay una cuenta con ese correo. Revisa el correo o crea una cuenta.',
      );
    }
    // El backend real envía el correo aquí; el fake solo simula el envío.
  });

  @override
  Future<void> signOut() => _network(() {
    _user = null;
    _controller.add(null);
  });
}
