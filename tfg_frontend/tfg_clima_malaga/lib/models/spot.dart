class Spot {
  final String id;
  final String nombre;
  final String? icono;
  final String? camUrl;

  final double lat;
  final double lng;

  final bool isSurf;
  final bool isKitesurf;
  final bool isWindsurf;
  final bool isWing;
  final bool isSail;

  final DateTime createdAt;

  Spot({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.camUrl,
    required this.lat,
    required this.lng,
    required this.isSurf,
    required this.isKitesurf,
    required this.isWindsurf,
    required this.isWing,
    required this.isSail,
    required this.createdAt,
  });

  factory Spot.fromJson(Map<String, dynamic> json) {
    // Extraer coordenadas desde pointjson
    final coords = json['pointjson']?['coordinates'] ?? [0.0, 0.0];

    return Spot(
      id: json['id'],
      nombre: json['nombre'],
      icono: json['icono'],
      camUrl: json['cam_url'],
      lat: (coords[0] as num).toDouble(),
      lng: (coords[1] as num).toDouble(),
      isSurf: json['is_surf'] ?? false,
      isKitesurf: json['is_kitesurf'] ?? false,
      isWindsurf: json['is_windsurf'] ?? false,
      isWing: json['is_wing'] ?? false,
      isSail: json['is_sail'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
