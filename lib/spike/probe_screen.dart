import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr_probe.dart';
import 'reading_paragraph.dart';
import 'speech_probe.dart';
import 'text_ranges.dart';

class ProbeScreen extends StatefulWidget {
  const ProbeScreen({super.key});
  @override
  State<ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<ProbeScreen> with WidgetsBindingObserver {
  final _ocr = OcrProbe();
  final _speech = SpeechProbe();
  final _picker = ImagePicker();
  final _paragraphs = <String>[];
  String? _imagePath;
  String? _error;
  String? _selection;
  int _selectedParagraph = -1;
  bool _busy = false;
  bool _recovering = true;
  bool _audioBusy = false;
  String _progress = '';
  String _locale = 'en-US';
  double _fontSize = 22;
  int _readBase = 0;
  bool _readingExcerpt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _speech.initialize();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo preparar la voz. Puedes seguir probando el reconocimiento.',
        );
      }
    }
    try {
      if (Platform.isAndroid) {
        final result = await _picker.retrieveLostData();
        if (result.files != null) await _import(result.files!);
        if (result.exception != null && mounted) {
          setState(
            () => _error =
                'La captura anterior no se pudo recuperar. Vuelve a elegirla.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo recuperar la captura anterior.');
      }
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_speech.pause());
  }

  Future<void> _audio(Future<void> Function() action) async {
    if (_audioBusy) return;
    setState(() {
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo reproducir. Revisa la voz y el idioma elegidos.',
        );
      }
    }
  }

  Future<void> _settings(Future<void> Function() action) async {
    if (_audioBusy) return;
    setState(() => _audioBusy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo cambiar la configuración de voz.');
      }
    } finally {
      if (mounted) setState(() => _audioBusy = false);
    }
  }

  Future<void> _listen({int? paragraph, String? excerpt}) async {
    _readBase = paragraph ?? 0;
    _readingExcerpt = excerpt != null;
    await _audio(
      () => _speech.play(
        excerpt != null
            ? [excerpt]
            : paragraph != null
            ? [_paragraphs[paragraph]]
            : _paragraphs,
      ),
    );
  }

  Future<void> _sample() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Leyendo la imagen de ejemplo…';
    });
    await _speech.stop();
    try {
      _append(await _ocr.sample());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos leer el ejemplo. Comprueba la instalación del OCR.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _append(OcrProbeResult result) {
    if (!mounted) return;
    setState(() {
      _imagePath = result.path;
      _paragraphs.addAll(result.paragraphs);
      _progress =
          '${result.paragraphs.length} bloques reconocidos · ${result.elapsed.inMilliseconds} ms';
      _selection = null;
      if (result.paragraphs.isEmpty) {
        _error =
            'No encontramos texto. Prueba con más luz o una foto más cercana.';
      }
    });
  }

  Future<void> _capture(bool camera) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = camera
          ? [await _picker.pickImage(source: ImageSource.camera)]
                .whereType<XFile>()
                .toList()
          : await _picker.pickMultiImage();
      if (files.isNotEmpty) await _import(files);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir las fotos. Revisa el permiso en Ajustes e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(List<XFile> files) async {
    await _speech.stop();
    var failed = 0;
    for (var i = 0; i < files.length; i++) {
      if (!mounted) break;
      setState(() => _progress = 'Leyendo foto ${i + 1} de ${files.length}…');
      try {
        _append(await _ocr.recognize(await _ocr.persist(files[i].path)));
      } catch (_) {
        failed++;
      }
    }
    if (failed > 0 && mounted) {
      setState(
        () => _error =
            '$failed fotos no se pudieron leer. Puedes seleccionarlas otra vez.',
      );
    }
  }

  Future<void> _edit(int index) async {
    await _speech.stop();
    if (!mounted) return;
    final controller = TextEditingController(text: _paragraphs[index]);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar el texto'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Texto del párrafo'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    // El controlador sigue vivo durante la animación de cierre del diálogo.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (text != null && mounted) {
      setState(() {
        _paragraphs[index] = text;
        _selection = null;
      });
    }
  }

  Widget _capturePanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'De una foto a una lectura',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade una página y escucha su texto en inglés. También puedes corregir lo que reconoce la cámara.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _busy || _recovering ? null : () => _capture(true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _recovering ? null : () => _capture(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir fotos'),
              ),
              TextButton.icon(
                key: const Key('sample'),
                onPressed: _busy || _recovering ? null : _sample,
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('Probar con un ejemplo'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_progress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_progress, key: const Key('ocr-status')),
            ),
          if (_imagePath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                semanticLabel: 'Última página reconocida. Su transcripción aparece en el lector.',
              ),
            ),
          ],
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _locale,
            decoration: const InputDecoration(labelText: 'Idioma del texto'),
            items: const [
              DropdownMenuItem(
                value: 'en-US',
                child: Text('Inglés · Estados Unidos'),
              ),
              DropdownMenuItem(
                value: 'en-GB',
                child: Text('Inglés · Reino Unido'),
              ),
              DropdownMenuItem(value: 'es-MX', child: Text('Español · México')),
            ],
            onChanged: !_speech.ready || _audioBusy
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _locale = value);
                      unawaited(_settings(() => _speech.setLocale(value)));
                    }
                  },
          ),
          const SizedBox(height: 16),
          if (_speech.ready)
            DropdownButtonFormField<String>(
              key: ValueKey('voice-${_speech.voice?.id}'),
              initialValue: _speech.voice?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Voz del dispositivo',
              ),
              items: _speech.voices
                  .where((v) => v.locale.startsWith(_locale.split('-').first))
                  .map(
                    (v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(
                        '${v.locale} · ${v.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _audioBusy
                  ? null
                  : (id) {
                      if (id != null) {
                        unawaited(
                          _settings(
                            () => _speech.selectVoice(
                              _speech.voices.firstWhere((v) => v.id == id),
                            ),
                          ),
                        );
                      }
                    },
            ),
          if (_speech.ready && _speech.voice == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No hay una voz compatible disponible. Configura una voz para este idioma en los ajustes de voz del dispositivo.',
              ),
            ),
          const SizedBox(height: 16),
          const Text('Velocidad'),
          Wrap(
            spacing: 8,
            children: [
              for (final item in [
                (0.3, 'Más lento'),
                (0.45, 'Normal'),
                (0.6, 'Más rápido'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _speech.rate == item.$1,
                  onSelected: _audioBusy || !_speech.ready
                      ? null
                      : (_) => _settings(() => _speech.setRate(item.$1)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tamaño del texto'),
          Slider(
            value: _fontSize,
            min: 18,
            max: 36,
            divisions: 9,
            label: _fontSize.round().toString(),
            onChanged: (value) => setState(() => _fontSize = value),
          ),
        ],
      ),
    ),
  );

  Widget _reader() => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leamos juntos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca una palabra para escucharla o mantén pulsado para seleccionar una frase.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('listen-book'),
                onPressed:
                    _paragraphs.isEmpty ||
                        _speech.voice == null ||
                        _busy ||
                        _audioBusy
                    ? null
                    : () => _listen(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Escuchar todo'),
              ),
              OutlinedButton.icon(
                onPressed: _speech.state == ProbePlayback.paused
                    ? () => _audio(_speech.resume)
                    : _speech.state == ProbePlayback.speaking
                    ? () => _audio(_speech.pause)
                    : null,
                icon: Icon(
                  _speech.state == ProbePlayback.paused
                      ? Icons.play_arrow
                      : Icons.pause,
                ),
                label: Text(
                  _speech.state == ProbePlayback.paused
                      ? 'Continuar'
                      : 'Pausar',
                ),
              ),
              IconButton(
                tooltip: 'Detener',
                onPressed: () => _audio(_speech.stop),
                icon: const Icon(Icons.stop),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(switch (_speech.state) {
            ProbePlayback.idle => 'Listo para escuchar',
            ProbePlayback.preparing => 'Preparando voz…',
            ProbePlayback.speaking => 'Leyendo…',
            ProbePlayback.paused =>
              'En pausa. Continuará desde el último límite disponible.',
            ProbePlayback.completed => 'Lectura terminada',
            ProbePlayback.failed => _speech.error ?? 'Error de voz',
          }, key: const Key('speech-status')),
          if (_selection != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selección: $_selection',
                    key: const Key('selection-label'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('listen-selection'),
                    onPressed: _speech.voice == null
                        ? null
                        : () => _listen(
                            paragraph: _selectedParagraph,
                            excerpt: _selection,
                          ),
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Escuchar selección'),
                  ),
                ],
              ),
            ),
          if (_paragraphs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Tu lectura aparecerá aquí.\nEmpieza con una foto o usa el ejemplo incluido.',
                style: TextStyle(fontSize: 20, height: 1.5),
              ),
            ),
          for (var i = 0; i < _paragraphs.length; i++)
            Container(
              key: ValueKey('paragraph-card-$i'),
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _speech.activeParagraph + _readBase == i &&
                          !_readingExcerpt &&
                          _speech.state == ProbePlayback.speaking
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Párrafo ${i + 1}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Escuchar párrafo ${i + 1}',
                        onPressed: _speech.voice == null || _busy
                            ? null
                            : () => _listen(paragraph: i),
                        icon: const Icon(Icons.volume_up_outlined),
                      ),
                      IconButton(
                        tooltip: 'Editar párrafo ${i + 1}',
                        onPressed: _busy ? null : () => _edit(i),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  ReadingParagraph(
                    key: ValueKey('paragraph-$i-${_paragraphs[i]}'),
                    text: _paragraphs[i],
                    fontSize: _fontSize,
                    onSelection: (TextRangeSlice? range) {
                      setState(() {
                        _selectedParagraph = i;
                        _selection = range?.extract(_paragraphs[i]);
                      });
                    },
                    onListen: (text) => _listen(paragraph: i, excerpt: text),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _speech,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('MySchoolMyParents'),
        actions: [
          IconButton(
            tooltip: 'Información de la prueba',
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Primera prueba · A00'),
                content: Text(
                  'Esta versión valida fotos, OCR y voz. El texto permanece durante esta sesión; todavía no crea libros persistentes.\n\nEventos de progreso recibidos: ${_speech.progressEvents}.\n\nNo se envían fotos a un servidor de OCR. Verifica la voz sin conexión antes de usar contenido privado.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Prueba inicial · El texto de esta sesión aún no se guarda como libro.',
                    ),
                  ),
                  if (_error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_error!)),
                            IconButton(
                              tooltip: 'Cerrar aviso',
                              onPressed: () => setState(() => _error = null),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= 840
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 4, child: _capturePanel()),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: _reader()),
                            ],
                          )
                        : Column(
                            children: [
                              _capturePanel(),
                              const SizedBox(height: 16),
                              _reader(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.dispose();
    unawaited(_ocr.close());
    super.dispose();
  }
}
