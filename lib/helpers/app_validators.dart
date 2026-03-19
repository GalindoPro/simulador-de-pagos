class AppValidators {
  AppValidators._();

  static String? nombre(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (v.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  static String? apellido(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El apellido es requerido';
    }
    if (v.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  static String? telefono(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      return 'El teléfono debe tener 8 dígitos';
    }
    return null;
  }

  static String? dpi(String? v) {
    if (v == null || v.trim().isEmpty) {
      return null; // DPI es opcional
    }
    final digits = v.replaceAll('-', '');
    if (digits.length != 13) {
      return 'DPI debe tener 13 dígitos';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) {
      return null; // Email es opcional
    }
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!regex.hasMatch(v.trim())) {
      return 'Correo electrónico no válido';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'La contraseña es requerida';
    }
    if (v.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? confirmarPassword(String? v, String password) {
    if (v == null || v.trim().isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (v != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? monto(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'El monto es requerido';
    }
    final parsed = double.tryParse(v.replaceAll(',', ''));
    if (parsed == null) {
      return 'Ingresa un monto válido';
    }
    if (parsed <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    return null;
  }

  static String? requerido(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Este campo es requerido';
    }
    return null;
  }
}
