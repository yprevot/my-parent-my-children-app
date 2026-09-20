# MySchoolMyParents — Prompt original y ejecución por agentes

## Alcance confirmado de la entrega

La entrega debe incluir los documentos operativos `PLAN.md` y `PROMPT.md`, además de una primera versión funcional de la aplicación. El plan no es solo un artefacto de planificación: los agentes deben implementar, compilar y validar el recorrido funcional disponible, documentando lo que aún requiera prueba física o configuración externa.


Fecha de captura: 11 de septiembre de 2026.

## 1. Prompt original del usuario

El siguiente bloque conserva literalmente el texto recibido, incluidos su redacción y espacios. Las secciones posteriores son instrucciones operativas derivadas y no forman parte de la cita original.

```text
Diseña un plan en este directorio, y guardalo en un archivo PLAN.md, así como este prompt y guardalo en un archivo PROMPT.md con la finalidad de que multiples agentes con niveles distintos de esfuerzo puedan trabajar sobre el. Diseña el plan para construir una app para iOS y Android, compatible con formato tablet y teléfono,  con el objetivo de tomar aprender y enseñar un idioma X  para padres que no dominan el idioma X y hablan junto con sus hijos el idioma Y. En este caso hablamos español, y con conocimientos básicos de inglés, pero nuestro hijo está en una escuela bilingue, apenas aprende a leer español, pero tiene textos en inglés. La problemática que queremos resolver es que necesitamos dada una foto tomada con un movil o una tablet, leer la imagen del libro y extraer el texto correspondiente. La app debe permitir subir muchas fotos a la vez, o tomar de todo en foto y añadir el texto en formato libro tras leer cada foto. Ejemplo imagen 1 tiene un párrafo, se adiciona el párrafo al libro, tomas una foto que sería imagen 2 y se continua añadiendo ese segundo párrafo al libro que va a crear  la app, y así sucesivamente. Esa es la primera fase. La segunda fase y tan o más importante es que el texto, se puede escuchar en una voz en el idioma correspondiente, si en este caso es inglés, que se pueda leer el texto completo en inglés o si se selecciona un párrafo, que se pueda leer un párrafo, si se selecciona una palabra, que se pueda leer esa palabra. Para la lectura puedes apoyarte en google para android y quizá para ios o recomiendame proveedores. Lo ideal es que este proceso suceda para cada libro. Abro mi aplicación, creo un libro, y para ese libro subo las fotos. Todo con contexto educativo. Procede a implementar el plan con tecnologías modernas.
```

## 2. Prompt maestro para implementar el proyecto

Copiar el siguiente bloque en la sesión del agente coordinador. [PLAN.md](PLAN.md) contiene las decisiones, contratos, tareas, dependencias y criterios completos.

