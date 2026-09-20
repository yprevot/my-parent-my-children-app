# A00/A01-A04 — evidencia de implementación

Fecha: 2026-09-11.

## Evidencia automatizada

- `scripts/flutterw analyze --no-pub`: sin errores tras el último ajuste.
- `scripts/flutterw test --no-pub`: 6 pruebas de texto/selección y 2 pruebas de persistencia.
- `scripts/flutterw build apk --debug`: APK Android generado en `build/app/outputs/flutter-apk/app-debug.apk`.
- APK instalado y proceso iniciado en el emulador Android `emulator-5554`.
- `scripts/flutterw build ios --simulator --debug`: compilación iOS generada en `build/ios/iphonesimulator/Runner.app`.

## Cobertura implementada

- A00: OCR/TTS y selección de texto como adaptadores de prueba.
- A01: primeras entidades y operaciones de almacenamiento local.
- A02: tema Material 3, diseño adaptable y controles accesibles.
- A03: SQLite/Drift con transacción de página y párrafos, actualización reactiva y borrado por libro.
- A04: biblioteca, creación, renombrado, eliminación y apertura de libros.

## Pendientes de esta evidencia

- La prueba nativa de Android no completó TTS porque el emulador no tenía una voz inglesa local disponible.
- La prueba nativa de iOS no quedó ejecutable en el simulador disponible; la combinación inicial con ML Kit presentó incompatibilidad arm64 y Apple Vision quedó preparado como sustituto.
- No hay dispositivos físicos conectados. Cámara, audio audible, modo avión, VoiceOver/TalkBack y comportamiento de tablet real siguen sin evidencia.
- Las páginas se insertan directamente como contenido aprobado en esta iteración; la cola persistida, revisión editorial separada, reintentos y reprocesamiento sin sobrescribir correcciones corresponden a A05-A08.
