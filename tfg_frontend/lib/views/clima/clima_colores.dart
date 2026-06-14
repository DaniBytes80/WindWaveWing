import 'package:flutter/material.dart';

// Convierte la velocidad del viento (en nudos) a un color
Color colorViento(double kn) {
  if (kn < 7) return const Color(0xFF64B5F6); // azul claro — calma
  if (kn < 14) return const Color(0xFF26C6DA); // cian — brisa suave
  if (kn < 21) return const Color(0xFF66BB6A); // verde — brisa moderada
  if (kn < 33) return const Color(0xFFFFEE58); // amarillo — viento fresco
  if (kn < 47) return const Color(0xFFFFA726); // naranja — viento fuerte
  return const Color(0xFFEF5350); // rojo — temporal
}

// Convierte la dirección del viento a radianes para rotar el icono de flecha
Color colorOla(double m) {
  if (m < 0.5) return const Color(0xFF90A4AE); // gris — calma
  if (m < 1.0) return const Color(0xFF66BB6A); // verde — suave
  if (m < 2.0) return const Color(0xFF26C6DA); // cian — moderada
  if (m < 3.0) return const Color(0xFF42A5F5); // azul — considerable
  if (m < 4.0) return const Color(0xFFFFA726); // naranja — fuerte
  return const Color(0xFFEF5350); // rojo — peligrosa
}

// Convierte un porcentaje de lluvia a un color
Color colorLluvia(int porcentaje) {
  if (porcentaje == 0) {
    return const Color(0xFF1565C0).withValues(alpha: 0.0); // transparente
  }
  if (porcentaje < 20) return const Color(0xFF90CAF9); // azul pálido
  if (porcentaje < 40) return const Color(0xFF42A5F5); // azul
  if (porcentaje < 60) return const Color(0xFF1565C0); // azul intenso
  if (porcentaje < 80) return const Color(0xFF7B1FA2); // violeta
  return const Color(0xFFAD1457); // magenta — tormenta
}

// Convierte la temperatura a un color
Color colorTemperatura(double t) {
  if (t < 0) return const Color(0xFF1A237E); // azul oscuro — frío peligroso
  if (t < 10) return const Color(0xFF1565C0); // azul
  if (t < 18) return const Color(0xFF00ACC1); // cian — fresco
  if (t < 24) return const Color(0xFF43A047); // verde — óptimo surf
  if (t < 30) return const Color(0xFFFDD835); // amarillo — caluroso
  if (t < 38) return const Color(0xFFFB8C00); // naranja — calor
  return const Color(0xFFB71C1C); // rojo — peligro calor
}
