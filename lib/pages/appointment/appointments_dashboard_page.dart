import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/pages/appointment/AdminAppointmentsPage.dart';
import 'package:barber_xe/pages/appointment/appointment_page.dart';
import 'package:barber_xe/pages/widget/appointment_filters.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'appointment_history_tab.dart';
import 'appointment_manage_tab.dart';

class AppointmentsDashboardPage extends StatelessWidget {
  const AppointmentsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<ProfileController>().isAdmin;
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
          actions: [
            Consumer<ProfileController>(
              builder: (context, profileController, _) {
                final tabController = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: tabController!,
                  builder: (context, _) {
                    return Visibility(
                      visible: tabController.index == 0,
                      child: const AppointmentFilters(),
                    );
                  },
                );
              },
            ),
          ],
          bottom: TabBar(
            unselectedLabelColor: const Color.fromARGB(255, 200, 200, 200),
            labelColor: Colors.white,
            indicatorColor: const Color.fromARGB(255, 255, 255, 255),
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
              Tab(icon: Icon(Icons.add_box), text: 'Reservar'), 
              Tab(icon: Icon(Icons.edit_calendar), text: 'Modificar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isAdmin 
                ? const AdminAppointmentsPage()
                : const AppointmentHistoryTab(),
            const AppointmentPage(),
            const AppointmentManageTab(),
          ],
        ),
      ),
    );
  }
}