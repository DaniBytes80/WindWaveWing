import 'package:flutter/material.dart';

class WWWWidgets {
  // Campo de texto inteligente: Configura el teclado según la necesidad
  static Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    bool obscure = false,
    TextInputType tipoTeclado = TextInputType.text,
    required bool readOnly, // <--- ESTO activa la @
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: tipoTeclado,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icono, color: Colors.white70, size: 20),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  static void mostrarSnackBar(
    BuildContext context,
    String mensaje, {
    bool esError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
      ),
    );
  }
}
