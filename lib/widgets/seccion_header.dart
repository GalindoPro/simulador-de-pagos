import 'package:flutter/material.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class SeccionHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback? onVerTodos;

  const SeccionHeader({
    super.key,
    required this.titulo,
    this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: AppTextStyles.titleMedium),
          if (onVerTodos != null)
            TextButton(
              onPressed: onVerTodos,
              child: const Text(AppStrings.verTodos),
            ),
        ],
      ),
    );
  }
}
