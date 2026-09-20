import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/features/auth/auth_scope.dart';
import 'package:images_to_book/features/auth/auth_service.dart';
import 'package:images_to_book/features/auth/login_screen.dart';

/// Flujos de navegación entre login, registro y recuperación.
void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    // Superficie alta para que todos los botones queden visibles sin scroll.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        service: FakeInternetAuthService(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login muestra accesos a registro y recuperación', (tester) async {
    await pumpLogin(tester);
    expect(find.text('Hola de nuevo'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('ir a registro y volver al login', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Hola de nuevo'), findsOneWidget);
  });

  testWidgets('registro avisa si las contraseñas no coinciden', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre').first, 'María');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico').first,
      'madre@ejemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña').first,
      'Segura1!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña').first,
      'Distinta1!',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('registro válido crea sesión y vuelve', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre').first, 'María');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico').first,
      'madre@ejemplo.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña').first,
      'Segura1!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña').first,
      'Segura1!',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    // Avanza más allá de la latencia simulada sin quedar atrapado en el
    // spinner de progreso (animación infinita para pumpAndSettle).
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    // Registro exitoso: se cierra la pantalla y vuelve al login.
    expect(find.text('Hola de nuevo'), findsOneWidget);
  });

  testWidgets('recuperación envía enlace y ofrece volver', (tester) async {
    // Avances acotados en vez de pumpAndSettle: evitan quedar atrapados en
    // animaciones en curso (transiciones, spinners).
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
    }

    final service = FakeInternetAuthService();
    // Fuera de pump el reloj es falso: los delays simulados del fake solo
    // avanzan con tiempo real vía runAsync.
    await tester.runAsync(() async {
      await service.registerWithEmail(
        name: 'María',
        email: 'madre@ejemplo.com',
        password: 'Segura1!',
      );
      await service.signOut();
    });
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      AuthScope(
        service: service,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await settle();

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await settle();
    expect(find.text('Recupera tu acceso'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico').first,
      'madre@ejemplo.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar enlace'));
    await settle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text('Volver a iniciar sesión'), findsOneWidget);
  });
}
