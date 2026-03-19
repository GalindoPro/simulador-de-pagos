import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icono;
  final Color? color;

  const LoadingButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.isLoading = false,
    this.icono,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(texto),
                ],
              ),
      ),
    );
  }
}
