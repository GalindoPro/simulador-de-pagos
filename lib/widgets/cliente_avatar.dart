import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClienteAvatar extends StatelessWidget {
  final String nombre;
  final String apellido;
  final String? fotoPath;
  final double radio;

  const ClienteAvatar({
    super.key,
    required this.nombre,
    required this.apellido,
    this.fotoPath,
    this.radio = 24,
  });

  Color _colorPorNombre(String nombre) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      const Color(0xFF8E24AA),
      const Color(0xFFE65100),
      const Color(0xFF00695C),
    ];
    final index = nombre.codeUnits.fold<int>(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final iniciales =
        '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'
            .toUpperCase();

    if (fotoPath != null && fotoPath!.isNotEmpty) {
      final file = File(fotoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radio,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: radio,
      backgroundColor: _colorPorNombre(nombre),
      child: Text(
        iniciales,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radio * 0.7,
        ),
      ),
    );
  }
}
