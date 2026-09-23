# Reglas Oficiales del Proyecto: MySchoolMyParents Online

Este documento establece las reglas obligatorias de desarrollo, versionado y distribución de la aplicación. Todos los desarrolladores y agentes de IA deben cumplir con estas directrices de forma estricta.

---

## 1. Regla de Nombres de Instaladores y Artefactos

1. **Prohibición de nombres genéricos**:
   - Queda terminantemente prohibido distribuir, publicar o compartir instaladores con nombres genéricos como `app-release.apk`, `app-debug.apk`, o `runner.ipa`.

2. **Nomenclatura oficial del instalador**:
   - Todo paquete de distribución Android (APK) debe incluir el nombre oficial de la aplicación y la versión exacta:
     ```text
     MySchoolMyParents-Online-v<versionName>+<versionCode>.apk
     ```
     Ejemplo: `MySchoolMyParents-Online-v0.2.3+4.apk`
   - Para enlaces directos de descarga amigable, también se debe proveer el alias:
     ```text
     MySchoolMyParents-Online-v<versionName>.apk
     ```
     Ejemplo: `MySchoolMyParents-Online-v0.2.3.apk`

3. **Ubicaciones de salida**:
   - Los instaladores generados deben copiarse a:
     - `dist/MySchoolMyParents-Online-v<version>+<build>.apk`
     - `dist/MySchoolMyParents-Online-v<version>.apk`
     - `build/app/outputs/flutter-apk/MySchoolMyParents-Online-v<version>.apk`

---

## 2. Regla de Visibilidad de la Versión dentro de la App

La versión de la aplicación no es un secreto técnico; es información crítica para padres, educadores y soporte:

1. **Pantalla Principal (`LibraryScreen`)**:
   - El encabezado (`AppBar`) debe mostrar la versión de la app (`AppVersion.displayString`) debajo del título "Mis libros".
   - Debe existir un botón de información (`Icons.info_outline_rounded`) en la barra de acciones que abre el modal "Acerca de la app", mostrando:
     - Logotipo oficial de la app.
     - Nombre oficial (`MySchoolMyParents Online`).
     - Versión y compilación (`v0.2.3 (Build 4)`).
     - Estado de sincronización (Nube / Local).

2. **Pantalla de Bienvenida / Acceso (`LoginScreen`)**:
   - En el pie de página de inicio de sesión debe figurar visiblemente la versión actual.

3. **Centralización en `AppVersion` (`lib/core/config/app_version.dart`)**:
   - Toda visualización de versión debe alimentarse de `AppVersion`, el cual lee dinámicamente de la plataforma (`PackageInfo.fromPlatform()`) con respaldo en las constantes sincronizadas con `pubspec.yaml`.

---

## 3. Regla de Incremento de Versión y Actualización In-Place

1. **Actualización sin fricción**:
   - Cada entrega, corrección o nueva funcionalidad debe incrementar el número de compilación (`versionCode` / `+buildNumber`) en `pubspec.yaml` (ej. de `0.2.2+3` a `0.2.3+4`).
   - Esto garantiza que el instalador de Android permita actualizar la aplicación directamente ("Actualizar") sin necesidad de que el usuario deba desinstalar la versión previa ni perder sus libros locales.

---

## 4. Script Estándar de Compilación

Para generar instaladores conformes a estas reglas:
```bash
./scripts/build_release_apk.sh
```
Este script extrae la versión de `pubspec.yaml`, ejecuta la compilación de lanzamiento con OpenJDK 17 y nombra automáticamente todos los artefactos en `dist/` y en el servidor local.
