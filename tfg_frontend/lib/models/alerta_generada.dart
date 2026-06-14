class AlertaGenerada {
  final String id;
  final String userId;
  final String spotId;
  final DateTime fecha;
  final String? mensaje;
  final String? materialId;

  // Datos del material (join)
  final String? materialNombre;
  final String? materialTipo;
  final String? materialMedida;
  final String? materialDisciplina;
  final String? materialMarca;
  final String? materialModelo;

  AlertaGenerada({
    required this.id,
    required this.userId,
    required this.spotId,
    required this.fecha,
    this.mensaje,
    this.materialId,
    this.materialNombre,
    this.materialTipo,
    this.materialMedida,
    this.materialDisciplina,
    this.materialMarca,
    this.materialModelo,
  });

  factory AlertaGenerada.fromJson(Map<String, dynamic> json) {
    final mat = json['MaterialUsuario'] as Map<String, dynamic>?;
    return AlertaGenerada(
      id: json['id'],
      userId: json['user_id'],
      spotId: json['spot_id'],
      fecha: DateTime.parse(json['fecha']),
      mensaje: json['mensaje'],
      materialId: json['material_usado'],
      materialNombre: mat?['nombre'],
      materialTipo: mat?['tipo'],
      materialMedida: mat?['medida'],
      materialDisciplina: mat?['disciplina'],
      materialMarca: mat?['marca'],
      materialModelo: mat?['modelo'],
    );
  }

  /// Texto compacto del material para mostrar en la card
  String get materialResumen {
    if (materialNombre != null && materialNombre!.isNotEmpty) {
      final medida = materialMedida != null ? ' · ${_medidaConUnidad()}' : '';
      return '$materialNombre$medida';
    }
    if (materialTipo != null) {
      final marca = materialMarca != null ? ' $materialMarca' : '';
      final modelo = materialModelo != null ? ' $materialModelo' : '';
      final medida = materialMedida != null ? ' · ${_medidaConUnidad()}' : '';
      return '${materialTipo!}$marca$modelo$medida';
    }
    return 'Material no especificado';
  }

  String _medidaConUnidad() {
    final v = materialMedida ?? '';
    final tipo = materialTipo?.toLowerCase() ?? '';
    final disc = materialDisciplina?.toLowerCase() ?? '';
    if (tipo == 'foil') return '$v cm²';
    if (tipo == 'cometa' || tipo == 'ala') return '$v m²';
    if (tipo == 'vela') return '$v m²';
    if (tipo == 'botavara' || tipo == 'mástil') return '$v cm';
    if (tipo == 'tabla' && disc.contains('kite')) return '$v cm';
    if (tipo == 'tabla') return '$v L';
    return v;
  }
}
