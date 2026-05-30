import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';

class CrearAlertaPage extends StatefulWidget {
  const CrearAlertaPage({super.key});

  @override
  State<CrearAlertaPage> createState() => _CrearAlertaPageState();
}

class _CrearAlertaPageState extends State<CrearAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final AlertasService _alertasService = AlertasService();
  final SpotManager _spotManager = SpotManager();

  String? _spotId;
  String? _disciplina;
  String? _nivel;
  String? _mensaje;
  String? _nombre;

  final nivelesTecnicos = ["Principiante", "Ocasional", "Intensivo", "Pro"];

  List<Spot> _spotsFavoritos = [];

  @override
  void initState() {
    super.initState();
    _spotsFavoritos = _spotManager.spots
        .where((s) => _spotManager.favoritos.contains(s.id))
        .toList();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final userId = _alertasService.supabase.auth.currentUser?.id;

    if (userId == null) return;

    final ok = await _alertasService.crearAlerta({
      "user_id": userId,
      "spot_id": _spotId,
      "nombre": _nombre,
      "disciplina": _disciplina,
      "nivel": _nivel,
      "mensaje": _mensaje,
      "activa": true,
    });

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error guardando alerta")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Alerta")),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Introduce un nombre" : null,
                onSaved: (v) => _nombre = v,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Spot"),
                items: _spotsFavoritos
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                    )
                    .toList(),
                validator: (v) => v == null ? "Selecciona un spot" : null,
                onChanged: (v) => setState(() => _spotId = v),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Disciplina"),
                items:
                    ["surf", "kitesurf", "windsurf", "wingfoil", "vela ligera"]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) => setState(() => _disciplina = v),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Nivel técnico"),
                items: nivelesTecnicos
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => _nivel = v),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: "Mensaje"),
                maxLines: 2,
                onSaved: (v) => _mensaje = v,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _crear,
                child: const Text("Crear alerta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
