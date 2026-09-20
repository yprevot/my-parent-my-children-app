/// Validadores de los formularios de autenticación (ES).
///
/// Reglas de contraseña: mínimo 8 caracteres, al menos una mayúscula,
/// una minúscula, un número y un símbolo.
class AuthValidators {
  AuthValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _upper = RegExp(r'[A-ZÁÉÍÓÚÜÑ]');
  static final RegExp _lower = RegExp(r'[a-záéíóúüñ]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _symbol = RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9\s]');

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe tu nombre.';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 letras.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe tu correo electrónico.';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Ese correo no parece válido. Revísalo.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Escribe una contraseña.';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres.';
    }
    if (!_upper.hasMatch(value)) {
      return 'Añade al menos una mayúscula (A-Z).';
    }
    if (!_lower.hasMatch(value)) {
      return 'Añade al menos una minúscula (a-z).';
    }
    if (!_digit.hasMatch(value)) {
      return 'Añade al menos un número (0-9).';
    }
    if (!_symbol.hasMatch(value)) {
      return 'Añade al menos un símbolo (ej. !, @, #).';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Repite la contraseña.';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }
}
