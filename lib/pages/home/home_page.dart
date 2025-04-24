import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/pages/services/service_combo_page.dart';
import 'package:barber_xe/pages/services/service_page.dart';
import 'package:barber_xe/pages/widget/combo_card.dart';
import 'package:barber_xe/pages/widget/service_card.dart';
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
      context.read<ServiceController>().loadServicesAndCombos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceController = context.watch<ServiceController>();

    return RefreshIndicator(
      onRefresh: () => serviceController.loadServicesAndCombos(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(serviceController),
            const SizedBox(height: 20),
            _buildCombosSection(context),
            const SizedBox(height: 30),
            _buildServicesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ServiceController controller) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
            controller.setSearchQuery('');
          },
        ),
      ),
      onChanged: controller.setSearchQuery,
    );
  }

  Widget _buildCombosSection(BuildContext context) {
    final controller = context.watch<ServiceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Combos',
          onAdd: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServiceComboPage()),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.combos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final combo = controller.combos[index];
              return ComboCard(
                combo: combo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceComboPage(combo: combo),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final controller = context.watch<ServiceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Servicios',
          onAdd: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServicePage()), // Página corregida
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = controller.services[index];
            return ServiceCard(
              service: service,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicePage(service: service), // Envía el servicio a editar
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAdd,
        ),
      ],
    );
  }
}