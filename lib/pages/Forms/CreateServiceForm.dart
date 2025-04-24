import 'dart:io'; // Necesario para File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para input formatters
import 'package:image_picker/image_picker.dart'; // Importa el paquete

class CreateServiceForm extends StatefulWidget {
  const CreateServiceForm({super.key});

  @override
  State<CreateServiceForm> createState() => _CreateServiceFormState();
}

class _CreateServiceFormState extends State<CreateServiceForm> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  // Variable para la categoría seleccionada
  String? _selectedCategory;
  final List<String> _categories = ['Corte', 'Barba', 'Facial', 'Combo', 'Otro']; // Ejemplo de categorías

  // Variable para almacenar la imagen seleccionada
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Colores basados en tu captura (ajusta si es necesario)
  final Color primaryColor = Colors.black;
  final Color backgroundColor = const Color(0xFFF8F8F8); // Un gris muy claro
  final Color textFieldFillColor = Colors.white;
  final Color hintTextColor = Colors.grey.shade600;
  final Color buttonTextColor = Colors.white;

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se desecha
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Función para seleccionar imagen de la galería
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Función para manejar el envío del formulario
  void _submitForm() {
    // Valida que la imagen no sea nula Y que el formulario sea válido
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una imagen.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Detiene el envío si no hay imagen
    }

    if (_formKey.currentState!.validate()) {
      // Si el formulario es válido, procede a guardar los datos
      _formKey.currentState!.save(); // Llama a onSaved si lo usaras

      // Aquí recolectas los datos
      final name = _nameController.text;
      final description = _descriptionController.text;
      final category = _selectedCategory; // Ya está guardado
      final duration = int.tryParse(_durationController.text) ?? 0; // Convierte a entero
      final price = double.tryParse(_priceController.text) ?? 0.0; // Convierte a double
      final imageFile = _selectedImage; // Ya está guardado

      // --- Lógica de envío ---
      // Aquí es donde enviarías los datos a tu backend, base de datos local, etc.
      print('Nombre: $name');
      print('Descripción: $description');
      print('Categoría: $category');
      print('Duración: $duration minutos');
      print('Precio: \$${price.toStringAsFixed(2)}');
      print('Ruta Imagen: ${imageFile?.path}');

      // Muestra un mensaje de éxito (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servicio "$name" creado exitosamente.'),
          backgroundColor: Colors.green,
        ),
      );

      // Puedes limpiar el formulario o navegar a otra pantalla después de guardar
       _formKey.currentState?.reset();
       _nameController.clear();
       _descriptionController.clear();
       _durationController.clear();
       _priceController.clear();
       setState(() {
         _selectedCategory = null;
         _selectedImage = null;
       });
      // Navigator.pop(context); // Ejemplo para cerrar la pantalla
    } else {
      // Muestra un mensaje si hay errores de validación
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrige los errores en el formulario.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define el estilo base para los InputDecoration
    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: textFieldFillColor,
      hintStyle: TextStyle(color: hintTextColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none, // Sin borde visible como en tu captura
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        // Puedes añadir un borde sutil al enfocar si lo deseas
        // borderSide: BorderSide(color: primaryColor, width: 1.0),
         borderSide: BorderSide.none,
      ),
       errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );

    return Scaffold(
      // Puedes poner un AppBar si lo necesitas
      // appBar: AppBar(
      //   title: const Text('Crear Nuevo Servicio'),
      //   backgroundColor: backgroundColor,
      //   elevation: 0, // Sin sombra
      //   foregroundColor: primaryColor, // Color del texto y los iconos
      // ),
      backgroundColor: backgroundColor,
      body: SafeArea( // Para evitar que el contenido se solape con la barra de estado/notificaciones
        child: SingleChildScrollView( // Permite hacer scroll si el contenido no cabe
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey, // Asigna la clave al formulario
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estira los widgets hijos
              children: <Widget>[
                const Text(
                  'Crear Nuevo Corte o Servicio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25.0),

                // --- Campo Nombre ---
                TextFormField(
                  controller: _nameController,
                  decoration: inputDecorationTheme.copyWith(
                    hintText: 'Nombre del servicio (ej: Corte Clásico)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15.0),

                // --- Campo Descripción ---
                TextFormField(
                  controller: _descriptionController,
                  decoration: inputDecorationTheme.copyWith(
                    hintText: 'Descripción (opcional)',
                  ),
                  maxLines: 3, // Permite varias líneas
                  // No es obligatorio, así que no necesita validador estricto
                ),
                const SizedBox(height: 15.0),

                // --- Campo Categoría (Dropdown) ---
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: inputDecorationTheme.copyWith(
                     hintText: 'Categoría',
                     // Ajusta el padding si es necesario para alinear con TextFormField
                     contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                   validator: (value) {
                    if (value == null) {
                      return 'Por favor, selecciona una categoría';
                    }
                    return null;
                  },
                  // Para que el dropdown ocupe el ancho y tenga fondo blanco
                  isExpanded: true,
                  dropdownColor: textFieldFillColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                const SizedBox(height: 15.0),

                // --- Campo Duración ---
                TextFormField(
                  controller: _durationController,
                  decoration: inputDecorationTheme.copyWith(
                    hintText: 'Duración (en minutos)',
                    prefixIcon: Icon(Icons.timer_outlined, color: hintTextColor),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly // Solo permite números
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa la duración';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Ingresa una duración válida (número > 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15.0),

                // --- Campo Precio ---
                TextFormField(
                  controller: _priceController,
                  decoration: inputDecorationTheme.copyWith(
                    hintText: 'Precio',
                    prefixIcon: Icon(Icons.attach_money, color: hintTextColor),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    // Permite números y un solo punto decimal
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                   validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa el precio';
                    }
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Ingresa un precio válido (número >= 0)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                 // --- Selector de Imagen ---
                Text(
                  'Imagen del Servicio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 10.0),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity, // Ocupa todo el ancho
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: _selectedImage == null && _formKey.currentState != null && !_formKey.currentState!.validate()
                          ? Colors.red // Borde rojo si no hay imagen y se intentó enviar
                          : Colors.grey.shade400,
                        width: 1
                      ),
                    ),
                    child: _selectedImage == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: hintTextColor),
                              const SizedBox(height: 8),
                              Text('Toca para seleccionar imagen', style: TextStyle(color: hintTextColor)),
                            ],
                          )
                        )
                      : ClipRRect( // Para aplicar bordes redondeados a la imagen
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover, // Ajusta la imagen al contenedor
                            width: double.infinity,
                            height: 150,
                          ),
                        ),
                  ),
                ),
                // Mensaje de error para la imagen (opcional, pero útil)
                if (_selectedImage == null) // Puedes añadir lógica para mostrarlo solo después del intento de submit
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       // Se podría activar este mensaje solo después de presionar submit
                       // si el form está invalidado específicamente por la imagen.
                       // Por ahora, la lógica de validación está en _submitForm.
                       '', //'* Se requiere una imagen'
                       style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                     ),
                   ),

                const SizedBox(height: 30.0),

                // --- Botón de Envío ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Color de fondo negro
                    foregroundColor: buttonTextColor, // Color del texto blanco
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    minimumSize: const Size(double.infinity, 50), // Ancho completo
                  ),
                  onPressed: _submitForm, // Llama a la función de envío
                  child: const Text(
                    'Crear Servicio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}