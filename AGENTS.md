# Antigravity Rules for MySchoolMyParents Online

## Reglas Obligatorias del Proyecto

1. **Nombre del Instalador y Artefactos de Distribución**:
   - NUNCA compartir ni distribuir instaladores con nombres genéricos como `app-release.apk`.
   - SIEMPRE nombrar el APK con el nombre de la app y la versión:
     `MySchoolMyParents-Online-v<versionName>+<versionCode>.apk` y `MySchoolMyParents-Online-v<versionName>.apk`.
   - Colocar los artefactos finales en `dist/` y en la carpeta del servidor web local.

2. **Visibilidad de la Versión dentro de la App**:
   - La versión DEBE ser visible dentro de la app:
     - En el `AppBar` de `LibraryScreen` (bajo el título).
     - En el diálogo modal de información ("Acerca de") en `LibraryScreen`.
     - En el pie de página de `LoginScreen`.
   - Usar siempre `AppVersion.displayString` de `lib/core/config/app_version.dart`.

3. **Versionado e Instalación In-Place en Android**:
   - Incrementar el `versionCode` (el número después de `+` en `pubspec.yaml`, ej. `0.2.3+4`) con cada cambio distribuible.
   - De esta forma, Android actualiza la aplicación existente sin obligar al usuario a desinstalarla.
