class ClimaModelo {
  final String spotId;
  final DateTime fechaHora;
  final double velocidadViento;
  final String direccionViento;
  final double rachaViento;
  final double alturaOla;
  final double periodoOla;
  final String direccionOla;

  // ⭐ NUEVO CAMPO
  final double probabilidadLluvia;

  ClimaModelo({
    required this.spotId,
    required this.fechaHora,
    required this.velocidadViento,
    required this.direccionViento,
    required this.rachaViento,
    required this.alturaOla,
    required this.periodoOla,
    required this.direccionOla,
    required this.probabilidadLluvia,
  });

  factory ClimaModelo.fromJson(Map<String, dynamic> json) {
    return ClimaModelo(
      spotId: json['spot_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      velocidadViento: (json['velocidad_viento'] as num).toDouble(),
      direccionViento: json['direccion_viento'] ?? '',
      rachaViento: (json['racha_viento'] as num).toDouble(),
      alturaOla: (json['altura_ola'] as num).toDouble(),
      periodoOla: (json['periodo_ola'] as num).toDouble(),
      direccionOla: json['direccion_ola'] ?? '',

      // ⭐ NUEVO MAPEADO
      probabilidadLluvia: json['probabilidad_lluvia'] != null
          ? (json['probabilidad_lluvia'] as num).toDouble()
          : 0.0,
    );
  }
}
