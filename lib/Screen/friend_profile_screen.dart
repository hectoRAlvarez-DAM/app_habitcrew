import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:app_habitcrew/servicios/friend_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const FriendProfileScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final FriendService _friendService = FriendService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _habitos = [];
  List<bool> _historialGlobal = List.filled(7, false);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final results = await Future.wait([
      _friendService.obtenerDatosUsuario(widget.friendUid),
      _obtenerHabitos(),
    ]);

    final userData = results[0] as Map<String, dynamic>?;
    final habitos = results[1] as List<Map<String, dynamic>>;

    // Calcular historial global de los últimos 7 días
    final historial = await _calcularHistorialGlobal(habitos);

    if (mounted) {
      setState(() {
        _userData = userData;
        _habitos = habitos;
        _historialGlobal = historial;
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerHabitos() async {
    try {
      final snap = await _firestore
          .collection('usuaris')
          .doc(widget.friendUid)
          .collection('habitos')
          .orderBy('fechaCreacion')
          .get();
      return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<bool>> _calcularHistorialGlobal(
      List<Map<String, dynamic>> habitos) async {
    final ahora = DateTime.now();
    final resultado = List<bool>.filled(7, false);

    for (int i = 0; i < 7; i++) {
      final dia =
          DateTime(ahora.year, ahora.month, ahora.day).subtract(Duration(days: 6 - i));

      for (final habito in habitos) {
        final historial =
            List<Map<String, dynamic>>.from(habito['historial'] ?? []);
        final completado = historial.any((e) {
          final f = (e['fecha'] as Timestamp?)?.toDate();
          if (f == null) return false;
          return f.year == dia.year &&
              f.month == dia.month &&
              f.day == dia.day;
        });
        if (completado) {
          resultado[i] = true;
          break;
        }
      }
    }

    return resultado;
  }

  String _formatearFecha(dynamic timestamp) {
    if (timestamp == null) return '—';
    final fecha = (timestamp as Timestamp).toDate();
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF22C55E)))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Banner ──────────────────────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF1D4ED8),
                                  Color(0xFF1E1B4B),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          // Botón volver
                          Positioned(
                            top: 12,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          // Avatar
                          Positioned(
                            bottom: -45,
                            left: 20,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFF3B82F6),
                                  child: Center(
                                    child: Text(
                                      widget.friendName.isNotEmpty
                                          ? widget.friendName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 56),

                      // ── Info usuario ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.friendName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Miembro desde ${_formatearFecha(_userData?['data_registre'])}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Stats ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassmorphismCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat('Hábitos',
                                    '${_habitos.length}', '📋'),
                                _buildStat(
                                  'Completados',
                                  '${_userData?['totalHabitosCompletados'] ?? 0}',
                                  '✅',
                                ),
                                _buildStat(
                                  'Mejor racha',
                                  _habitos.isEmpty
                                      ? '0'
                                      : '${_habitos.map((h) => (h['recordRacha'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b)}',
                                  '🔥',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Gráfica últimos 7 días ───────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Actividad últimos 7 días',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            GlassmorphismCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _buildBarChart(_historialGlobal),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Hábitos individuales ─────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Hábitos',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            _habitos.isEmpty
                                ? GlassmorphismCard(
                                    child: const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Sin hábitos todavía',
                                          style: TextStyle(
                                              color: Colors.white54)),
                                    ),
                                  )
                                : Column(
                                    children: _habitos.map((h) {
                                      final completado = _estaCompletadoHoy(h);
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: GlassmorphismCard(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Text(h['emoji'] ?? '✅',
                                                  style: const TextStyle(
                                                      fontSize: 20)),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      h['nombre'] ?? '',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    Text(
                                                      h['frecuencia'] ??
                                                          'Diario',
                                                      style: const TextStyle(
                                                          color: Colors.white38,
                                                          fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if ((h['rachaActual'] as num? ??
                                                      0) >
                                                  0)
                                                Text(
                                                  '🔥 ${h['rachaActual']}',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.orange[300],
                                                      fontSize: 12),
                                                ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                completado
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                color: completado
                                                    ? const Color(0xFF22C55E)
                                                    : Colors.white24,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  bool _estaCompletadoHoy(Map<String, dynamic> habito) {
    final timestamp = habito['fechaUltimoCompletado'] as Timestamp?;
    if (timestamp == null) return false;
    final fecha = timestamp.toDate();
    final ahora = DateTime.now();
    return fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;
  }

  Widget _buildStat(String label, String value, String emoji) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _buildBarChart(List<bool> historial) {
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final ahora = DateTime.now();
    final labels = List.generate(7, (i) {
      final dia = ahora.subtract(Duration(days: 6 - i));
      return dias[dia.weekday - 1];
    });

    return SizedBox(
      height: 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final completado = historial[i];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300 + i * 50),
                curve: Curves.easeOut,
                width: 28,
                height: completado ? 80 : 8,
                decoration: BoxDecoration(
                  color: completado
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[i],
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          );
        }),
      ),
    );
  }
}