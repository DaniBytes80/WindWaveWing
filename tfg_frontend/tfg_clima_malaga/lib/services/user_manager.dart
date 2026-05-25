import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/models/perfil.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  final _supabase = Supabase.instance.client;

  Perfil? get usuario => _perfil;

  Perfil? _perfil;
  bool _isLogueado = false;

  Perfil? get perfil => _perfil;
  bool get isLogueado => _isLogueado;

  Future<void> cargarPerfilSiExiste() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _perfil = null;
      _isLogueado = false;
      return;
    }

    final data = await _supabase
        .from("Perfiles")
        .select()
        .eq("id", user.id)
        .single();

    _perfil = Perfil.fromJson(data);
    _isLogueado = true;
  }

  void setPerfil(Perfil perfil) {
    _perfil = perfil;
    _isLogueado = true;
  }

  void actualizarPerfilLocal(Perfil nuevoPerfil) {
    _perfil = nuevoPerfil;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _perfil = null;
    _isLogueado = false;
  }
}
