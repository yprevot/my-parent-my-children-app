import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'text_ranges.dart';

enum ProbePlayback { idle, preparing, speaking, paused, completed, failed }

class ProbeVoice {
  const ProbeVoice(this.name, this.locale, this.requiresNetwork);
  final String name;
  final String locale;
  final bool? requiresNetwork;
  String get id => '$locale::$name';
}

class SpeechProbe extends ChangeNotifier {
  SpeechProbe({FlutterTts? engine}) : _engine = engine ?? FlutterTts();
  final FlutterTts _engine;
  static const _settingsChannel = MethodChannel('online.myschoolmyparents/ocr');
  List<ProbeVoice> voices = [];
  ProbeVoice? voice;
  ProbePlayback state = ProbePlayback.idle;
  String? error;
  int activeParagraph = -1;
  int rangeStart = 0;
  int rangeEnd = 0;
  int progressEvents = 0;
  int currentParagraph = 0;
  int currentOffset = 0;
  void Function(int paragraph, int offset)? onPositionChanged;
  bool ready = false;
  double rate = 0.45;
  int _generation = 0;
  bool _closed = false;
  List<String> _paragraphs = [];
  int _paragraph = 0;
  int _paragraphBase = 0;
  int _offset = 0;
  int _segmentBase = 0;
  String _spokenText = '';
  bool _acceptProgress = false;
  TextRangeSlice? _wordRange;
  Future<void> _commands = Future<void>.value();

  TextRangeSlice? get currentWordRange {
    if (state != ProbePlayback.speaking || rangeEnd <= rangeStart) return null;
    return TextRangeSlice(rangeStart, rangeEnd);
  }

  void _changed() {
    if (!_closed) notifyListeners();
  }

