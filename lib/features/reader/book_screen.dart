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
  }) async {
    try {
      await _speech.play(
        excerpt != null
            ? [excerpt]
            : index == null
            ? [paragraphs.map((p) => p.content).join('\n\n')]
            : [paragraphs[index].content],
        // "Escuchar todo" es una acción explícita de reinicio. La posición
        // guardada se reserva para una futura acción de continuar.
        startParagraph: 0,
        startOffset: 0,
        activeParagraphBase: index ?? 0,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo reproducir. Revisa la voz instalada para $_learningLocale.',
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
          ],
        ),
        Semantics(
          label: 'Tamaño del texto, ${_fontSize.round()} puntos',
          child: Slider(
            value: _fontSize,
            min: 18,
            max: 36,
            divisions: 9,
            label: _fontSize.round().toString(),
            onChanged: (v) => setState(() => _fontSize = v),
          ),
        ),
        if (paragraphs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Todavía no hay páginas aprobadas. Añade una foto para empezar.',
              style: TextStyle(fontSize: 20),
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
                    padding: const EdgeInsets.all(20),
                    child: controls,
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
                _audioSettingsCard(context),
                if (pages.isNotEmpty)
                  _pagesCard(context, pages, jobs, paragraphs),
                for (final draft in drafts)
                  _draftCard(
                    context,
                    draft,
                    imagePath: jobsById[draft.jobId]?.imagePath,
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: reading,
                  ),
                ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Idiomas del libro',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
                    ? 'Voz para $_learningLocale'
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
              onChanged: (voice) => voice == null ? null : _selectVoice(voice),
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
                const Text('Velocidad'),
                Expanded(
                  child: Semantics(
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
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('Página ${index + 1}'),
                    subtitle: Text(
                      '$status · ${pageParagraphs.length} párrafo(s)',
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: 'Subir página',
                          onPressed: index == 0
                              ? null
                              : () => _movePage(index, index - 1),
                          icon: const Icon(Icons.keyboard_arrow_up),
                        ),
                        IconButton(
                          tooltip: 'Bajar página',
                          onPressed: index == pages.length - 1
                              ? null
                              : () => _movePage(index, index + 1),
                          icon: const Icon(Icons.keyboard_arrow_down),
                        ),
                        IconButton(
                          tooltip: 'Reprocesar foto',
                          onPressed: page.originalPath == null || _busy
                              ? null
                              : () => _reprocess(page),
                          icon: const Icon(Icons.refresh),
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
        () => _progress = 'Página marcada para reprocesar; el texto anterior se conserva hasta aprobar el nuevo.',
      );
    }
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
          Text(
            'Revisa esta página antes de añadirla',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Compara el texto detectado con la foto. Corrige palabras, separa párrafos o elimina encabezados antes de confirmarlo.',
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 12),
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
          ],
          const SizedBox(height: 12),
          Text(
            'Vista previa (${draft.rawText.length} caracteres):',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 180),
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              child: SelectableText(
                draft.rawText.isEmpty ? 'No se detectó texto.' : draft.rawText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'El texto no entra al libro ni a la lectura hasta que pulses «Añadir al libro».',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _approveDraft(draft),
                icon: const Icon(Icons.check),
                label: const Text('Añadir al libro'),
              ),
              OutlinedButton.icon(
                onPressed: () => _editDraft(draft),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar texto'),
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: _speech.activeParagraph == index
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  IconButton(
                    tooltip: 'Escuchar párrafo',
                    onPressed: _speech.voice == null
                        ? null
                        : () => _listen(paragraphs, index: index),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                ],
              ),
              ReadingParagraph(
                text: content,
                fontSize: _fontSize,
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
