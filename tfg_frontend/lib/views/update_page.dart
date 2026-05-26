import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/perfil.dart';
import 'package:tfg_clima_malaga/services/perfil_bd.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/www_widgets.dart'; // ← Ojo: mismo nombre que tu archivo

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final Map<String, bool> deportesController = {
    'Surf': false,
    'Kitesurf': false,
    'Windsurf': false,
    'Wingfoil': false,
    'Vela': false,
  };

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    final Perfil? perfil = UserManager().perfil;
    if (perfil == null) return;

    _emailController.text = perfil.email;
    _nombreController.text = perfil.nombre ?? '';
    _telefonoController.text = perfil.telefono ?? '';

    deportesController['Surf'] = perfil.surf;
    deportesController['Kitesurf'] = perfil.kiteSurf;
    deportesController['Windsurf'] = perfil.windsurf;
    deportesController['Wingfoil'] = perfil.wing;
    deportesController['Vela'] = perfil.sail;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final perfilBd = PerfilBd();

      await perfilBd.updateWithAll(
        email: _emailController.text,
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        deportes: deportesController,
      );

      final perfilActual = UserManager().perfil!;
      final perfilActualizado = perfilActual.copyWith(
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        surf: deportesController['Surf'],
        kiteSurf: deportesController['Kitesurf'],
        windsurf: deportesController['Windsurf'],
        wing: deportesController['Wingfoil'],
        sail: deportesController['Vela'],
      );

      UserManager().actualizarPerfilLocal(perfilActualizado);

      if (mounted) {
        WWWWidgets.mostrarSnackBar(
          context,
          'Perfil actualizado',
          esError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        WWWWidgets.mostrarSnackBar(
          context,
          'Error al actualizar el perfil: $e',
          esError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _buildDeporteSwitch(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: deportesController[key] ?? false,
      onChanged: (v) {
        setState(() {
          deportesController[key] = v;
        });
      },
      // Si quieres evitar el warning de activeColor:
      // thumbColor: MaterialStateProperty.all(EstilosWWW.colorLetra),
      activeThumbColor: EstilosWWW
          .colorLetra, // puedes dejarlo aunque esté deprecado, no rompe nada
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        backgroundColor: EstilosWWW.colorFondoPantalla,
        title: const Text('Editar perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: EstilosWWW.colorLetra),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white70),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Introduce un nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Deportes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildDeporteSwitch('Surf', 'Surf'),
                    _buildDeporteSwitch('Kitesurf', 'Kitesurf'),
                    _buildDeporteSwitch('Windsurf', 'Windsurf'),
                    _buildDeporteSwitch('Wingfoil', 'Wingfoil'),
                    _buildDeporteSwitch('Vela', 'Vela'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EstilosWWW.colorLetra,
                      ),
                      child: const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
