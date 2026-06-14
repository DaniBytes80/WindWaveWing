import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/alerta.dart';
import 'package:tfg_clima_malaga/services/alertas_service.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/alertas/crear_alerta_page.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/alertas/editar_alerta_page.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class MisAlertasPage extends StatefulWidget {
  const MisAlertasPage({super.key});
  @override
  State<MisAlertasPage> createState() => _MisAlertasPageState();
}

class _MisAlertasPageState extends State<MisAlertasPage> {
  final _service = AlertasService();
  final _spotManager = SpotManager();
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
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        title: const Text("Mis Alertas"),
        backgroundColor: EstilosWWW.colorFondoPantalla,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
          ? Center(
              child: Text(
                "No tienes alertas creadas",
                style: EstilosWWW.textoSecundario,
              ),
            )
          : _buildListaAgrupada(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: EstilosWWW.colorBordeTabla,
        foregroundColor: EstilosWWW.colorLetra,
        onPressed: () =>
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrearAlertaPage()),
            ).then((ok) {
              if (ok == true) _cargarAlertas();
            }),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListaAgrupada() {
    final Map<String, List<Alerta>> agrupadas = {};
    for (final a in _alertas) {
      agrupadas.putIfAbsent(a.spotId, () => []);
      agrupadas[a.spotId]!.add(a);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: agrupadas.entries.map((entry) {
        final spot = _buscarSpot(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                spot?.nombre ?? "Spot desconocido",
                style: EstilosWWW.tituloSeccion,
              ),
            ),
            ...entry.value.map(_buildAlertaCard),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAlertaCard(Alerta a) {
    bool estadoVisual = a.activa;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: EstilosWWW.decoracionCard,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: GestureDetector(
                onTap: () async {
                  final nuevo = !estadoVisual;
                  setLocalState(() => estadoVisual = nuevo);
                  await _service.cambiarEstadoAlerta(a.id, nuevo);
                  _cargarAlertas();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    estadoVisual
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    key: ValueKey(estadoVisual),
                    size: 30,
                    color: estadoVisual
                        ? EstilosWWW.colorCampana
                        : Colors.white30,
                  ),
                ),
              ),
              title: Text(
                a.nombre ?? "Alerta sin nombre",
                style: EstilosWWW.textoNegritaTabla,
              ),
              subtitle: Text(
                "${a.disciplina ?? '-'} · ${a.nivel ?? '-'}",
                style: EstilosWWW.textoSecundario,
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Colors.white54,
                ),
                color: EstilosWWW.colorAzulMedio,
                onSelected: (value) async {
                  if (value == 'editar') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarAlertaPage(alerta: a),
                      ),
                    ).then((ok) {
                      if (ok == true) _cargarAlertas();
                    });
                  }
                  if (value == 'borrar') {
                    await _service.borrarAlerta(a.id);
                    _cargarAlertas();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                        SizedBox(width: 10),
                        Text("Editar"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'borrar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Text("Eliminar"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
