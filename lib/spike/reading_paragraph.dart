import 'package:flutter/material.dart';

import 'text_ranges.dart';

class ReadingParagraph extends StatefulWidget {
  const ReadingParagraph({
    super.key,
    required this.text,
    required this.onSelection,
    required this.onListen,
    this.activeWordRange,
    this.fontSize = 22,
  });
  final String text;
  final ValueChanged<TextRangeSlice?> onSelection;
  final ValueChanged<String> onListen;
  final TextRangeSlice? activeWordRange;
  final double fontSize;

  @override
  State<ReadingParagraph> createState() => _ReadingParagraphState();
}

class _ReadingParagraphState extends State<ReadingParagraph> {
  TextRangeSlice? _range;

  TextSpan _buildTextSpan(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: widget.fontSize,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final range = widget.activeWordRange;
    if (range == null ||
        range.start < 0 ||
        range.end > widget.text.length ||
        range.start >= range.end) {
      return TextSpan(text: widget.text, style: baseStyle);
    }

    final theme = Theme.of(context);
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: theme.colorScheme.primary,
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
    );

    return TextSpan(
      style: baseStyle,
      children: [
        if (range.start > 0)
          TextSpan(text: widget.text.substring(0, range.start)),
        TextSpan(
          text: widget.text.substring(range.start, range.end),
          style: highlightStyle,
        ),
        if (range.end < widget.text.length)
          TextSpan(text: widget.text.substring(range.end)),
      ],
    );
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
        final range = selection.isCollapsed
            ? wordAt(widget.text, selection.start)
            : TextRangeSlice(selection.start, selection.end);
        _range = range;
        widget.onSelection(range);
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
                    widget.onListen(range.extract(widget.text));
                  }
                },
              ),
              ...editableTextState.contextMenuButtonItems,
            ],
          ),
    ),
  );
}
