import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/storage/app_database.dart';
import '../reader/book_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.database});
  final AppDatabase database;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Future<void> _createBook() async {
    final controller = TextEditingController();
    var homeLocale = 'es-MX';
    var learningLocale = 'en-US';
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear libro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. Lecturas de inglés',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: homeLocale,
                  decoration: const InputDecoration(
                    labelText: 'Idioma nativo de la familia',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'es-MX', child: Text('Español')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => homeLocale = value ?? 'es-MX'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: learningLocale,
                  decoration: const InputDecoration(
                    labelText: 'Idioma que vamos a leer',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'en-US', child: Text('English')),
                    DropdownMenuItem(value: 'es-MX', child: Text('Español')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => learningLocale = value ?? 'en-US'),
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
              onPressed: () => Navigator.pop(context, {
                'title': controller.text,
                'homeLocale': homeLocale,
                'learningLocale': learningLocale,
              }),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    // El TextField puede seguir participando en la animación de cierre del
    // diálogo durante un frame después de que showDialog termine.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    final title = values?['title'];
    if (!mounted || title == null || title.trim().isEmpty) return;
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    await widget.database
        .into(widget.database.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            title: title.trim(),
            homeLocale: Value(values?['homeLocale'] ?? 'es-MX'),
            learningLocale: Value(values?['learningLocale'] ?? 'en-US'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (mounted) await _open(await widget.database.findBook(id));
  }

  Future<void> _open(Book? book) async {
    if (book == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookScreen(database: widget.database, book: book),
      ),
    );
  }

  Future<void> _delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar «${book.title}»?'),
        content: const Text(
          'Se eliminarán sus textos locales. Esta acción no se puede deshacer desde la app.',
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
    if (confirmed == true) {
      await widget.database.deleteBook(book.id);
    }
  }

  String _friendlyLocale(String locale) => switch (locale) {
    'en-US' => 'English',
    'en-GB' => 'English (UK)',
    'es-MX' => 'Español',
    _ => locale,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/branding/my_school_my_parents_logo.png',
              width: 36,
              height: 36,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Mis libros'),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createBook,
      icon: const Icon(Icons.add),
      label: const Text('Crear libro'),
    ),
    body: StreamBuilder<List<Book>>(
      stream: widget.database.watchBooks(),
      builder: (context, snapshot) {
        final books = snapshot.data ?? const <Book>[];
        if (snapshot.hasError) {
          return Center(
            child: Text('No se pudo abrir la biblioteca: ${snapshot.error}'),
          );
        }
        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/branding/my_school_my_parents_logo.png',
                      width: 112,
                      height: 112,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Crea tu primer libro',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Añade fotos de páginas, revisa el texto y escúchalo en su idioma.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _createBook,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear libro'),
                  ),
                ],
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: books.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 840
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                child: InkWell(
                  onTap: () => _open(book),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book_outlined, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Leer en ${_friendlyLocale(book.learningLocale)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_outlined,
                          size: 28,
                        ),
                        IconButton(
                          tooltip: 'Eliminar libro',
                          onPressed: () => _delete(book),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
