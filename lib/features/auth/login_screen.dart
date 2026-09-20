import 'package:flutter/material.dart';

import 'auth_scope.dart';
import 'auth_service.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Inicio de sesión con correo+contraseña o con Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthService get _service => AuthScope.of(context).service;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // La sesión se propaga por AuthScope -> AuthGate muestra la biblioteca.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      await _service.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _localMode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.signInLocally();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goForgot() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Iniciar sesión',
    children: [
      const AuthHeader(
        title: 'Hola de nuevo',
        subtitle: 'Entra para seguir con tus libros de lectura.',
      ),
      const SizedBox(height: 24),
      if (_error != null) ...[
        AuthErrorCard(message: _error!),
        const SizedBox(height: 16),
      ],
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
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
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Escribe tu contraseña.'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _busy ? null : _goForgot,
          child: const Text('¿Olvidaste tu contraseña?'),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Entrar'),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'o',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 16),
      GoogleSignInButton(onPressed: _google, busy: _googleBusy),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: (_busy || _googleBusy) ? null : _localMode,
        icon: const Icon(Icons.offline_pin_outlined),
        label: const Text('Continuar sin cuenta (Modo local)'),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('¿No tienes cuenta?'),
          TextButton(
            onPressed: _busy ? null : _goRegister,
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    ],
  );
}
