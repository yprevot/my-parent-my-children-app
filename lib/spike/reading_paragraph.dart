import 'dart:async';

import 'package:flutter/material.dart';

import '../core/dictionary/dictionary_service.dart';
import '../core/translation/translation_service.dart';
import 'text_ranges.dart';

final _wordRegex = RegExp(
  r"[\p{L}\p{N}]+(?:['’\-‐‑][\p{L}\p{N}]+)*",
  unicode: true,
);

class ReadingParagraph extends StatefulWidget {
  const ReadingParagraph({
    super.key,
    required this.text,
    required this.onSelection,
    required this.onListen,
    this.onListenRange,
    this.activeWordRange,
    this.fontSize = 22,
    this.homeLocale = 'es-MX',
    this.learningLocale = 'en-US',
    this.showDropCap = false,
  });

  final String text;
  final ValueChanged<TextRangeSlice?> onSelection;
  final ValueChanged<String> onListen;
  final void Function(String text, TextRangeSlice? range)? onListenRange;
  final TextRangeSlice? activeWordRange;
  final double fontSize;
  final String homeLocale;
  final String learningLocale;
  final bool showDropCap;

  @override
  State<ReadingParagraph> createState() => _ReadingParagraphState();
}

class _ReadingParagraphState extends State<ReadingParagraph> {
  TextRangeSlice? _range;
  OverlayEntry? _tooltipEntry;
  Timer? _dismissTimer;
  String? _activeTooltipWord;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTooltip(clearRange: false);
    super.dispose();
  }

  void _removeTooltip({bool clearRange = true}) {
    _dismissTimer?.cancel();
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    _activeTooltipWord = null;
    if (clearRange && mounted) {
      setState(() {
        _range = null;
      });
      widget.onSelection(null);
    }
  }

  void _triggerListen(String text, [TextRangeSlice? range]) {
    final targetRange = range ?? _range;
    if (targetRange != null) {
      setState(() {
        _range = targetRange;
      });
      widget.onSelection(targetRange);
    }
    if (widget.onListenRange != null) {
      widget.onListenRange!(text, targetRange);
    } else {
      widget.onListen(text);
    }
  }

  void _scheduleDismissTooltip() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _removeTooltip();
    });
  }

  void _cancelDismissTimer() {
    _dismissTimer?.cancel();
  }

  int _tooltipGeneration = 0;

  Future<void> _showWordTooltip(
    int start,
    int end, {
    Offset? anchorPosition,
  }) async {
    final rawWord = widget.text.substring(start, end).trim();
    if (rawWord.isEmpty) return;

    // If the same word's tooltip is already open, just keep it alive.
    if (_activeTooltipWord == rawWord && _tooltipEntry != null) {
      _cancelDismissTimer();
      return;
    }

    // Always close previous tooltip and highlight the new word immediately.
    _cancelDismissTimer();
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    _activeTooltipWord = rawWord;
    final generation = ++_tooltipGeneration;

    setState(() {
      _range = TextRangeSlice(start, end);
    });
    widget.onSelection(_range);

    final definition = await DictionaryService.instance.lookup(
      rawWord,
      homeLocale: widget.homeLocale,
      learningLocale: widget.learningLocale,
    );

    if (!mounted || generation != _tooltipGeneration) return;

    // Calcular posición de anclaje
    Offset targetOffset = anchorPosition ?? Offset.zero;
    if (anchorPosition == null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final painter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.7,
              letterSpacing: 0.2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: box.size.width);

        final boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        );
        if (boxes.isNotEmpty) {
          final rect = boxes.first.toRect();
          targetOffset = box.localToGlobal(rect.center);
        } else {
          targetOffset = box.localToGlobal(box.size.center(Offset.zero));
        }
      }
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _tooltipEntry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        const tooltipWidth = 270.0;
        final estimatedHeight = (definition.translation != null && definition.translation!.isNotEmpty) ? 185.0 : 145.0;

        var left = (targetOffset.dx - (tooltipWidth / 2)).clamp(
          12.0,
          screenWidth - tooltipWidth - 12.0,
        );

        final placeAbove = targetOffset.dy > (estimatedHeight + 40.0);
        final top = placeAbove
            ? (targetOffset.dy - estimatedHeight - 14.0)
            : (targetOffset.dy + 24.0);

        return Stack(
          children: [
            // Cierre al pulsar fuera en pantallas táctiles
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeTooltip,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: MouseRegion(
                onEnter: (_) => _cancelDismissTimer(),
                onExit: (_) => _scheduleDismissTooltip(),
                child: Material(
                  elevation: 5,
                  shadowColor: const Color(0x220f172a),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xffede6db),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                definition.displayWord,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Color(0xff1e293b),
                                ),
                              ),
                            ),
                            if (definition.partOfSpeech.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xfffef3c7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xfffcd34d),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  definition.partOfSpeech,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff92400e),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: _removeTooltip,
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xff94a3b8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (definition.translation != null && definition.translation!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xfff0f9ff),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xffbae6fd),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.translate_rounded,
                                  size: 16,
                                  color: Color(0xff0284c7),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.3,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Traducción (${TranslationService.getLanguageName(definition.translationLocale ?? '')}): ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff0369a1),
                                          ),
                                        ),
                                        TextSpan(
                                          text: definition.translation!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xff0c4a6e),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Significado:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff64748b),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          definition.meaning,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: Color(0xff334155),
                          ),
                        ),
                        if (definition.example != null && definition.example!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Ejemplo: "${definition.example}"',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff1d4ed8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              _triggerListen(rawWord, TextRangeSlice(start, end));
                            },
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: const Text(
                              'Volver a escuchar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_tooltipEntry!);
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: widget.fontSize,
      height: 1.7,
      letterSpacing: 0.2,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final highlightStyle = baseStyle.copyWith(
      backgroundColor: const Color(0xfffde68a),
      color: const Color(0xff1e293b),
      fontWeight: FontWeight.w800,
    );

    final selectedStyle = baseStyle.copyWith(
      backgroundColor: const Color(0xfffef3c7),
      color: const Color(0xff92400e),
      fontWeight: FontWeight.w700,
    );

    final matches = _wordRegex.allMatches(widget.text).toList();
    if (matches.isEmpty) {
      return TextSpan(text: widget.text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var currentOffset = 0;

    for (final match in matches) {
      if (match.start > currentOffset) {
        spans.add(
          TextSpan(
            text: widget.text.substring(currentOffset, match.start),
            style: baseStyle,
          ),
        );
      }

      final wordText = widget.text.substring(match.start, match.end);
      final range = widget.activeWordRange;
      final isKaraokeActive =
          range != null &&
          range.start <= match.start &&
          match.end <= range.end &&
          range.start < range.end;

      final isSelected = _range != null &&
          _range!.start <= match.start &&
          match.end <= _range!.end &&
          _range!.start < _range!.end;

      final effectiveStyle = isKaraokeActive
          ? highlightStyle
          : (isSelected ? selectedStyle : baseStyle);

      InlineSpan wordSpan;
      if (widget.showDropCap && match == matches.first && wordText.isNotEmpty) {
        final isHighlighted = isKaraokeActive || isSelected;
        final dropCapStyle = effectiveStyle.copyWith(
          fontSize: widget.fontSize * 1.5,
          fontWeight: FontWeight.w900,
          color: isHighlighted ? null : const Color(0xff1d4ed8),
        );
        wordSpan = TextSpan(
          style: effectiveStyle,
          mouseCursor: SystemMouseCursors.click,
          onEnter: (event) {
            _showWordTooltip(
              match.start,
              match.end,
              anchorPosition: event.position,
            );
          },
          onExit: (_) => _scheduleDismissTooltip(),
          children: [
            TextSpan(
              text: wordText.substring(0, 1),
              style: dropCapStyle,
            ),
            if (wordText.length > 1)
              TextSpan(text: wordText.substring(1)),
          ],
        );
      } else {
        wordSpan = TextSpan(
          text: wordText,
          style: effectiveStyle,
          mouseCursor: SystemMouseCursors.click,
          onEnter: (event) {
            _showWordTooltip(
              match.start,
              match.end,
              anchorPosition: event.position,
            );
          },
          onExit: (_) => _scheduleDismissTooltip(),
        );
      }
      spans.add(wordSpan);

      currentOffset = match.end;
    }

    if (currentOffset < widget.text.length) {
      spans.add(
        TextSpan(
          text: widget.text.substring(currentOffset),
          style: baseStyle,
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Texto de lectura. Selecciona una palabra o una parte para escucharla.',
    child: SelectableText.rich(
      _buildTextSpan(context),
      onSelectionChanged: (selection, cause) {
        if (!selection.isValid) return;

        if (selection.isCollapsed) {
          // Single word tap: let _showWordTooltip manage both highlight & popup.
          final range = wordAt(widget.text, selection.start);
          if (range != null && range.start < range.end) {
            _showWordTooltip(range.start, range.end);
          }
        } else {
          // Multi-word drag selection: set highlight, close any open tooltip.
          _removeTooltip(clearRange: false);
          final range = TextRangeSlice(selection.start, selection.end);
          setState(() {
            _range = range;
          });
          widget.onSelection(range);
        }
      },
      contextMenuBuilder: (context, editableTextState) =>
          AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              ContextMenuButtonItem(
                label: 'Escuchar selección',
                onPressed: () {
                  final range = _range;
                  editableTextState.hideToolbar();
                  if (range != null) {
                    _triggerListen(range.extract(widget.text), range);
                  }
                },
              ),
              ContextMenuButtonItem(
                label: 'Ver significado',
                onPressed: () {
                  final range = _range;
                  editableTextState.hideToolbar();
                  if (range != null) {
                    _showWordTooltip(range.start, range.end);
                  }
                },
              ),
              ...editableTextState.contextMenuButtonItems,
            ],
          ),
    ),
  );
}
