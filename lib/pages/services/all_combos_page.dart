import 'dart:math';
import 'package:barber_xe/controllers/appointment_controller.dart';
import 'package:barber_xe/controllers/services_controller.dart';
import 'package:barber_xe/pages/widget/selectable_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllCombosPage extends StatefulWidget {
  final List<String> selectedIds;
  
  const AllCombosPage({super.key, required this.selectedIds});

  @override
  State<AllCombosPage> createState() => _AllCombosPageState();
}

class _AllCombosPageState extends State<AllCombosPage> {
  late List<String> _selectedIds;
  String? _selectedSort;
  TextEditingController _priceController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  bool _filtersApplied = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _toggleSelection(String comboId) {
    setState(() {
      if (_selectedIds.contains(comboId)) {
        _selectedIds.remove(comboId);
      } else {
        _selectedIds.add(comboId);
      }
    });
  }

  void _confirmSelection() {
    final appointmentController = context.read<AppointmentController>();
    appointmentController
      ..clearCombos()
      ..addMultipleCombos(_selectedIds);
    Navigator.pop(context);
  }

  void _applyFilters() {
    setState(() {
      _filtersApplied = true;
      _showFilters = false; // Ocultamos los filtros después de aplicar
    });
  }

  void _resetFilters() {
    setState(() {
      _priceController.clear();
      _durationController.clear();
      _filtersApplied = false;
      _selectedSort = null;
    });
  }

  void _toggleFiltersVisibility() {
    setState(() {
      _showFilters = !_showFilters;
      if (!_showFilters) {
        _filtersApplied = false;
      }
    });
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _showFilters ? 320 : 0,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Text(
              'Filtrar Combos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filtro por Precio
            Text(
              'Precio máximo',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                hintText: 'Ej: 50.000',
                prefixIcon: const Icon(Icons.attach_money),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: _priceController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _priceController.clear()),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            
            // Filtro por Duración
            Text(
              'Duración máxima (minutos)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                hintText: 'Ej: 60',
                prefixIcon: const Icon(Icons.access_time),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: _durationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _durationController.clear()),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              keyboardType: TextInputType.number,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Ordenar
            Text(
              'Ordenar por',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSort,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: theme.cardColor,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('Predeterminado', style: theme.textTheme.bodyLarge),
                ),
                ...['price_asc', 'price_desc', 'duration_asc', 'duration_desc'].map((value) {
                  final text = {
                    'price_asc': 'Precio: Menor a Mayor',
                    'price_desc': 'Precio: Mayor a Menor',
                    'duration_asc': 'Duración: Corto a Largo',
                    'duration_desc': 'Duración: Largo a Corto',
                  }[value]!;
                  return DropdownMenuItem(
                    value: value,
                    child: Text(text, style: theme.textTheme.bodyLarge),
                  );
                }).toList(),
              ],
              onChanged: (value) => setState(() => _selectedSort = value),
            ),
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt_outlined, size: 20),
                    label: const Text('APLICAR FILTROS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _applyFilters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: const Text('LIMPIAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _resetFilters,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();

    final filteredCombos = controller.combos.where((combo) {
      if (!_filtersApplied) return true;
      
      final priceFilter = _priceController.text.isEmpty || 
                        combo.totalPrice <= (double.tryParse(_priceController.text) ?? double.infinity);
      
      final durationFilter = _durationController.text.isEmpty || 
                          combo.totalDuration <= (int.tryParse(_durationController.text) ?? 9999);
      
      return priceFilter && durationFilter;
    }).toList();

    if (_selectedSort != null) {
      filteredCombos.sort((a, b) {
        switch (_selectedSort) {
          case 'price_asc': return a.totalPrice.compareTo(b.totalPrice);
          case 'price_desc': return b.totalPrice.compareTo(a.totalPrice);
          case 'duration_asc': return a.totalDuration.compareTo(b.totalDuration);
          case 'duration_desc': return b.totalDuration.compareTo(a.totalDuration);
          default: return 0;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todos los Combos',
          style: TextStyle(
            color: Colors.white, // Texto blanco
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black, // Fondo negro
        centerTitle: true, // Centrar título
        elevation: 0, // Sin sombra
        iconTheme: const IconThemeData(
          color: Colors.white, // Iconos blancos
          size: 28, // Tamaño consistente
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white, // Color para iconos de acciones
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.close : Icons.filter_alt,
              color: Colors.white, // Color explícito
            ),
            onPressed: _toggleFiltersVisibility,
          ),
          IconButton(
            icon: const Icon(
              Icons.check,
              color: Colors.white, // Color explícito
            ),
            onPressed: _confirmSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersPanel(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filteredCombos.length,
                itemBuilder: (context, index) {
                  final combo = filteredCombos[index];
                  return SelectableItemCard(
                    isCombo: true,
                    title: combo.name,
                    price: combo.totalPrice,
                    duration: combo.totalDuration,
                    imageUrl: combo.imageUrl,
                    description: combo.description,
                    isSelected: _selectedIds.contains(combo.id),
                    onTap: () => _toggleSelection(combo.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}