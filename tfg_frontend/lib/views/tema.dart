// tema.dart
import 'package:flutter/material.dart';

class EstilosWWW {
  // Colores base
  static const Color colorFondoPantalla = Color.fromARGB(255, 0, 7, 35);
  static final Color fondoTransparente = colorFondoPantalla.withValues(
    alpha: 0.6,
  );
  static const Color colorLetra = Colors.white;
  static const Color colorLetraMenuMapa = Color.fromARGB(255, 0, 7, 35);
  static const Color colorEnlace = Colors.white70;
  static const Color colorBordeTabla = Colors.white24;
  static const Color colorError = Colors.redAccent;

  // Estilos de texto (Como si fueran clases CSS)
  static const TextStyle tituloApp = TextStyle(
    color: colorLetra,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle textoTabla = TextStyle(
    color: colorLetra,
    fontSize: 14,
  );

  static const TextStyle textoNegritaTabla = TextStyle(
    color: colorLetra,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle linkRegistro = TextStyle(
    color: colorEnlace,
    decoration: TextDecoration.underline,
    fontSize: 12,
  );
  static const TextStyle bordeTabla = TextStyle(
    color: colorBordeTabla,
    fontWeight: FontWeight.bold,
  );
  static final ButtonStyle botonOscuro = ElevatedButton.styleFrom(
    backgroundColor: colorBordeTabla,
    foregroundColor: colorEnlace,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
