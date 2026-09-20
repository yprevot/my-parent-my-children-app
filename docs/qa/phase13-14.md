# QA A13-A14 — accesibilidad y aceptación

Fecha: 2026-09-11.

## A13 implementado

- Texto de lectura expuesto como elemento semántico con instrucción clara para
  seleccionar palabra o rango.
- Progreso de importación y mensajes de estado marcados como regiones vivas.
- Control de tamaño de texto y velocidad con etiquetas accesibles.
- Página reordenable expuesta con estado y acción de arrastre.
- Selector de voz y controles visibles con etiquetas y ayudas en español.
- Prueba widget con texto ampliado al 200 % y prueba de etiqueta Semantics.

## A14 implementado

- Fixture de texto bilingüe existente para OCR.
- Prueba de lote de 50 páginas con aislamiento entre libros, orden y medición de
  persistencia menor de cinco segundos en memoria.
- Pruebas de recuperación de trabajos, errores aislados, reordenamiento y
  reprocesamiento sin pérdida del texto aprobado.
- Builds de emulador Android y simulador iOS ejecutados después de los cambios.

## Evidencia

- `scripts/flutterw analyze --no-pub`: sin issues.
- `scripts/flutterw test --no-pub`: 14 tests correctos.
- `scripts/flutterw build apk --debug`: correcto.
- `scripts/flutterw build ios --simulator --no-codesign`: correcto.

## Pendiente de aceptación final

La matriz física de TalkBack/VoiceOver, cámara, audio, bloqueo de pantalla,
auriculares, modo avión y tablet real se mantiene para el cierre con dispositivos.
