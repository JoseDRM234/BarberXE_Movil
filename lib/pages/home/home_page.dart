import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/pages/appointment/appointments_dashboard_page.dart';
import 'package:barber_xe/pages/services/service_combo_page.dart';
import 'package:barber_xe/pages/services/service_page.dart';
import 'package:barber_xe/pages/widget/home_helpers.dart';
import 'package:barber_xe/pages/widget/selectable_item_card.dart';
import 'package:barber_xe/pages/widget/service_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Barbería El Estilo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 25,
          ),
        ),
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
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined), label: 'Citas'),
          BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined), label: 'Barberos'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined), label: 'Notificaciones'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), label: 'Perfil'),
      ],
      onTap: (index) async {
        await Future.delayed(Duration.zero);
        switch (index) {
          case 0:
            break;
          case 1:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsDashboardPage(),
                ),
              );
            });
            break;
          case 2:
            WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamed(context, '/barbers');
              });
            break;
          case 3:
            break;
          case 4:
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
  return Container(
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 255, 255, 255),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 24,
          ),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                padding: const EdgeInsets.only(right: 12),
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  controller.setSearchQuery('');
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black87,
      ),
      onChanged: (value) {
        controller.setSearchQuery(value);
        setState(() {}); // Para actualizar el icono de limpiar
      },
    ),
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
      decoration: const BoxDecoration(
        color: Colors.white, // Fondo blanco
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          style: GoogleFonts.poppins( // Fuente Poppins
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
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
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (combo.discount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '-\$${combo.discount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${(combo.totalPrice - combo.discount).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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
                      Icon(
                        Icons.access_time, 
                        size: 18, 
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${combo.totalDuration ~/ 60}h ${combo.totalDuration % 60}min',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Descripción
                  if (combo.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      combo.description,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                  
                  // Servicios incluidos
                  const SizedBox(height: 24),
                  Text(
                    'SERVICIOS INCLUIDOS (${services.length}):',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista de servicios
                  ...services.map((service) => HomeHelpers.buildServiceItem(
                    service, 
                    theme.copyWith(
                      textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme),
                      cardColor: Colors.white,
                    ),
                  )),
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
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (isAdmin && onAdd != null)
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200], // Fondo gris claro
            borderRadius: BorderRadius.circular(50), // Bordes redondeados
          ),
          child: IconButton(
            icon: const Icon(Icons.add_outlined),
            color: Colors.black, // Color del icono
            onPressed: onAdd,
          ),
        ),
    ],
  );
}
}