import 'package:uuid/uuid.dart';

class MaterialUsuario {
  final String id;
  final String userId;

  /// Disciplina: kitesurf, wingfoil, windsurf, surf, paddle, vela ligera, foil…
  final String disciplina;

  /// Tipo: tabla, cometa, wing, foil, mástil, fuselaje, arnés, etc.
  final String tipo;

  /// Nombre descriptivo del material (opcional)
  final String? nombre;

  final DateTime fechaCreacion;

  final String? marca;
  final String? modelo;
  final int? ano;

  /// Medida genérica (ej: “5m”, “85L”, “210cm”, “800cm2”)
  final String? medida;

  final String? descripcion;

  MaterialUsuario({
    String? id,
    required this.userId,
    required this.disciplina,
    required this.tipo,
    this.nombre,
    DateTime? fechaCreacion,
    this.marca,
    this.modelo,
    this.ano,
    this.medida,
    this.descripcion,
  }) : id = id ?? const Uuid().v4(),
       fechaCreacion = fechaCreacion ?? DateTime.now();

  // Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'disciplina': disciplina,
      'tipo': tipo,
      'nombre': nombre,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'medida': medida,
      'descripcion': descripcion,
    };
  }

  // Crear desde JSON de Supabase
  factory MaterialUsuario.fromJson(Map<String, dynamic> json) {
    return MaterialUsuario(
      id: json['id'],
      userId: json['user_id'],
      disciplina: json['disciplina'],
      tipo: json['tipo'],
      nombre: json['nombre'],
      fechaCreacion:
          DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      marca: json['marca'],
      modelo: json['modelo'],
      ano: json['ano'],
      medida: json['medida'],
      descripcion: json['descripcion'],
    );
  }

  // copyWith para editar material
  MaterialUsuario copyWith({
    String? id,
    String? userId,
    String? disciplina,
    String? tipo,
    String? nombre,
    DateTime? fechaCreacion,
    String? marca,
    String? modelo,
    int? ano,
    String? medida,
    String? descripcion,
  }) {
    return MaterialUsuario(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      disciplina: disciplina ?? this.disciplina,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      medida: medida ?? this.medida,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  @override
  String toString() {
    return 'MaterialUsuario(id: $id, userId: $userId, disciplina: $disciplina, tipo: $tipo, nombre: $nombre, marca: $marca, modelo: $modelo, ano: $ano, medida: $medida)';
  }
}
