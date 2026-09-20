import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/features/auth/auth_service.dart';
import 'package:images_to_book/features/auth/auth_validators.dart';

void main() {
  group('AuthValidators.password', () {
    test('acepta contraseña válida', () {
      expect(AuthValidators.password('Segura1!'), isNull);
    });

    test('rechaza corta, sin mayúscula, sin minúscula, sin número y sin símbolo', () {
      expect(AuthValidators.password('Ab1!'), isNotNull); // corta
      expect(AuthValidators.password('segura1!'), isNotNull); // sin mayúscula
      expect(AuthValidators.password('SEGURA1!'), isNotNull); // sin minúscula
      expect(AuthValidators.password('Segura!!'), isNotNull); // sin número
      expect(AuthValidators.password('Segura12'), isNotNull); // sin símbolo
      expect(AuthValidators.password(''), isNotNull);
      expect(AuthValidators.password(null), isNotNull);
    });
  });

  group('AuthValidators.confirmPassword', () {
    test('coincide', () {
      expect(AuthValidators.confirmPassword('Segura1!', 'Segura1!'), isNull);
    });

    test('no coincide o vacía', () {
      expect(AuthValidators.confirmPassword('Otra1!', 'Segura1!'), isNotNull);
      expect(AuthValidators.confirmPassword('', 'Segura1!'), isNotNull);
    });
  });

  group('AuthValidators.email y name', () {
    test('email válido e inválidos', () {
      expect(AuthValidators.email('madre@ejemplo.com'), isNull);
      expect(AuthValidators.email('sin-arroba'), isNotNull);
      expect(AuthValidators.email(''), isNotNull);
    });

    test('nombre válido e inválidos', () {
      expect(AuthValidators.name('María'), isNull);
      expect(AuthValidators.name(''), isNotNull);
      expect(AuthValidators.name('A'), isNotNull);
    });
  });

  group('FakeInternetAuthService', () {
    test('registro -> sesión, duplicado falla, login y reset', () async {
      final service = FakeInternetAuthService();

      final user = await service.registerWithEmail(
        name: 'María',
        email: 'madre@ejemplo.com',
        password: 'Segura1!',
      );
      expect(user.email, 'madre@ejemplo.com');
      expect(service.currentUser, isNotNull);

      await expectLater(
        service.registerWithEmail(
          name: 'Otra',
          email: 'madre@ejemplo.com',
          password: 'Segura1!',
        ),
        throwsA(isA<AuthException>()),
      );

      await service.signOut();
      expect(service.currentUser, isNull);

      await expectLater(
        service.signInWithEmail(email: 'madre@ejemplo.com', password: 'Mal1!!!!'),
        throwsA(isA<AuthException>()),
      );

      final back = await service.signInWithEmail(
        email: 'madre@ejemplo.com',
        password: 'Segura1!',
      );
      expect(back.name, 'María');

      await service.sendPasswordReset(email: 'madre@ejemplo.com');
      await expectLater(
        service.sendPasswordReset(email: 'nadie@ejemplo.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('google devuelve usuario demo', () async {
      final service = FakeInternetAuthService();
      final user = await service.signInWithGoogle();
      expect(user.isGoogle, isTrue);
      expect(service.currentUser, isNotNull);
    });
  });
}
