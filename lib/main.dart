import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'router/app_router.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar DB antes de runApp
  await DatabaseHelper.instance.database;

  // Inicializar locale español
  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: CapitalProApp()));
}

class CapitalProApp extends StatelessWidget {
  const CapitalProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = createRouter();

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
