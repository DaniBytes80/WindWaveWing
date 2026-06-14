import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tfg_clima_malaga/models/alerta.dart';
import 'package:tfg_clima_malaga/models/alerta_generada.dart';
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
  List<AlertaGenerada> _generadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    final userId = _service.supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _cargando = false);
      return;
    }

    final futures = await Future.wait([
      _service.obtenerAlertasUsuario(userId),
      _service.obtenerAlertasGeneradas(userId),
    ]);

    setState(() {
      _alertas = futures[0] as List<Alerta>;
      _generadas = futures[1] as List<AlertaGenerada>;
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

  // Alertas generadas de un spot concreto, ordenadas por fecha desc
  List<AlertaGenerada> _generadasDeSpot(String spotId) =>
      _generadas.where((g) => g.spotId == spotId).toList();

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
              if (ok == true) _cargarTodo();
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
      padding: const EdgeInsets.only(bottom: 80),
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
    final generadasSpot = _generadasDeSpot(a.spotId);

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: EstilosWWW.decoracionCard,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: GestureDetector(
                    onTap: () async {
                      final nuevo = !estadoVisual;
                      setLocalState(() => estadoVisual = nuevo);
                      await _service.cambiarEstadoAlerta(a.id, nuevo);
                      _cargarTodo();
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
                          if (ok == true) _cargarTodo();
                        });
                      }
                      if (value == 'borrar') {
                        await _service.borrarAlerta(a.id);
                        _cargarTodo();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Editar"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'borrar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Eliminar"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Historial de notificaciones recibidas ─
                if (generadasSpot.isNotEmpty) ...[
                  Divider(
                    height: 1,
                    color: EstilosWWW.colorAzulBorde.withValues(alpha: 0.4),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 14,
                              color: EstilosWWW.colorCampana.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Notificaciones recibidas",
                              style: EstilosWWW.textoSecundario.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        // Borrar todas las de este spot
                        GestureDetector(
                          onTap: () async {
                            final userId =
                                _service.supabase.auth.currentUser?.id;
                            if (userId == null) return;
                            await _service.borrarAlertasGeneradasDeSpot(
                              userId,
                              a.spotId,
                            );
                            _cargarTodo();
                          },
                          child: Text(
                            "Borrar todas",
                            style: EstilosWWW.textoSecundario.copyWith(
                              fontSize: 11,
                              color: Colors.redAccent.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...generadasSpot.map((g) => _buildGeneradaRow(g)),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneradaRow(AlertaGenerada g) {
    final fecha = DateFormat('dd/MM HH:mm').format(g.fecha.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: [
          // Icono material
          Icon(
            _iconoMaterial(g.materialTipo),
            size: 16,
            color: EstilosWWW.colorAccent,
          ),
          const SizedBox(width: 8),

          // Material + fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.materialResumen,
                  style: const TextStyle(
                    color: EstilosWWW.colorLetra,
                    fontSize: 12,
                  ),
                ),
                Text(
                  fecha,
                  style: EstilosWWW.textoSecundario.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),

          // Botón eliminar esta notificación
          GestureDetector(
            onTap: () async {
              await _service.borrarAlertaGenerada(g.id);
              _cargarTodo();
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: Colors.white30),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoMaterial(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'tabla':
        return Icons.surfing;
      case 'foil':
        return Icons.navigation;
      case 'ala':
        return Icons.paragliding;
      case 'cometa':
        return Icons.air;
      case 'vela':
        return Icons.sailing;
      case 'botavara':
        return Icons.horizontal_rule;
      case 'mástil':
        return Icons.vertical_align_top;
      case 'tipo de barco':
        return Icons.directions_boat;
      default:
        return Icons.inventory_2;
    }
  }
}
