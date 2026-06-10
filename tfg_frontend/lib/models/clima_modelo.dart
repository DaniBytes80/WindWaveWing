class ClimaModelo {
  final String spotId;
  final DateTime fechaHora;
  final double velocidadViento;
  final String direccionViento;
  final double rachaViento;
  final double alturaOla;
  final double periodoOla;
  final String direccionOla;

  final double temperatura;
  final double humedad;
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
    required this.temperatura,
    required this.humedad,
    required this.probabilidadLluvia,
  });

  factory ClimaModelo.fromJson(Map<String, dynamic> json) {
    return ClimaModelo(
      spotId: json['spot_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      velocidadViento: (json['velocidad_viento'] as num?)?.toDouble() ?? 0.0,
      direccionViento: json['direccion_viento'] ?? '',
      rachaViento: (json['racha_viento'] as num?)?.toDouble() ?? 0.0,
      alturaOla: (json['altura_ola'] as num?)?.toDouble() ?? 0.0,
      periodoOla: (json['periodo_ola'] as num?)?.toDouble() ?? 0.0,
      direccionOla: json['direccion_ola'] ?? '',

      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 0.0,
      humedad: (json['humedad'] as num?)?.toDouble() ?? 0.0,
      probabilidadLluvia:
          (json['probabilidad_lluvia'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
