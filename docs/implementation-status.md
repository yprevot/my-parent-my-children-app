# Estado de implementación

Última actualización: 2026-09-11.
Hito actual: M2 implementado en código; G2 pendiente de validación física.
Tareas implementadas: A01–A08; A05–A08 quedan en revisión de aceptación manual.
Responsable: agente integrador; esfuerzo alto.

## Implementado en A00–A04

- Proyecto Flutter para Android/iOS, cámara, selección múltiple y ejemplo propio.
- OCR local mediante puente nativo; texto bruto y párrafos de una columna.
- Revisión de texto durante la sesión; lectura de texto, párrafo y selección.
- Selección por offset UTF-16, controles de voz, velocidad y pausa/reanudación.
- Pruebas unitarias, de widgets y de integración nativa.
- Drift/SQLite local con libros, páginas y párrafos, transacciones y borrado aislado.
- Biblioteca adaptable para crear, abrir, renombrar y borrar libros.
- Flujo de añadir fotos dentro del libro y lectura del contenido persistido.
- Trabajos y borradores OCR persistidos; el adulto puede revisar, editar y aprobar
  una página antes de que sus párrafos entren al libro.

## Límites de alcance

La fase 1 está cerrada en código: incluye worker recuperable, reintentos con backoff,
estado de error por foto, recorte centrado, rotación, reordenamiento y
reprocesamiento que conserva el texto aprobado hasta una nueva aprobación. Las
fotos se copian a almacenamiento privado y las referencias, trabajos, borradores y
párrafos aprobados se guardan en SQLite.

A09–A14 están implementadas en código y en revisión de simulador. A15 permanece TODO. A16 queda planificada como fase 3 opcional para cuenta adulta
con Google y sincronización. G0, G1 y G2 todavía no se declaran completas porque la prueba física en Android/iOS
se ha pospuesto deliberadamente. Continuaremos con simulador iOS y emulador Android;
la cámara, OCR y voz en equipos reales se validarán al final.

## Validación en curso

El resultado está registrado en `docs/qa/spike.md`, `docs/qa/phase1.md`, `docs/qa/audio-simulator.md`, `docs/qa/phase13-14.md`, `docs/handoffs/A01-A04.md` y `docs/handoffs/A05-A08.md`.
La adaptación OCR está en `docs/adr/0001-ocr-nativo-por-plataforma.md`.

## Recurso pendiente

El usuario dispone de un Samsung Galaxy S25 Ultra para la prueba física, pero no
está conectado todavía a este entorno. La comprobación de cámara real, audio oído
y disponibilidad sin red deberá distinguirse de callbacks y simuladores.

El dominio canónico reservado es `myschoolmyparents.online`; falta configurar sus credenciales OAuth cuando comience A16.

El logo generado para MySchoolMyParents se encuentra en
`assets/branding/my_school_my_parents_logo.png` y ya está integrado en la pantalla de
biblioteca.
