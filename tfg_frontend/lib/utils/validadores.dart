class Validadores {
  static bool esEmailValido(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  static bool tieneContactoMinimo(String email, String tlf) =>
      email.trim().isNotEmpty || tlf.trim().isNotEmpty;

  // NUEVA: Validación de contraseña compleja
  static bool esContrasenaSegura(String pass) {
    // Explicación de la RegExp para tu memoria del TFG:
    // (?=.*[A-Z]) -> Al menos una mayúscula
    // (?=.*[a-z]) -> Al menos una minúscula
    // (?=.*?[0-9]) -> Al menos un número
    // (?=.*?[!@#\$&*~]) -> Al menos un carácter especial
    // .{8,} -> Mínimo 8 caracteres
    return RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
    ).hasMatch(pass);
  }
}
