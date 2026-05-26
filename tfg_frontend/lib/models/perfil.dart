class Perfil {
  final String id;
  final String? nombre;
  final String email;
  final String? rol;
  final DateTime fechaRegistro;
  final String? telefono;

  final bool surf;
  final bool kiteSurf;
  final bool windsurf;
  final bool wing;
  final bool sail;

  final String? avatarUrl;

  Perfil({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaRegistro,
    required this.telefono,
    required this.surf,
    required this.kiteSurf,
    required this.windsurf,
    required this.wing,
    required this.sail,
    required this.avatarUrl,
  });

  // ============================================================
  // 1. Crear Perfil desde JSON de Supabase
  // ============================================================
  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      telefono: json['telefono'],
      surf: json['surf'] ?? false,
      kiteSurf: json['kite_surf'] ?? false,
      windsurf: json['windsurf'] ?? false,
      wing: json['wing'] ?? false,
      sail: json['sail'] ?? false,
      avatarUrl: json['avatar_url'],
    );
  }

  // ============================================================
  // 2. Convertir Perfil a JSON
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'telefono': telefono,
      'surf': surf,
      'kite_surf': kiteSurf,
      'windsurf': windsurf,
      'wing': wing,
      'sail': sail,
      'avatar_url': avatarUrl,
    };
  }

  // ============================================================
  // 3. Copiar perfil modificando solo algunos campos
  // ============================================================
  Perfil copyWith({
    String? nombre,
    String? telefono,
    bool? surf,
    bool? kiteSurf,
    bool? windsurf,
    bool? wing,
    bool? sail,
    String? avatarUrl,
    bool? vela,
  }) {
    return Perfil(
      id: id,
      nombre: nombre ?? this.nombre,
      email: email,
      rol: rol,
      fechaRegistro: fechaRegistro,
      telefono: telefono ?? this.telefono,
      surf: surf ?? this.surf,
      kiteSurf: kiteSurf ?? this.kiteSurf,
      windsurf: windsurf ?? this.windsurf,
      wing: wing ?? this.wing,
      sail: sail ?? this.sail,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