  Future<void> initialize({String locale = 'en-US'}) async {
    await _engine.awaitSpeakCompletion(true);
    await _engine.setSpeechRate(rate);
    if (Platform.isIOS) {
      await _engine.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ]);
    }
    final dynamic rawVoices = await _engine.getVoices;
    final raw = (rawVoices is List) ? rawVoices : const <dynamic>[];
    voices =
        raw
            .map((dynamic item) {
              if (item is! Map) return null;
              final map = Map<String, dynamic>.from(item);
              final name = (map['name'] as String?) ?? 'Voice';
              final rawLocale = (map['locale'] as String?) ?? 'en-US';
              return ProbeVoice(
                name,
                rawLocale.replaceAll('_', '-'),
                map['network_required'] is bool
                    ? map['network_required'] as bool
                    : null,
              );
            })
            .whereType<ProbeVoice>()
            // Algunos motores Android no devuelven `network_required`. En ese
            // caso la voz sigue siendo utilizable y no debemos ocultarla.
            .where((v) => !Platform.isAndroid || v.requiresNetwork != true)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    _engine.setProgressHandler((text, start, end, word) {
      if (!_acceptProgress ||
          state != ProbePlayback.speaking ||
          text != _spokenText) {
        return;
      }
      if (start < 0 || end > text.length || end <= start) return;
      if (_wordRange != null) {
        rangeStart = _wordRange!.start + start;
        rangeEnd = (_wordRange!.start + end).clamp(rangeStart, _wordRange!.end);
      } else {
        rangeStart = _segmentBase + start;
        rangeEnd = _segmentBase + end;
      }
      _offset = rangeStart;
      currentParagraph = _paragraph + _paragraphBase;
      currentOffset = rangeStart;
      progressEvents++;
      onPositionChanged?.call(currentParagraph, currentOffset);
      _changed();
    });
    await setLocale(locale);
    ready = true;
    _changed();
  }

  Future<bool> openTtsSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openTtsSettings');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> setLocale(String locale) async {
    await stop();
    final exact = voices
        .where((v) => v.locale.toLowerCase() == locale.toLowerCase())
        .toList();
    final compatible = voices
        .where((v) => v.locale.split('-').first == locale.split('-').first)
        .toList();
    voice = exact.isNotEmpty ? exact.first : compatible.firstOrNull;
    if (voice != null) await selectVoice(voice!);
    _changed();
  }

  Future<void> selectVoice(ProbeVoice selected) async {
    await stop();
    final language = await _engine.setLanguage(selected.locale);
    final result = await _engine.setVoice({
      'name': selected.name,
      'locale': selected.locale,
    });
    // Android puede devolver LANG_AVAILABLE, LANG_COUNTRY_AVAILABLE o
    // LANG_COUNTRY_VAR_AVAILABLE (0, 1 o 2 según el motor).
    if (language < 0 || result != 1) {
      throw StateError('No se pudo activar esta voz.');
    }
    voice = selected;
    _changed();
  }

  Future<void> setRate(double value) async {
    await pause();
    rate = value;
    await _engine.setSpeechRate(value);
    _changed();
  }

  Future<void> play(
    List<String> paragraphs, {
    int startParagraph = 0,
    int startOffset = 0,
    int activeParagraphBase = 0,
    TextRangeSlice? wordRange,
  }) async {
    if (voice == null) {
      throw StateError('Configura una voz para el idioma elegido.');
    }
    await stop();
    _paragraphs = List.of(paragraphs);
    _paragraph = startParagraph;
    _paragraphBase = activeParagraphBase;
    _offset = startOffset;
    currentParagraph = activeParagraphBase + startParagraph;
    currentOffset = startOffset;
    _wordRange = wordRange;
    await _run(++_generation);
  }

  Future<void> _run(int generation) async {
    state = ProbePlayback.preparing;
    error = null;
    _changed();
    try {
      for (; _paragraph < _paragraphs.length; _paragraph++) {
        if (generation != _generation || _closed) return;
        activeParagraph = _paragraph + _paragraphBase;
        final text = _paragraphs[_paragraph];
        final base = _offset.clamp(0, text.length);
        for (final slice in splitForSpeech(text.substring(base))) {
          if (generation != _generation || _closed) return;
          _segmentBase = base + slice.start;
          _offset = _segmentBase;
          if (_wordRange != null) {
            rangeStart = _wordRange!.start;
            rangeEnd = _wordRange!.end;
          } else {
            rangeStart = rangeEnd = _segmentBase;
          }
          _spokenText = slice.extract(text.substring(base));
          if (_spokenText.trim().isEmpty) continue;
          state = ProbePlayback.speaking;
          _acceptProgress = true;
          _changed();
          final result = await _engine.speak(
            _spokenText,
            focus: Platform.isAndroid,
          );
          if (generation != _generation || _closed) return;
          _acceptProgress = false;
          if (result != 1) throw StateError('El motor no completó la lectura.');
        }
        _offset = 0;
      }
      state = ProbePlayback.completed;
      activeParagraph = -1;
      currentParagraph = 0;
      currentOffset = 0;
      rangeStart = rangeEnd = 0;
      _wordRange = null;
      _changed();
    } catch (_) {
      if (generation != _generation || _closed) return;
      _acceptProgress = false;
      state = ProbePlayback.failed;
      rangeStart = rangeEnd = 0;
      _wordRange = null;
      error = 'No pudimos reproducir el texto. Comprueba la voz instalada.';
      _changed();
      rethrow;
    }
  }

  Future<void> pause() async {
    if (state != ProbePlayback.speaking && state != ProbePlayback.preparing) {
      return;
    }
    ++_generation;
    _acceptProgress = false;
    _wordRange = null;
    state = ProbePlayback.paused;
    _commands = _commands.then((_) async {
      await _engine.stop();
    });
    await _commands;
    _changed();
  }

  Future<void> resume() async {
    if (state != ProbePlayback.paused) return;
    await _commands;
    await _run(++_generation);
  }

  Future<void> stop() async {
    ++_generation;
    _acceptProgress = false;
    state = ProbePlayback.idle;
    activeParagraph = -1;
    rangeStart = rangeEnd = 0;
    _wordRange = null;
    _commands = _commands.then((_) async {
      await _engine.stop();
    });
    await _commands;
    _changed();
  }

  @override
  void dispose() {
    _closed = true;
    ++_generation;
    unawaited(_engine.stop());
    super.dispose();
  }
}
