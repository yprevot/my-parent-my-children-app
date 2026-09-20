# MySchoolMyParents — Plan de construcción

Fecha: 11 de septiembre de 2026. Versión: 1.0. Idioma de trabajo: español.

**Estado: plan base aprobado; implementación en curso.** La fase 1 está cerrada en código y su aceptación física sigue pendiente. El requerimiento original y las instrucciones reutilizables para agentes están en [PROMPT.md](PROMPT.md).

**Alcance de esta entrega:** conservar `PLAN.md` y `PROMPT.md` como documentos operativos y entregar una primera versión funcional de MySchoolMyParents, compilable para Android/iOS, antes de ampliar el producto a beta y sincronización.

## 1. Objetivo y resultado esperado

Construir una app para iOS y Android, usable en teléfono y tablet, que permita a una familia convertir fotos de textos impresos en libros personales y escuchar su contenido en el idioma que está aprendiendo.

Caso inicial: padres e hijo hablan español; los padres tienen inglés básico y el hijo empieza a leer español, pero recibe libros escolares en inglés. La interfaz debe ayudar al adulto en español, mientras reproduce el texto del libro en inglés.

El recorrido esencial es: **crear libro → tomar varias fotos o seleccionar muchas imágenes → extraer y revisar texto → incorporarlo en orden → escuchar libro, párrafo o palabra → cerrar y continuar después**.

La fase de audio tiene la misma prioridad que la de captura. Tener OCR sin lectura granular no constituye el producto mínimo completo.

### 1.1 Idiomas y significado de «libro»

- `learningLocale` representa el idioma X que se aprende; inicialmente `en-US`, con opción `en-GB` según voces disponibles.
- `homeLocale` representa el idioma Y de la familia; inicialmente `es-MX`. La interfaz inicial estará en español.
- El idioma de la interfaz, el del texto y el de la voz son ajustes independientes. Nunca elegir una voz española para texto inglés porque el teléfono esté configurado en español.
- La estructura admite otros pares de idiomas, pero cada nuevo idioma debe superar pruebas de escritura, OCR, segmentación y voz. No se promete cobertura universal.
- Un libro es una colección local de páginas capturadas y párrafos editables, con orden, idioma, preferencias de voz y posición de lectura. El lector muestra texto que se adapta a la pantalla; no es necesario imitar la paginación del libro físico.
- PDF, EPUB, traducción y audiolibros exportables no son requisitos de las dos primeras fases.

## 2. Alcance del producto mínimo

### Fase 1 — Construir libros a partir de fotos

1. Crear, nombrar, abrir, renombrar y eliminar libros independientes.
2. Elegir idioma del texto al crear el libro; permitir cambiarlo después.
3. Seleccionar múltiples imágenes en una operación o tomar fotos sucesivas dentro del mismo libro.
4. Mostrar miniaturas y permitir ordenar las imágenes antes de procesarlas.
5. Guardar cada foto en almacenamiento persistente y asignarle posición antes de iniciar OCR.
6. Permitir rotar y recortar manualmente; conservar la imagen original para rehacer el procesamiento.
7. Procesar una cola con progreso por foto, cancelación, errores individuales y reintentos.
8. Mostrar texto extraído junto a la imagen para corregir palabras, separar/unir párrafos de una página y excluir encabezados o números de página.
9. Incorporar el texto revisado al libro sin sobrescribir las páginas anteriores. Permitir aprobar un lote tras revisar sus resultados.
10. Reordenar páginas y párrafos dentro de su página; eliminar una captura con una advertencia concreta sobre el texto asociado.
11. Recuperar libros, borradores y trabajos pendientes después de cerrar o reiniciar la app.

Las páginas se guardan como borrador al importarse; sus párrafos aparecen en el libro al aprobar la revisión. El OCR no exige esperar a que termine toda la cola para revisar una página terminada. Aprobar no cambia el orden reservado de las capturas.

### Fase 2 — Escuchar y practicar

1. Leer todo el libro siguiendo el orden de páginas y párrafos aprobados.
2. Reproducir un párrafo con un botón visible junto a él.
3. Tocar una palabra para seleccionarla y mostrar «Escuchar palabra» y «Repetir».
4. Mantener selección por pulsación prolongada para escuchar una selección de texto dentro de un párrafo.
5. Ofrecer reproducir, pausar, continuar, detener, anterior/siguiente párrafo y repetir.
6. Ofrecer velocidades «Más lento», «Normal» y «Más rápido», calibradas para cada motor. No presentar multiplicadores de velocidad exactos si el motor no permite garantizarlos.
7. Elegir y probar voces compatibles con el idioma del libro; guardar la elección por libro.
8. Resaltar el párrafo activo. Resaltar palabras solo si el motor entrega rangos de progreso fiables.
9. Recordar la posición de lectura por libro. Al reabrir, ofrecer continuar sin iniciar audio automáticamente.
10. Funcionar sin conexión cuando el modelo OCR y la voz local necesaria estén disponibles y se haya verificado el funcionamiento en ese dispositivo.

### Fuera de las primeras dos fases

Traducción automática, evaluación de pronunciación, grabación del niño, chatbot, ejercicios generados, cuentas infantiles, comunidad, publicidad, pagos, exportación EPUB/PDF/audio y lectura en segundo plano con controles de pantalla bloqueada. La cuenta del adulto con Google y la sincronización se evalúan como fase 3 después de completar y probar las dos fases esenciales.

### Fase 3 opcional — cuenta y sincronización familiar

La autenticación con Google tiene sentido cuando permite respaldar y sincronizar
libros entre el teléfono y una tablet. No será requisito para usar la aplicación
localmente ni para importar o leer libros sin conexión.

- La app se inicia en modo local sin cuenta.
- El adulto puede elegir «Continuar con Google» desde Ajustes.
- Al autenticarse, se ofrece subir los libros locales y se evita fusionar datos sin
  una revisión explícita.
- La cuenta no se comparte con el perfil infantil; la aplicación no necesita
  cuentas infantiles en esta fase.
- El backend debe almacenar solo los datos necesarios, permitir borrar cuenta y
  datos, aplicar reglas por usuario y resolver conflictos por libro y página.
- El contenido local seguirá disponible si la sesión caduca o no hay conexión.

La implementación recomendada es una interfaz `AuthProvider` desacoplada de la UI,
con Google como proveedor inicial. Firebase Authentication con el proveedor Google
es la primera opción práctica para Android/iOS; Supabase Auth es una alternativa si
se desea controlar más el backend. La decisión final se tomará al empezar A16,
cuando se definan sincronización, privacidad, costes y retención de imágenes.

## 3. Decisiones tecnológicas

### 3.1 Arquitectura recomendada

