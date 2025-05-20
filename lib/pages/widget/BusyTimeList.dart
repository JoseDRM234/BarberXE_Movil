import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BusyTimeList extends StatelessWidget {
  final List<Map<String, DateTime>> busyPeriods;

  const BusyTimeList({super.key, required this.busyPeriods});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: busyPeriods.map((period) => _TimeSlotItem(
          start: period['start']!,
          end: period['end']!,
        )).toList(),
      ),
    );
  }
}

class _TimeSlotItem extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const _TimeSlotItem({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}