import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/config/app_version.dart';
import '../../core/export/book_export_import_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/sync/sync_engine.dart';
import '../auth/auth_scope.dart';
import '../reader/book_screen.dart';

class _BookTheme {
  const _BookTheme({
    required this.spineColor,
    required this.spineDark,
    required this.badgeColor,
    required this.badgeText,
    required this.iconColor,
    required this.icon,
    required this.vibe,
  });
  final Color spineColor;
  final Color spineDark;
  final Color badgeColor;
  final Color badgeText;
  final Color iconColor;
  final IconData icon;
  final String vibe;
}

_BookTheme _getBookTheme(Book book) {
  const themes = [
    _BookTheme(
      spineColor: Color(0xfff59e0b),
      spineDark: Color(0xffb45309),
      badgeColor: Color(0xfffef3c7),
      badgeText: Color(0xff92400e),
      iconColor: Color(0xffb45309),
      icon: Icons.auto_stories_rounded,
      vibe: 'Cuento Mágico',
    ),
    _BookTheme(
      spineColor: Color(0xff2563eb),
      spineDark: Color(0xff1d4ed8),
      badgeColor: Color(0xffdbeafe),
      badgeText: Color(0xff1e40af),
      iconColor: Color(0xff1d4ed8),
      icon: Icons.menu_book_rounded,
      vibe: 'Aventura Escolar',
    ),
    _BookTheme(
      spineColor: Color(0xff10b981),
      spineDark: Color(0xff047857),
      badgeColor: Color(0xffd1fae5),
      badgeText: Color(0xff065f46),
      iconColor: Color(0xff047857),
      icon: Icons.park_rounded,
      vibe: 'Naturaleza',
    ),
    _BookTheme(
      spineColor: Color(0xfff97316),
      spineDark: Color(0xffc2410c),
      badgeColor: Color(0xffffedd5),
      badgeText: Color(0xff9a3412),
      iconColor: Color(0xffc2410c),
      icon: Icons.wb_sunny_rounded,
      vibe: 'Fantasía',
    ),
    _BookTheme(
      spineColor: Color(0xff8b5cf6),
      spineDark: Color(0xff6d28d9),
      badgeColor: Color(0xffede9fe),
      badgeText: Color(0xff5b21b6),
      iconColor: Color(0xff6d28d9),
      icon: Icons.star_rounded,
      vibe: 'Buenas Noches',
    ),
  ];
  final hash = (book.id.hashCode ^ book.title.hashCode).abs();
  return themes[hash % themes.length];
}

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

  Future<void> _editBookLanguage(Book book) async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditBookLanguageDialog(book: book),
    );
    if (values != null && mounted) {
      await widget.database.updateBookLanguages(
        book.id,
        homeLocale: values['homeLocale'] ?? book.homeLocale,
        learningLocale: values['learningLocale'] ?? book.learningLocale,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Idioma de «${book.title}» actualizado a ${_friendlyLocale(values['learningLocale'] ?? book.learningLocale)}.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _friendlyLocale(String locale) => switch (locale) {
    'en-US' => '🇺🇸 English (US)',
    'en-GB' => '🇬🇧 English (UK)',
    'es-MX' => '🇲🇽 Español (MX)',
    'es-ES' => '🇪🇸 Español (ES)',
    _ => locale,
  };

  Future<void> _importBook() async {
    try {
      final result = await BookExportImportService.instance.importBookFromFile(
        database: widget.database,
      );
      if (!mounted) return;
      if (!result.success) {
        if (result.errorMessage != 'No se seleccionó ningún archivo.') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'No se pudo importar el libro.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      final importedBook = result.book;
      if (importedBook != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '«${importedBook.title}» importado con éxito (${result.totalParagraphs} párrafos listos en Modo Lectura).',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xff15803d),
          ),
        );
        await _open(importedBook);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar libro: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _exportBook(Book book) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exportando «${book.title}» en Modo Lectura...'),
          duration: const Duration(seconds: 1),
        ),
      );

      final result = await BookExportImportService.instance.exportBookToFile(
        database: widget.database,
        bookId: book.id,
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
                'El libro «${book.title}» quedó exportado en formato JSON universal de Modo Lectura compatible.',
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
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mis libros',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  AppVersion.displayString,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Información de la app',
          onPressed: () => AppVersion.showAboutDialog(
            context,
            syncStatus: AuthScope.of(context).user?.isGuest == true
                ? 'Modo Local (sin conexión)'
                : 'Sincronizado con la nube',
          ),
          icon: const Icon(Icons.info_outline_rounded),
        ),
        if (widget.syncEngine != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ActionChip(
              avatar: _syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      AuthScope.of(context).user?.isGuest == true
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 16,
                    ),
              label: Text(
                AuthScope.of(context).user?.isGuest == true ? 'Local' : 'Nube',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              tooltip: AuthScope.of(context).user?.isGuest == true
                  ? 'Modo local (toca para vincular Google)'
                  : 'Sincronizado con la nube',
              onPressed: _syncing ? null : _showCloudDialog,
            ),
          ),
        IconButton(
          tooltip: 'Importar libro (Modo Lectura)',
          onPressed: _importBook,
          icon: const Icon(Icons.file_download_outlined),
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
      icon: const Icon(Icons.add_rounded, size: 24),
      label: const Text(
        'Crear libro',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xfffef3c7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xfff59e0b).withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/branding/my_school_my_parents_logo.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '¡Vamos a leer juntos!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff1e293b),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Añade fotos de cuentos o lecturas escolares para practicarlas en inglés o español con pronunciación guiada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xff64748b),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffd97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _createBook,
                    icon: const Icon(Icons.auto_stories_rounded, size: 22),
                    label: const Text(
                      'Crear mi primer libro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff1e293b),
                      side: const BorderSide(color: Color(0xffcbd5e1)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _importBook,
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: const Text(
                      'Importar libro existente',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? '¡Buenos días! ☀️'
            : (hour < 19 ? '¡Buenas tardes! 📖' : '¡Buenas noches! 🌙');

        return LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting A leer juntos',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff1e293b),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${books.length} ${books.length == 1 ? "libro en tu estantería familiar" : "libros en tu estantería familiar"}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xff64748b),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 840
                        ? 3
                        : constraints.maxWidth >= 560
                        ? 2
                        : 1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      final theme = _getBookTheme(book);
                      return Card(
                        elevation: 3,
                        shadowColor: const Color(0x140f172a),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: Color(0xffede6db),
                            width: 1.2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _open(book),
                          child: Stack(
                            children: [
                              // Lomo 3D cilíndrico del libro a la izquierda
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 14,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        theme.spineDark,
                                        theme.spineColor,
                                        theme.spineColor.withValues(alpha: 0.9),
                                        theme.spineDark.withValues(alpha: 0.7),
                                      ],
                                      stops: const [0.0, 0.35, 0.8, 1.0],
                                    ),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 1.2,
                                      color: Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                              ),
                              // Detalle de páginas apiladas en el canto derecho
                              Positioned(
                                right: 0,
                                top: 12,
                                bottom: 12,
                                width: 4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    7,
                                    (_) => Container(
                                      height: 1.5,
                                      color: const Color(0xffe2d9cd),
                                    ),
                                  ),
                                ),
                              ),
                              // Contenido principal del libro
                              Padding(
                                padding: const EdgeInsets.fromLTRB(26, 12, 10, 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Miniatura de portada de cuento con relieve
                                    Container(
                                      width: 48,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.badgeColor,
                                            theme.badgeColor.withValues(alpha: 0.55),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(5),
                                          right: Radius.circular(10),
                                        ),
                                        border: Border.all(
                                          color: theme.spineColor.withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.spineColor.withValues(alpha: 0.18),
                                            blurRadius: 8,
                                            offset: const Offset(1, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned(
                                            right: 0,
                                            top: 2,
                                            bottom: 2,
                                            width: 3,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                borderRadius: const BorderRadius.horizontal(
                                                  right: Radius.circular(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            theme.icon,
                                            size: 26,
                                            color: theme.iconColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Color(0xff1e293b),
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              InkWell(
                                                borderRadius: BorderRadius.circular(8),
                                                onTap: () => _editBookLanguage(book),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme.badgeColor.withValues(alpha: 0.85),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: theme.spineColor.withValues(alpha: 0.35),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.translate_rounded,
                                                        size: 13,
                                                        color: theme.badgeText,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _friendlyLocale(book.learningLocale),
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: theme.badgeText,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 11,
                                                        color: theme.badgeText,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfff1f5f9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  theme.vibe,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xff64748b),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Opciones de libro',
                                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                                      onSelected: (action) {
                                        if (action == 'language') _editBookLanguage(book);
                                        if (action == 'export') _exportBook(book);
                                        if (action == 'delete') _delete(book);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'language',
                                          child: ListTile(
                                            leading: Icon(Icons.tune_rounded),
                                            title: Text('Configurar idioma'),
                                            dense: true,
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'export',
                                          child: ListTile(
                                            leading: Icon(Icons.ios_share_outlined),
                                            title: Text('Exportar (Modo Lectura)'),
                                            dense: true,
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              'Eliminar libro',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                            dense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              ),
            ],
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

class _EditBookLanguageDialog extends StatefulWidget {
  const _EditBookLanguageDialog({required this.book});
  final Book book;

  @override
  State<_EditBookLanguageDialog> createState() =>
      _EditBookLanguageDialogState();
}

class _EditBookLanguageDialogState extends State<_EditBookLanguageDialog> {
  late String _learningLocale;
  late String _homeLocale;

  @override
  void initState() {
    super.initState();
    _learningLocale = widget.book.learningLocale;
    _homeLocale = widget.book.homeLocale;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Idioma de «${widget.book.title}»'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajusta los idiomas usados para la voz en voz alta y las ayudas de vocabulario.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('edit_book_learn_$_learningLocale'),
              initialValue: [
                'en-US',
                'en-GB',
                'es-MX',
                'es-ES',
              ].contains(_learningLocale)
                  ? _learningLocale
                  : 'en-US',
              decoration: const InputDecoration(
                labelText: 'Idioma del libro (para voz y lectura)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'en-US',
                  child: Text('🇺🇸 English (US)'),
                ),
                DropdownMenuItem(
                  value: 'en-GB',
                  child: Text('🇬🇧 English (UK)'),
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
              onChanged: (val) {
                if (val != null) setState(() => _learningLocale = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('edit_book_home_$_homeLocale'),
              initialValue: [
                'es-MX',
                'es-ES',
                'en-US',
              ].contains(_homeLocale)
                  ? _homeLocale
                  : 'es-MX',
              decoration: const InputDecoration(
                labelText: 'Idioma nativo de la familia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
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
                  child: Text('🇺🇸 English (US)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _homeLocale = val);
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
          onPressed: () => Navigator.pop(context, {
            'learningLocale': _learningLocale,
            'homeLocale': _homeLocale,
          }),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}


