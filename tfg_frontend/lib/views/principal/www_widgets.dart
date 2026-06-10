import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class WWWWidgets {
  // ⭐ Campo de texto reutilizable
  static Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    bool obscure = false,
    TextInputType tipoTeclado = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        keyboardType: tipoTeclado,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icono, color: Colors.white70, size: 20),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: EstilosWWW.colorLetra),
          ),
        ),
      ),
    );
  }

  // ⭐ SnackBar reutilizable (por si lo necesitas en otras pantallas)
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
