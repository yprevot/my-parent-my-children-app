import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:images_to_book/spike/reading_paragraph.dart';
import 'package:images_to_book/spike/text_ranges.dart';

void main() {
  for (final size in [const Size(375, 812), const Size(1024, 768)]) {
    testWidgets('Un toque selecciona la segunda palabra repetida en $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const text = 'the the cat';
      TextRangeSlice? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: ReadingParagraph(
                text: text,
                onSelection: (range) => selected = range,
                onListen: (_) {},
              ),
            ),
          ),
        ),
      );
      final render = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final caret = render.getLocalRectForCaret(const TextPosition(offset: 5));
      await tester.tapAt(
        render.localToGlobal(caret.center + const Offset(2, 0)),
      );
      await tester.pump();
      expect(selected?.start, 4);
      expect(selected?.extract(text), 'the');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Texto ampliado conserva selección y muestra menú de lectura', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? spoken;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ReadingParagraph(
              text: "We don't stop learning.",
              onSelection: (_) {},
              onListen: (text) => spoken = text,
            ),
          ),
        ),
      ),
    );
    final render = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    final caret = render.getLocalRectForCaret(const TextPosition(offset: 5));
    await tester.longPressAt(render.localToGlobal(caret.center));
    await tester.pumpAndSettle();
    expect(find.text('Escuchar selección'), findsOneWidget);
    await tester.tap(find.text('Escuchar selección'));
    await tester.pumpAndSettle();
    expect(spoken, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El párrafo expone una acción de lectura accesible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingParagraph(
            text: 'A short paragraph.',
            onSelection: _ignoreSelection,
            onListen: _ignoreText,
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Texto de lectura. Selecciona una palabra o una parte para escucharla.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('ReadingParagraph resalta palabra activa con TextSpan', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingParagraph(
            text: 'Hello world',
            activeWordRange: TextRangeSlice(6, 11),
            onSelection: _ignoreSelection,
            onListen: _ignoreText,
          ),
        ),
      ),
    );
    expect(find.byType(SelectableText), findsOneWidget);
    final selectableText = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    expect(selectableText.textSpan, isNotNull);
  });

  testWidgets('Pulsar una palabra muestra tooltip con significado y opción de volver a escuchar', (
    tester,
  ) async {
    String? relistenedWord;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ReadingParagraph(
              text: 'The cat is small.',
              onSelection: _ignoreSelection,
              onListen: (word) => relistenedWord = word,
            ),
          ),
        ),
      ),
    );

    final render = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    // Offset de la palabra 'cat' (índice 5)
    final caret = render.getLocalRectForCaret(const TextPosition(offset: 5));
    await tester.tapAt(render.localToGlobal(caret.center));
    await tester.pumpAndSettle();

    // Comprobar que el tooltip aparece con la definición y el botón de volver a escuchar
    expect(find.text('Volver a escuchar'), findsOneWidget);
    expect(find.textContaining('Gato'), findsOneWidget);

    // Pulsar el botón para volver a escuchar
    await tester.tap(find.text('Volver a escuchar'));
    await tester.pumpAndSettle();

    expect(relistenedWord, 'cat');
  });

  testWidgets('Pulsar volver a escuchar entrega rango exacto para marcar la palabra', (
    tester,
  ) async {
    String? spokenText;
    TextRangeSlice? spokenRange;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ReadingParagraph(
              text: 'The cat is small.',
              onSelection: _ignoreSelection,
              onListen: (word) {},
              onListenRange: (word, range) {
                spokenText = word;
                spokenRange = range;
              },
            ),
          ),
        ),
      ),
    );

    final render = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    final caret = render.getLocalRectForCaret(const TextPosition(offset: 5));
    await tester.tapAt(render.localToGlobal(caret.center));
    await tester.pumpAndSettle();

    expect(find.text('Volver a escuchar'), findsOneWidget);
    await tester.tap(find.text('Volver a escuchar'));
    await tester.pumpAndSettle();

    expect(spokenText, 'cat');
    expect(spokenRange, isNotNull);
    expect(spokenRange?.start, 4);
    expect(spokenRange?.end, 7);
  });
}

void _ignoreSelection(TextRangeSlice? _) {}

void _ignoreText(String _) {}
