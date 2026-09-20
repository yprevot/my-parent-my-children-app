import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/app_database.dart';
import '../../core/storage/app_database.dart' as storage;
import '../../spike/ocr_probe.dart';
import '../../spike/reading_paragraph.dart';
import '../../spike/speech_probe.dart';
import 'image_transformer.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.database, required this.book});
  final AppDatabase database;
  final Book book;
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _ocr = OcrProbe();
  final _speech = SpeechProbe();
  String? _error;
  bool _busy = false;
  String _progress = '';
  String? _selection;
  int _selectedParagraph = -1;
  double _fontSize = 22;
  bool _queueBusy = false;
  late String _homeLocale;
  late String _learningLocale;
  Timer? _positionTimer;
  int _queuedPositionParagraph = 0;
  int _queuedPositionOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeLocale = widget.book.homeLocale;
    _learningLocale = widget.book.learningLocale;
    _speech.onPositionChanged = _onSpeechPosition;
    unawaited(_initializeSpeech());
    unawaited(_recoverAndProcess());
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speech.initialize(locale: _learningLocale);
      if (widget.book.voiceId != null) {
        final preferred = _speech.voices
            .where((item) => item.id == widget.book.voiceId)
            .firstOrNull;
        if (preferred != null) await _speech.selectVoice(preferred);
      }
      if ((widget.book.speechRate - _speech.rate).abs() > .001) {
        await _speech.setRate(widget.book.speechRate);
      }
    } catch (_) {
      // La lectura es opcional para importar páginas. No debe convertir un
      // fallo del motor TTS del dispositivo en una excepción de arranque.
      if (mounted) {
        setState(
          () => _progress = 'Texto listo. La lectura en voz alta no está disponible todavía en este dispositivo.',
        );
      }
    }
  }

  void _onSpeechPosition(int paragraph, int offset) {
    _queuedPositionParagraph = paragraph;
    _queuedPositionOffset = offset;
    _positionTimer?.cancel();
    _positionTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(
        widget.database.saveReadingPosition(
          widget.book.id,
          _queuedPositionParagraph,
          _queuedPositionOffset,
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_speech.pause());
    } else {
      unawaited(_initializeSpeech());
    }
  }

  Future<void> _add(bool camera) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = camera
          ? [await _picker.pickImage(source: ImageSource.camera)]
                .whereType<XFile>()
                .toList()
          : await _picker.pickMultiImage();
      if (files.isEmpty) {
        if (mounted) setState(() => _progress = 'No se añadieron fotos.');
        return;
      }
      final options = await _showImageOptions();
      if (options == null) return;
      for (var i = 0; i < files.length; i++) {
        if (!mounted) break;
        setState(
          () => _progress = 'Preparando foto ${i + 1} de ${files.length}…',
        );
        final persisted = await _ocr.persist(files[i].path);
        final adjusted = await transformImage(persisted, options);
        final pageId = '${DateTime.now().microsecondsSinceEpoch}_$i';
        await widget.database.createQueuedPage(
          bookId: widget.book.id,
          pageId: pageId,
          jobId: '${pageId}_job',
          imagePath: adjusted,
        );
      }
      final completed = await _runQueue();
      if (mounted) {
        setState(
          () => _progress = completed
              ? '${files.length} foto(s) lista(s) para revisión.'
              : 'Algunas fotos no pudieron leerse. Revisa el estado de cada página.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos procesar una de las fotos. Puedes intentarlo otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sample() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Procesando ejemplo…';
    });
    try {
      final result = await _ocr.sample();
      final pageId = DateTime.now().microsecondsSinceEpoch.toString();
      await widget.database.createQueuedPage(
        bookId: widget.book.id,
        pageId: pageId,
        jobId: '${pageId}_job',
        imagePath: result.path,
      );
      final completed = await _runQueue();
      if (mounted) {
        setState(
          () => _progress = completed
              ? 'Ejemplo listo para revisión.'
              : 'No pudimos leer el ejemplo. Revisa el estado de la página.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos procesar el ejemplo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recoverAndProcess() async {
    if (Platform.isAndroid) {
      try {
        final lost = await _picker.retrieveLostData();
        if (lost.files != null && lost.files!.isNotEmpty) {
          for (var i = 0; i < lost.files!.length; i++) {
            final file = lost.files![i];
            final persisted = await _ocr.persist(file.path);
            final pageId = '${DateTime.now().microsecondsSinceEpoch}_lost_$i';
            await widget.database.createQueuedPage(
              bookId: widget.book.id,
              pageId: pageId,
              jobId: '${pageId}_job',
              imagePath: persisted,
            );
          }
        }
      } catch (_) {}
    }
    await widget.database.recoverInterruptedJobs(widget.book.id);
    await _runQueue();
  }

  Future<bool> _runQueue() async {
    if (_queueBusy) return true;
    _queueBusy = true;
    var completed = true;
    try {
      while (true) {
        final jobs = await widget.database.queuedJobs(widget.book.id);
        if (jobs.isEmpty) break;
        for (final job in jobs) {
          completed = await _processJob(job) && completed;
        }
      }
    } finally {
      _queueBusy = false;
    }
    return completed;
  }

  Future<bool> _processJob(ImportJob job) async {
    final path = job.imagePath;
    if (path == null) {
      await widget.database.failJob(
        job,
        willRetry: false,
        errorCode: 'missing_image',
      );
      return false;
    }
    await widget.database.startJob(job.id);
    try {
      if (mounted) setState(() => _progress = 'Leyendo una página…');
      final result = await _ocr.recognize(path);
      await widget.database.saveDraft(
        bookId: job.bookId,
        pageId: job.pageId,
        jobId: job.id,
        rawText: result.rawText,
        paragraphs: result.paragraphs,
      );
      return true;
    } catch (_) {
      final current = await widget.database.findJob(job.id) ?? job;
      final willRetry = current.attempts < 3;
      await widget.database.failJob(
        current,
        willRetry: willRetry,
        errorCode: 'ocr_failed',
      );
      if (willRetry) {
        final seconds = 1 << (current.attempts - 1).clamp(0, 2);
        await Future<void>.delayed(Duration(seconds: seconds));
      }
      return willRetry;
    }
  }

  Future<ImageTransformOptions?> _showImageOptions() async {
    var cropFactor = 1.0;
    var quarterTurns = 0;
    return showDialog<ImageTransformOptions>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajustar páginas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Recorte centrado'),
              ),
              Slider(
                value: cropFactor,
                min: .65,
                max: 1,
                divisions: 7,
                label: '${(cropFactor * 100).round()}%',
                onChanged: (value) => setDialogState(() => cropFactor = value),
              ),
              DropdownButtonFormField<int>(
                initialValue: quarterTurns,
                decoration: const InputDecoration(labelText: 'Rotación'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Sin rotar')),
                  DropdownMenuItem(value: 1, child: Text('90° a la derecha')),
                  DropdownMenuItem(
                    value: -1,
                    child: Text('90° a la izquierda'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => quarterTurns = value ?? 0),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                ImageTransformOptions(
                  cropFactor: cropFactor,
                  quarterTurns: quarterTurns,
                ),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: widget.book.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar libro'),
        content: TextField(controller: controller),
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (title != null && title.trim().isNotEmpty) {
      await widget.database.updateBookTitle(widget.book.id, title);
    }
  }

  Future<void> _listen(
    List<Paragraph> paragraphs, {
    int? index,
    String? excerpt,
    int? startOffset,
  }) async {
    try {
      if (excerpt != null) {
        await _speech.play(
          [excerpt],
          startParagraph: 0,
          startOffset: 0,
          activeParagraphBase: index ?? 0,
        );
      } else if (index != null) {
        await _speech.play(
          [paragraphs[index].content],
          startParagraph: 0,
          startOffset: startOffset ?? 0,
          activeParagraphBase: index,
        );
      } else {
        // Enviar la lista de todos los párrafos individuales para que el motor
        // TTS avance entre párrafos de forma secuencial y actualice activeParagraph.
        await _speech.play(
          paragraphs.map((p) => p.content).toList(),
          startParagraph: 0,
          startOffset: 0,
          activeParagraphBase: 0,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo reproducir. Revisa la voz instalada para $_learningLocale.',
        );
      }
    }
  }

  Future<void> _resume(List<Paragraph> paragraphs) async {
    if (paragraphs.isEmpty) return;
    final currentBook =
        await widget.database.findBook(widget.book.id) ?? widget.book;
    final pIndex =
        currentBook.lastParagraph.clamp(0, paragraphs.length - 1);
    final offset = currentBook.lastOffset;
    try {
      await _speech.play(
        paragraphs.map((p) => p.content).toList(),
        startParagraph: pIndex,
        startOffset: offset,
        activeParagraphBase: 0,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo reanudar la lectura. Revisa la voz instalada para $_learningLocale.',
        );
      }
    }
  }

  Future<void> _goToParagraph(
    List<Paragraph> paragraphs,
    int targetIndex,
  ) async {
    if (targetIndex < 0 || targetIndex >= paragraphs.length) return;
    try {
      await _speech.play(
        paragraphs.map((p) => p.content).toList(),
        startParagraph: targetIndex,
        startOffset: 0,
        activeParagraphBase: 0,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo cambiar de párrafo. Revisa la voz instalada para $_learningLocale.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.book.title),
      actions: [
        IconButton(
          tooltip: 'Renombrar libro',
          onPressed: _rename,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: _speech,
      builder: (context, _) => StreamBuilder<List<Paragraph>>(
        stream: widget.database.watchParagraphs(widget.book.id),
        builder: (context, snapshot) =>
            _body(context, snapshot.data ?? const <Paragraph>[]),
      ),
    ),
  );

  Widget _body(BuildContext context, List<Paragraph> paragraphs) {
    return StreamBuilder<List<PageDraft>>(
      stream: widget.database.watchDrafts(widget.book.id),
      builder: (context, draftSnapshot) => StreamBuilder<List<storage.Page>>(
        stream: widget.database.watchPages(widget.book.id),
        builder: (context, pageSnapshot) => StreamBuilder<List<ImportJob>>(
          stream: widget.database.watchJobs(widget.book.id),
          builder: (context, jobSnapshot) => _bodyWithDrafts(
            context,
            paragraphs,
            draftSnapshot.data ?? const <PageDraft>[],
            pageSnapshot.data ?? const <storage.Page>[],
            jobSnapshot.data ?? const <ImportJob>[],
          ),
        ),
      ),
    );
  }

  Widget _bodyWithDrafts(
    BuildContext context,
    List<Paragraph> paragraphs,
    List<PageDraft> drafts,
    List<storage.Page> pages,
    List<ImportJob> jobs,
  ) {
    final jobsById = {for (final job in jobs) job.id: job};
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Añadir páginas', style: Theme.of(context).textTheme.titleLarge),
        FilledButton.icon(
          onPressed: _busy ? null : () => _add(true),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Tomar foto'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _add(false),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Elegir fotos'),
        ),
        TextButton.icon(
          onPressed: _busy ? null : _sample,
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('Usar ejemplo'),
        ),
        if (_busy)
          Semantics(
            label: 'Procesando páginas',
            liveRegion: true,
            child: SizedBox(width: 140, child: LinearProgressIndicator()),
          ),
        if (_progress.isNotEmpty)
          Semantics(liveRegion: true, label: _progress, child: Text(_progress)),
      ],
    );
    final reading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Lectura', style: Theme.of(context).textTheme.headlineSmall),
            FilledButton.icon(
              onPressed: paragraphs.isEmpty || _speech.voice == null
                  ? null
                  : () => _listen(paragraphs),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Escuchar todo'),
            ),
            OutlinedButton.icon(
              onPressed: paragraphs.isEmpty || _speech.voice == null
                  ? null
                  : () => _resume(paragraphs),
              icon: const Icon(Icons.history_outlined),
              label: const Text('Continuar'),
            ),
            IconButton(
              tooltip: 'Pausar o continuar',
              onPressed: _speech.state == ProbePlayback.speaking
                  ? _speech.pause
                  : _speech.state == ProbePlayback.paused
                  ? _speech.resume
                  : null,
              icon: Icon(
                _speech.state == ProbePlayback.paused
                    ? Icons.play_arrow
                    : Icons.pause,
              ),
            ),
            IconButton(
              tooltip: 'Detener lectura',
              onPressed: _speech.state == ProbePlayback.speaking ||
                      _speech.state == ProbePlayback.paused
                  ? _speech.stop
                  : null,
              icon: const Icon(Icons.stop_outlined),
            ),
            IconButton(
              tooltip: 'Párrafo anterior',
              onPressed: _speech.activeParagraph > 0
                  ? () => _goToParagraph(paragraphs, _speech.activeParagraph - 1)
                  : null,
              icon: const Icon(Icons.skip_previous_outlined),
            ),
            IconButton(
              tooltip: 'Repetir párrafo',
              onPressed: _speech.activeParagraph >= 0
                  ? () => _goToParagraph(paragraphs, _speech.activeParagraph)
                  : null,
              icon: const Icon(Icons.replay_outlined),
            ),
            IconButton(
              tooltip: 'Párrafo siguiente',
              onPressed: _speech.activeParagraph >= 0 &&
                      _speech.activeParagraph < paragraphs.length - 1
                  ? () => _goToParagraph(paragraphs, _speech.activeParagraph + 1)
                  : null,
              icon: const Icon(Icons.skip_next_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.format_size_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tamaño del texto',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              '${_fontSize.round()} pt',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Semantics(
          label: 'Tamaño del texto, ${_fontSize.round()} puntos',
          child: Slider(
            value: _fontSize,
            min: 18,
            max: 36,
            divisions: 9,
            label: '${_fontSize.round()} pt',
            onChanged: (v) => setState(() => _fontSize = v),
          ),
        ),
        if (paragraphs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Todavía no hay páginas aprobadas. Añade una foto para empezar.',
              style: TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: reading,
                  ),
                ),
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!),
                    ),
                  ),
                for (final draft in drafts)
                  _draftCard(
                    context,
                    draft,
                    imagePath: jobsById[draft.jobId]?.imagePath,
                  ),
                if (pages.isNotEmpty)
                  _pagesCard(context, pages, jobs, paragraphs),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: controls,
                  ),
                ),
                _audioSettingsCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioSettingsCard(BuildContext context) {
    final selected = _speech.voice;
    final learningLanguage = _learningLocale.split('-').first.toLowerCase();
    final filteredVoices = _speech.voices
        .where(
          (item) =>
              item.locale.split('-').first.toLowerCase() == learningLanguage,
        )
        .toList();
    String friendlyLearning() => switch (_learningLocale) {
      'en-US' => 'English',
      'en-GB' => 'English (UK)',
      'es-MX' => 'Español',
      _ => _learningLocale,
    };
    final subtitle = selected == null
        ? 'Leer en ${friendlyLearning()} · elige voz'
        : 'Leer en ${friendlyLearning()} · ${selected.name}';
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.tune_outlined),
        title: const Text('Idioma y voz'),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _homeLocale == 'es-MX' ? _homeLocale : 'es-MX',
                decoration: const InputDecoration(
                  labelText: 'Idioma nativo de la familia',
                ),
                items: const [
                  DropdownMenuItem(value: 'es-MX', child: Text('Español')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _homeLocale = value);
                  unawaited(
                    widget.database.updateBookLanguages(
                      widget.book.id,
                      homeLocale: value,
                      learningLocale: _learningLocale,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _learningLocale,
                decoration: const InputDecoration(
                  labelText: 'Idioma que vamos a leer',
                ),
                items: const [
                  DropdownMenuItem(value: 'en-US', child: Text('English')),
                  DropdownMenuItem(value: 'es-MX', child: Text('Español')),
                ],
                onChanged: _changeLearningLanguage,
              ),
              const Divider(height: 28),
              Text(
                'Voz de lectura',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProbeVoice>(
                initialValue: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _speech.ready
                      ? 'Voz para ${friendlyLearning()}'
                      : 'Cargando voces…',
                  helperText: !_speech.ready
                      ? null
                      : selected == null
                      ? 'Activa una voz de texto a voz en Ajustes del teléfono para habilitar la lectura.'
                      : selected.requiresNetwork == true
                      ? 'Esta voz requiere conexión.'
                      : 'La voz local funciona sin conexión.',
                ),
                items: filteredVoices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text('${item.name} (${item.locale})'),
                      ),
                    )
                    .toList(),
                onChanged: (voice) =>
                    voice == null ? null : _selectVoice(voice),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openTtsSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Configurar voz del teléfono'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.speed_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Velocidad de lectura',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    _speech.rate < .4
                        ? 'Lenta'
                        : _speech.rate > .6
                        ? 'Rápida'
                        : 'Normal',
                  ),
                ],
              ),
              Semantics(
                label: 'Velocidad de lectura',
                child: Slider(
                  value: _speech.rate,
                  min: .2,
                  max: .8,
                  divisions: 12,
                  label: _speech.rate.toStringAsFixed(2),
                  onChanged: (value) => unawaited(_setSpeechRate(value)),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _speech.rate <= .2
                        ? null
                        : () => unawaited(
                            _setSpeechRate((_speech.rate - .05).clamp(.2, .8)),
                          ),
                    icon: const Icon(Icons.slow_motion_video_outlined),
                    label: const Text('Más lento'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _speech.rate >= .8
                        ? null
                        : () => unawaited(
                            _setSpeechRate((_speech.rate + .05).clamp(.2, .8)),
                          ),
                    icon: const Icon(Icons.speed_outlined),
                    label: const Text('Más rápido'),
                  ),
                ],
              ),
              if (_speech.error != null)
                Text(
                  _speech.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectVoice(ProbeVoice selected) async {
    try {
      await _speech.selectVoice(selected);
      await widget.database.updateReadingPreferences(
        widget.book.id,
        voiceId: selected.id,
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo activar esa voz.');
    }
  }

  Future<void> _changeLearningLanguage(String? value) async {
    if (value == null || value == _learningLocale) return;
    setState(() {
      _learningLocale = value;
      _speech.voice = null;
    });
    await widget.database.updateBookLanguages(
      widget.book.id,
      homeLocale: _homeLocale,
      learningLocale: value,
    );
    await _initializeSpeech();
  }

  Future<void> _openTtsSettings() async {
    final opened = await _speech.openTtsSettings();
    if (!opened && mounted) {
      setState(
        () => _error = 'No se pudo abrir los ajustes de voz. Ábrelos desde Ajustes > Administración general > Texto a voz.',
      );
    }
  }

  Future<void> _setSpeechRate(double value) async {
    await _speech.setRate(value);
    await widget.database.updateReadingPreferences(
      widget.book.id,
      speechRate: value,
    );
  }

  Widget _pagesCard(
    BuildContext context,
    List<storage.Page> pages,
    List<ImportJob> jobs,
    List<Paragraph> paragraphs,
  ) {
    final jobsByPage = {for (final job in jobs) job.pageId: job};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Páginas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final job = jobsByPage[page.id];
                final status = job?.state == 'failed'
                    ? 'Error: ${job?.errorCode ?? 'OCR'}'
                    : _pageStatusLabel(page.status);
                final pageParagraphs = paragraphs
                    .where((paragraph) => paragraph.pageId == page.id)
                    .toList();
                return Semantics(
                  key: ValueKey(page.id),
                  container: true,
                  label: 'Página ${index + 1}. Estado: $status.',
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('Página ${index + 1}'),
                    subtitle: Text(
                      '$status · ${pageParagraphs.length} párrafo(s)',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones de página',
                      onSelected: (value) {
                        if (value == 'up') {
                          _movePage(index, index - 1);
                        } else if (value == 'down') {
                          _movePage(index, index + 1);
                        } else if (value == 'reprocess') {
                          _reprocess(page);
                        } else if (value == 'delete') {
                          _deletePage(page);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'up',
                          enabled: index != 0,
                          child: const ListTile(
                            leading: Icon(Icons.keyboard_arrow_up),
                            title: Text('Subir página'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'down',
                          enabled: index != pages.length - 1,
                          child: const ListTile(
                            leading: Icon(Icons.keyboard_arrow_down),
                            title: Text('Bajar página'),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'reprocess',
                          enabled: page.originalPath != null && !_busy,
                          child: const ListTile(
                            leading: Icon(Icons.refresh),
                            title: Text('Reprocesar foto'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline, color: Colors.red),
                            title: Text('Eliminar página', style: TextStyle(color: Colors.red)),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    children: pageParagraphs.isEmpty
                        ? const [
                            ListTile(
                              title: Text(
                                'Esta página aún no tiene texto aprobado.',
                              ),
                            ),
                          ]
                        : [
                            for (
                              var paragraphIndex = 0;
                              paragraphIndex < pageParagraphs.length;
                              paragraphIndex++
                            )
                              _paragraphCard(
                                context,
                                paragraphs,
                                paragraphs.indexOf(
                                  pageParagraphs[paragraphIndex],
                                ),
                                pageNumber: index + 1,
                                paragraphNumber: paragraphIndex + 1,
                              ),
                          ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _pageStatusLabel(String status) => switch (status) {
    'approved' => 'Añadida al libro',
    'review' => 'Lista para revisar',
    'reprocessing' => 'Reprocesando',
    'error' => 'Error de lectura',
    _ => 'Pendiente',
  };

  Future<void> _movePage(int oldIndex, int newIndex) async {
    await widget.database.reorderPages(widget.book.id, oldIndex, newIndex);
    if (mounted) setState(() => _progress = 'Orden de páginas actualizado.');
  }

  Future<void> _reprocess(storage.Page page) async {
    await widget.database.queueReprocess(page);
    await _runQueue();
    if (mounted) {
      setState(
        () => _progress =
            'Página marcada para reprocesar; el texto anterior se conserva hasta aprobar el nuevo.',
      );
    }
  }

  Future<void> _deletePage(storage.Page page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta página?'),
        content: const Text(
          'Se eliminarán sus fotos y párrafos del libro. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.database.deletePage(page.id);
      if (mounted) {
        setState(() => _progress = 'Página eliminada.');
      }
    }
  }

  void _showImageZoom(String imagePath) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Foto de la página'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftCard(
    BuildContext context,
    PageDraft draft, {
    String? imagePath,
  }) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pendiente por revisar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Compara con la foto. Corrige, separa párrafos con línea en blanco o quita encabezados antes de añadirla.',
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showImageZoom(imagePath),
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 48,
                        child: Center(
                          child: Text('La foto original ya no está disponible.'),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Toca para ampliar',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Texto detectado (${draft.rawText.length} caracteres):',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                draft.rawText.isEmpty ? 'No se detectó texto.' : draft.rawText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Solo entra al libro y a la lectura al pulsar «Añadir al libro».',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _approveDraft(draft),
                icon: const Icon(Icons.check),
                label: const Text('Añadir al libro'),
              ),
              OutlinedButton.icon(
                onPressed: () => _editDraft(draft),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Corregir texto'),
              ),
              OutlinedButton.icon(
                onPressed: () => _retryDraft(draft),
                icon: const Icon(Icons.refresh),
                label: const Text('Reprocesar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _retryDraft(PageDraft draft) async {
    await widget.database.retryJob(draft);
    await _runQueue();
    if (mounted) setState(() => _progress = 'Página marcada para reintento.');
  }

  Future<void> _approveDraft(PageDraft draft) async {
    try {
      final paragraphs = List<String>.from(
        jsonDecode(draft.paragraphsJson) as List,
      );
      await _saveApprovedDraft(draft, paragraphs);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo añadir esta página. Inténtalo de nuevo o usa «Editar texto».',
        );
      }
    }
  }

  Future<void> _editDraft(PageDraft draft) async {
    final initial = List<String>.from(jsonDecode(draft.paragraphsJson) as List);
    final controller = TextEditingController(text: initial.join('\n\n'));
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisar texto OCR'),
        content: SizedBox(
          width: 700,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Corrige antes de añadir al libro',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context, controller.text);
            },
            child: const Text('Añadir al libro'),
          ),
        ],
      ),
    );
    if (edited == null || !mounted) {
      controller.dispose();
      return;
    }
    // Deja que el diálogo y su FocusScope terminen de desmontarse antes de
    // que los streams de páginas reconstruyan la pantalla del libro.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    controller.dispose();
    final paragraphs = edited
        .split(RegExp(r'\n\s*\n'))
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    await _saveApprovedDraft(draft, paragraphs);
  }

  Future<void> _saveApprovedDraft(
    PageDraft draft,
    List<String> paragraphs,
  ) async {
    if (paragraphs.every((text) => text.trim().isEmpty)) {
      if (mounted) {
        setState(() => _error = 'La página no contiene texto para añadir.');
      }
      return;
    }
    await widget.database.approveDraft(draft, paragraphs);
    if (mounted) {
      setState(() {
        _error = null;
        _progress = 'Página añadida al libro.';
      });
    }
  }

  Widget _paragraphCard(
    BuildContext context,
    List<Paragraph> paragraphs,
    int index, {
    required int pageNumber,
    required int paragraphNumber,
  }) {
    final content = paragraphs[index].content;
    final isActive = _speech.activeParagraph == index;
    final isSpeaking = isActive && _speech.state == ProbePlayback.speaking;
    final activeWord = isSpeaking ? _speech.currentWordRange : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Página $pageNumber · párrafo $paragraphNumber',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _speech.voice == null
                        ? null
                        : () => _listen(paragraphs, index: index),
                    icon: const Icon(Icons.volume_up_outlined, size: 20),
                    label: const Text('Escuchar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ReadingParagraph(
                text: content,
                fontSize: _fontSize,
                activeWordRange: activeWord,
                onSelection: (range) => setState(() {
                  _selectedParagraph = index;
                  _selection = range?.extract(content);
                }),
                onListen: (text) =>
                    _listen(paragraphs, index: index, excerpt: text),
              ),
              if (_selection != null && _selectedParagraph == index)
                TextButton.icon(
                  onPressed: _speech.voice == null
                      ? null
                      : () => _listen(
                          paragraphs,
                          index: index,
                          excerpt: _selection,
                        ),
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Escuchar selección'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionTimer?.cancel();
    _speech.dispose();
    unawaited(_ocr.close());
    super.dispose();
  }
}
