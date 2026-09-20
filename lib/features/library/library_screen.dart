import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/storage/app_database.dart';
import '../../core/sync/sync_engine.dart';
import '../auth/auth_scope.dart';
import '../reader/book_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.database,
    this.syncEngine,
  });
  final AppDatabase database;
  final SyncEngine? syncEngine;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    if (widget.syncEngine == null || _syncing) return;
    setState(() => _syncing = true);
    final result = await widget.syncEngine!.synchronize();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? (result.isGuest
                  ? 'Modo local: conecta tu cuenta para respaldar en la nube.'
                  : 'Sincronizado con la nube (${result.pushedCount} subidos, ${result.pulledCount} descargados).')
              : (result.errorMessage ?? 'Error al sincronizar.'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showCloudDialog() async {
    final user = AuthScope.of(context).user;
    if (user?.isGuest == true) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Respaldar en la nube'),
          content: const Text(
            'Actualmente estás usando la app en modo local. Puedes conectar tu cuenta de Google para respaldar tus libros en la nube y acceder a ellos desde otros dispositivos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir en local'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Conectar con Google'),
            ),
          ],
        ),
      );
      if (proceed == true && mounted) {
        try {
          await AuthScope.of(context).service.linkWithGoogle();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cuenta de Google vinculada con éxito.')),
            );
            await _sync();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo vincular: $e')),
            );
          }
        }
      }
    } else {
      await _sync();
    }
  }

  Future<void> _createBook() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateBookDialog(),
    );
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
      widget.syncEngine?.recordDeletedBook(book.id);
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
      actions: [
        if (widget.syncEngine != null)
          IconButton(
            tooltip: AuthScope.of(context).user?.isGuest == true
                ? 'Conectar cuenta de Google'
                : 'Sincronizar con la nube',
            onPressed: _syncing ? null : _showCloudDialog,
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    AuthScope.of(context).user?.isGuest == true
                        ? Icons.cloud_queue_outlined
                        : Icons.cloud_sync_outlined,
                  ),
          ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () => AuthScope.of(context).service.signOut(),
          icon: const Icon(Icons.logout_outlined),
        ),
      ],
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
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _open(book),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar libro',
                      onPressed: () => _delete(book),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _CreateBookDialog extends StatefulWidget {
  const _CreateBookDialog();

  @override
  State<_CreateBookDialog> createState() => _CreateBookDialogState();
}

class _CreateBookDialogState extends State<_CreateBookDialog> {
  final _controller = TextEditingController();
  String _learningLocale = 'en-US';
  final String _homeLocale = 'es-MX';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo libro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título del libro',
                hintText: 'Ej. Harry Potter, Ciencias Naturales...',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _learningLocale,
              decoration: const InputDecoration(
                labelText: 'Idioma del libro (para voz)',
              ),
              items: const [
                DropdownMenuItem(value: 'en-US', child: Text('Inglés (US)')),
                DropdownMenuItem(value: 'en-GB', child: Text('Inglés (UK)')),
                DropdownMenuItem(value: 'es-MX', child: Text('Español')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _learningLocale = val);
              },
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
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, {
      'title': title,
      'learningLocale': _learningLocale,
      'homeLocale': _homeLocale,
    });
  }
}

