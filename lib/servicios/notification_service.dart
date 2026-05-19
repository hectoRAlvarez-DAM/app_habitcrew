import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int defaultHour = 9;
  static const int defaultMinute = 0;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> programarNotificacionHabito({
    required int id,
    required String nombreHabito,
    required String emoji,
    required int hora,
    required int minuto,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancel(id);

    final ahora = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora,
      minuto,
    );

    if (scheduledDate.isBefore(ahora)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habitos_channel',
      'Recordatorios de hábitos',
      channelDescription: 'Notificaciones diarias para tus hábitos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      '$emoji $nombreHabito',
      '¡No olvides completar tu hábito de hoy!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarNotificacion(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelarTodas() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  Future<void> guardarConfigNotificacion({
    required String habitId,
    required bool activa,
    required int hora,
    required int minuto,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('usuaris')
        .doc(uid)
        .collection('habitos')
        .doc(habitId)
        .update({
      'notificacion': {
        'activa': activa,
        'hora': hora,
        'minuto': minuto,
      },
    });
  }

  Future<void> reprogramarTodasLasNotificaciones() async {
    if (kIsWeb || !_initialized) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final habitosSnap = await FirebaseFirestore.instance
        .collection('usuaris')
        .doc(uid)
        .collection('habitos')
        .get();

    for (final doc in habitosSnap.docs) {
      final data = doc.data();
      final notif = data['notificacion'] as Map<String, dynamic>?;
      if (notif == null) continue;

      final activa = notif['activa'] as bool? ?? false;
      if (!activa) continue;

      final hora = notif['hora'] as int? ?? defaultHour;
      final minuto = notif['minuto'] as int? ?? defaultMinute;
      final notifId = doc.id.hashCode.abs() % 100000;

      await programarNotificacionHabito(
        id: notifId,
        nombreHabito: data['nombre'] ?? 'Hábito',
        emoji: data['emoji'] ?? '⭐',
        hora: hora,
        minuto: minuto,
      );
    }
  }
}
