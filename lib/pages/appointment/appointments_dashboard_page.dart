import 'package:barber_xe/pages/appointment/appointment_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          title: Text(
            'Citas',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          foregroundColor: Colors.white,
          bottom: TabBar(
            unselectedLabelColor: const Color.fromARGB(255, 200, 200, 200),
            labelColor: Colors.white,
            indicatorColor: const Color.fromARGB(255, 255, 255, 255), // Color dorado para el indicador
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.history), text: 'Historial'), 
              Tab(icon: Icon(Icons.add_box),text: 'Reservar' ), 
              Tab(icon: Icon(Icons.edit_calendar),  text: 'Modificar'),
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