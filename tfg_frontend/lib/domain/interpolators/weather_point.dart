//  WeatherPoint — punto con posición + valor + dirección
//  Usado por todos los CustomPainter de capas meteorológicas

// ignore_for_file: file_names

class WeatherPoint {
  final double lat;
  final double lng;
  final double value; // velocidad en nudos / altura en metros / mm / °C
  final double dir; // dirección en grados (0=Norte, 90=Este)

  const WeatherPoint({
    required this.lat,
    required this.lng,
    required this.value,
    this.dir = 0.0,
  });
}
