import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/pages/widget/combo_card.dart';
import 'package:barber_xe/pages/widget/service_card.dart';
import 'package:barber_xe/pages/widget/service_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbería El Estilo'),
        backgroundColor: const Color.fromARGB(255, 10, 10, 10),
        automaticallyImplyLeading: false,
      ),
      body: const _HomeContent(),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  static BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(255, 244, 241, 241),
      selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
      unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today), label: 'Citas'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications), label: 'Notificaciones'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), label: 'Perfil'),
      ],
      onTap: (index) {
        switch (index) {
          case 0: break;
          case 1: break;
          case 2: break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Llamar al método para cargar los servicios y combos
      Provider.of<ServiceController>(context, listen: false).loadServicesAndCombos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceController = Provider.of<ServiceController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(serviceController),
          const SizedBox(height: 20),
          _buildCombosSection(serviceController, context),
          const SizedBox(height: 30),
          _buildServicesSection(serviceController, context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ServiceController serviceController) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar servicios o combos...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onChanged: (value) => serviceController.setSearchQuery(value),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ServiceManagementDialog(),
      ),
    );
  }

  void _showAddComboDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ServiceManagementDialog(
          serviceToEdit: BarberService(
            id: '',
            name: '',
            description: '',
            price: 0,
            duration: 0,
            category: 'Combo',
          ),
        ),
      ),
    );
  }

  Widget _buildCombosSection(ServiceController serviceController, BuildContext context) {
    if (serviceController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Combos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              onPressed: () => _showAddComboDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: serviceController.combos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final combo = serviceController.combos[index];
              return ComboCard(combo: combo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(ServiceController serviceController, BuildContext context) {
    if (serviceController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Servicios Individuales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              onPressed: () => _showAddServiceDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: serviceController.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = serviceController.services[index];
            return ServiceCard(service: service);
          },
        ),
      ],
    );
  }
}
