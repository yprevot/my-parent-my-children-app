import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Gestión centralizada de versión y metadatos de la aplicación.
///
/// Cumple con la regla del proyecto:
/// - La versión y número de compilación deben estar siempre sincronizados y ser visibles al usuario en la UI.
/// - Los instaladores deben generarse con el nombre de la app y la versión:
///   `MySchoolMyParents-Online-v<versionName>+<versionCode>.apk`.
class AppVersion {
  AppVersion._();

  static const String appName = 'MySchoolMyParents Online';
  static const String version = '0.2.3';
  static const String buildNumber = '4';

  static String? _cachedDisplayString;

  /// Texto amigable de versión por defecto: ej. `v0.2.3 (Build 4)`.
  static String get defaultDisplayString => 'v$version (Build $buildNumber)';

  /// Texto corto de versión: ej. `v0.2.3`.
  static String get shortDisplayString => 'v$version';

  /// Nombre del instalador APK generado según las reglas del proyecto.
  static String get installerApkName => 'MySchoolMyParents-Online-v$version+$buildNumber.apk';

  /// Nombre amigable simplificado para distribución directa.
  static String get installerFriendlyName => 'MySchoolMyParents-Online-v$version.apk';

  /// Devuelve el texto de versión actual (desde la plataforma nativa si está disponible,
  /// o desde las constantes de compilación).
  static String get displayString => _cachedDisplayString ?? defaultDisplayString;

  /// Inicializa la lectura asíncrona de metadatos desde el paquete nativo Android / iOS.
  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.isNotEmpty ? info.version : version;
      final b = info.buildNumber.isNotEmpty ? info.buildNumber : buildNumber;
      _cachedDisplayString = 'v$v (Build $b)';
    } catch (_) {
      _cachedDisplayString = defaultDisplayString;
    }
  }

  /// Muestra un diálogo modal informativo con los datos y versión de la aplicación.
  static void showAboutDialog(BuildContext context, {String? syncStatus}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/branding/my_school_my_parents_logo.png',
                  width: 64,
                  height: 64,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff0f172a),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xffbfdbfe),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  displayString,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1d4ed8),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Lectura comprensiva interactiva y bilingüe para niños y familias. Transforma fotos de libros escolares en audio-lecturas con karaoke palabra por palabra.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xff475569),
                ),
              ),
              if (syncStatus != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync_rounded, size: 16, color: Color(0xff64748b)),
                      const SizedBox(width: 6),
                      Text(
                        syncStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
