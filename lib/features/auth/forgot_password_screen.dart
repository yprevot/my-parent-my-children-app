import 'package:flutter/material.dart';

import 'auth_scope.dart';
import 'auth_service.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

/// Recuperación de contraseña: pide el correo y envía el enlace.
///
/// Al enviar con éxito muestra confirmación y ofrece volver al login.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).service.sendPasswordReset(
        email: _emailController.text,
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Recuperar contraseña',
    children: [
      const AuthHeader(
        title: 'Recupera tu acceso',
        subtitle: 'Te enviamos un enlace para crear una contraseña nueva.',
      ),
      const SizedBox(height: 24),
      if (_error != null) ...[
        AuthErrorCard(message: _error!),
        const SizedBox(height: 16),
      ],
      if (_sent)
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revisa tu correo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Si hay una cuenta con ${_emailController.text.trim()}, '
                  'recibirás un enlace para restablecer tu contraseña.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ),
          ),
        )
      else ...[
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.mail_outlined),
            ),
            validator: AuthValidators.email,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar enlace'),
        ),
      ],
    ],
  );
}
