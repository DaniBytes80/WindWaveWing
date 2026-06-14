import 'package:uuid/uuid.dart';

class Alerta {
  final String id;
  final String userId;
  final String spotId;

  final bool activa;
  final String? nombre;
  final String? disciplina;
  final String? nivel;
  final String? mensaje;

  final int frecuenciaHoras;
  final int horaInicio;
  final int horaFin;

  final DateTime fechaCreacion;

  Alerta({
    String? id,
    required this.userId,
    required this.spotId,
    this.activa = true,
    this.nombre,
    this.disciplina,
    this.nivel,
    this.mensaje,
    this.frecuenciaHoras = 4,
    this.horaInicio = 7,
    this.horaFin = 22,
    DateTime? fechaCreacion,
  }) : id = id ?? const Uuid().v4(),
       fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'spot_id': spotId,
      'activa': activa,
      'nombre': nombre,
      'disciplina': disciplina,
      'nivel': nivel,
      'mensaje': mensaje,
      'frecuencia_horas': frecuenciaHoras,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      userId: json['user_id'],
      spotId: json['spot_id'],
      activa: json['activa'] ?? true,
      nombre: json['nombre'],
      disciplina: json['disciplina'],
      nivel: json['nivel'],
      mensaje: json['mensaje'],
      frecuenciaHoras: json['frecuencia_horas'] ?? 4,
      horaInicio: json['hora_inicio'] ?? 7,
      horaFin: json['hora_fin'] ?? 22,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}