```text
Trabaja en el directorio ImagesToBook. Construye una aplicación móvil educativa
para iOS y Android, teléfono y tablet, siguiendo PLAN.md.

Antes de editar:
1. Lee las instrucciones aplicables del repositorio, PROMPT.md y PLAN.md.
2. Si existe docs/implementation-status.md, léelo y continúa desde la última
   puerta verde. Revisa entregas y cambios actuales; no reinicies el proyecto.
3. Comprueba el estado real del entorno y del código. No presentes una tarea
   planificada como implementada ni una prueba pendiente como aprobada.

El problema que debes resolver es el de padres hispanohablantes con inglés básico
que acompañan a su hijo, que inicia lectura en español y usa libros en inglés en
una escuela bilingüe. Mantén la interfaz inicial en español y reproduce el texto
en su idioma, inicialmente inglés. Distingue idioma del hogar, del libro y de voz.

Implementa los dos flujos esenciales con igual prioridad:
A. Crear varios libros independientes; importar muchas fotos juntas o tomar fotos
   sucesivas; extraer texto, revisar/corregir y añadir párrafos en orden al libro;
   guardar y recuperar todo al cerrar la app.
B. Abrir cada libro y escuchar el texto completo, un párrafo o una palabra
   seleccionada; repetir, ajustar velocidad, pausar, continuar y guardar posición.

Usa la arquitectura acordada: Flutter/Dart, Riverpod, go_router, Drift/SQLite,
captura mediante adaptador, ML Kit local y TTS del sistema encapsulado. Valida la
combinación de versiones en A00 antes de fijarla. Si surge incompatibilidad,
prueba una solución acotada y documenta el cambio de arquitectura mediante ADR.

Empieza por A00: demuestra OCR real y lectura de texto, párrafo y palabra en
Android e iOS; prueba selección, pausa y capacidades de la voz. Luego fija los
contratos con A01. No pospongas todo el riesgo del audio hasta terminar el OCR.

Conserva el orden de captura aunque las tareas terminen fuera de orden. Guarda
fotos fuera de la caché temporal, mantén borradores recuperables y haz idempotentes
los reintentos/aprobaciones. No sobreescribas correcciones al reprocesar fotos.

El lector trabaja con texto canónico y rangos de posición, incluidos Unicode,
contracciones y palabras repetidas. Un solo controlador gestiona sesiones de
audio; los eventos viejos no pueden controlar la sesión nueva. Usa resaltado por
palabra solo si el motor da rangos fiables; la reproducción de palabra siempre
debe funcionar. Respeta las alternativas de pausa descritas en PLAN.md.

La app inicial procesa y guarda localmente. No añadas backend, claves, LLM,
traducción, grabaciones infantiles, pagos o sincronización al MVP. No envíes
contenido a nube mediante una alternativa oculta. Si falta voz local, informa
cómo configurarla y conserva el libro. No inventes texto faltante en las fotos.

Adapta la navegación y revisión al ancho de ventana, orientación y tamaño de
texto. El adulto debe poder usar botones visibles para escuchar párrafos y la
selección de palabra debe funcionar con accesibilidad, sin romper las líneas.

Coordina agentes cuando estén disponibles y el trabajo sea independiente:
- Esfuerzo bajo: documentación, textos y fixtures con contrato definido.
- Medio: funcionalidades delimitadas de biblioteca, preferencias y UI.
- Alto: OCR, persistencia recuperable, integración nativa y audio/selección.
- Muy alto: contratos transversales y revisión de defectos complejos.
Asigna IDs de PLAN.md, rutas y criterios concretos. Mantén un solo escritor para
dependencias, esquemas y archivos globales. No dupliques trabajo ni lances agentes
que aún no tienen entradas definidas. Con un solo agente, sigue el mismo orden.

Completa la tarea asignada, valida lo necesario y deja evidencia. Ejecuta los
checks definidos por el proyecto y pruebas en el runtime correspondiente.
Compilar o usar mocks no demuestra que OCR, voz o cámara funcionen realmente.
No marques una puerta verde sin su evidencia. Si falta un recurso externo,
registra el bloqueo y continúa tareas independientes sin inventar resultados.

El coordinador mantiene docs/implementation-status.md y los agentes sus entregas
docs/handoffs/<ID>.md. Reporta en español: qué funciona, qué cambió, cómo se
verificó, archivos relevantes, límites y siguiente paso. No publiques en tiendas
ni habilites servicios externos solo por preparar una compilación local.
```

## 3. Plantilla para asignar una tarea a un agente

Completar los campos antes de iniciar trabajo. El alcance de una asignación prevalece sobre el recorrido completo del prompt maestro: un agente especializado entrega su tarea, no intenta ejecutar todo el proyecto.