**Flutter + Dart, almacenamiento local con SQLite y adaptadores nativos para OCR y voz.** Es una elección de arquitectura para este proyecto: una base de código para ambas plataformas, control del diseño de lectura y acceso a capacidades nativas. Flutter documenta la adaptación a tamaño, orientación y métodos de entrada. [Diseño adaptable en Flutter](https://docs.flutter.dev/ui/adaptive-responsive).

| Área | Tecnología propuesta | Decisión y límite |
|---|---|---|
| App | Flutter estable y Dart incluido en ese SDK | Fijar versión exacta al superar G0; no usar versiones beta por defecto. |
| Estado e inyección | Riverpod | Controladores por funcionalidad, dependencias sustituibles en pruebas. [Documentación](https://riverpod.dev/). |
| Navegación | `go_router` | Rutas de biblioteca, libro, importación, revisión, lector y ajustes. [Paquete mantenido por Flutter](https://pub.dev/packages/go_router). |
| Persistencia | Drift sobre SQLite | Esquema tipado, transacciones y migraciones verificables. [Documentación](https://drift.simonbinder.eu/). |
| Fotos | `image_picker` | Selección múltiple y cámara invocada repetidamente conservando el libro activo. [Documentación](https://pub.dev/packages/image_picker). |
| Recorte | Adaptador de transformación de imagen | Resolver paquete mantenido o código nativo mínimo en G0; verificar orientación y coordenadas. No asumir capacidades de escáner automático. |
| OCR | ML Kit Text Recognition v2, modelo latino | Adaptador Flutter mediante `google_mlkit_text_recognition`. El puente es comunitario, no mantenido por Google. [SDK](https://developers.google.com/ml-kit/vision/text-recognition/v2), [puente Flutter](https://pub.dev/packages/google_mlkit_text_recognition). |
| Voz | `flutter_tts` encapsulado | Acceso a las voces del sistema; pequeñas extensiones Kotlin/Swift si las capacidades necesarias no están expuestas. [Documentación](https://pub.dev/packages/flutter_tts). |
| Internacionalización | `flutter_localizations`, recursos ARB y `intl` | Interfaz española inicialmente; contenido y voz con etiquetas BCP-47. |
| Verificación | `flutter_test`, `integration_test`, pruebas nativas donde corresponda | Pruebas de dominio, persistencia, widgets y recorridos reales. |
| Automatización | Scripts locales; CI en GitHub Actions si el repositorio se hospeda allí | Linux para análisis/Android y macOS para compilar iOS. No depender de la publicación en tiendas para ejecutar pruebas. |

No se requiere backend ni credencial de IA para el producto mínimo. No se usará un modelo generativo para reescribir o completar el texto del libro.

### 3.2 Compatibilidad y versiones

- Objetivo inicial: Android 8.0/API 26 o posterior e iOS/iPadOS 15.5 o posterior, sujeto a validación conjunta de dependencias en G0.
- Android API 26 es una decisión del producto para disponer de la API de rangos de voz; no garantiza que todos los motores emitan esos eventos. [API de progreso de Android](https://developer.android.com/reference/android/speech/tts/UtteranceProgressListener).
- El puente OCR consultado declara iOS 15.5 como mínimo. Sus requisitos deben contrastarse con los SDK nativos y la versión de Flutter elegida. [Requisitos del puente](https://pub.dev/packages/google_mlkit_text_recognition).
- No copiar ciegamente `minSdk`, `targetSdk`, Kotlin, Gradle o Xcode de ejemplos de plugins: sus documentos pueden reflejar versiones distintas. Resolver la combinación real compilando ambas plataformas.
- Fijar Flutter, dependencias, `pubspec.lock`, archivos de resolución nativos aplicables y Gradle Wrapper. Registrar la matriz exacta en `docs/toolchain.md`.
- Revisar el objetivo de SDK y los requisitos de las tiendas en el momento de preparar una publicación, sin inventar requisitos futuros.

### 3.3 Proveedores de lectura recomendados

| Opción | Plataformas | Uso en este proyecto | Aspectos que comprobar |
|---|---|---|---|
| Android `TextToSpeech` | Android | Primera opción. Usar motor local instalado; permitir elegir Google si está disponible. | No todos los dispositivos incluyen el motor de Google. Enumerar idiomas, voces y necesidad de red. |
| Apple `AVSpeechSynthesizer` | iPhone/iPad | Primera opción en iOS. Elegir voz por idioma y disponibilidad. | Catálogo instalado, comportamiento de audio y voz sin conexión en dispositivos reales. |
| Google Cloud Text-to-Speech | Ambas mediante backend | Primera alternativa futura para una voz consistente entre plataformas o audio persistente. | Conexión, facturación, cuotas, privacidad, caché y capacidades de la voz concreta. |
| Azure AI Speech | Ambas mediante backend | Alternativa futura para comparar calidad y herramientas de síntesis. | Comparar voces inglesas con el mismo corpus; verificar SSML y eventos para la voz elegida. |

Android ofrece una API de síntesis y una propiedad para identificar voces que requieren conexión. Google Cloud TTS es un servicio distinto del motor instalado en Android. [Android TTS](https://developer.android.com/reference/android/speech/tts/TextToSpeech), [Voice](https://developer.android.com/reference/android/speech/tts/Voice).

Apple permite controlar una cola de enunciados mediante su sintetizador. Google Cloud produce audio a partir de texto o SSML; Azure ofrece síntesis con voces y opciones que varían según el modelo. [Apple](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer), [Google Cloud](https://cloud.google.com/text-to-speech/docs/basics), [Azure](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/text-to-speech).

**Elección inicial:** voces locales. **Elección futura si se necesita uniformidad:** comparar Google Cloud y Azure con una prueba de escucha del adulto. No hay motivo para pagar llamadas a la nube antes de validar el producto local.

Si se incorpora nube, crear un backend autenticado que conserve credenciales en el servidor, aplique cuotas por usuario y permita borrar datos. El coste deberá estimarse con precios vigentes, caracteres facturables y caché; este plan no presupone una tarifa ni uso gratuito ilimitado.

## 4. Experiencia de uso y diseño adaptable

La dirección visual propuesta es una biblioteca tranquila: fondo claro, texto oscuro, acento índigo, controles reconocibles y pocas distracciones. La estética infantil no debe dificultar la revisión del adulto ni competir con las palabras del libro.

| Pantalla | Acción principal | Estados necesarios |
|---|---|---|
| Biblioteca | «Crear libro» o «Continuar leyendo» | Vacía con explicación breve, libros existentes, error recuperable. |
| Nuevo libro | Título e idioma del texto | Validación de título; inglés preseleccionado y editable. |
| Libro | «Añadir fotos» / «Leer» | Sin páginas, páginas pendientes, listo para leer, trabajo en curso. |
| Añadir fotos | «Tomar foto» / «Elegir fotos» | Permiso rechazado, cancelación normal, selección múltiple, recuperación tras cierre. |
| Cola | Revisar resultados disponibles | Progreso por imagen, error aislado, reintentar, cancelar pendientes. |
| Revisar | Comparar foto y texto; «Añadir al libro» | Sin texto, borrador editado, advertencia de orden, guardado pendiente. |
| Lector | «Escuchar libro» | Reproduciendo, pausado, selección de palabra, voz no disponible. |
| Ajustes del libro | Probar voz y tamaño de letra | Voz local disponible, descarga/configuración necesaria, idioma sin voz. |

### 4.1 Teléfono y tablet

- Ancho disponible menor de 600 unidades lógicas: navegación apilada y una columna. La revisión alterna foto/texto y permite ampliar la foto.
- Desde 600: admitir navegación lateral cuando quede espacio; no clasificar un dispositivo solo por su nombre o tipo.
- Desde 840: revisión con imagen y editor en dos paneles; lector con índice lateral opcional. En ventanas estrechas de iPad volver al diseño compacto.
- Admitir orientación vertical y horizontal, áreas seguras, teclado en pantalla y redimensionamiento durante uso.
- Controles táctiles de al menos 48 × 48 unidades lógicas; etiquetas visibles para las acciones principales.
- Texto del lector ajustable, valor inicial aproximado de 22 unidades lógicas, interlineado cómodo y ancho de línea limitado. Respetar el escalado del sistema y comprobar 200 % sin cortar acciones.
- Contraste objetivo de 4.5:1 para texto normal, foco visible, semántica para VoiceOver/TalkBack y estado activo identificable además del color.
- No usar animaciones continuas ni avances automáticos que muevan el texto mientras se selecciona una palabra. Seguir la lectura solo cuando el usuario no esté desplazándose manualmente.

### 4.2 Selección y ayuda al adulto

- Botón «Escuchar párrafo» por bloque; no exigir un gesto oculto para la acción esencial.
- Un toque selecciona una palabra, sin iniciar sonido inesperadamente; la acción visible la reproduce. Respetar gestos de accesibilidad.
- Pulsación prolongada selecciona texto y añade «Escuchar selección» al menú, manteniendo la selección habitual.
- Puntuación, apóstrofos y guiones deben tratarse sin convertir cada palabra en un botón independiente que rompa el ajuste de líneas o la accesibilidad.
- En `don't`, la palabra seleccionada es la contracción completa. Las palabras repetidas se identifican por su posición, no buscando la primera coincidencia textual.
- Mensajes concretos en español: «No encontramos texto. Prueba con más luz o recorta la página», «Esta foto sigue pendiente» y «La voz elegida no está disponible».
- Repetir y escuchar despacio ayudan al acompañamiento educativo. La app no promete resultados de aprendizaje ni presenta el TTS como evaluación del niño.

## 5. Organización del código y contratos

Aplicación modular por funcionalidades, con dominio separado de Flutter y de los plugins. No crear microservicios ni una jerarquía de paquetes antes de necesitarla.

```text
lib/
  app/                        # arranque, navegación e inyección
  core/
    domain/                   # entidades, errores y contratos compartidos
    storage/                  # Drift, repositorios, migraciones y archivos
    design/                   # tema, tipografía y componentes accesibles
    l10n/                     # recursos de interfaz
  features/
    library/                  # biblioteca y ajustes por libro
    capture/                  # selección, cámara y transformaciones
    ocr/                      # adaptador, reconstrucción y revisión
    reader/                   # presentación y selección del texto
    speech/                   # adaptador TTS y controlador de reproducción
    settings/                 # preferencias generales y almacenamiento
test/                         # dominio, almacenamiento y widgets
integration_test/             # recorridos en la app
test_assets/                  # textos e imágenes propios o autorizados
docs/
  contracts/                  # contratos congelados en G0
  adr/                        # decisiones y cambios de arquitectura
  tasks/                      # una ficha por tarea
  handoffs/                   # una entrega por tarea
  qa/                         # matriz y evidencias, sin libros privados
  implementation-status.md    # estado y siguiente paso
scripts/                      # comprobaciones reproducibles
```

Esta estructura es un destino de implementación: solo `PLAN.md` y `PROMPT.md` deben existir al finalizar la planificación.

### 5.1 Contratos que se fijan antes del trabajo paralelo

Las siguientes firmas son especificaciones, no API de plugins. A01 debe convertirlas en tipos Dart y pruebas de contrato.

| Contrato | Operaciones y datos mínimos |
|---|---|
| `BookRepository` | Crear/observar libro, listar páginas y párrafos, aprobar revisión, reordenar, editar, borrar, guardar posición. Mutaciones transaccionales con revisión esperada. |
| `CaptureService` | Obtener imágenes de galería/cámara, recuperar resultado pendiente, copiar a almacenamiento privado y devolver referencias persistentes. |
| `ImageTransformService` | Rotar/recortar, normalizar orientación, producir imagen derivada y mapa de coordenadas hacia el original. |
| `OcrService` | Reconocer archivo con escritura solicitada y devolver texto bruto, bloques, líneas, polígonos, metadatos del motor y confianza opcional. |
| `ImportQueue` | Añadir trabajo, observar estado, reintentar y cancelar; recuperar trabajos al reiniciar. Cada trabajo pertenece a un libro y una página. |
| `SpeechService` | Enumerar voces/capacidades, hablar un segmento, detener y emitir inicio, rango, fin o error con identificadores de sesión y segmento. |
| `PlaybackController` | Preparar libro/párrafo/palabra/selección; pausar, continuar, repetir y avanzar sin acoplar la UI al proveedor. |

`SpeechCapabilities` debe incluir al menos: `supportsNativePause`, `supportsRangeEvents`, `requiresNetwork`, `maxInputLength` y unidad del límite. Un valor desconocido se representa explícitamente; no se interpreta como capacidad confirmada.

Todos los eventos asíncronos deben incluir `bookId`, `sessionId` o `jobId`, y revisión correspondiente. Los errores distinguen permiso, archivo, almacenamiento, OCR, voz, idioma y cancelación. Cancelar no es un error para el usuario.

### 5.2 Modelo de datos local

| Entidad | Campos clave | Regla |
|---|---|---|
| `Book` | `id`, `title`, `learningLocale`, `homeLocale`, `createdAt`, `updatedAt`, `contentRevision` | Configuración y contenido aislados por libro. |
| `ImportBatch` | `id`, `bookId`, `createdAt`, `status` | Agrupa una selección múltiple o una sesión de capturas. |
| `Page` | `id`, `bookId`, `batchId`, `orderKey`, `originalPath`, `derivedPath`, `sha256`, `transformRevision`, `approvedDraftRevision`, `pendingJobId`, `contentStatus` | Posición reservada antes de OCR; contenido aprobado y trabajo pendiente tienen estados separados. |
| `OcrRevision` | `id`, `pageId`, `jobId`, `transformRevision`, `rawText`, `layoutJson`, `engine`, `createdAt` | Resultado OCR inmutable; el texto corregido se guarda por separado. |
| `PageDraft` | `pageId`, `ocrRevisionId`, `draftRevision`, `blocksJson`, `updatedAt` | Conserva cambios sin publicar hasta aprobar la revisión. |
| `Paragraph` | `id`, `bookId`, `pageId`, `orderKey`, `text`, `localeOverride`, `textRevision` | Texto canónico que ve y escucha la familia. |
| `ParagraphSource` | `paragraphId`, `ocrRevisionId`, `blockRefs`, `sourceGeometry` | Trazabilidad de la transcripción; puede ser aproximada tras edición manual. |
| `ImportJob` | `id`, `pageId`, `transformRevision`, `state`, `attemptCount`, `errorCode`, `updatedAt` | Una generación vigente por página; resultados antiguos no sobrescriben nuevos. |
| `BookVoiceSettings` | `bookId`, `provider`, `engineId`, `voiceId`, `locale`, `ratePreset` | Un identificador de voz puede dejar de estar disponible. |
| `ReadingPosition` | `bookId`, `paragraphId`, `textRevision`, `offsetUtf16`, `updatedAt` | Si cambia el texto, revalidar o volver al inicio del párrafo. |

Reglas de persistencia:

1. SQLite almacena estructura y referencias; las imágenes se guardan como archivos privados, no como grandes blobs en cada fila.
2. El libro se renderiza por `Page.orderKey` y luego `Paragraph.orderKey`. Reordenar una página mueve todos sus párrafos.
3. Aprobar una revisión inserta o sustituye únicamente el contenido de esa página, incrementa `contentRevision` y actualiza su estado en una transacción. Reaprobar el mismo borrador no duplica párrafos.
4. Páginas sin contenido aprobado aparecen como pendientes; «Escuchar libro» avisa de las páginas excluidas. Una página aprobada en reprocesamiento conserva su texto legible y audible hasta aprobar el borrador nuevo.
5. Un recorte nuevo invalida el OCR de la transformación anterior. Los resultados tardíos se descartan sin eliminar el texto aprobado.
6. Un reprocesamiento de página ya aprobada crea un borrador nuevo: no destruye correcciones manuales. Mostrar diferencias y sustituir solo al aceptar.
7. Los párrafos se unen/dividen dentro de una página. La fusión editorial entre fotografías queda fuera del MVP; la lectura continúa entre páginas en orden.
8. Un hash idéntico muestra aviso de posible foto repetida con opciones de omitir o conservar. No deduplicar texto de forma automática: las repeticiones pueden ser parte del ejercicio.
9. Guardar rutas relativas al directorio privado. Copiar mediante archivo temporal y renombrado; reconciliar archivos huérfanos y referencias rotas al arrancar.
10. El borrado de un libro cancela trabajos/audio y elimina sus filas, imágenes y derivados. Un registro de limpieza permite reintentar archivos que no se pudieron borrar; no prometer borrado criptográfico.

## 6. Pipeline de captura y OCR

```mermaid
flowchart LR
  A[Libro activo] --> B[Cámara o selección múltiple]
  B --> C[Persistir fotos y reservar orden]
  C --> D[Rotar o recortar]
  D --> E[Cola OCR local]
  E --> F[Revisar imagen y borrador]
  F --> G[Aprobar texto de la página]
  G --> H[Libro con párrafos ordenados]
  H --> I[Escuchar libro, párrafo o palabra]
```

### 6.1 Orden, interrupciones y uso de recursos

- Al añadir fotos, confirmar su orden visual. No asumir que todos los selectores de sistema devuelven el orden de toque.
- Reservar páginas nuevas al final del libro en una transacción. El identificador del libro queda capturado al iniciar la importación, aunque después se abra otro.
- Procesar una imagen a la vez inicialmente. El límite de memoria depende de imágenes en procesamiento, no del tamaño del lote. Usar miniaturas y listas virtualizadas.
- Objetivo del MVP: lotes de 50 imágenes y libros de 200 páginas. Son tamaños de validación, no promesa de capacidad ilimitada ni límites fijos sin medición.
- Comprobar espacio antes de copiar; validar el contenido del archivo y dimensiones, no solo la extensión. Determinar límites documentados en G0.
- JPEG, PNG y HEIC procedentes del dispositivo forman el conjunto de validación; convertir formatos cuando el SDK lo necesite sin perder la orientación. No anunciar soporte sin probarlo.
- Corregir EXIF y mantener las transformaciones para que las regiones detectadas correspondan a la imagen mostrada. Reducir resolución solo tras medir legibilidad del texto pequeño.
- En Android, recuperar resultados pendientes de `image_picker` al iniciar. Las fotos devueltas por cámara pueden residir en caché y deben copiarse antes de depender de ellas. [Recuperación y persistencia en image_picker](https://pub.dev/packages/image_picker).
- El sistema operativo puede suspender o terminar el proceso: el trabajo se reanuda desde la cola persistida al abrir. No prometer procesamiento continuo con la app cerrada.
- Cancelar impide encolar o publicar nuevos resultados. Si una llamada nativa no se puede interrumpir, descartar su resultado al regresar según su generación.

### 6.2 Reconstrucción de texto

ML Kit devuelve estructura de bloques, líneas y elementos; eso no equivale a una reconstrucción editorial perfecta del libro. Su cobertura de escrituras debe verificarse antes de ampliar idiomas. [Estructura de texto en ML Kit](https://developers.google.com/ml-kit/vision/text-recognition/v2).

- Primera cobertura: texto impreso latino en español e inglés, con una columna o región recortada.
- Conservar el resultado bruto y producir una propuesta de párrafos basada en geometría y saltos de línea.
- Normalizar saltos y espacios de forma reversible. No corregir ortografía, traducir ni completar frases silenciosamente.
- No unir automáticamente palabras con guion al final de línea si existe ambigüedad. La revisión permite corregirlas.
- Detectar disposiciones dudosas y ofrecer recortar por columna/reordenar bloques. Tablas, ejercicios dispersos, curvas fuertes y texto manuscrito no deben presentarse como casos resueltos.
- Conservar números de página y encabezados en el borrador hasta que el adulto los excluya. No borrarlos mediante una regla global no revisada.
- Confianza OCR: valor opcional y específico del motor. Si falta, mostrar «Revisa el texto»; no fabricar porcentajes. Un indicador de desenfoque no equivale a confianza OCR.
- Una página sin texto queda disponible para recapturar, editar manualmente o excluir; no bloquear el resto del lote.
- Usar el modelo latino empaquetado donde corresponda y verificar los artefactos finales. En Android, Google distingue modelo incluido y modelo descargado: solo el primero evita esperar a su descarga inicial. [Opciones de instalación del modelo](https://developers.google.com/ml-kit/vision/text-recognition/v2/android).

## 7. Motor de lectura

### 7.1 Máquina de estados

`idle → preparing → speaking ↔ paused → completed`, con salidas a `stopped` y `error`. Los cambios pasan por un único controlador de reproducción.

1. Crear una sesión con `sessionId`, libro, revisión y alcance: libro, párrafo, palabra o selección.
2. Construir una cola de segmentos a partir del texto aprobado y su idioma efectivo.
3. Segmentar párrafos largos por frases y, cuando sea necesario, por límites de palabra; respetar el límite real del motor y su unidad. No partir pares sustitutos ni grafemas.
4. Reproducir con una ventana pequeña de segmentos encolados. No enviar todo el libro como una única cadena al motor.
5. Guardar el párrafo y último límite conocido. Cada segmento mapea sus offsets al texto canónico de una revisión concreta.
6. Al tocar otro párrafo o palabra, cancelar la sesión anterior, limpiar su cola y crear otra. Ignorar callbacks de sesiones antiguas.
7. Escuchar una palabra o selección interrumpe la lectura de libro y la deja pausada. Al terminar, el adulto puede continuar explícitamente desde la posición guardada.
8. Si se edita, elimina o reordena el contenido durante la reproducción, detener y reconstruir la sesión con la nueva revisión. No mezclar fragmentos de revisiones distintas.

### 7.2 Offsets y selección

- Usar rangos `[start, end)` UTF-16 en el texto canónico de cada párrafo; documentar cualquier conversión exigida por el SDK.
- Registrar para cada segmento `paragraphId`, `textRevision`, `segmentBaseOffsetUtf16`, texto exacto enviado y mapa de rangos si se transforma el texto.
- Validar contracciones, apóstrofos curvos, palabras repetidas, guiones, acentos, saltos, signos y emojis adyacentes. La UI selecciona por rango, no por igualdad de palabra.
- Cambiar el tamaño de fuente o la orientación no altera el rango seleccionado ni el texto reproducido.
- No sustituir el widget de texto por una lista de botones por palabra. Resolver selección, hit testing y semántica dentro de la composición de texto.

### 7.3 Pausa, resaltado y compatibilidad real

El puente `flutter_tts` documenta una pausa emulada en Android basada en rangos desde API 26; los offsets cambian al reconstruir el fragmento. Esta limitación debe probarse y encapsularse. [Pausa en flutter_tts](https://pub.dev/packages/flutter_tts).

Android solo entrega rangos si el motor aporta esa información. Apple expone un delegado para el rango que va a pronunciarse. [Rangos en Android](https://developer.android.com/reference/android/speech/tts/UtteranceProgressListener), [rangos en Apple](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:willspeakrangeofspeechstring:utterance:)).

Política del producto:

- Con pausa nativa: usarla y mantener la sesión.
- Con rangos fiables, pero sin pausa nativa: detener y continuar desde el último límite seguro, ajustando el desplazamiento base.
- Sin rangos fiables: detener y continuar desde el inicio de la frase actual. Informarlo de forma breve; nunca saltar palabras para fingir precisión.
- Sin eventos por palabra: resaltar el párrafo actual. La selección y reproducción de una palabra siguen siendo obligatorias y no dependen del resaltado sincronizado.
- No simular resaltado de palabras con temporizadores de duración estimada.
- Al cambiar de voz/velocidad, pausar y reconstruir desde un límite seguro. Guardar la preferencia solo si la voz acepta el idioma.
- Si falta una voz: mostrar voces disponibles o instrucciones para configurarla, conservando el libro. No sustituir automáticamente el idioma ni enviar texto a la nube.

### 7.4 Audio y ciclo de vida

- Configurar sesión de audio de iOS y foco de audio de Android para lectura; comprobar modo silencio, altavoz, auriculares y Bluetooth.
- Ante llamada, alarma, pérdida de foco o desconexión de auriculares: pausar y conservar posición; no reanudar de manera inesperada por el altavoz.
- Para el MVP, pasar a segundo plano o bloquear pantalla pausa la lectura y guarda posición. La lectura de fondo requiere una fase propia.
- VoiceOver/TalkBack debe poder acceder a controles y selección. No iniciar simultáneamente narración automática que compita con la navegación accesible.
- Cada libro conserva sus preferencias y progreso. Abrir el libro B detiene el audio de A.

## 8. Datos familiares y operación local

Estas son decisiones de diseño del producto, no una afirmación de cumplimiento legal:

- No exigir nombre, edad, escuela, cuenta o grabaciones del niño.
- Mantener fotos y texto en el almacenamiento privado de la app. No incluir contenido del libro, rutas privadas ni imágenes en logs, informes automáticos o analítica.
- Pedir acceso a cámara/fotos al usar la función. No pedir micrófono para sintetizar voz.
- Tratar las voces que requieren red como una capacidad distinta, visible y desactivada por defecto en el modo local. No hay fallback oculto a nube.
- Definir y probar exclusión de fotos/texto de copias automáticas del sistema para el MVP local. Si se habilita respaldo del sistema o sincronización después, explicarlo al adulto y verificar su comportamiento.
- Informar en almacenamiento que borrar la app puede eliminar libros locales; no prometer recuperación sin un respaldo implementado.
- Usar fixtures propios o con licencia para pruebas. No añadir fotografías de libros de la familia ni datos infantiles al repositorio o evidencias compartidas.
- Antes de una distribución comercial, revisar políticas vigentes de las tiendas para la audiencia elegida, privacidad y uso de contenidos. El contexto educativo no se tratará como autorización automática para redistribuir libros.

## 9. Trabajo para múltiples agentes y niveles de esfuerzo

### 9.1 Niveles

Los niveles indican esfuerzo de razonamiento recomendado; no nombres fijos de modelos. Elegir modelos con capacidades suficientes y ajustar su esfuerzo, si la herramienta lo permite.

| Nivel | Uso | Ejemplos | Regla de revisión |
|---|---|---|---|
| Bajo (`low`) | Trabajo acotado con contrato y ejemplos definidos | Textos ARB, documentación, fixtures sintéticos, ajustes pequeños de UI. | No decide arquitectura, migraciones ni semántica del audio. |
| Medio (`medium`) | Funcionalidad delimitada con pruebas claras | Biblioteca, selección de imágenes, persistencia de preferencias. | Revisión de integración antes de cerrar la tarea. |
| Alto (`high`) | Concurrencia, integraciones nativas o estados complejos | Cola recuperable, transacciones, reconstrucción OCR, selección y TTS. | Revisar fallos, cancelación y ciclo de vida en dispositivos. |
| Muy alto (`xhigh`) | Decisiones transversales y problemas sin causa localizada | Contratos, arquitectura, revisión independiente de pérdida de datos/offsets. | Uso puntual; cerrar con decisión verificable y alcance pequeño. |

### 9.2 Roles y propiedad

| Rol | Responsabilidad | Rutas principales |
|---|---|---|
| Coordinador/integrador | Descomponer, fijar contratos, dependencias, integración y estado | `docs/contracts/`, `docs/adr/`, `lib/core/domain/`, arranque y archivos compartidos. |
| Datos | Libros, SQLite, migraciones, archivos y recuperación | `lib/core/storage/`, pruebas de almacenamiento. |
| Captura/OCR | Importación, transformaciones, cola, revisión | `lib/features/capture/`, `lib/features/ocr/`. |
| Lector/audio | Selección, cola TTS, voz y ciclo de vida | `lib/features/reader/`, `lib/features/speech/`. |
| UI/QA | Accesibilidad, flujos adaptables, corpus y validación | Tema, recursos, pruebas/evidencias según asignación. |

No es necesario activar todos los roles a la vez. Configuración inicial sugerida: un coordinador y dos agentes ejecutores; el revisor puede entrar cuando termina una implementación. Si solo hay un agente, ejecutar las mismas tareas secuencialmente.

### 9.3 Reglas de colaboración

1. No ejecutar agentes sobre un contrato compartido aún indefinido. Primero A00 y A01.
2. Cada tarea tiene un único responsable, dependencias, rutas editables, criterios de aceptación y nivel de esfuerzo.
3. Un solo escritor para `pubspec.yaml`, lockfiles, rutas globales, esquemas y configuración nativa compartida. Los demás proponen el cambio al integrador.
4. Usar ramas/worktrees por tarea cuando haya Git. Si comparten directorio, asignar rutas disjuntas y no correr generadores ni pruebas que muten artefactos compartidos a la vez.
5. Las mutaciones de contratos requieren ADR y coordinación con consumidores. No cambiar silenciosamente una firma para terminar una tarea local.
6. Los agentes dejan evidencia por tarea en `docs/handoffs/<ID>.md`. Solo el coordinador actualiza `docs/implementation-status.md`.
7. Estados: `TODO`, `READY`, `IN_PROGRESS`, `IN_REVIEW`, `DONE`, `BLOCKED`. `BLOCKED` exige motivo, impacto y siguiente acción; no equivale a «difícil».
8. Un agente de esfuerzo bajo eleva a alto si aparecen cambios de contrato, pérdida de datos, Unicode, carreras asíncronas o diferencias nativas no previstas.
9. No declarar una fase completa con mocks como única evidencia. Separar pruebas automatizadas, compilación, simulador y prueba física.
10. No avanzar al hito dependiente sin su puerta verde. Se puede trabajar en tareas independientes con contratos aprobados, sin declarar integrado lo pendiente.

## 10. Backlog ejecutable

El backlog conserva los criterios de aceptación; el estado operativo se mantiene en `docs/implementation-status.md`. A01–A12 tienen implementación parcial o completa según esa evidencia; los criterios de aceptación física siguen siendo obligatorios.

| ID | Tarea y entregable | Esfuerzo | Depende de | Aceptación mínima |
|---|---|---|---|---|
| A00 | Prueba de viabilidad Flutter + OCR + TTS + selección de palabra; `docs/toolchain.md` y `docs/qa/spike.md`. | Alto | — | Compila Android/iOS; una foto produce texto real; libro/párrafo/palabra se oyen; se documentan rangos, pausa, voces locales y límites por dispositivo. |
| A01 | Contratos, tipos, ADR y estado inicial; `docs/contracts/*`, `lib/core/domain/*`. | Muy alto | A00 | Modelo, estados, orden, offsets y errores acordados; fixtures de contrato consumibles por otros agentes. |
| A02 | Proyecto, tema, navegación, recursos ARB y scripts de verificación. | Medio | A01 | Arranque en ambas plataformas y diseños de biblioteca/lector de prueba en anchos compacto y amplio. |
| A03 | Drift, archivos, migraciones, repositorios y borrado recuperable. | Alto | A01, A02 | Libros aislados; reabrir conserva datos; fallos de transacción no dejan contenido parcial; migración preserva fixtures. |
| A04 | Biblioteca y preferencias por libro. | Medio | A03 | Crear dos libros, renombrar, cambiar idioma/voz, abrir y borrar sin afectar al otro. |
| A05 | Selección múltiple, fotos sucesivas, persistencia, orden y recorte/rotación. | Alto | A03 | Importar 10 fotos y tomar 3 más; confirmar orden; permisos/cancelación/recuperación Android sin pérdida. |
| A06 | Adaptador OCR y reconstrucción de bloques/párrafos. | Alto | A01, A02 | Corpus EN/ES reproducible; orientación correcta; preserva OCR bruto; no añade palabras; vacíos y columnas tienen salida de revisión. |
| A07 | Cola persistida, estados y reintentos idempotentes. | Alto | A03, A05, A06 | Lote de 50 con fallo/cierre/cancelación conserva orden y resultados; no duplica texto ni cruza libros. |
| A08 | Editor de revisión y aprobación transaccional. | Alto | A04, A07 | Corregir/excluir/unir/dividir dentro de página; aprobar añade en orden; reprocesar conserva edición anterior hasta aceptar. |
| A09 | Catálogo de voces, adaptador nativo y capacidades. | Alto | A01, A02 | Habla EN/ES; detecta voz ausente/red; prueba local en modo avión y documenta pausa/progreso reales. |
| A10 | Motor de reproducción, segmentación, offsets y posición. | Alto | A03, A09 | Libro largo, pausa, reanudación, interrupción y cambio de libro sin superposición ni callbacks obsoletos. |
| A11 | Lector adaptable, selección de palabra y controles. | Alto | A04, A08, A10 | Libro/párrafo/palabra/selección funcionan en teléfono/tablet, con texto ampliado y palabras repetidas. |
| A12 | Ajustes de velocidad/voz, audio y recuperación de lectura. | Alto | A11 | Llamada, auriculares, bloqueo, edición y voz eliminada conservan estado y no reproducen inesperadamente. |
| A13 | Revisión de UX, accesibilidad y mensajes. | Medio | A02, A11, A12 | VoiceOver/TalkBack, teclado, orientación, ancho reducido y texto al 200 % completan el recorrido. |
| A14 | Fixtures, pruebas de aceptación, rendimiento y defectos de integración. | Alto | A08, A12, A13 | Matriz de sección 12 ejecutada; medidas reproducibles; cero defectos abiertos de pérdida de datos o lectura de contenido equivocado. |
| A15 | Guía de uso, guía de desarrollo, licencias y preparación de beta. | Medio | A14 | README reproducible, artefactos identificados, límites claros y pendientes de firma/distribución separados. |
| A16 | Cuenta adulta con Google, vinculación local y sincronización opcional. | Alto | A15 | Inicio local sin cuenta; autenticación Google; subida y borrado explícitos; libros disponibles sin conexión; conflictos y privacidad documentados. |

Trabajo de esfuerzo bajo se extrae de A02, A13 y A15 con subtareas como `A13-copy` o `A15-readme`, una vez fijados los contratos. No asignar A10 completo a esfuerzo bajo por contener pocas pantallas: su complejidad está en los estados y offsets.

### 10.1 Paralelismo permitido

- A00 → A01 → A02 forman el inicio común.
- Tras A02: A03, A06 y A09 pueden avanzar en paralelo con interfaces aprobadas.
- Tras A03: A04 y A05 pueden avanzar en rutas distintas; A10 puede arrancar al estar A09 listo.
- A07 une captura, OCR y almacenamiento. A08 cierra la fase 1.
- A11 integra el lector con texto real y el motor de voz; A12 cierra la fase 2.
- A13–A15 validan y preparan la entrega. Fixtures de A14 pueden prepararse antes, pero su aceptación final depende del recorrido integrado.

## 11. Hitos y puertas de aceptación

Estimación orientativa: 20–35 jornadas de trabajo efectivo, a revisar después de G0. No es un compromiso de calendario; los dispositivos disponibles, plugins y defectos nativos condicionan el plazo. Más agentes no eliminan las dependencias ni sustituyen pruebas físicas.

| Hito | Tareas | Demostración | Puerta |
|---|---|---|---|
| M0: viabilidad y contratos | A00–A01 | Una imagen propia → texto real → audio completo/párrafo/palabra en Android e iOS. | G0: matriz de toolchain y capacidades confirmadas; problemas de selección, voz u OCR resueltos o alternativa concreta validada. |
| M1: biblioteca persistente | A02–A04 | Dos libros independientes conservados tras reinicio. | G1: compilación, persistencia, borrado y migración inicial comprobados. |
| M2: fase 1 completa | A05–A08 | Fotos de galería + fotos sucesivas → revisión → libro ordenado; recuperación tras fallo. | G2: ninguna pérdida/duplicación/cruce de libros; el adulto puede corregir y continuar. |
| M3: fase 2 completa | A09–A12 | Escuchar libro, párrafo y palabra, cambiar velocidad, pausar y volver al mismo libro. | G3: tres alcances obligatorios funcionales en ambas plataformas; capacidades y fallbacks verificados. |
| M4: calidad de uso | A13–A14 | Recorrido completo en teléfono/tablet, sin red y con accesibilidad. | G4: matriz aprobada, métricas registradas y defectos críticos cerrados. |
| M5: beta lista | A15 | Instalación y guía reproducibles para prueba familiar. | G5: artefactos, instrucciones y limitaciones revisados; distribución solo cuando estén disponibles credenciales y autorización correspondientes. |
| M6: cuenta opcional | A16 | Iniciar sesión con Google, respaldar un libro y continuar sin conexión. | G6: autenticación, sincronización, borrado y recuperación verificados sin bloquear el modo local. |

G0 debe probar la selección de palabras y el audio desde el inicio, aunque la funcionalidad de producto se entregue en la fase 2. Si un puente falla, dedicar una prueba acotada al adaptador nativo; documentar la decisión sin cambiar toda la arquitectura por un error aislado.

## 12. Pruebas y criterios verificables

### 12.1 Matriz de aceptación

| Caso | Preparación / acción | Resultado obligatorio |
|---|---|---|
| T01 — Libro incremental | Crear A; foto 1 con «The cat is small.»; foto 2 con «It likes to play.»; aprobar ambas. | Dos párrafos en ese orden, conservados al reabrir A. |
| T02 — Importación múltiple | Elegir 10 imágenes, reordenar 3 y hacer que OCR termine fuera de orden. | El libro mantiene el orden confirmado, no el orden de finalización. |
| T03 — Libros aislados | Importar en A, abrir B durante el trabajo y añadir imágenes a B. | Cada resultado y preferencia pertenece al libro correcto. |
| T04 — Recuperación | Terminar proceso durante copia/OCR/aprobación en ejecuciones separadas; reabrir. | Recuperación consistente sin texto duplicado ni fotos aceptadas perdidas. |
| T05 — Edición y reproceso | Corregir OCR, aprobar y recortar/reprocesar esa misma página. | Corrección anterior conservada hasta aprobar nueva versión. |
| T06 — Error parcial | Lote con página vacía, archivo inválido, foto borrosa y falta de espacio inducida. | Errores accionables por foto; no se pierde el resto del libro. |
| T07 — Tres alcances | Escuchar libro, párrafo 2 y una palabra de párrafo 1. | Se escucha exactamente el alcance pedido en inglés, con interfaz española. |
| T08 — Selección exacta | Texto con `don't`, `don’t`, `mother-in-law`, `the the`, `niño` y emoji adyacente. | Rango correcto; no salta a otra coincidencia ni corta Unicode. |
| T09 — Lectura larga | Libro sintético de 200 páginas, incluidos párrafos mayores que el límite del motor. | Segmentación sin truncamiento, límites seguros y progreso recuperable. |
| T10 — Pausa/progreso | Motores con rangos y sin rangos; pausar y continuar varias veces. | Sin omisiones; fallback de frase visible cuando corresponda; sin resaltado ficticio. |
| T11 — Sesiones obsoletas | Tocar palabras rápidamente, cambiar libro, editar texto y recibir callback antiguo. | Una sola reproducción activa; se ignoran eventos de la sesión anterior. |
| T12 — Sin conexión | Instalar modelo/voz local; modo avión; importar, revisar, cerrar y leer. | Flujo esencial funcional; voz ausente tiene salida clara sin fallback de red. |
| T13 — Ciclo de audio | Llamada/interrupción, quitar auriculares, bloqueo y segundo plano. | Pausa segura y posición conservada; no reanuda automáticamente. |
| T14 — Diseño adaptable | Teléfono y tablet, ambas orientaciones, ventana estrecha y texto al 200 %. | Sin controles ocultos, desbordamientos ni pérdida de selección. |
| T15 — Accesibilidad | Completar creación, revisión y lectura con VoiceOver y TalkBack. | Controles etiquetados, orden de foco útil, palabra/párrafo accesibles. |
| T16 — Borrado/migración | Borrar A con trabajos/audio activos; migrar una BD de prueba anterior. | A no reaparece, B permanece íntegro y la migración conserva relaciones. |

### 12.2 Corpus y medición

- Preparar al menos 30 imágenes propias/autorizadas: texto inglés/español nítido, distintos tamaños, rotaciones, sombras, dos columnas, páginas sin texto y formato de cámara HEIC/JPEG.
- Mantener transcripción de referencia. Medir CER (distancia de edición por caracteres dividida entre caracteres de referencia) y exactitud del orden de bloques por categoría; no ocultar fotos difíciles en una media global.
- Objetivo inicial para impresión nítida de una columna: CER agregado ≤ 3 % antes de edición. Es una meta de aceptación que debe medirse; no una precisión demostrada del proveedor.
- Orden de capturas y párrafos aprobados: 100 % en los fixtures deterministas. Ninguna palabra añadida deliberadamente por un paso generativo.
- Objetivos iniciales en un teléfono de referencia de gama media, documentado en G0: abrir libro local con vista inicial en ≤ 1 s p95, OCR por foto normalizada en ≤ 3 s p95 en caliente, inicio audible TTS local en ≤ 1 s p95 en caliente.
- Registrar aparte arranque en frío, modelo/voz/idioma, dimensiones de imagen, versión del SO, número de muestras y condiciones. Usar al menos 30 observaciones para métricas p95; medir el inicio audible, no solo el callback de solicitud.
- Procesar 50 fotos y leer un libro de 200 páginas sin terminación por memoria ni crecimiento proporcional a todas las imágenes decodificadas a la vez. Registrar pico de memoria, duración y tamaño final; fijar presupuesto numérico después de G0.
- Si una meta no se alcanza, documentar causa y propuesta medible; no reducirla silenciosamente ni declararla lograda con un mock.

### 12.3 Dispositivos y automatización

Matriz mínima: iPhone, iPad, teléfono Android y tablet Android. Incluir al menos un dispositivo físico por plataforma para cámara y voz; los tamaños restantes pueden empezar en simulador/emulador, pero la compatibilidad final de tablet requiere evidencia en tablet real o quedar expresamente pendiente.

Comandos de referencia que A02 debe adaptar y documentar con la toolchain elegida:

```bash
flutter doctor -v
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test -d <device-id>
flutter build apk --debug
flutter build ios --simulator --debug
```

Ejecutar generadores solo desde el rol dueño de los artefactos generados; no usar eliminación de conflictos para borrar cambios manuales desconocidos. El script final debe trabajar desde un checkout limpio y fallar ante errores.

Las pruebas unitarias verifican contratos, segmentación, orden y carreras; las de integración verifican almacenamiento y plugins. Escuchar la voz, usar la cámara y evaluar accesibilidad requieren comprobación real. Una compilación no demuestra que el audio se oyó.

## 13. Riesgos y respuesta prevista

| Riesgo | Respuesta | Responsable / puerta |
|---|---|---|
| Plugin comunitario incompatible con SDK nuevo | Compilar temprano, fijar versiones y sustituir solo el adaptador si hace falta. | Coordinador, G0. |
| Orden de OCR incorrecto en ejercicios escolares | Recorte, revisión por bloques y corrección manual; no prometer reconstrucción automática de cualquier maquetación. | OCR, G2. |
| Fotos perdidas por caché o cierre | Copia persistente, cola recuperable y transacciones idempotentes. | Datos/captura, G2. |
| Offset de palabra incorrecto al pausar | Mapa UTF-16 por revisión y segmento; pruebas con contracciones y callbacks tardíos. | Audio/lector, G3. |
| Motor sin rangos o voz local | Catálogo/capacidades, fallback de frase y párrafo; configuración guiada. | Audio, G3. |
| Demasiada memoria en lotes | Un trabajo por vez, imágenes normalizadas y miniaturas; medir en dispositivo de referencia. | Captura/QA, G4. |
| Lectura poco cómoda para quien inicia alfabetización | Texto ajustable, controles claros, prueba guiada con adulto y niño sin grabación por defecto. | UI/QA, G4. |
| Agentes pisan archivos compartidos | Propiedad de rutas, integrador único y entregas pequeñas. | Coordinador, todos los hitos. |
| Falta de dispositivo o firma | Continuar verificaciones independientes, registrar evidencia pendiente y no marcar la puerta completa. | Coordinador, G0/G5. |

## 14. Evolución posterior al MVP

Priorizar con la familia después de usar ambos flujos, sin retrasar el audio básico:

1. Guardar vocabulario por libro y repetir palabras favoritas.
2. Traducción opcional X → Y de palabra/párrafo, siempre separada del texto original; validar calidad y proveedor.
3. Respaldo/exportación privada e importación con versión de formato.
4. Lectura en segundo plano, temporizador y controles de pantalla bloqueada.
5. Voces en nube con caché y presupuesto, si las locales resultan insuficientes.
6. Sincronización familiar con cuentas adultas y autorización explícita de acceso entre dispositivos.
7. Nuevos alfabetos, maquetaciones complejas y herramientas de práctica, cada uno con sus pruebas específicas.

## 15. Inicio y reanudación del trabajo

Próxima tarea: **A00 — prueba de viabilidad**. No comenzar construyendo toda la biblioteca antes de demostrar OCR, selección de palabra y TTS en ambas plataformas.

El primer agente debe leer `PROMPT.md` y este plan, inspeccionar el entorno y producir evidencia de A00. Después, A01 crea el registro persistente con esta estructura:

```markdown
# Estado de implementación
Última actualización: <fecha>
Revisión/commit base: <identificador o sin Git>
Hito actual: M0
Última puerta verde: ninguna
Tarea activa: A00
Responsable y esfuerzo: <rol / nivel>
Completado con evidencia: <rutas>
Pruebas ejecutadas: <comando, entorno, resultado>
Pendientes/bloqueos: <hecho, impacto, siguiente acción>
Siguiente tarea lista: <ID y motivo>
Archivos compartidos reservados: <rutas / dueño>
```

Plantilla de entrega por tarea:

```markdown
# Entrega <ID>
Objetivo y criterio cubierto:
Estado: IN_REVIEW | DONE | BLOCKED
Base y archivos modificados:
Decisiones o contratos afectados:
Pruebas ejecutadas y resultados reales:
Dispositivos / SO / motor y voz, si aplica:
Evidencias:
Limitaciones y trabajo pendiente:
Siguiente paso:
```

La entrega completa del producto mínimo exige G0–G4 verdes, ambos flujos esenciales funcionando y una guía reproducible. La publicación en tiendas y G5 dependen de preparación de beta, firma y canal de distribución; no deben confundirse con una app ya publicada.

## 16. Fuentes y vigencia

Las fuentes primarias enlazadas junto a cada decisión se consultaron el 11 de septiembre de 2026. Arquitectura, tareas, metas y reglas de producto son propuestas para MySchoolMyParents; no son garantías de los proveedores. Revalidar dependencias durante G0 y políticas/precios al incorporar distribución o servicios de nube.
