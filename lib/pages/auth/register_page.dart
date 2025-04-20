import 'package:barber_xe/pages/auth/widgets/auth_button.dart';
import 'package:barber_xe/pages/auth/widgets/auth_header.dart';
import 'package:barber_xe/pages/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEFEFEF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AuthHeader(
                      title: 'BarberXE',
                      subtitle: 'Crear Cuenta',
                      description: 'Completa el formulario para registrarte',
                    ),
                    
                    // Campo de nombre
                    AuthTextField(
                      controller: _nameController,
                      hintText: 'Nombre',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su nombre';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.person),
                    ),
                    
                    // Campo de apellido
                    AuthTextField(
                      controller: _apellidoController,
                      hintText: 'Apellido',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su apellido';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    
                    // Campo de email
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'email@domain.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su correo electrónico';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Ingrese un correo válido';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.email),
                    ),
                    
                    // Campo de teléfono
                    AuthTextField(
                      controller: _telefonoController,
                      hintText: 'Teléfono (opcional)',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                          return 'Ingrese un teléfono válido (10-15 dígitos)';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    
                    // Campo de contraseña
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    
                    // Campo de confirmar contraseña
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirmar Contraseña',
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    
                    // Botón de registro
                    AuthButton(
                      text: 'Registrarse',
                      onPressed: authController.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  await authController.register(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    _nameController.text.trim(),
                                    _apellidoController.text.trim(),
                                    _telefonoController.text.trim(),
                                  );
                                  
                                  // Navegar a pantalla de perfil después de registro exitoso
                                  Navigator.of(context).pushReplacementNamed('/profile');
                                  
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                      isLoading: authController.isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Divider con "O"
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('O'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón de Google (sin logo)
                    AuthButton(
                      text: 'Continuar con Google',
                      onPressed: authController.isLoading
                          ? null
                          : () async {
                              try {
                                await authController.signInWithGoogle();
                                // Navigate after successful sign-in
                                Navigator.pushReplacementNamed(context, '/home');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authController.errorMessage ?? 'Error desconocido'),
                                  ),
                                );
                              }
                            },
                      isSecondary: true,
                    ),
                    
                    // Enlace a login
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
                    ),
                    
                    // Texto de términos
                    Text(
                      'Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}