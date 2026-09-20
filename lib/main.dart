import 'package:flutter/material.dart';

import 'core/storage/app_database.dart';
import 'core/sync/sync_api_client.dart';
import 'core/sync/sync_engine.dart';
import 'features/auth/auth_scope.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/library/library_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ImagesToBookBootstrap());
}

class ImagesToBookBootstrap extends StatefulWidget {
  const ImagesToBookBootstrap({super.key});
  @override
  State<ImagesToBookBootstrap> createState() => _ImagesToBookBootstrapState();
}

class _ImagesToBookBootstrapState extends State<ImagesToBookBootstrap> {
  late final Future<AppDatabase> _database = openAppDatabase();
  // Implementación temporal del backend en internet. Sustituir por el
  // cliente HTTP real sin cambiar las pantallas (mismo AuthService).
  final AuthService _authService = FakeInternetAuthService();
  final SyncApiClient _apiClient = HttpSyncApiClient();
  SyncEngine? _syncEngine;

  @override
  Widget build(BuildContext context) => AuthScope(
    service: _authService,
    child: FutureBuilder<AppDatabase>(
      future: _database,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ImagesToBookApp(home: _DatabaseError(error: snapshot.error));
        }
        if (!snapshot.hasData) {
          return const ImagesToBookApp(home: _LoadingScreen());
        }
        final database = snapshot.data!;
        _syncEngine ??= SyncEngine(
          database: database,
          authService: _authService,
          apiClient: _apiClient,
        );
        return ImagesToBookApp(
          home: AuthGate(
            signInScreen: const LoginScreen(),
            signedInBuilder: (_) => LibraryScreen(
              database: database,
              syncEngine: _syncEngine,
            ),
          ),
        );
      },
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _DatabaseError extends StatelessWidget {
  const _DatabaseError({this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Text('No se pudo abrir la biblioteca local.\n$error', textAlign: TextAlign.center))));
}

class ImagesToBookApp extends StatelessWidget {
  const ImagesToBookApp({super.key, this.home});
  final Widget? home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MySchoolMyParents Online',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4f46e5)),
      scaffoldBackgroundColor: const Color(0xfff7f7fc),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home: home,
  );
}
