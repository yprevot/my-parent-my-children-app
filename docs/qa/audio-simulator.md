# QA A09-A12 — audio y posición de lectura

Fecha: 2026-09-11.

## Implementado

- Catálogo de voces locales filtrado por idioma y voces Android que no requieren red.
- Selector de voz por libro y velocidad persistida en SQLite.
- Reproducción segmentada con párrafo activo y rangos de progreso.
- Lectura de libro, párrafo, palabra y selección con el mismo adaptador.
- Posición de párrafo y offset guardada con debounce para continuar después.
- Pausa al abandonar la app y reanudación con la sesión vigente.
- Migración Drift de esquema 2 a 3 para preferencias y posición.

## Evidencia de compilación

- `scripts/flutterw analyze --no-pub`: sin issues.
- `scripts/flutterw test --no-pub`: 12 tests correctos.
- `scripts/flutterw build apk --debug`: correcto.
- `scripts/flutterw build ios --simulator --no-codesign`: correcto.

## Pendiente de simulador/dispositivo

- El emulador Android disponible no tiene una voz inglesa local instalada, por lo
  que el audio audible no se puede declarar probado allí.
- Falta recorrer el selector y la lectura en el simulador iOS.
- La prueba audible, bloqueo de pantalla, auriculares y modo avión se reserva para
  el dispositivo físico al cierre de G0/G3.
