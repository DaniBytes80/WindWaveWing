import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class EditarPerfilDialog extends StatefulWidget {
  const EditarPerfilDialog({super.key});

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  final supabase = Supabase.instance.client;

  late TextEditingController nombreCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController avatarCtrl;
  late TextEditingController pesoCtrl;

  bool surf = false;
  bool kite = false;
  bool wind = false;
  bool wing = false;
  bool vela = false;

  bool notificacionesActivas = true;

  File? imagenLocal;
  bool _pickerActivo = false;

  @override
  void initState() {
    super.initState();

    final user = UserManager().usuario;

    nombreCtrl = TextEditingController(text: user?.nombre ?? "");
    telefonoCtrl = TextEditingController(text: user?.telefono ?? "");
    avatarCtrl = TextEditingController(text: user?.avatarUrl ?? "");
    pesoCtrl = TextEditingController(
      text: user?.pesoKg != null ? user!.pesoKg.toString() : "",
    );

    surf = user?.surf ?? false;
    kite = user?.kiteSurf ?? false;
    wind = user?.windsurf ?? false;
    wing = user?.wing ?? false;
    vela = user?.sail ?? false;

    notificacionesActivas = user?.notificacionesActivas ?? true;
  }

  Future<void> seleccionarImagen() async {
    if (_pickerActivo) return;
    _pickerActivo = true;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          imagenLocal = File(picked.path);
        });
      }
    } finally {
      _pickerActivo = false;
    }
  }

  Future<String?> subirImagenAStorage(String userId) async {
    if (imagenLocal == null) return null;

    final fileName =
        "$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage
        .from("avatars")
        .upload(
          fileName,
          imagenLocal!,
          fileOptions: const FileOptions(upsert: true),
        );

    return supabase.storage.from("avatars").getPublicUrl(fileName);
  }

  Future<void> borrarAvatarDeStorage(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final path = url.split("/avatars/").last;
      await supabase.storage.from("avatars").remove([path]);
    } catch (_) {}
  }

  Future<void> guardar() async {
    final user = UserManager().usuario;
    if (user == null) return;

    String? avatarUrl = avatarCtrl.text.trim();

    if (imagenLocal != null) {
      await borrarAvatarDeStorage(user.avatarUrl);
      avatarUrl = await subirImagenAStorage(user.id);
    }

    if (imagenLocal == null && avatarCtrl.text.trim().isEmpty) {
      await borrarAvatarDeStorage(user.avatarUrl);
      avatarUrl = null;
    }

    final int? pesoKg = pesoCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(pesoCtrl.text.trim());

    await supabase
        .from("Perfiles")
        .update({
          "nombre": nombreCtrl.text.trim(),
          "telefono": telefonoCtrl.text.trim(),
          "avatar_url": avatarUrl,
          "surf": surf,
          "kite_surf": kite,
          "windsurf": wind,
          "wing": wing,
          "sail": vela,
          "peso_kg": pesoKg,
          "notificaciones_activas": notificacionesActivas,
          "rol": "USUARIO",
        })
        .eq("id", user.id);

    final perfilActualizado = user.copyWith(
      nombre: nombreCtrl.text.trim(),
      telefono: telefonoCtrl.text.trim(),
      avatarUrl: avatarUrl,
      surf: surf,
      kiteSurf: kite,
      windsurf: wind,
      wing: wing,
      sail: vela,
      pesoKg: pesoKg,
      notificacionesActivas: notificacionesActivas,
      rol: "USUARIO",
    );

    UserManager().actualizarPerfilLocal(perfilActualizado);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ AVATAR + BOTÓN X
              Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: seleccionarImagen,
                    child: CircleAvatar(
                      key: ValueKey(avatarCtrl.text),
                      radius: 30,
                      backgroundColor: Colors.white24,
                      backgroundImage: imagenLocal != null
                          ? FileImage(imagenLocal!)
                          : (avatarCtrl.text.isNotEmpty
                                    ? NetworkImage(avatarCtrl.text)
                                    : null)
                                as ImageProvider?,
                      child: (imagenLocal == null && avatarCtrl.text.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),

                  Positioned(
                    right: -6,
                    top: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          imagenLocal = null;
                          avatarCtrl.text = "";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: nombreCtrl,
                style: TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(
                  labelText: "Nombre de usuario",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: telefonoCtrl,
                      style: TextStyle(color: EstilosWWW.colorLetra),
                      decoration: const InputDecoration(
                        labelText: "Teléfono",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: pesoCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: EstilosWWW.colorLetra),
                      decoration: const InputDecoration(
                        labelText: "Peso (kg)",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _check("Surf", surf, (v) => setState(() => surf = v)),
                        _check(
                          "Windsurf",
                          wind,
                          (v) => setState(() => wind = v),
                        ),
                        _check("Vela", vela, (v) => setState(() => vela = v)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _check(
                          "Kite Surf",
                          kite,
                          (v) => setState(() => kite = v),
                        ),
                        _check("Wing", wing, (v) => setState(() => wing = v)),

                        Row(
                          children: [
                            const Text(
                              "Notif.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: notificacionesActivas,
                              onChanged: (v) =>
                                  setState(() => notificacionesActivas = v),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              activeThumbColor: Colors.white,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white24,
                              activeTrackColor: Colors.white38,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    style: EstilosWWW.botonOscuro,
                    onPressed: guardar,
                    child: const Text("Aceptar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _check(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.white,
      checkColor: Colors.black,
      contentPadding: EdgeInsets.zero,
    );
  }
}
