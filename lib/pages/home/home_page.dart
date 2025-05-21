import 'package:barber_xe/controllers/profile_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/models/service_combo.dart';
import 'package:barber_xe/models/service_model.dart';
import 'package:barber_xe/pages/appointment/appointments_dashboard_page.dart';
import 'package:barber_xe/pages/auth/widgets/Active_button.dart';
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 25),
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
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: 'Citas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          label: 'Barberos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_outlined),
          label: 'Notificaciones',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
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
      constraints: BoxConstraints(maxHeight: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          20,
        ), // Borde más pequeño para coincidir con el diseño
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Sombra más suave
            blurRadius: 8, // Radio de difuminado aumentado
            offset: const Offset(0, 2), // Desplazamiento vertical reducido
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 15, // Tamaño de fuente ligeramente reducido
            fontWeight: FontWeight.w400, // Peso de fuente regular
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 12,
            ), // Ajuste fino de espaciado
            child: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade600,
              size: 18, // Tamaño de ícono reducido
            ),
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                    ), // Alineación precisa
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded, // Ícono de cierre redondeado
                        color: Colors.grey.shade600,
                        size: 15, // Tamaño reducido
                      ),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8, // Altura del campo reducida
            horizontal: 0,
          ),
          isDense: true, // Control preciso de densidad
        ),
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500, // Peso de fuente medio
        ),
        onChanged: (value) {
          controller.setSearchQuery(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCombosSection(BuildContext context, bool isAdmin) {
    final controller = context.watch<ServiceController>();
    final combosToShow = controller.getCombosForRoleSimple(isAdmin: isAdmin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Combos',
          onAdd:
              isAdmin
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServiceComboPage()),
                  )
                  : null,
          isAdmin: isAdmin,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: combosToShow.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final combo = combosToShow[index];
              return SelectableItemCard(
                isCombo: true,
                title: combo.name,
                price: combo.totalPrice,
                duration: combo.totalDuration,
                imageUrl: combo.imageUrl,
                description: combo.description,
                isSelected: false,
                onTap: () => _showComboDetails(context, combo, isAdmin),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showComboDetails(
    BuildContext context,
    ServiceCombo combo,
    bool isAdmin,
  ) async {
    final theme = Theme.of(context);
    final serviceController = context.read<ServiceController>();
    final services = await serviceController.getServicesByIds(combo.serviceIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
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
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            combo.imageUrl != null
                                ? Image.network(
                                  combo.imageUrl!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          HomeHelpers.buildPlaceholderImage(),
                                )
                                : HomeHelpers.buildPlaceholderImage(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '\$${combo.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: theme.primaryColor,
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
                      ...services.map(
                        (service) => HomeHelpers.buildServiceItem(
                          service,
                          theme.copyWith(
                            textTheme: GoogleFonts.poppinsTextTheme(
                              theme.textTheme,
                            ),
                            cardColor: Colors.white,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 24),
                        // Contenedor para los botones de administración
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Botón de toggle
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        combo.isActive
                                            ? Colors.red[100]
                                            : Colors.green[100],
                                    foregroundColor:
                                        combo.isActive
                                            ? Colors.red
                                            : Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    final nuevoEstado = !combo.isActive;
                                    final updatedCombo = combo.copyWith(
                                      isActive: nuevoEstado,
                                    );
                                    await serviceController.updateCombo(
                                      updatedCombo,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            nuevoEstado
                                                ? 'Combo activado'
                                                : 'Combo desactivado',
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        combo.isActive
                                            ? Icons.toggle_on
                                            : Icons.toggle_off,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        combo.isActive
                                            ? 'Desactivar Combo'
                                            : 'Activar Combo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Botones de editar y eliminar
                              Row(
                                children: [
                                  // Botón de editar
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[50],
                                        foregroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ServiceComboPage(
                                                  combo: combo,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.edit, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Editar',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Botón de eliminar
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[50],
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: Text(
                                                  'Eliminar combo',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  '¿Estás seguro? Esta acción no se puede deshacer.',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      'Cancelar',
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                  ),
                                                  TextButton(
                                                    child: Text(
                                                      'Eliminar',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.red,
                                                          ),
                                                    ),
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirm == true) {
                                          await serviceController.deleteCombo(
                                            combo.id,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Combo eliminado',
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.delete, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Eliminar',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
    final servicesToShow = controller.getServicesForRole(isAdmin: isAdmin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Servicios',
          onAdd:
              isAdmin
                  ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServicePage()),
                  )
                  : null,
          isAdmin: isAdmin,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: servicesToShow.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = servicesToShow[index];
            return ServiceCard(
              service: service,
              onTap: () => _showServiceDetails(context, service, isAdmin),
            );
          },
        ),
      ],
    );
  }

  void _showServiceDetails(
    BuildContext context,
    BarberService service,
    bool isAdmin,
  ) async {
    final theme = Theme.of(context);
    final serviceController = context.read<ServiceController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barra de agarre
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
                              service.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Imagen del servicio
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            service.imageUrl != null
                                ? Image.network(
                                  service.imageUrl!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => _placeholderImage(),
                                )
                                : _placeholderImage(),
                      ),
                      const SizedBox(height: 16),

                      // Precio y duración
                      Row(
                        children: [
                          Text(
                            '\$${service.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${service.duration} min',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      if (service.description.isNotEmpty) ...[
                        Text(
                          'DESCRIPCIÓN:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.description,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botones para el admin
                      if (isAdmin)
                        _buildAdminButtons(context, service, serviceController),
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

  Widget _placeholderImage() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[200],
      child: Center(child: Icon(Icons.cut, size: 60, color: Colors.grey[400])),
    );
  }

  Widget _buildAdminButtons(
    BuildContext context,
    BarberService service,
    ServiceController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Activar/desactivar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    service.isActive ? Colors.red[100] : Colors.green[100],
                foregroundColor: service.isActive ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final nuevoEstado = !service.isActive;
                final updatedService = service.copyWith(isActive: nuevoEstado);
                await controller.updateService(updatedService);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nuevoEstado
                            ? 'Servicio activado'
                            : 'Servicio desactivado',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    service.isActive ? Icons.toggle_on : Icons.toggle_off,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    service.isActive
                        ? 'Desactivar Servicio'
                        : 'Activar Servicio',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Editar y Eliminar
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServicePage(service: service),
                      ),
                    );
                  },

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Editar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: Text(
                              'Eliminar servicio',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              '¿Estás seguro? Esta acción no se puede deshacer.',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.poppins(),
                                ),
                                onPressed: () => Navigator.pop(ctx, false),
                              ),
                              TextButton(
                                child: Text(
                                  'Eliminar',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      await controller.deleteService(service.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Servicio eliminado',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onAdd,
    required bool isAdmin,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
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
