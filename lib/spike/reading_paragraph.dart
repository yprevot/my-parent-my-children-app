import 'package:flutter/material.dart';

import 'text_ranges.dart';

class ReadingParagraph extends StatefulWidget {
  const ReadingParagraph({
    super.key,
    required this.text,
    required this.onSelection,
    required this.onListen,
    this.fontSize = 22,
  });
  final String text;
  final ValueChanged<TextRangeSlice?> onSelection;
  final ValueChanged<String> onListen;
  final double fontSize;

  @override
  State<ReadingParagraph> createState() => _ReadingParagraphState();
}

class _ReadingParagraphState extends State<ReadingParagraph> {
  TextRangeSlice? _range;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'Texto de lectura. Selecciona una palabra o una parte para escucharla.',
    child: SelectableText(
      widget.text,
      style: TextStyle(fontSize: widget.fontSize, height: 1.6),
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
