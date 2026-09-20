# QA fase 1 — captura y construcción del libro

Fecha: 2026-09-11.

## Evidencia automatizada

- `scripts/flutterw analyze --no-pub`: sin issues.
- `scripts/flutterw test --no-pub`: 12 tests correctos.
- `scripts/flutterw build apk --debug`: APK generado correctamente.
- `test/storage_test.dart` cubre recuperación de trabajos, conteo de intentos,
  error final por página, reprocesamiento conservando el texto aprobado y
  reordenamiento de páginas con sus párrafos.

## Funcionalidad cerrada en código

- Importación de varias fotos y fotos sucesivas dentro de un libro.
- Persistencia de página y trabajo antes de ejecutar OCR.
- Recuperación de trabajos `processing` al reiniciar.
- Worker OCR local con estados `queued`, `processing`, `review`, `approved` y
  `failed`, tres intentos y backoff de 1, 2 y 4 segundos.
- Error aislado por foto, sin bloquear el resto del libro.
- Recorte centrado y rotación de 90 grados antes de OCR.
- Reordenamiento visual de páginas y normalización del orden de párrafos.
- Reprocesamiento de una página aprobada conservando su texto anterior hasta que
  el adulto aprueba el nuevo borrador.
- Revisión y aprobación transaccional antes de añadir texto audible.

## Validación manual pendiente (reservada para el cierre)

- Conectar el dispositivo físico disponible al cierre y comprobar permisos, cámara, galería,
  rotación de fotos y OCR con páginas reales.
- Repetir el recorrido con cierre forzado y modo avión.
- Verificar que el audio local y la voz inglesa instalada funcionen en el mismo
  dispositivo.
