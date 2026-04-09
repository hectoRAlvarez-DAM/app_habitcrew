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
  });

  /// true si el hábito ya fue completado hoy
  bool get completadoHoy {
    if (fechaUltimoCompletado == null) return false;
    final now = DateTime.now();
    final ultimo = fechaUltimoCompletado!;
    return ultimo.year == now.year &&
        ultimo.month == now.month &&
        ultimo.day == now.day;
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
    );
  }
}
