import 'package:barber_xe/controllers/home_controller.dart';
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
        backgroundColor: const Color(0xFF757575),
        automaticallyImplyLeading: false,
      ),
      body: const _HomeContent(),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.brown[800],
      unselectedItemColor: Colors.grey,
      currentIndex: 0, // Home está seleccionado
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
        // Navegación entre páginas
        switch (index) {
          case 0:
            // Ya estamos en home
            break;
          case 1:
            // Navigator.pushNamed(context, '/appointments');
            break;
          case 2:
            // Navigator.pushNamed(context, '/notifications');
            break;
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
      Provider.of<HomeController>(context, listen: false).loadServices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Provider.of<HomeController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          _buildSearchBar(homeController),
          const SizedBox(height: 20),
          
          // Sección de Combos
          _buildCombosSection(homeController),
          const SizedBox(height: 30),
          
          // Sección de Servicios Individuales
          _buildServicesSection(homeController),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeController homeController) {
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
      onChanged: (value) => homeController.setSearchQuery(value),
    );
  }

  Widget _buildCombosSection(HomeController homeController) {
    if (homeController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Combos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: homeController.combos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final combo = homeController.combos[index];
              return ComboCard(service: combo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(HomeController homeController) {
    if (homeController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios Individuales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: homeController.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = homeController.services[index];
            return ServiceCard(service: service);
          },
        ),
      ],
    );
  }
}