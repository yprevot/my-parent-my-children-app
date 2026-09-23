import 'package:flutter/material.dart';

import 'core/config/app_version.dart';
import 'core/storage/app_database.dart';
import 'core/sync/sync_api_client.dart';
import 'core/sync/sync_engine.dart';
import 'features/auth/auth_scope.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_screen.dart';
import 'features/library/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.init();
  runApp(const MySchoolMyParentsBootstrap());
}

class MySchoolMyParentsBootstrap extends StatefulWidget {
  const MySchoolMyParentsBootstrap({super.key});
  @override
  State<MySchoolMyParentsBootstrap> createState() => _MySchoolMyParentsBootstrapState();
}

class _MySchoolMyParentsBootstrapState extends State<MySchoolMyParentsBootstrap> {
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
          return MySchoolMyParentsApp(home: _DatabaseError(error: snapshot.error));
        }
        if (!snapshot.hasData) {
          return const MySchoolMyParentsApp(home: _LoadingScreen());
        }
        final database = snapshot.data!;
        _syncEngine ??= SyncEngine(
          database: database,
          authService: _authService,
          apiClient: _apiClient,
        );
        return MySchoolMyParentsApp(
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

class MySchoolMyParentsApp extends StatelessWidget {
  const MySchoolMyParentsApp({super.key, this.home});
  final Widget? home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MySchoolMyParents Online',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff1d4ed8),
        primary: const Color(0xff1d4ed8),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xffdbeafe),
        onPrimaryContainer: const Color(0xff1e3a8a),
        secondary: const Color(0xffd97706),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xfffef3c7),
        onSecondaryContainer: const Color(0xff78350f),
        tertiary: const Color(0xff059669),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xffd1fae5),
        onTertiaryContainer: const Color(0xff064e3b),
        surface: const Color(0xfffdfbf7),
        onSurface: const Color(0xff1e293b),
        surfaceContainerLow: const Color(0xfff8f4ec),
        surfaceContainer: const Color(0xfff2ede2),
        outlineVariant: const Color(0xffe8e2d8),
      ),
      scaffoldBackgroundColor: const Color(0xfffdfbf7),
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: const Color(0x120f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xffede6db), width: 1),
        ),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfffdfbf7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xff1e293b),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xff1d4ed8),
        unselectedLabelColor: Color(0xff64748b),
        indicatorColor: Color(0xff1d4ed8),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xfff59e0b),
        foregroundColor: const Color(0xff1e293b),
        elevation: 2.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffe2d9cd)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff1d4ed8), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: Color(0xffcbd5e1), width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xff1e293b),
      ),
    ),
    home: home,
  );
}
