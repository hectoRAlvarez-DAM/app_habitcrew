import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String nombre;
  final String emoji;
  final String descripcion;
  final String frecuencia;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoCompletado;
  final int rachaActual;
  final int recordRacha;
  final int totalCompletados;
  final bool esDefecto;

  // Campos para hábitos grupales
  final bool esGrupal;
  final String? grupoId;

  Habit({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.descripcion,
    required this.frecuencia,
    required this.fechaCreacion,
    this.fechaUltimoCompletado,
    required this.rachaActual,
    required this.recordRacha,
    required this.totalCompletados,
    required this.esDefecto,
    this.esGrupal = false,
    this.grupoId,
  });

  /// true si el hábito ya fue completado en el período actual
  /// según su frecuencia (diario, semanal, mensual)
  bool get completadoHoy {
    if (fechaUltimoCompletado == null) return false;
    final now = DateTime.now();
    final ultimo = fechaUltimoCompletado!;

    switch (frecuencia.toLowerCase()) {
      case 'diario':
        return ultimo.year == now.year &&
            ultimo.month == now.month &&
            ultimo.day == now.day;

      case 'semanal':
        // Misma semana ISO (lunes a domingo)
        final inicioSemanaActual = now.subtract(Duration(days: now.weekday - 1));
        final inicioSemana = DateTime(
            inicioSemanaActual.year, inicioSemanaActual.month, inicioSemanaActual.day);
        final finSemana = inicioSemana.add(const Duration(days: 7));
        return ultimo.isAfter(inicioSemana.subtract(const Duration(seconds: 1))) &&
            ultimo.isBefore(finSemana);

      case 'mensual':
        return ultimo.year == now.year && ultimo.month == now.month;

      default:
        return ultimo.year == now.year &&
            ultimo.month == now.month &&
            ultimo.day == now.day;
    }
  }

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      emoji: data['emoji'] ?? '✅',
      descripcion: data['descripcion'] ?? '',
      frecuencia: data['frecuencia'] ?? 'Diario',
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaUltimoCompletado:
          (data['fechaUltimoCompletado'] as Timestamp?)?.toDate(),
      rachaActual: (data['rachaActual'] as num?)?.toInt() ?? 0,
      recordRacha: (data['recordRacha'] as num?)?.toInt() ?? 0,
      totalCompletados: (data['totalCompletados'] as num?)?.toInt() ?? 0,
      esDefecto: data['esDefecto'] ?? false,
      esGrupal: data['esGrupal'] ?? false,
      grupoId: data['grupoId'] as String?,
    );
  }
}