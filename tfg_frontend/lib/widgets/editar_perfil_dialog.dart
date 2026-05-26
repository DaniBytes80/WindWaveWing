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

  bool surf = false;
  bool kite = false;
  bool wind = false;
  bool wing = false;
  bool sail = false;

  File? imagenLocal;

  @override
  void initState() {
    super.initState();

    final user = UserManager().usuario;

    nombreCtrl = TextEditingController(text: user?.nombre ?? "");
    telefonoCtrl = TextEditingController(text: user?.telefono ?? "");
    avatarCtrl = TextEditingController(text: user?.avatarUrl ?? "");

    surf = user?.surf ?? false;
    kite = user?.kiteSurf ?? false;
    wind = user?.windsurf ?? false;
    wing = user?.wing ?? false;
    sail = user?.sail ?? false;
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imagenLocal = File(picked.path);
      });
    }
  }

  Future<String?> subirImagenAStorage(String userId) async {
    if (imagenLocal == null) return null;

    final fileName =
        "$userId-avatar-${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage
        .from("avatars")
        .upload(
          fileName,
          imagenLocal!,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = supabase.storage.from("avatars").getPublicUrl(fileName);

    return url;
  }

  Future<void> guardar() async {
    final user = UserManager().usuario;
    if (user == null) return;

    String? avatarUrl = avatarCtrl.text.trim();

    if (imagenLocal != null) {
      avatarUrl = await subirImagenAStorage(user.id);
    }

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
          "sail": sail,
          "rol": "USUARIO",
        })
        .eq("id", user.id);

    await UserManager().cargarPerfilSiExiste();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Registros actualizados")));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⭐ AVATAR
            GestureDetector(
              onTap: seleccionarImagen,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                backgroundImage: imagenLocal != null
                    ? FileImage(imagenLocal!)
                    : (avatarCtrl.text.isNotEmpty
                              ? NetworkImage(avatarCtrl.text)
                              : null)
                          as ImageProvider?,
                child: (imagenLocal == null && avatarCtrl.text.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Toca el avatar para cambiarlo",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nombreCtrl,
              style: TextStyle(color: EstilosWWW.colorLetra),
              decoration: const InputDecoration(
                labelText: "Nombre de usuario",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            TextField(
              controller: telefonoCtrl,
              style: TextStyle(color: EstilosWWW.colorLetra),
              decoration: const InputDecoration(
                labelText: "Teléfono",
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 20),

            _check("Surf", surf, (v) => setState(() => surf = v)),
            _check("Kite Surf", kite, (v) => setState(() => kite = v)),
            _check("Windsurf", wind, (v) => setState(() => wind = v)),
            _check("Wing", wing, (v) => setState(() => wing = v)),
            _check("Sail", sail, (v) => setState(() => sail = v)),

            const SizedBox(height: 25),

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
    );
  }
}
