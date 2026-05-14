import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:app_habitcrew/Screen/models/habit.dart';
import 'package:app_habitcrew/servicios/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final Habit habit;

  const NotificationSettingsScreen({super.key, required this.habit});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {

  final NotificationService _notifService = NotificationService();

  bool _activa = false;
  int _hora = NotificationService.defaultHour;
  int _minuto = NotificationService.defaultMinute;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Cargar configuración existente si la hay
    final notif = widget.habit.notificacion;
    if (notif != null) {
      _activa = notif['activa'] as bool? ?? false;
      _hora = notif['hora'] as int? ?? NotificationService.defaultHour;
      _minuto = notif['minuto'] as int? ?? NotificationService.defaultMinute;
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hora, minute: _minuto),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _hora = picked.hour;
        _minuto = picked.minute;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    await _notifService.guardarConfigNotificacion(
      habitId: widget.habit.id,
      activa: _activa,
      hora: _hora,
      minuto: _minuto,
    );

    final notifId = widget.habit.id.hashCode.abs() % 100000;

    if (_activa) {
      await _notifService.programarNotificacionHabito(
        id: notifId,
        nombreHabito: widget.habit.nombre,
        emoji: widget.habit.emoji,
        hora: _hora,
        minuto: _minuto,
      );
    } else {
      await _notifService.cancelarNotificacion(notifId);
    }

    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatHora() {
    final h = _hora.toString().padLeft(2, '0');
    final m = _minuto.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔔 Notificaciones',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.habit.emoji} ${widget.habit.nombre}',
                            style: TextStyle(
                                color: t.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Toggle activar/desactivar
                GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recordatorio diario',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Recibe un aviso cada día',
                              style: TextStyle(
                                  color: t.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        Switch(
                          value: _activa,
                          onChanged: (v) => setState(() => _activa = v),
                          activeThumbColor: const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selector de hora
                AnimatedOpacity(
                  opacity: _activa ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: GlassmorphismCard(
                    onTap: _activa ? _seleccionarHora : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hora del recordatorio',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toca para cambiar la hora',
                                style: TextStyle(
                                    color: t.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _formatHora(),
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_activa) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Recibirás un recordatorio cada día a las ${_formatHora()} para completar "${widget.habit.nombre}".',
                      style: TextStyle(
                          color: t.textMuted, fontSize: 12),
                    ),
                  ),
                ],

                const Spacer(),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
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
                        : Text('Guardar configuración',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}