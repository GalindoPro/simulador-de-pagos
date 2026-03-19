import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registro_screen.dart';
import '../screens/auth/recuperar_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/simulador/simulador_screen.dart';
import '../screens/clientes/clientes_screen.dart';
import '../screens/clientes/clientes_inactivos_screen.dart';
import '../screens/clientes/form_cliente_screen.dart';
import '../screens/clientes/detalle_cliente_screen.dart';
import '../screens/prestamos/prestamos_screen.dart';
import '../screens/prestamos/form_prestamo_screen.dart';
import '../screens/prestamos/detalle_prestamo_screen.dart';
import '../screens/pagos/pagos_screen.dart';
import '../screens/pagos/form_pago_screen.dart';
import '../screens/pagos/detalle_pago_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/configuracion/configuracion_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarPassword,
        builder: (context, state) => const RecuperarPasswordScreen(),
      ),

      // Dashboard
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),

      // Simulador
      GoRoute(
        path: AppRoutes.simulador,
        builder: (context, state) => const SimuladorScreen(),
      ),

      // Clientes
      GoRoute(
        path: AppRoutes.clientes,
        builder: (context, state) => const ClientesScreen(),
      ),
      GoRoute(
        path: AppRoutes.clientesInactivos,
        builder: (context, state) => const ClientesInactivosScreen(),
      ),
      GoRoute(
        path: AppRoutes.nuevoCliente,
        builder: (context, state) => const FormClienteScreen(),
      ),
      GoRoute(
        path: AppRoutes.detalleCliente,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetalleClienteScreen(clienteId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.editarCliente,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FormClienteScreen(clienteId: id);
        },
      ),

      // Préstamos
      GoRoute(
        path: AppRoutes.prestamos,
        builder: (context, state) => const PrestamosScreen(),
      ),
      GoRoute(
        path: AppRoutes.nuevoPrestamo,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FormPrestamoScreen(datosSimulador: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.detallePrestamo,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetallePrestamoScreen(prestamoId: id);
        },
      ),

      // Pagos
      GoRoute(
        path: AppRoutes.pagos,
        builder: (context, state) => const PagosScreen(),
      ),
      GoRoute(
        path: AppRoutes.nuevoPago,
        builder: (context, state) {
          final clienteId = state.uri.queryParameters['clienteId'];
          final prestamoId = state.uri.queryParameters['prestamoId'];
          return FormPagoScreen(
            clienteId: clienteId,
            prestamoId: prestamoId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.detallePago,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetallePagoScreen(pagoId: id);
        },
      ),

      // Reportes
      GoRoute(
        path: AppRoutes.reportes,
        builder: (context, state) => const ReportesScreen(),
      ),

      // Configuración
      GoRoute(
        path: AppRoutes.configuracion,
        builder: (context, state) => const ConfiguracionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
}
