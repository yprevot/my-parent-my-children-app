import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Expone el [AuthService] y el usuario actual a todo el árbol.
class AuthScope extends StatefulWidget {
  const AuthScope({super.key, required this.service, required this.child});

  final AuthService service;
  final Widget child;

  static AuthScopeState of(BuildContext context) {
    final state = context.findAncestorStateOfType<AuthScopeState>();
    assert(state != null, 'AuthScope no encontrado en el árbol.');
    return state!;
  }

  @override
  State<AuthScope> createState() => AuthScopeState();
}

class AuthScopeState extends State<AuthScope> {
  AuthUser? _user;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthService get service => widget.service;
  AuthUser? get user => _user;

  @override
  void initState() {
    super.initState();
    _user = widget.service.currentUser;
    _subscription = widget.service.userChanges.listen((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Decide qué mostrar según la sesión:
/// sin usuario -> [LoginScreen]; con usuario -> `signedInBuilder`.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.signedInBuilder,
    required this.signInScreen,
  });

  final WidgetBuilder signedInBuilder;
  final Widget signInScreen;

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    if (user == null) return signInScreen;
    return signedInBuilder(context);
  }
}
