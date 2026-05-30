import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/alerta.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/views/alertas/crear_alerta_page.dart';
import 'package:tfg_clima_malaga/views/alertas/editar_alerta_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class MisAlertasPage extends StatefulWidget {
  const MisAlertasPage({super.key});

  @override
  State<MisAlertasPage> createState() => _MisAlertasPageState();
}

class _MisAlertasPageState extends State<MisAlertasPage> {
  final AlertasService _service = AlertasService();
  final SpotManager _spotManager = SpotManager();

  List<Alerta> _alertas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    final userId = _service.supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _cargando = false);
      return;
    }

    final lista = await _service.obtenerAlertasUsuario(userId);

    setState(() {
      _alertas = lista;
      _cargando = false;
    });
  }

  Future<void> _borrarAlerta(String id) async {
    final ok = await _service.borrarAlerta(id);
    if (ok) {
      _cargarAlertas();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error borrando alerta")));
    }
  }

  Spot? _buscarSpot(String id) {
    try {
      return _spotManager.spots.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Alertas")),

      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
          ? const Center(
              child: Text(
                "No tienes alertas creadas",
                style: TextStyle(fontSize: 18),
              ),
            )
          : _buildListaAgrupada(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearAlertaPage()),
          ).then((creada) {
            if (creada == true) {
              _cargarAlertas();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListaAgrupada() {
    final Map<String, List<Alerta>> agrupadas = {};

    for (final alerta in _alertas) {
      agrupadas.putIfAbsent(alerta.spotId, () => []);
      agrupadas[alerta.spotId]!.add(alerta);
    }

    return ListView(
      children: agrupadas.entries.map((entry) {
        final spotId = entry.key;
        final alertasSpot = entry.value;

        final spot = _buscarSpot(spotId);
        final nombreSpot = spot?.nombre ?? "Spot desconocido";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                nombreSpot,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ...alertasSpot.map((a) => _buildAlertaCard(a)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAlertaCard(Alerta a) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ), // 👈 reduce altura
        visualDensity: const VisualDensity(
          vertical: -3,
        ), // 👈 compacta el ListTile

        leading: Icon(
          Icons.notifications_active,
          size: 32, // 👈 antes 40, reduce altura total
          color: a.activa
              ? EstilosWWW.colorLetraMenuMapa
              : EstilosWWW.colorError,
        ),

        title: Text(
          a.nombre ?? "Alerta sin nombre",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),

        subtitle: Text(
          "Disciplina: ${a.disciplina ?? '-'}",
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // 👇 MUY IMPORTANTE: elimina la altura extra
        isThreeLine: false,
        minVerticalPadding: 0,

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: a.activa,
              onChanged: (v) async {
                await _service.cambiarEstadoAlerta(a.id, v);
                _cargarAlertas();
              },
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap, // 👈 más pequeño
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) async {
                if (value == 'editar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarAlertaPage(alerta: a),
                    ),
                  ).then((actualizado) {
                    if (actualizado == true) _cargarAlertas();
                  });
                }

                if (value == 'borrar') {
                  _borrarAlerta(a.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Editar"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'borrar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Eliminar"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
