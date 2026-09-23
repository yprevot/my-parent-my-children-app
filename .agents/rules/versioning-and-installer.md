# Regla de Versionado y Nombres de Instalador

Toda compilación o distribución para el usuario final debe cumplir con:

1. El archivo APK resultante debe llamarse obligatoriamente `MySchoolMyParents-Online-v<version>.apk` (ej. `MySchoolMyParents-Online-v0.2.3+4.apk` o `MySchoolMyParents-Online-v0.2.3.apk`). No usar `app-release.apk` para entrega al usuario.
2. La versión de la app debe ser visible dentro de la app en la pantalla principal (`LibraryScreen`), en el modal "Acerca de" y en la pantalla de inicio de sesión (`LoginScreen`).
3. Siempre incrementar el número de compilación (`+buildNumber` en `pubspec.yaml`) para permitir actualizaciones sin desinstalar.
