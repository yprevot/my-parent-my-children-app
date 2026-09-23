import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/core/config/app_version.dart';

void main() {
  group('AppVersion', () {
    test('Contiene metadatos correctos de la aplicación', () {
      expect(AppVersion.appName, 'MySchoolMyParents Online');
      expect(AppVersion.version, '0.2.3');
      expect(AppVersion.buildNumber, '4');
      expect(AppVersion.defaultDisplayString, 'v0.2.3 (Build 4)');
      expect(AppVersion.shortDisplayString, 'v0.2.3');
    });

    test('Genera nombres de instalador consistentes con las reglas del proyecto', () {
      expect(AppVersion.installerApkName, 'MySchoolMyParents-Online-v0.2.3+4.apk');
      expect(AppVersion.installerFriendlyName, 'MySchoolMyParents-Online-v0.2.3.apk');
    });

    test('Provee displayString por defecto de forma síncrona', () {
      expect(AppVersion.displayString, contains('0.2.3'));
      expect(AppVersion.displayString, contains('4'));
    });
  });
}
