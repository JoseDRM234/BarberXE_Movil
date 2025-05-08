import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/pages/services/service_combo_page.dart';
import 'package:barber_xe/pages/services/service_page.dart';
import 'package:barber_xe/pages/widget/home_helpers.dart';
import 'package:barber_xe/pages/widget/selectable_item_card.dart';
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
      onTap: (index) async{
        await Future.delayed(Duration.zero); // Permitir que el frame actual se complete
        switch (index) {
          case 0: break;
          case 1: 
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/appointments');
            });
          case 2: break;
          case 3:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/profile');
            });
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
      final controller = context.read<ServiceController>();
      controller.loadServicesAndCombos();
      context.read<ProfileController>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<ProfileController>().isAdmin;
    final serviceController = context.watch<ServiceController>();

    return RefreshIndicator(
      onRefresh: () => serviceController.loadServicesAndCombos(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(serviceController),
            const SizedBox(height: 20),
            _buildCombosSection(context, isAdmin),
            const SizedBox(height: 30),
            _buildServicesSection(context, isAdmin),
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

  Widget _buildCombosSection(BuildContext context, bool isAdmin) {
    final controller = context.watch<ServiceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Combos',
          onAdd: isAdmin ? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServiceComboPage()),
          ) : null,
          isAdmin: isAdmin,
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
              return SelectableItemCard(
                isCombo: true,
                title: combo.name,
                price: combo.totalPrice,
                duration: combo.totalDuration,
                imageUrl: combo.imageUrl,
                description: combo.description,
                isSelected: false,
                onTap: () => _showComboDetails(context, combo),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showComboDetails(BuildContext context, ServiceCombo combo) async {
  final theme = Theme.of(context);
  final serviceController = context.read<ServiceController>();
  
  // Obtener los servicios completos a partir de los IDs
  final services = await serviceController.getServicesByIds(combo.serviceIds);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Handle para arrastrar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            combo.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    // Imagen del combo
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: combo.imageUrl != null
                          ? Image.network(
                              combo.imageUrl!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => HomeHelpers.buildPlaceholderImage(),
                            )
                          : HomeHelpers.buildPlaceholderImage(),
                    ),
                    
                    // Precio y descuento
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '\$${combo.totalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (combo.discount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '-\$${combo.discount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${(combo.totalPrice - combo.discount).toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Duración
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: theme.hintColor),
                        const SizedBox(width: 8),
                        Text(
                          '${combo.totalDuration ~/ 60}h ${combo.totalDuration % 60}min',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    
                    // Descripción
                    if (combo.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        combo.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    
                    // Servicios incluidos
                    const SizedBox(height: 24),
                    Text(
                      'Servicios incluidos (${services.length}):',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Lista de servicios
                    ...services.map((service) => HomeHelpers.buildServiceItem(service, theme)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildServicesSection(BuildContext context, bool isAdmin) {
    final controller = context.watch<ServiceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Servicios',
          onAdd: isAdmin ? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServicePage()),
          ) : null,
          isAdmin: isAdmin, // Pasar el estado de admin
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
              onEdit: isAdmin ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServicePage(service: service),
                ),
              ) : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onAdd, required bool isAdmin}) {
    final isAdmin = Provider.of<ProfileController>(context, listen: false).isAdmin;
    
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
        if (isAdmin) // Solo muestra el botón si el usuario es admin
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAdd,
          ),
      ],
    );
  }
}