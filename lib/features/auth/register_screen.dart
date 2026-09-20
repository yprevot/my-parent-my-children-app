import 'package:flutter/material.dart';

import 'auth_scope.dart';
import 'auth_service.dart';
import 'auth_validators.dart';
import 'auth_widgets.dart';

/// Registro con nombre, correo, contraseña + confirmación, o con Google.
///
/// La contraseña exige: mínimo 8 caracteres, mayúscula, minúscula,
/// número y símbolo. Al registrar con éxito, la sesión se propaga por
/// [AuthScope] y el [AuthGate] lleva a la biblioteca (vuelve solo).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  bool _googleBusy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
      await _service.registerWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Sesión creada: AuthGate muestra la biblioteca. Cerramos el registro
      // para no dejarlo en la pila de navegación.
      Navigator.of(context).pop();
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
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Crear cuenta',
    children: [
      const AuthHeader(
        title: 'Crea tu cuenta',
        subtitle: 'Guarda tus libros y sigue donde te quedaste.',
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
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. María García',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              validator: AuthValidators.name,
            ),
            const SizedBox(height: 12),
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
                helperText:
                    'Mínimo 8 caracteres, con mayúscula, minúscula, número y símbolo.',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
            ),
          ],
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
            : const Text('Crear cuenta'),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('o', style: Theme.of(context).textTheme.bodyMedium),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 16),
      GoogleSignInButton(onPressed: _google, busy: _googleBusy),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('¿Ya tienes cuenta?'),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    ],
  );
}
