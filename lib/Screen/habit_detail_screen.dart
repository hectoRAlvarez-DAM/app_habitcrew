import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:app_habitcrew/Screen/models/habit.dart';
import 'package:app_habitcrew/servicios/habit_service.dart';
import 'package:app_habitcrew/servicios/group_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {

  AppTheme get _t => AppTheme.fromContrast(ContrastMode.of(context));


  final HabitService _habitService = HabitService();
  final GroupService _groupService = GroupService();

  List<bool> _historialPersonal = List.filled(7, false);
  Map<String, dynamic> _estadisticasGrupo = {};
  bool _loadingPersonal = true;
  bool _loadingGrupo = true;

  // Código del grupo
  String? _codigoGrupo;

  // Controladores de edición
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late String _frecuenciaSeleccionada;
  late String _emojiSeleccionado;
  bool _guardando = false;

  final List<String> _frecuencias = ['Diario', 'Semanal', 'Mensual'];
  final List<String> _emojis = [
    '⭐', '🌅', '💧', '📚', '🏃', '🧘', '💪', '🎯',
    '🥗', '😴', '✍️', '🎵', '🧹', '💻', '📝', '🌿',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.habit.nombre);
    _descripcionController =
        TextEditingController(text: widget.habit.descripcion);
    _frecuenciaSeleccionada = widget.habit.frecuencia;
    _emojiSeleccionado = widget.habit.emoji;
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Cargar historial personal y código de grupo en paralelo
    final futures = <Future>[
      _habitService.obtenerHistorial7Dias(widget.habit.id),
    ];

    if (widget.habit.esGrupal && widget.habit.grupoId != null) {
      futures.add(
          _groupService.obtenerCodigoGrupo(widget.habit.grupoId!));
      futures.add(
          _groupService.obtenerEstadisticasGrupo(widget.habit.grupoId!));
    }

    final resultados = await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      _historialPersonal = resultados[0] as List<bool>;
      _loadingPersonal = false;

      if (widget.habit.esGrupal && widget.habit.grupoId != null) {
        _codigoGrupo = resultados[1] as String?;
        _estadisticasGrupo = resultados[2] as Map<String, dynamic>;
        _loadingGrupo = false;
      } else {
        _loadingGrupo = false;
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.trim().isEmpty) return;
    setState(() => _guardando = true);

    await _habitService.editarHabito(
      habitId: widget.habit.id,
      nombre: _nombreController.text.trim(),
      emoji: _emojiSeleccionado,
      descripcion: _descripcionController.text.trim(),
      frecuencia: _frecuenciaSeleccionada,
    );

    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Hábito actualizado'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.isContrast ? Colors.white : const Color(0xFF1E1E2E),
        title: Text('Eliminar hábito',
            style: TextStyle(color: _t.isContrast ? const Color(0xFF111111) : Colors.white)),
        content: Text(
          '¿Eliminar "${widget.habit.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: _t.isContrast ? const Color(0xFF555555) : Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _habitService.eliminarHabito(widget.habit.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: t.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: t.cardBg),
                        ),
                        child: Icon(Icons.arrow_back,
                            color: t.iconPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(widget.habit.emoji,
                        style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.habit.nombre,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: t.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.habit.esGrupal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people,
                                color: Color(0xFF3B82F6), size: 14),
                            SizedBox(width: 4),
                            Text('Grupal',
                                style: TextStyle(
                                    color: Color(0xFF3B82F6), fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Stats rápidas ─────────────────────────────────
                GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Racha', '${widget.habit.rachaActual}🔥'),
                        _buildStat(
                            'Récord', '${widget.habit.recordRacha} días'),
                        _buildStat(
                            'Total', '${widget.habit.totalCompletados}✅'),
                        _buildStat('Freq.', widget.habit.frecuencia),
                      ],
                    ),
                  ),
                ),

                // ── Código del grupo ──────────────────────────────
                if (widget.habit.esGrupal) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('🔑 Código del grupo'),
                  const SizedBox(height: 12),
                  GlassmorphismCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _codigoGrupo == null
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF22C55E), strokeWidth: 2),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Comparte este código con tus compañeros',
                                      style: TextStyle(
                                          color: t.textMuted, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _codigoGrupo!,
                                      style: TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 6,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _codigoGrupo!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('📋 Código copiado'),
                                        backgroundColor: Color(0xFF22C55E),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF22C55E)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(Icons.copy,
                                        color: Color(0xFF22C55E), size: 20),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Gráfica personal últimos 7 días ───────────────
                _buildSectionTitle('📊 Mis últimos 7 días'),
                const SizedBox(height: 12),
                GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _loadingPersonal
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF22C55E)))
                        : _buildBarChart(
                            data: [_historialPersonal],
                            labels: _ultimos7DiasLabels(),
                            nombres: ['Tú'],
                            colores: [const Color(0xFF22C55E)],
                          ),
                  ),
                ),

                // ── Gráfica grupal ────────────────────────────────
                if (widget.habit.esGrupal) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('👥 Progreso del grupo'),
                  const SizedBox(height: 12),
                  GlassmorphismCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _loadingGrupo
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF3B82F6)))
                          : _estadisticasGrupo.isEmpty
                              ? Text(
                                  'No hay datos del grupo todavía',
                                  style: TextStyle(
                                      color: t.textMuted, fontSize: 13),
                                )
                              : _buildGrupalChart(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Editar hábito ─────────────────────────────────
                _buildSectionTitle('✏️ Editar hábito'),
                const SizedBox(height: 12),

                GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji picker
                        Text('Emoji',
                            style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _emojis.map((e) {
                            final sel = e == _emojiSeleccionado;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _emojiSeleccionado = e),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF22C55E)
                                          .withValues(alpha: 0.2)
                                      : t.cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF22C55E)
                                        : t.cardBorder,
                                  ),
                                ),
                                child: Center(
                                    child: Text(e,
                                        style:
                                            TextStyle(fontSize: 18))),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Nombre
                        Text('Nombre',
                            style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _buildTextField(
                            _nombreController, 'Nombre del hábito'),

                        const SizedBox(height: 16),

                        // Descripción
                        Text('Descripción',
                            style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _buildTextField(_descripcionController, 'Descripción',
                            maxLines: 2),

                        const SizedBox(height: 16),

                        // Frecuencia
                        Text('Frecuencia',
                            style: TextStyle(
                                color: t.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: _frecuencias.map((f) {
                            final sel = f == _frecuenciaSeleccionada;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _frecuenciaSeleccionada = f),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFF22C55E)
                                        : t.chipBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: sel
                                          ? const Color(0xFF22C55E)
                                          : t.chipBorder,
                                    ),
                                  ),
                                  child: Text(f,
                                      style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : t.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 12),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: t.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Guardar cambios',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón eliminar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _confirmarEliminar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Eliminar hábito',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
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

  // ─── Helpers ────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    final t = _t;
    return Text(
      title,
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: t.textPrimary),
    );
  }

  Widget _buildStat(String label, String value) {
    final t = _t;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    final t = _t;
    return Container(
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.cardBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: t.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  List<String> _ultimos7DiasLabels() {
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final ahora = DateTime.now();
    return List.generate(7, (i) {
      final dia = ahora.subtract(Duration(days: 6 - i));
      return dias[dia.weekday - 1];
    });
  }

  Widget _buildBarChart({
    required List<List<bool>> data,
    required List<String> labels,
    required List<String> nombres,
    required List<Color> colores,
  }) {
    final t = _t;
    const barMaxHeight = 80.0;
    const barWidth = 28.0;
    final groupCount = labels.length;
    final memberCount = data.length;

    return Column(
      children: [
        SizedBox(
          height: barMaxHeight + 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(groupCount, (dayIndex) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(memberCount, (memberIndex) {
                      final completado = data[memberIndex][dayIndex];
                      return Padding(
                        padding: EdgeInsets.only(
                            right: memberIndex < memberCount - 1 ? 2 : 0),
                        child: AnimatedContainer(
                          duration:
                              Duration(milliseconds: 300 + dayIndex * 50),
                          curve: Curves.easeOut,
                          width: memberCount == 1
                              ? barWidth
                              : barWidth / memberCount + 2,
                          height: completado ? barMaxHeight : 8,
                          decoration: BoxDecoration(
                            color: completado
                                ? colores[memberIndex]
                                : t.cardBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[dayIndex],
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              );
            }),
          ),
        ),
        if (memberCount > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(memberCount, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colores[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(nombres[i],
                      style: TextStyle(
                          color: t.textSecondary, fontSize: 12)),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildGrupalChart() {
    if (_estadisticasGrupo.isEmpty) {
      return const Text('No hay datos del grupo',
          style: TextStyle(color: Colors.white54));
    }

    final miembros = _estadisticasGrupo.entries.toList();
    final coloresMiembros = [
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFFF97316),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899),
      const Color(0xFFEAB308),
    ];

    final data = miembros
        .map((e) =>
            List<bool>.from(e.value['dias'] ?? List.filled(7, false)))
        .toList();
    final nombres = miembros
        .map((e) => e.value['nombre'] as String? ?? 'Usuario')
        .toList();
    final colores = List.generate(miembros.length,
        (i) => coloresMiembros[i % coloresMiembros.length]);

    return _buildBarChart(
      data: data,
      labels: _ultimos7DiasLabels(),
      nombres: nombres,
      colores: colores,
    );
  }
}