import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DateTimePicker {
  static Future<DateTime?> selectDate(BuildContext context, {DateTime? initialDate}) async {
    // Inicializar localización si no está inicializada
    try {
      await initializeDateFormatting('es_ES', null);
    } catch (e) {
      debugPrint('Error initializing date formatting: $e');
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        return date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      },
      locale: const Locale('es', 'ES'),
    );
    return picked;
  }

  static Future<TimeOfDay?> selectTime(
      BuildContext context, {
      TimeOfDay? initialTime,
      required DateTime selectedDate}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Localizations.override(
            context: context,
            locale: const Locale('es', 'ES'),
            child: child!,
          ),
        );
      },
    );
    return picked;
  }

  static String formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM, y', 'es_ES').format(date);
    } catch (e) {
      return DateFormat('EEEE, d MMMM, y').format(date);
    }
  }

  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    try {
      return DateFormat('h:mm a', 'es_ES').format(dt);
    } catch (e) {
      return DateFormat('h:mm a').format(dt);
    }
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}