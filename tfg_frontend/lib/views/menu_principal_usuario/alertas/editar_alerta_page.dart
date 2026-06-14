import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/alerta.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class EditarAlertaPage extends StatefulWidget {
  final Alerta alerta;
  const EditarAlertaPage({super.key, required this.alerta});
  @override
  State<EditarAlertaPage> createState() => _EditarAlertaPageState();
}

class _EditarAlertaPageState extends State<EditarAlertaPage> {
  final _formKey = GlobalKey<FormState>();
  final _alertasService = AlertasService();
  final _spotManager = SpotManager();

  late String _spotId;
  String? _disciplina, _nivel, _mensaje, _nombre;
  bool _activa = true;
  int _frecuenciaHoras = 4;
  int _horaInicio = 7;
  int _horaFin = 22;

  final nivelesTecnicos = ["Principiante", "Ocasional", "Intensivo", "Pro"];
  final frecuencias = [1, 2, 4, 8, 12, 24];
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
    _frecuenciaHoras = a.frecuenciaHoras;
    _horaInicio = a.horaInicio;
    _horaFin = a.horaFin;
    _spotsFavoritos = _spotManager.spots
        .where((s) => _spotManager.favoritos.contains(s.id))
        .toList();
  }

  Future<void> _guardar() async {
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
      frecuenciaHoras: _frecuenciaHoras,
      horaInicio: _horaInicio,
      horaFin: _horaFin,
      fechaCreacion: widget.alerta.fechaCreacion,
    );

    final ok = await _alertasService.actualizarAlerta(alertaActualizada);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _snack("Error actualizando alerta");
    }
  }

  Future<void> _borrar() async {
    final ok = await _alertasService.borrarAlerta(widget.alerta.id);
    if (ok) Navigator.pop(context, true);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: EstilosWWW.colorFondoPantalla,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        title: const Text("Editar Alerta"),
        backgroundColor: EstilosWWW.colorFondoPantalla,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _borrar,
            tooltip: "Eliminar alerta",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nombre,
                style: const TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Introduce un nombre"
                    : null,
                onSaved: (v) => _nombre = v?.trim(),
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
                validator: (v) => v == null ? "Selecciona un spot" : null,
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
                validator: (v) => v == null ? "Selecciona disciplina" : null,
                onChanged: (v) => setState(() => _disciplina = v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _nivel,
                decoration: const InputDecoration(labelText: "Nivel técnico"),
                items: nivelesTecnicos
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                validator: (v) => v == null ? "Selecciona un nivel" : null,
                onChanged: (v) => setState(() => _nivel = v),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: EstilosWWW.decoracionSeccion,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: 16,
                          color: EstilosWWW.colorCampana,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Configuración de avisos",
                          style: TextStyle(
                            color: EstilosWWW.colorLetra,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<int>(
                      initialValue: _frecuenciaHoras,
                      decoration: const InputDecoration(
                        labelText: "Frecuencia máxima",
                      ),
                      items: frecuencias
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(
                                h == 1
                                    ? "Cada hora"
                                    : h == 24
                                    ? "1 vez al día"
                                    : "Cada $h horas",
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _frecuenciaHoras = v ?? 4),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _horaInicio,
                            decoration: const InputDecoration(
                              labelText: "Desde",
                            ),
                            items: List.generate(
                              24,
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text(
                                  "${h.toString().padLeft(2, '0')}:00",
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) =>
                                setState(() => _horaInicio = v ?? 7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _horaFin,
                            decoration: const InputDecoration(
                              labelText: "Hasta",
                            ),
                            items: List.generate(
                              24,
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text(
                                  "${h.toString().padLeft(2, '0')}:00",
                                ),
                              ),
                            ).toList(),
                            onChanged: (v) =>
                                setState(() => _horaFin = v ?? 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Alerta activa",
                        style: TextStyle(color: EstilosWWW.colorLetra),
                      ),
                      value: _activa,
                      onChanged: (v) => setState(() => _activa = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _mensaje,
                style: const TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(
                  labelText: "Mensaje personalizado (opcional)",
                ),
                maxLines: 2,
                onSaved: (v) => _mensaje = v?.trim(),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                style: EstilosWWW.botonOscuro,
                onPressed: _guardar,
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
