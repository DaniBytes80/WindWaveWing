import 'dart:math' as math;

String capitalizar(String texto) {
  if (texto.isEmpty) return texto;
  return texto[0].toUpperCase() + texto.substring(1);
}

double direccionToAngle(String direccion) {
  if (direccion.isEmpty) return 0;

  final d = direccion.trim().toUpperCase();

  // Casos especiales
  if (d == "VARIABLE" || d == "---") return 0;

  // Normalizar direcciones largas a los 8 rumbos principales
  // Ejemplo: NNE → N, ENE → E, SSW → S, etc.
  String base = d;

  if (d.length > 2) {
    if (d.contains("N") && !d.contains("S")) base = "N";
    if (d.contains("S") && !d.contains("N")) base = "S";
    if (d.contains("E") && !d.contains("W")) base = "E";
    if (d.contains("W") && !d.contains("E")) base = "W";

    if (d.contains("N") && d.contains("E")) base = "NE";
    if (d.contains("S") && d.contains("E")) base = "SE";
    if (d.contains("S") && d.contains("W")) base = "SW";
    if (d.contains("N") && d.contains("W")) base = "NW";
  }

  final mapa = {
    "N": 0,
    "NE": 45,
    "E": 90,
    "SE": 135,
    "S": 180,
    "SW": 225,
    "W": 270,
    "NW": 315,
  };

  final grados = mapa[base] ?? 0;

  // Convertir a radianes
  return grados * math.pi / 180;
}

double kmhToKnots(double kmh) => kmh / 1.852;
