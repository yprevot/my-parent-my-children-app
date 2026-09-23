import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/export/book_export_import_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/app_database.dart' as storage;
import '../../spike/ocr_probe.dart';
import '../../spike/reading_paragraph.dart';
import '../../spike/speech_probe.dart';
import '../../spike/text_ranges.dart';
import 'image_transformer.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.database, required this.book});
  final AppDatabase database;
  final Book book;
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _PdfImportConfig {
  const _PdfImportConfig({
    required this.startPage,
    required this.endPage,
    required this.mergeTexts,
    required this.autoApprove,
  });
  final int startPage;
  final int endPage;
  final bool mergeTexts;
  final bool autoApprove;
}

class _BookScreenState extends State<BookScreen> with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _ocr = OcrProbe();
  final _speech = SpeechProbe();
  String? _error;
  bool _busy = false;
  String _progress = '';
  String? _selection;
  TextRangeSlice? _selectedRange;
  int _selectedParagraph = -1;
  double _fontSize = 22;
  bool _queueBusy = false;
  late String _homeLocale;
  late String _learningLocale;
  Timer? _positionTimer;
  int _queuedPositionParagraph = 0;
  int _queuedPositionOffset = 0;
  int _selectedTabIndex = 0;
  int _bookViewPageIndex = 0;

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
          ? [
              await _picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 2048,
                maxHeight: 2048,
                imageQuality: 90,
              ),
            ].whereType<XFile>().toList()
          : await _picker.pickMultiImage(
              maxWidth: 2048,
              maxHeight: 2048,
              imageQuality: 90,
            );
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
    } catch (e, stack) {
      debugPrint('Error en _add al procesar fotos: $e\n$stack');
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

  Future<void> _addPdf() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = 'Seleccionando archivo PDF…';
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (picked.isEmpty || picked.first.path == null) {
        if (mounted) setState(() => _progress = 'No se seleccionó ningún archivo PDF.');
        return;
      }

      final pdfPath = picked.first.path!;
      final pdfName = picked.first.name;

      if (mounted) setState(() => _progress = 'Analizando PDF…');
      final totalPages = await _ocr.getPdfPageCount(pdfPath);
      if (totalPages <= 0) {
        if (mounted) setState(() => _error = 'El PDF no contiene páginas legibles.');
        return;
      }

      final _PdfImportConfig config;
      if (totalPages > 1 && mounted) {
        final dialogConfig = await showDialog<_PdfImportConfig>(
          context: context,
          builder: (context) {
            var selectedAll = true;
            var mergeTexts = true;
            var autoApprove = false;
            var from = 1;
            var to = totalPages.clamp(1, 20);
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Importar páginas del PDF',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pdfName ($totalPages páginas)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: true,
                                label: Text('Todas (1-$totalPages)'),
                                icon: const Icon(Icons.select_all),
                              ),
                              const ButtonSegment(
                                value: false,
                                label: Text('Rango'),
                                icon: Icon(Icons.view_array_outlined),
                              ),
                            ],
                            selected: {selectedAll},
                            onSelectionChanged: (val) => setDialogState(() => selectedAll = val.first),
                          ),
                        ),
                        if (!selectedAll) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '$from',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Desde',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    from = int.tryParse(val) ?? 1;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '$to',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Hasta',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    to = int.tryParse(val) ?? totalPages;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.join_inner_rounded),
                          title: const Text('Juntar los textos'),
                          subtitle: const Text(
                            'Une todos los párrafos de las páginas en una sola lectura continua.',
                          ),
                          value: mergeTexts,
                          onChanged: (val) => setDialogState(() => mergeTexts = val),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.check_circle_outline),
                          title: const Text('Añadir directo al libro'),
                          subtitle: const Text(
                            'Guarda los párrafos sin tener que aprobarlos uno por uno.',
                          ),
                          value: autoApprove,
                          onChanged: (val) => setDialogState(() => autoApprove = val),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final f = selectedAll ? 0 : (from - 1).clamp(0, totalPages - 1);
                        final t = selectedAll ? totalPages - 1 : (to - 1).clamp(f, totalPages - 1);
                        Navigator.pop(
                          context,
                          _PdfImportConfig(
                            startPage: f,
                            endPage: t,
                            mergeTexts: mergeTexts,
                            autoApprove: autoApprove,
                          ),
                        );
                      },
                      child: const Text('Importar'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (dialogConfig == null) {
          if (mounted) setState(() => _progress = 'Importación cancelada.');
          return;
        }
        config = dialogConfig;
      } else {
        config = const _PdfImportConfig(
          startPage: 0,
          endPage: 0,
          mergeTexts: false,
          autoApprove: false,
        );
      }

      final pageCount = config.endPage - config.startPage + 1;
      final directory = await getApplicationSupportDirectory();
      final capturesDir = Directory('${directory.path}/a00-captures');
      await capturesDir.create(recursive: true);

      if (config.mergeTexts && pageCount > 1) {
        final combinedParagraphs = <String>[];
        final combinedRaw = StringBuffer();
        String? coverImagePath;

        for (var pageIdx = config.startPage; pageIdx <= config.endPage; pageIdx++) {
          if (!mounted) break;
          final currentNum = pageIdx - config.startPage + 1;
          setState(() => _progress = 'Leyendo página $currentNum de $pageCount…');

          final pageId = '${DateTime.now().microsecondsSinceEpoch}_pdf_$pageIdx';
          final targetPath = '${capturesDir.path}/$pageId.png';

          final result = await _ocr.processPdfPage(
            path: pdfPath,
            page: pageIdx,
            targetPath: targetPath,
          );

          coverImagePath ??= result.imagePath ?? targetPath;

          for (final p in result.paragraphs) {
            final trimmed = p.trim();
            if (trimmed.isNotEmpty) combinedParagraphs.add(trimmed);
          }
          if (result.rawText.trim().isNotEmpty) {
            if (combinedRaw.isNotEmpty) combinedRaw.write('\n\n');
            combinedRaw.write(result.rawText.trim());
          }
        }

        if (combinedParagraphs.isEmpty && combinedRaw.isNotEmpty) {
          combinedParagraphs.add(combinedRaw.toString().trim());
        }

        final mergedPageId = '${DateTime.now().microsecondsSinceEpoch}_pdf_merged';
        final mergedJobId = '${mergedPageId}_job';

        await widget.database.createQueuedPage(
          bookId: widget.book.id,
          pageId: mergedPageId,
          jobId: mergedJobId,
          imagePath: coverImagePath,
        );

        await widget.database.saveDraft(
          bookId: widget.book.id,
          pageId: mergedPageId,
          jobId: mergedJobId,
          rawText: combinedRaw.toString(),
          paragraphs: combinedParagraphs,
        );

        if (config.autoApprove) {
          final draft = await (widget.database.select(widget.database.pageDrafts)
                ..where((d) => d.id.equals(mergedJobId)))
              .getSingleOrNull();
          if (draft != null) {
            await widget.database.approveDraft(draft, combinedParagraphs);
          }
          if (mounted) {
            setState(() {
              _progress = '$pageCount páginas del PDF unidas y añadidas al libro.';
              _selectedTabIndex = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _progress = '$pageCount páginas del PDF unidas en un borrador listo para revisar.';
              _selectedTabIndex = 2;
            });
          }
        }
      } else {
        var importedCount = 0;
        for (var pageIdx = config.startPage; pageIdx <= config.endPage; pageIdx++) {
          if (!mounted) break;
          final currentNum = pageIdx - config.startPage + 1;
          setState(() => _progress = 'Procesando página $currentNum de $pageCount…');

          final pageId = '${DateTime.now().microsecondsSinceEpoch}_pdf_$pageIdx';
          final jobId = '${pageId}_job';
          final targetPath = '${capturesDir.path}/$pageId.png';

          final result = await _ocr.processPdfPage(
            path: pdfPath,
            page: pageIdx,
            targetPath: targetPath,
          );

          await widget.database.createQueuedPage(
            bookId: widget.book.id,
            pageId: pageId,
            jobId: jobId,
            imagePath: result.imagePath ?? targetPath,
          );

          await widget.database.saveDraft(
            bookId: widget.book.id,
            pageId: pageId,
            jobId: jobId,
            rawText: result.rawText,
            paragraphs: result.paragraphs,
          );

          if (config.autoApprove) {
            final draft = await (widget.database.select(widget.database.pageDrafts)
                  ..where((d) => d.id.equals(jobId)))
                .getSingleOrNull();
            if (draft != null) {
              await widget.database.approveDraft(draft, result.paragraphs);
            }
          }

          importedCount++;
        }

        if (mounted) {
          setState(() {
            if (config.autoApprove) {
              _progress = '$importedCount páginas del PDF añadidas al libro.';
              _selectedTabIndex = 0;
            } else {
              _progress = '$importedCount página(s) de PDF listas para revisar.';
              _selectedTabIndex = 2;
            }
          });
        }
      }
    } catch (e, stack) {
      debugPrint('Error en _addPdf: $e\n$stack');
      if (mounted) {
        setState(() => _error = 'No pudimos procesar el archivo PDF. Asegúrate de que sea un documento válido.');
      }
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
    } catch (e, stack) {
      debugPrint('Error en _processJob para job ${job.id} con ruta $path: $e\n$stack');
      final current = await widget.database.findJob(job.id) ?? job;
      final willRetry = current.attempts < 3;
      final errorCode = e is PlatformException ? e.code : 'ocr_failed';
      await widget.database.failJob(
        current,
        willRetry: willRetry,
        errorCode: errorCode,
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

  Future<void> _exportCurrentBook() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exportando libro en Modo Lectura...'),
          duration: Duration(seconds: 1),
        ),
      );

      final result = await BookExportImportService.instance.exportBookToFile(
        database: widget.database,
        bookId: widget.book.id,
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'No se pudo exportar el libro.'),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Color(0xff15803d), size: 40),
          title: const Text('Libro exportado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El libro «${widget.book.title}» se exportó en formato JSON compatible con Modo Lectura.',
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Archivo: ${result.fileName}\n${result.filePath != null ? 'Ubicación: ${result.filePath}' : ''}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.totalParagraphs} párrafos y ${result.totalPages} página(s) incluidos.',
                style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar libro: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _listen(
    List<Paragraph> paragraphs, {
    int? index,
    String? excerpt,
    TextRangeSlice? excerptRange,
    int? startOffset,
  }) async {
    try {
      if (excerpt != null) {
        TextRangeSlice? resolvedRange = excerptRange;
        if (resolvedRange == null &&
            index != null &&
            index >= 0 &&
            index < paragraphs.length) {
          final content = paragraphs[index].content;
          final matchIndex = content.indexOf(excerpt);
          if (matchIndex != -1) {
            resolvedRange =
                TextRangeSlice(matchIndex, matchIndex + excerpt.length);
          }
        }
        await _speech.play(
          [excerpt],
          startParagraph: 0,
          startOffset: 0,
          activeParagraphBase: index ?? 0,
          wordRange: resolvedRange,
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

  void _showFontSizeDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tamaño del texto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_fontSize.round()} pt',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _fontSize,
                min: 18,
                max: 36,
                divisions: 9,
                label: '${_fontSize.round()} pt',
                onChanged: (v) {
                  setDialogState(() => _fontSize = v);
                  setState(() => _fontSize = v);
                },
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _bottomPlayerBar(List<Paragraph> paragraphs) {
    if (paragraphs.isEmpty) return null;
    final isSpeaking = _speech.state == ProbePlayback.speaking;
    final isPaused = _speech.state == ProbePlayback.paused;
    final activeIndex = _speech.activeParagraph;
    final total = paragraphs.length;
    final progressText = activeIndex >= 0 && activeIndex < total
        ? 'Párrafo ${activeIndex + 1} de $total'
        : 'Listo para leer ($total párrafos)';

    final isSlow = _speech.rate < 0.40;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xffede6db),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180f172a),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x0a000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Indicador y conmutador rápido de velocidad para niños
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final newRate = isSlow ? 0.45 : 0.32;
                  await _speech.setRate(newRate);
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSlow ? const Color(0xfffef3c7) : const Color(0xfff1f5f9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSlow ? const Color(0xfffcd34d) : const Color(0xffe2e8f0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isSlow ? '🐢 0.3x' : '🐇 0.45x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSlow ? const Color(0xff92400e) : const Color(0xff475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_mute_rounded,
                          size: 16,
                          color: const Color(0xff1d4ed8),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            progressText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xff1e293b),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _speech.voice?.name ?? 'Voz estándar ($_learningLocale)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Párrafo anterior',
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: activeIndex > 0
                    ? () => _goToParagraph(paragraphs, activeIndex - 1)
                    : null,
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xff1d4ed8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                  iconSize: 24,
                ),
                tooltip: isSpeaking
                    ? 'Pausar'
                    : (isPaused ? 'Continuar' : 'Escuchar todo'),
                icon: Icon(
                  isSpeaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                onPressed: _speech.voice == null
                    ? null
                    : () {
                        if (isSpeaking) {
                          _speech.pause();
                        } else if (isPaused) {
                          _speech.resume();
                        } else if (widget.book.lastOffset > 0 ||
                            widget.book.lastParagraph > 0) {
                          _resume(paragraphs);
                        } else {
                          _listen(paragraphs);
                        }
                      },
              ),
              IconButton(
                tooltip: 'Párrafo siguiente',
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: activeIndex >= 0 && activeIndex < total - 1
                    ? () => _goToParagraph(paragraphs, activeIndex + 1)
                    : null,
              ),
              IconButton(
                tooltip: 'Detener',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.stop_rounded),
                onPressed: isSpeaking || isPaused ? _speech.stop : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _speech,
    builder: (context, _) => StreamBuilder<List<Paragraph>>(
      stream: widget.database.watchParagraphs(widget.book.id),
      builder: (context, snapshot) {
        final paragraphs = snapshot.data ?? const <Paragraph>[];
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.book.title),
            actions: [
              IconButton(
                tooltip: 'Configuración de lectura e idioma',
                onPressed: _showReadingSettingsModal,
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                tooltip: 'Tamaño del texto (${_fontSize.round()} pt)',
                onPressed: _showFontSizeDialog,
                icon: const Icon(Icons.format_size_outlined),
              ),
              IconButton(
                tooltip: 'Exportar libro (Modo Lectura)',
                onPressed: _exportCurrentBook,
                icon: const Icon(Icons.ios_share_outlined),
              ),
              IconButton(
                tooltip: 'Renombrar libro',
                onPressed: _rename,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          bottomNavigationBar: _bottomPlayerBar(paragraphs),
          body: _body(context, paragraphs),
        );
      },
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
        OutlinedButton.icon(
          onPressed: _busy ? null : _addPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Importar PDF'),
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

    final segmentBar = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              icon: const Icon(Icons.notes_rounded),
              label: Text('Modo Lectura (${paragraphs.length})'),
            ),
            const ButtonSegment(
              value: 1,
              icon: Icon(Icons.auto_stories_rounded),
              label: Text('Ver Libro'),
            ),
            ButtonSegment(
              value: 2,
              icon: const Icon(Icons.collections_bookmark_outlined),
              label: Text(
                drafts.isNotEmpty
                    ? 'Páginas (${drafts.length} pend.)'
                    : 'Páginas (${pages.length})',
              ),
            ),
          ],
          selected: {_selectedTabIndex},
          onSelectionChanged: (set) =>
              setState(() => _selectedTabIndex = set.first),
        ),
      ),
    );

    Widget readingView() {
      if (paragraphs.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Todavía no hay páginas aprobadas',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Añade fotos de páginas en la pestaña de Páginas para leer y escuchar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Ir a añadir páginas'),
                ),
              ],
            ),
          ),
        );
      }

      // Cálculo de métricas del artículo
      final totalWords = paragraphs.fold<int>(
        0,
        (sum, p) => sum + p.content.trim().split(RegExp(r'\s+')).length,
      );
      final readMinutes = (totalWords / 120).ceil().clamp(1, 60);
      final langName = switch (_learningLocale) {
        'en-US' || 'en-GB' => 'English',
        'es-MX' || 'es-ES' => 'Español',
        _ => _learningLocale,
      };

      final articleChildren = <Widget>[
        // Encabezado editorial del artículo
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LECTURA · $langName'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$readMinutes min de lectura · $totalWords palabras',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _exportCurrentBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Exportar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.book.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ];

      // Cuerpo continuo del artículo
      String? lastPageId;
      var pageCounter = 0;

      for (var index = 0; index < paragraphs.length; index++) {
        final paragraph = paragraphs[index];
        final isNewPage = lastPageId != paragraph.pageId;

        if (isNewPage) {
          lastPageId = paragraph.pageId;
          pageCounter++;
          // Divisor sutil y elegante de sección entre páginas dentro del artículo
          if (index > 0) {
            articleChildren.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '✦  Página $pageCounter  ✦',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        final isActive = _speech.activeParagraph == index;
        final isSpeaking = isActive && _speech.state == ProbePlayback.speaking;
        final activeWord = isSpeaking ? _speech.currentWordRange : null;

        // Párrafo continuo integrado con estilo editorial
        articleChildren.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                left: isActive ? 16 : 0,
                top: isActive ? 10 : 0,
                bottom: isActive ? 10 : 0,
                right: isActive ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xfffef3c7).withValues(alpha: 0.65)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: const Color(0xfff59e0b).withValues(alpha: 0.75),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReadingParagraph(
                    text: paragraph.content,
                    fontSize: _fontSize,
                    homeLocale: _homeLocale,
                    learningLocale: _learningLocale,
                    activeWordRange: activeWord,
                    showDropCap: index == 0,
                    onSelection: (range) => setState(() {
                      _selectedParagraph = index;
                      _selectedRange = range;
                      _selection = range?.extract(paragraph.content);
                    }),
                    onListen: (text) =>
                        _listen(paragraphs, index: index, excerpt: text),
                    onListenRange: (text, range) => _listen(
                      paragraphs,
                      index: index,
                      excerpt: text,
                      excerptRange: range,
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            isSpeaking
                                ? Icons.graphic_eq_rounded
                                : Icons.pause_circle_outline_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSpeaking ? 'Leyendo ahora…' : 'En pausa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selection != null && _selectedParagraph == index)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _speech.voice == null
                            ? null
                            : () => _listen(
                                paragraphs,
                                index: index,
                                excerpt: _selection,
                                excerptRange: _selectedRange,
                              ),
                        icon: const Icon(Icons.volume_up_outlined, size: 16),
                        label: const Text('Escuchar selección'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      // Remate del artículo: celebración de lectura
      articleChildren.add(
        Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfffef3c7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xfffde68a),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✨', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Text(
                    '¡Fin de la lectura! Gran trabajo juntos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff92400e),
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('✨', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );

      // Hoja de artículo continuo estilo cuento
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xffede6db),
            width: 1,
          ),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: articleChildren,
          ),
        ),
      );
    }

    Widget bookView() {
      if (pages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay páginas en este libro',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Añade fotos de tu libro en la pestaña de Páginas para verlas aquí y leerlas página por página.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => setState(() => _selectedTabIndex = 2),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Ir a añadir páginas'),
                ),
              ],
            ),
          ),
        );
      }

      // Sincronizar automáticamente la página del libro si el audio está activo
      final activeP = _speech.activeParagraph;
      if (activeP >= 0 &&
          activeP < paragraphs.length &&
          _speech.state == ProbePlayback.speaking) {
        final activePageId = paragraphs[activeP].pageId;
        final targetIndex = pages.indexWhere((p) => p.id == activePageId);
        if (targetIndex != -1 && targetIndex != _bookViewPageIndex) {
          _bookViewPageIndex = targetIndex;
        }
      }

      final pageIndex = _bookViewPageIndex.clamp(0, pages.length - 1);
      final currentPage = pages[pageIndex];
      final pageParagraphs =
          paragraphs.where((p) => p.pageId == currentPage.id).toList();

      final hasImage = currentPage.originalPath != null &&
          File(currentPage.originalPath!).existsSync();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de navegación de páginas del libro
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: pageIndex > 0
                        ? () =>
                            setState(() => _bookViewPageIndex = pageIndex - 1)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Página ${pageIndex + 1} de ${pages.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Página siguiente',
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    onPressed: pageIndex < pages.length - 1
                        ? () =>
                            setState(() => _bookViewPageIndex = pageIndex + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Foto original de la página (si existe)
          if (hasImage)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => _showImageZoom(currentPage.originalPath!),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      constraints: const BoxConstraints(maxHeight: 280),
                      width: double.infinity,
                      child: Image.file(
                        File(currentPage.originalPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Ampliar foto original',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Encabezado de lectura de la página
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lectura · Página ${pageIndex + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (pageParagraphs.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: _speech.voice == null
                        ? null
                        : () {
                            final firstIdx =
                                paragraphs.indexOf(pageParagraphs.first);
                            _listen(paragraphs, index: firstIdx);
                          },
                    icon: const Icon(Icons.volume_up_outlined, size: 18),
                    label: const Text('Leer página'),
                  ),
              ],
            ),
          ),

          // Párrafos de la página con ejercicio de lectura completo
          if (pageParagraphs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Esta página no tiene párrafos de texto aprobados.'),
              ),
            )
          else
            for (var pIdx = 0; pIdx < pageParagraphs.length; pIdx++)
              _paragraphCard(
                context,
                paragraphs,
                paragraphs.indexOf(pageParagraphs[pIdx]),
                pageNumber: pageIndex + 1,
                paragraphNumber: pIdx + 1,
              ),
        ],
      );
    }

    Widget pagesView() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: controls,
            ),
          ),
          if (drafts.length > 1)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${drafts.length} páginas pendientes por revisar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _approveAllDrafts(drafts),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Añadir todas'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _mergeAllDrafts(drafts, jobsById),
                      icon: const Icon(Icons.join_inner_rounded, size: 18),
                      label: const Text('Juntar en una'),
                    ),
                  ],
                ),
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
          _audioSettingsCard(context),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                segmentBar,
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      ),
                    ),
                  ),
                switch (_selectedTabIndex) {
                  1 => bookView(),
                  2 => pagesView(),
                  _ => readingView(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyLearning(String locale) => switch (locale) {
    'en-US' => 'English (US)',
    'en-GB' => 'English (UK)',
    'es-MX' => 'Español (México)',
    'es-ES' => 'Español (España)',
    _ => locale,
  };

  Widget _audioSettingsCard(BuildContext context) {
    final selected = _speech.voice;
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.tune_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text(
          'Configuración de idioma y voz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Leyendo en ${_friendlyLearning(_learningLocale)} · ${selected?.name ?? (_speech.ready ? "Voz predeterminada" : "Cargando voces…")}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: _showReadingSettingsModal,
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
    await _speech.setLocale(value);
    if (_speech.voice != null) {
      await widget.database.updateReadingPreferences(
        widget.book.id,
        voiceId: _speech.voice!.id,
      );
    }
  }

  Future<void> _changeHomeLocale(String? value) async {
    if (value == null || value == _homeLocale) return;
    setState(() => _homeLocale = value);
    await widget.database.updateBookLanguages(
      widget.book.id,
      homeLocale: value,
      learningLocale: _learningLocale,
    );
  }

  Future<void> _testVoiceSample() async {
    final sampleText = _learningLocale.startsWith('es')
        ? '¡Hola! Esta es la voz de lectura en español.'
        : 'Hello! This is the reading voice in English.';
    try {
      await _speech.play([sampleText]);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo reproducir la prueba de voz.');
      }
    }
  }

  Future<void> _openTtsSettings() async {
    final opened = await _speech.openTtsSettings();
    if (!opened && mounted) {
      setState(
        () => _error =
            'No se pudo abrir los ajustes de voz. Ábrelos desde Ajustes > Administración general > Texto a voz.',
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

  Future<void> _showReadingSettingsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return AnimatedBuilder(
              animation: _speech,
              builder: (context, _) {
                final selected = _speech.voice;
                final learningLanguage =
                    _learningLocale.split('-').first.toLowerCase();
                final filteredVoices = _speech.voices
                    .where(
                      (item) =>
                          item.locale.split('-').first.toLowerCase() ==
                          learningLanguage,
                    )
                    .toList();

                return DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.tune_rounded,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Configuración de lectura',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'Idiomas, voz y velocidad del lector',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Cerrar',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () =>
                                        Navigator.pop(sheetContext),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Tarjeta de Idiomas
                              Card(
                                elevation: 0,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.translate_rounded,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Configuración de idiomas',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('modal_learn_$_learningLocale'),
                                        initialValue: [
                                          'en-US',
                                          'en-GB',
                                          'es-MX',
                                          'es-ES',
                                        ].contains(_learningLocale)
                                            ? _learningLocale
                                            : 'en-US',
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Idioma que vamos a leer (Libro)',
                                          helperText:
                                              'Voz de lectura y diccionario interactivo al tocar palabras.',
                                          border: OutlineInputBorder(),
                                          prefixIcon:
                                              Icon(Icons.menu_book_rounded),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'en-US',
                                            child: Text(
                                              '🇺🇸 English (Estados Unidos)',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'en-GB',
                                            child: Text(
                                              '🇬🇧 English (Reino Unido)',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: 'es-MX',
                                            child: Text('🇲🇽 Español (México)'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'es-ES',
                                            child: Text('🇪🇸 Español (España)'),
                                          ),
                                        ],
                                        onChanged: (val) async {
                                          await _changeLearningLanguage(val);
                                          setModalState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('modal_home_$_homeLocale'),
                                        initialValue: [
                                          'es-MX',
                                          'es-ES',
                                          'en-US',
                                        ].contains(_homeLocale)
                                            ? _homeLocale
                                            : 'es-MX',
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Idioma nativo de la familia',
                                          helperText:
                                              'Idioma para explicaciones y traducciones de apoyo.',
                                          border: OutlineInputBorder(),
                                          prefixIcon:
                                              Icon(Icons.home_outlined),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'es-MX',
                                            child: Text('🇲🇽 Español (México)'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'es-ES',
                                            child: Text('🇪🇸 Español (España)'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'en-US',
                                            child: Text(
                                              '🇺🇸 English (Estados Unidos)',
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) async {
                                          await _changeHomeLocale(val);
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tarjeta de Voz y Pronunciación
                              Card(
                                elevation: 0,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.record_voice_over_rounded,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Voz de lectura y pronunciación',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      DropdownButtonFormField<ProbeVoice>(
                                        key: ValueKey('modal_voice_${selected?.id}_$_learningLocale'),
                                        initialValue: selected != null &&
                                                filteredVoices.contains(selected)
                                            ? selected
                                            : null,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: _speech.ready
                                              ? 'Voz para ${_friendlyLearning(_learningLocale)}'
                                              : 'Cargando voces…',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(
                                            Icons.record_voice_over_outlined,
                                          ),
                                          helperText: !_speech.ready
                                              ? null
                                              : selected == null
                                              ? 'Activa una voz en Ajustes del teléfono para habilitar la lectura.'
                                              : selected.requiresNetwork == true
                                              ? 'Esta voz requiere conexión a internet.'
                                              : 'Voz local (funciona 100% sin conexión).',
                                        ),
                                        items: filteredVoices
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(
                                                  '${item.name} (${item.locale})',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (voice) async {
                                          if (voice != null) {
                                            await _selectVoice(voice);
                                            setModalState(() {});
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: selected == null
                                                ? null
                                                : _testVoiceSample,
                                            icon: const Icon(
                                              Icons.volume_up_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Probar voz'),
                                          ),
                                          TextButton.icon(
                                            onPressed: _openTtsSettings,
                                            icon: const Icon(
                                              Icons.settings_outlined,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Ajustes del teléfono',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.speed_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Velocidad de lectura',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge,
                                            ),
                                          ),
                                          Text(
                                            _speech.rate < .4
                                                ? 'Lenta (${_speech.rate.toStringAsFixed(2)})'
                                                : _speech.rate > .6
                                                ? 'Rápida (${_speech.rate.toStringAsFixed(2)})'
                                                : 'Normal (${_speech.rate.toStringAsFixed(2)})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Slider(
                                        value: _speech.rate,
                                        min: .2,
                                        max: .8,
                                        divisions: 12,
                                        label: _speech.rate.toStringAsFixed(2),
                                        onChanged: (value) async {
                                          await _setSpeechRate(value);
                                          setModalState(() {});
                                        },
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton(
                                            onPressed: _speech.rate <= .2
                                                ? null
                                                : () async {
                                                    await _setSpeechRate(
                                                      (_speech.rate - .05)
                                                          .clamp(.2, .8),
                                                    );
                                                    setModalState(() {});
                                                  },
                                            child: const Text('Más lento'),
                                          ),
                                          OutlinedButton(
                                            onPressed:
                                                (_speech.rate - .45).abs() <
                                                    .02
                                                ? null
                                                : () async {
                                                    await _setSpeechRate(.45);
                                                    setModalState(() {});
                                                  },
                                            child: const Text('Normal (0.45)'),
                                          ),
                                          OutlinedButton(
                                            onPressed: _speech.rate >= .8
                                                ? null
                                                : () async {
                                                    await _setSpeechRate(
                                                      (_speech.rate + .05)
                                                          .clamp(.2, .8),
                                                    );
                                                    setModalState(() {});
                                                  },
                                            child: const Text('Más rápido'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tarjeta de Tamaño de texto
                              Card(
                                elevation: 0,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.format_size_rounded,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tamaño de fuente del texto',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            '${_fontSize.round()} pt',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Slider(
                                        value: _fontSize,
                                        min: 18,
                                        max: 36,
                                        divisions: 9,
                                        label: '${_fontSize.round()} pt',
                                        onChanged: (v) {
                                          setState(() => _fontSize = v);
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(sheetContext),
                                  child: const Text('Guardar y continuar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
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
                        } else if (value == 'edit') {
                          _editPage(page, pageParagraphs);
                        } else if (value == 'reprocess') {
                          _reprocess(page);
                        } else if (value == 'delete') {
                          _deletePage(page);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          enabled: pageParagraphs.isNotEmpty,
                          child: const ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar texto'),
                            dense: true,
                          ),
                        ),
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

  Future<void> _editPage(
    storage.Page page,
    List<Paragraph> pageParagraphs,
  ) async {
    final initial = pageParagraphs.map((p) => p.content).join('\n\n');
    final controller = TextEditingController(text: initial);
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar texto de la página'),
        content: SizedBox(
          width: 700,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: 'Modifica el texto y guarda los cambios',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context, controller.text);
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
    if (edited == null || !mounted) {
      controller.dispose();
      return;
    }
    // Let the dialog and its FocusScope finish dismounting before the
    // page streams rebuild the book screen.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    controller.dispose();
    final paragraphs = edited
        .split(RegExp(r'\n\s*\n'))
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      if (mounted) {
        setState(
          () => _error = 'La página no puede quedar sin texto.',
        );
      }
      return;
    }
    await widget.database.updatePageParagraphs(
      bookId: widget.book.id,
      pageId: page.id,
      edited: paragraphs,
    );
    if (mounted) {
      setState(() {
        _error = null;
        _progress = 'Texto de la página actualizado.';
      });
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

  Future<void> _approveAllDrafts(List<PageDraft> drafts) async {
    setState(() {
      _busy = true;
      _progress = 'Añadiendo ${drafts.length} páginas al libro…';
    });
    try {
      for (final draft in drafts) {
        final paragraphs = List<String>.from(jsonDecode(draft.paragraphsJson) as List);
        await widget.database.approveDraft(draft, paragraphs);
      }
      if (mounted) {
        setState(() {
          _progress = '${drafts.length} páginas añadidas al libro.';
          _selectedTabIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al añadir páginas: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mergeAllDrafts(
    List<PageDraft> drafts,
    Map<String, ImportJob> jobsById,
  ) async {
    if (drafts.length < 2) return;
    setState(() {
      _busy = true;
      _progress = 'Juntando ${drafts.length} páginas en una sola…';
    });
    try {
      final combinedParagraphs = <String>[];
      final combinedRaw = StringBuffer();
      String? firstImagePath;

      for (final draft in drafts) {
        firstImagePath ??= jobsById[draft.jobId]?.imagePath;
        final paras = List<String>.from(jsonDecode(draft.paragraphsJson) as List);
        for (final p in paras) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) combinedParagraphs.add(trimmed);
        }
        if (draft.rawText.trim().isNotEmpty) {
          if (combinedRaw.isNotEmpty) combinedRaw.write('\n\n');
          combinedRaw.write(draft.rawText.trim());
        }
      }

      if (combinedParagraphs.isEmpty && combinedRaw.isNotEmpty) {
        combinedParagraphs.add(combinedRaw.toString().trim());
      }

      // Eliminar los borradores individuales para unificarlos en una sola página
      for (final draft in drafts) {
        await widget.database.deletePage(draft.pageId);
      }

      final pageId = '${DateTime.now().microsecondsSinceEpoch}_merged';
      final jobId = '${pageId}_job';

      await widget.database.createQueuedPage(
        bookId: widget.book.id,
        pageId: pageId,
        jobId: jobId,
        imagePath: firstImagePath,
      );

      await widget.database.saveDraft(
        bookId: widget.book.id,
        pageId: pageId,
        jobId: jobId,
        rawText: combinedRaw.toString(),
        paragraphs: combinedParagraphs,
      );

      if (mounted) {
        setState(() {
          _progress = '${drafts.length} páginas unidas en un solo borrador listo para revisar.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al juntar páginas: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
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
                homeLocale: _homeLocale,
                learningLocale: _learningLocale,
                activeWordRange: activeWord,
                onSelection: (range) => setState(() {
                  _selectedParagraph = index;
                  _selectedRange = range;
                  _selection = range?.extract(content);
                }),
                onListen: (text) =>
                    _listen(paragraphs, index: index, excerpt: text),
                onListenRange: (text, range) => _listen(
                  paragraphs,
                  index: index,
                  excerpt: text,
                  excerptRange: range,
                ),
              ),
              if (_selection != null && _selectedParagraph == index)
                TextButton.icon(
                  onPressed: _speech.voice == null
                      ? null
                      : () => _listen(
                          paragraphs,
                          index: index,
                          excerpt: _selection,
                          excerptRange: _selectedRange,
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
