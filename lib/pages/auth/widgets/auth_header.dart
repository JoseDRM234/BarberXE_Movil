import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Título BarberXE
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Subtítulo
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            subtitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Instrucciones
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF757575),
            ),
          ),
        ),
      ],
    );
  }
}