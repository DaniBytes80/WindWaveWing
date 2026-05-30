import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/alerta.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';

class EditarAlertaPage extends StatefulWidget {
  final Alerta alerta;

  const EditarAlertaPage({super.key, required this.alerta});

  @override
  State<EditarAlertaPage> createState() => _EditarAlertaPageState();
}

class _EditarAlertaPageState extends State<EditarAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final AlertasService _alertasService = AlertasService();
  final SpotManager _spotManager = SpotManager();

  late String _spotId;
  String? _disciplina;
  String? _nivel;
  String? _mensaje;
  String? _nombre;
  bool _activa = true;

  final nivelesTecnicos = ["Principiante", "Ocasional", "Intensivo", "Pro"];

  List<Spot> _spotsFavoritos = [];

  @override
  void initState() {
    super.initState();

    final a = widget.alerta;

    _spotId = a.spotId;
    _disciplina = a.disciplina;
    _nivel = a.nivel;
    _mensaje = a.mensaje;
    _nombre = a.nombre;
    _activa = a.activa;

    _spotsFavoritos = _spotManager.spots
        .where((s) => _spotManager.favoritos.contains(s.id))
        .toList();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final alertaActualizada = Alerta(
      id: widget.alerta.id,
      userId: widget.alerta.userId,
      spotId: _spotId,
      nombre: _nombre,
      disciplina: _disciplina,
      nivel: _nivel,
      mensaje: _mensaje,
      activa: _activa,
      fechaCreacion: widget.alerta.fechaCreacion,
    );

    final ok = await _alertasService.actualizarAlerta(alertaActualizada);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error actualizando alerta")),
      );
    }
  }

  Future<void> _borrar() async {
    final ok = await _alertasService.borrarAlerta(widget.alerta.id);
    if (ok) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Alerta"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'borrar') {
                _borrar();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'borrar',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Eliminar alerta"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nombre,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Introduce un nombre" : null,
                onSaved: (v) => _nombre = v,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _spotId,
                decoration: const InputDecoration(labelText: "Spot"),
                items: _spotsFavoritos
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _spotId = v!),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _disciplina,
                decoration: const InputDecoration(labelText: "Disciplina"),
                items:
                    ["surf", "kitesurf", "windsurf", "wingfoil", "vela ligera"]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) => setState(() => _disciplina = v),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _nivel,
                decoration: const InputDecoration(labelText: "Nivel técnico"),
                items: nivelesTecnicos
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => _nivel = v),
              ),

              const SizedBox(height: 16),

              TextFormField(
                initialValue: _mensaje,
                decoration: const InputDecoration(labelText: "Mensaje"),
                maxLines: 2,
                onSaved: (v) => _mensaje = v,
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text("Alerta activa"),
                value: _activa,
                onChanged: (v) => setState(() => _activa = v),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _guardarCambios,
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