```text
Proyecto: MySchoolMyParents
Tarea: <ID y título de PLAN.md>
Rol: <coordinador | datos | captura/OCR | lector/audio | UI/QA>
Esfuerzo recomendado: <low | medium | high | xhigh>
Objetivo concreto: <comportamiento observable>
Dependencias ya satisfechas: <IDs y evidencias>
Base de trabajo: <rama/worktree/commit o directorio compartido>
Rutas que puedes editar: <lista>
Archivos compartidos reservados a otros: <lista y responsables>
Contratos de entrada: <rutas, tipos y versiones>
Entregable esperado: <archivos y comportamiento>
Criterios de aceptación: <casos Txx y condiciones de PLAN.md>
Pruebas requeridas: <comandos/dispositivos/corpus>
Fuera de alcance: <límites de esta tarea>

Lee PROMPT.md, las secciones pertinentes de PLAN.md y los contratos. Inspecciona
el código actual antes de modificarlo. Resuelve elecciones rutinarias dentro del
contrato. Si necesitas cambiar un archivo compartido o un contrato, envía al
coordinador el cambio propuesto y su motivo; no pises trabajo ajeno.

Implementa y verifica esta tarea. Distingue pruebas reales de mocks y pendientes.
Guarda la entrega en docs/handoffs/<ID>.md con cambios, pruebas, entorno,
evidencias, limitaciones y siguiente paso. No marques tareas de otros agentes.
```

## 4. Asignación inicial lista para usar

```text
Ejecuta A00 de PLAN.md con esfuerzo alto. El proyecto todavía no está implementado.
Inspecciona Flutter, Xcode, Android SDK y dispositivos disponibles sin modificar
configuraciones ajenas al proyecto. Elige una combinación estable verificable.

Crea una prueba acotada y reutilizable de selección de imagen, OCR latino local,
texto seleccionable y TTS. Comprueba texto completo, párrafo y palabra, pausa,
rangos de progreso y funcionamiento sin red con una voz local disponible.
Usa una imagen propia/autorizada con transcripción conocida. Compila Android/iOS
y deja evidencia real; no reemplaces una plataforma con una demostración web.

Entrega docs/toolchain.md y docs/qa/spike.md con versiones resueltas, dispositivo,
SO, motor/voz, resultados, limitaciones y decisión sobre adaptadores. Si no hay
dispositivo o herramienta, declara qué no se pudo comprobar y sigue con la otra
plataforma y pruebas independientes. No declares G0 verde mientras falte evidencia.

El coordinador registrará el estado y el siguiente paso. A01 solo comienza cuando
la viabilidad de los contratos críticos esté resuelta conforme a G0.
```

## 5. Prompt para reanudar una sesión

```text
Continúa ImagesToBook desde su estado actual. Lee PROMPT.md, PLAN.md,
docs/implementation-status.md si existe, y la entrega de la última tarea.
Comprueba el código y los resultados registrados. Identifica la siguiente tarea
READY cuyas dependencias estén satisfechas y ejecútala dentro de su alcance.
No repitas trabajo validado ni cambies el stack sin evidencia y ADR. Mantén
los dos objetivos esenciales: libros incrementales desde fotos y lectura de
libro/párrafo/palabra. Actualiza la entrega y, si eres coordinador, el estado.
```

## 6. Prompt para revisión independiente

```text
Revisa la tarea <ID> de ImagesToBook con esfuerzo alto; usa muy alto solo si el
problema requiere razonamiento transversal. Lee su entrega, contratos, diff y
criterios de PLAN.md. No implementes funcionalidades nuevas durante la revisión.

Busca defectos observables: pérdida o duplicación de texto, resultados del libro
equivocado, orden dependiente de finalización OCR, edición sobreescrita, rangos
Unicode incorrectos, eventos TTS obsoletos, voz de idioma incorrecto, truncamiento,
recuperación defectuosa y controles inaccesibles en tablet/teléfono.

Reproduce las condiciones relevantes. Reporta cada hallazgo con gravedad,
archivo/línea, pasos, resultado esperado y observado. Indica lo que no pudiste
verificar. Recomienda aprobar solo si los criterios de esa tarea tienen evidencia;
no conviertas ausencia de pruebas en confirmación de funcionamiento.
```
