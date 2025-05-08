import 'package:barber_xe/pages/appointment/appointment_page.dart';
import 'package:flutter/material.dart';
import 'appointment_history_tab.dart';
import 'appointment_manage_tab.dart';

class AppointmentsDashboardPage extends StatelessWidget {
  const AppointmentsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Citas'),
          backgroundColor: Colors.black,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Historial'),
              Tab(icon: Icon(Icons.add_box), text: 'Reservar'),
              Tab(icon: Icon(Icons.edit_calendar), text: 'Modificar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AppointmentHistoryTab(),
            AppointmentPage(),
            AppointmentManageTab(),
          ],
        ),
      ),
    );
  }
}
