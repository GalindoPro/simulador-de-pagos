# Capital Pro — prompts por módulo

> Base de trabajo para pedir cambios específicos con IA. Usar junto con `CAPITAL_PRO_CONTEXT.md`.

## Instrucciones generales para todos los prompts

- Mantener el proyecto en Español.
- Usar `AppColors`, `AppStrings`, `AppTextStyles` y validadores existentes.
- Crear `try/catch` en procesos async.
- Verificar `if (mounted)` antes de `context` después de `await`.
- No hardcodear textos en interfaces.
- Usar `go_router` y rutas declaradas.
- Mantener consistencia con `lib/providers`, `lib/repositories` y `lib/services`.

---

## PROMPT 01 — Registro y login

```text
Genera o actualiza el flujo de autenticación de Capital Pro.

Objetivo:
- Auth con login y registro
- Registro de 3 pasos
- Recuperación de contraseña
- Respuestas de seguridad en SHA-256
- Validación de teléfono y contraseña

Archivos esperados:
- lib/screens/auth/login_screen.dart
- lib/screens/auth/registro_screen.dart
- lib/screens/auth/recuperar_password_screen.dart

Requisitos:
- Mantener separación de responsabilidades con providers y repositories
- Manejar loading y mensajes con el patrón del proyecto
- Validar contraseña, nombre, teléfono y capital inicial
- No auto-login después del registro
```

---

## PROMPT 02 — Dashboard financiero

```text
Actualiza la pantalla principal del dashboard.

Necesito:
- saludo por hora
- capital disponible del usuario
- tarjetas resumen
- pagos recientes
- próximos vencimientos
- gráfica mensual
- acciones rápidas de cliente, préstamo y simulador

Archivos esperados:
- lib/screens/dashboard/dashboard_screen.dart
- lib/widgets/

Requisitos:
- Usar datos del provider actual del usuario
- Mostrar métricas con formato Q y fechas locales
- Mantener estilo material consistente
```

---

## PROMPT 03 — Módulo de clientes

```text
Genera el flujo completo del módulo de clientes.

Debe incluir:
- listado de clientes activos
- historial de clientes inactivos
- formulario con foto, nombre, apellido, teléfono, DPI y dirección
- detalle del cliente con préstamos y pagos
- búsquedas y filtros por estado

Archivos esperados:
- lib/screens/clientes/clientes_screen.dart
- lib/screens/clientes/clientes_inactivos_screen.dart
- lib/screens/clientes/form_cliente_screen.dart
- lib/screens/clientes/detalle_cliente_screen.dart

Requisitos:
- Formato de DPI guatemalteco
- Teléfono con validación
- Integrar providers y repositorios del proyecto
- Mantener comportamiento de estado activo/inactivo
```

---

## PROMPT 04 — Módulo de préstamos

```text
Implementa el módulo de préstamos para Capital Pro.

Incluye:
- formulario de creación
- confirmación antes de guardar
- cálculo de cuota, intereses y vencimiento
- detalle del préstamo
- tabla de amortización
- flujo de pago y saldo pendiente

Archivos esperados:
- lib/screens/prestamos/form_prestamo_screen.dart
- lib/screens/prestamos/prestamos_screen.dart
- lib/screens/prestamos/detalle_prestamo_screen.dart

Requisitos:
- Tasa por defecto 7%
- Validar monto, plazo y cliente
- Usar cálculo de cuotas realista y persistencia local
```

---

## PROMPT 05 — Módulo de pagos

```text
Crea o modifica el flujo de pagos.

Debe soportar:
- registrar pago efectivo o transferencia
- adjuntar comprobante de imagen
- asociar cliente y préstamo
- actualizar saldo de préstamo
- marcar cuota pagada
- generar recibo o finiquito

Archivos esperados:
- lib/screens/pagos/pagos_screen.dart
- lib/screens/pagos/form_pago_screen.dart
- lib/screens/pagos/detalle_pago_screen.dart

Requisitos:
- Validar monto y fecha
- Generar registro persistente en SQLite
- Integrar WhatsApp o documento de comprobante si aplica
```

---

## PROMPT 06 — Simulador

```text
Crea o mejora el simulador de préstamos.

Objetivo:
- entrada de monto, tasa, plazo y fecha
- cálculo en tiempo real de cuota y total
- tabla de amortización
- resumen financiero

Archivos esperados:
- lib/screens/simulador/simulador_screen.dart
- lib/widgets/tabla_amortizacion.dart

Requisitos:
- Usar formato Q y fechas localizadas
- Mantener cálculos consistentes con la lógica de pagos del proyecto
```

---

## PROMPT 07 — Reportes y configuración

```text
Implementa o mejora reportes y configuración del sistema.

Debe incluir:
- métricas financieras por mes
- resumen de clientes y préstamos
- configuración del usuario
- exportación/importación local de la base de datos

Archivos esperados:
- lib/screens/reportes/
- lib/screens/configuracion/

Requisitos:
- Mantener compatibilidad con SQLite local
- Documentar en UI cuando se exporta/importa información
```

---

## PROMPT 08 — Optimización general

```text
Optimiza la app de Capital Pro sin romper la lógica existente.

Prioridades:
- limpieza de código
- eliminar imports sin usar
- mejorar validación y mensajes
- revisar navegación y estados
- mantener consistencia de estilo visual
- asegurar compatibilidad con web/móvil si aplica
```
   Si comprobante_path → mostrar imagen del comprobante
   Card datos del cliente
   Si tiene préstamo → Card resumen del préstamo
   Botón "Ver/Compartir recibo PDF"
   Botón "Enviar por WhatsApp"
```


---

## PROMPT 01 — Widgets reutilizables

```
Usando el contexto de Capital Pro, genera todos los widgets reutilizables en lib/widgets/:

1. app_card.dart — Card con sombra, padding, borderRadius 12, onTap opcional
2. stat_card.dart — Tarjeta KPI: icono + valor grande + título + color de acento
3. loading_button.dart — ElevatedButton con CircularProgressIndicator cuando isLoading=true
4. empty_state.dart — Widget centrado: icono grande + mensaje + subtitulo + botón opcional
5. confirm_dialog.dart — AlertDialog con método estático show() que retorna Future<bool>
6. cliente_avatar.dart — CircleAvatar: foto si existe, sino iniciales con color por nombre
7. pago_list_tile.dart — ListTile: icono método pago + cliente + concepto + monto + estado chip
8. prestamo_card.dart — Card: cliente + monto/saldo + LinearProgressIndicator + fecha vencimiento
9. seccion_header.dart — Row: título bold + TextButton "Ver todos" a la derecha
10. whatsapp_button.dart — IconButton verde que llama WhatsAppService.enviarMensaje
11. app_error_widget.dart — Centrado: icono error + mensaje + botón Reintentar
12. app_snack_bar.dart — Clase estática: exito / error / advertencia / info con colores AppColors

Reglas:
- Todos los colores de AppColors, strings de AppStrings, estilos de AppTextStyles
- Constructores con parámetros nombrados y valores por defecto donde aplique
- Código completo y funcional para cada archivo
```

---

## PROMPT 02 — Dashboard (Inicio)

```
Genera lib/screens/dashboard/dashboard_screen.dart para Capital Pro.

ESTRUCTURA DE LA PANTALLA:
- Scaffold con BottomNavigationBar de 6 items:
  Inicio (home) | Clientes (people) | Préstamos (payments) |
  Pagos (attach_money) | Reportes (bar_chart) | Config (settings)
- Cada tab navega a su ruta con context.go(AppRoutes.X)
- SpeedDial FAB (flutter_speed_dial) con 3 opciones:
  → Nuevo Cliente, Nuevo Pago, Nuevo Préstamo

CONTENIDO DEL DASHBOARD (SingleChildScrollView):
1. Header personalizado:
   - Saludo según hora: "Buenos días/tardes/noches, [nombre]"
   - Fecha: "Jueves, 15 de enero de 2024"
   - Avatar circular con iniciales del usuario

2. Grid 2x2 de StatCards (resumenFinancieroProvider):
   - Total cobrado este mes (AppColors.success)
   - Préstamos activos (AppColors.info)
   - Saldo pendiente total (AppColors.warning)
   - Préstamos vencidos (AppColors.error)

3. Sección "Cobros por mes" con BarChart (fl_chart):
   - Últimos 6 meses
   - Datos de resumenFinancieroProvider.pagosPorMes
   - Color barras: AppColors.primary
   - Altura: 200px

4. SeccionHeader "Últimos pagos" → onVerTodos: /pagos
   - Lista de últimos 5 pagos con PagoListTile

5. SeccionHeader "Próximos a vencer" → onVerTodos: /prestamos
   - Lista de préstamos que vencen en 30 días con PrestamoCard

Manejo de errores y loading en cada sección independientemente.
```

---

## PROMPT 03 — Módulo Clientes completo

```
Genera las 3 pantallas del módulo Clientes para Capital Pro.

1. lib/screens/clientes/clientes_screen.dart
   - AppBar con SearchBar conectado a clientesBusquedaProvider
   - Lista con clientesFiltradosProvider usando ClienteAvatar + datos
   - Swipe derecha → abrir WhatsApp
   - Swipe izquierda → ConfirmDialog → eliminar (soft delete)
   - Tap → context.go('/clientes/\$id')
   - FAB → /clientes/nuevo
   - Pull to refresh → ref.invalidate(clientesProvider)
   - EmptyState si lista vacía

2. lib/screens/clientes/form_cliente_screen.dart
   - Si clienteId != null → modo edición (carga datos)
   - Selector foto circular con image_picker (galería o cámara)
   - Campos: nombre* (Title Case auto onChanged), apellido* (Title Case auto),
     teléfono* (solo dígitos, máx 8), email, dirección, DPI
   - Al guardar: llama CarpetaService.generarPDFPerfil(cliente)
   - Al guardar: ref.invalidate(clientesProvider) + context.pop()

3. lib/screens/clientes/detalle_cliente_screen.dart
   - AppBar: nombre del cliente + botón editar
   - TabBar con 3 tabs:
     Tab 1 "Información": ClienteAvatar grande + todos los datos + WhatsAppButton
     Tab 2 "Préstamos": lista PrestamoCard + FAB nuevo préstamo
     Tab 3 "Pagos": lista PagoListTile + FAB nuevo pago
   - Cada FAB con clienteId como query param
```

---

## PROMPT 04 — Módulo Préstamos completo

```
Genera las pantallas del módulo Préstamos para Capital Pro.

1. lib/screens/prestamos/prestamos_screen.dart
   - Header: 3 StatCards (Total prestado | Activos | Vencidos)
   - FilterChips: Todos | Activos | Vencidos | Pagados
   - Lista con prestamosFiltradosProvider + PrestamoCard
   - FAB → /prestamos/nuevo
   - Pull to refresh

2. lib/screens/prestamos/form_prestamo_screen.dart
   - Dropdown cliente (con búsqueda)
   - Campos: monto*, tasa interés* (%), plazo* (Slider 1-60 + texto)
   - DatePicker fecha inicio*
   - Campos opcionales: garantía, notas
   
   PREVIEW EN TIEMPO REAL (Card que se actualiza con onChanged):
   - Monto total a pagar
   - Total de intereses
   - Cuota mensual estimada
   - Fecha de vencimiento calculada
   
   Al guardar:
   - Crea el préstamo en DB
   - Genera tabla de amortización (CuotaPago.generarTabla) y la guarda en tabla_pagos
   - Llama CarpetaService.generarPDFTablaPagos(cliente, prestamo, cuotas)
   - ref.invalidate(prestamosProvider)

3. lib/screens/prestamos/detalle_prestamo_screen.dart
   - AppBar: "Detalle del préstamo" + botón editar
   - Card resumen del préstamo con LinearProgressIndicator
   - TABLA DE CUOTAS completa (lista de CuotaPago del prestamo)
     Cada fila: # | Fecha | Capital | Interés | Total | Saldo | Estado (pagado/pendiente)
   - Botón "Registrar pago de cuota" → /pagos/nuevo?prestamoId=X&clienteId=Y
   - Banner rojo si préstamo vencido
   - Botón "Generar finiquito" si saldo = 0 → CarpetaService.generarFiniquito
```

---

## PROMPT 05 — Módulo Pagos completo

```
Genera las pantallas del módulo Pagos para Capital Pro.

1. lib/screens/pagos/pagos_screen.dart
   - Header: 3 StatCards (Cobrado este mes | Pendiente | Completados del mes)
   - FilterChips: Todos | Pendiente | Completado | Cancelado
   - SearchBar por cliente o concepto
   - Lista con pagosFiltradosProvider + PagoListTile
   - Swipe para eliminar con ConfirmDialog
   - FAB → /pagos/nuevo
   - Pull to refresh

2. lib/screens/pagos/form_pago_screen.dart
   Si clienteId en query → preseleccionar cliente
   Si prestamoId en query → preseleccionar préstamo y cuota actual
   
   Campos:
   - Cliente* (DropdownButtonFormField, lista de clientesProvider)
   - Al seleccionar cliente → carga sus préstamos activos
   - Préstamo (Dropdown opcional, filtra por cliente)
   - Monto* (numérico, AppValidators.monto)
   - Fecha* (InkWell abre DatePicker, default hoy)
   - Método pago* (SegmentedButton: Efectivo | Transferencia | Cheque | Tarjeta)
   - Concepto* (TextFormField)
   - Estado (SegmentedButton: Pendiente | Completado)
   - Notas (multiline, opcional)
   
   Al guardar:
   - Registra pago en DB
   - Si tiene prestamoId → PrestamoRepository.registrarPago(id, monto)
   - Si tiene prestamoId → marca cuota como pagada en tabla_pagos
   - Genera PDF recibo → CarpetaService.generarReciboPago
   - Muestra SnackBar con opción "Compartir por WhatsApp"

3. lib/screens/pagos/detalle_pago_screen.dart
   - Todos los datos del pago en Cards
   - Datos del cliente
   - Si tiene préstamo → Card con info del préstamo + cuota
   - Botón "Ver/Compartir recibo PDF" → abre PDF guardado
   - Botón "Enviar por WhatsApp" → mensaje de confirmación
```

---

## PROMPT 06 — Reportes

```
Genera lib/screens/reportes/reportes_screen.dart para Capital Pro.

SELECTOR DE PERÍODO:
- Row: botón mes anterior | mes/año actual | mes siguiente
- Opción "Rango personalizado" con 2 DatePickers

4 StatCards KPI del período:
- Total cobrado
- Total prestado
- Tasa de morosidad (prestamos_vencidos / activos * 100)
- Clientes nuevos

GRÁFICA DE LÍNEA (fl_chart LineChart):
- Ingresos vs Préstamos otorgados por mes (6 meses)
- Línea verde (cobros) y azul (préstamos)
- Leyenda y ejes con valores en Q

GRÁFICA DE PIE (fl_chart PieChart):
- Distribución por método de pago
- Porcentajes + leyenda de colores

TOP 5 clientes con más pagos en el período

Botones de acción:
- "Exportar PDF" → genera reporte completo con todas las métricas
- "Compartir base de datos" → CarpetaService.compartirBaseDatos (para respaldo)
```

---

## PROMPT 07 — Configuración

```
Genera lib/screens/configuracion/configuracion_screen.dart para Capital Pro.

SECCIONES:
1. Mi perfil
   - Avatar con iniciales + nombre del usuario actual (sesionActualProvider)
   - Opción cambiar nombre
   - Opción cambiar contraseña

2. Usuarios registrados
   - Lista de todos los usuarios activos
   - Opción desactivar usuario (activo = 0)

3. Respaldo de datos
   - "Exportar base de datos" → comparte capital_pro.db
   - "Ver carpeta de clientes" → abre CapitalPro/Clientes en explorador
   - Información: tamaño DB, última modificación, total registros

4. Acerca de
   - Versión de la app
   - Información del negocio (editable)

5. Cerrar sesión (rojo, al final)
   - ConfirmDialog → ref.read(authStateProvider.notifier).logout() → /login
```

---

## PROMPT 08 — Providers Riverpod completos

```
Genera los providers de Riverpod para Capital Pro en lib/providers/.

1. lib/providers/cliente_provider.dart
   - ClientesNotifier: CRUD completo
   - clientesProvider: AsyncNotifierProvider
   - clientesBusquedaProvider: StateProvider<String>
   - clientesFiltradosProvider: Provider que filtra por búsqueda

2. lib/providers/pago_provider.dart
   Clase PagoFiltro {estado, metodoPago, fechaDesde, fechaHasta, busqueda}
   - PagosNotifier: CRUD completo
   - pagosProvider: AsyncNotifierProvider
   - pagosFiltroProvider: StateProvider<PagoFiltro>
   - pagosFiltradosProvider: filtra la lista según PagoFiltro
   - resumenPagosProvider: FutureProvider con totales del mes actual
   - pagosRecientesProvider(int n): FutureProvider

3. lib/providers/prestamo_provider.dart
   - PrestamosNotifier: CRUD + registrarPago + marcarVencidos
   - prestamosProvider: AsyncNotifierProvider
   - prestamosFiltroProvider: StateProvider<String> (todos|activos|vencidos|pagados)
   - prestamosFiltradosProvider: filtra según el filtro activo
   - resumenFinancieroProvider: FutureProvider<ResumenFinanciero>
   - cuotasPrestamoProvider(String prestamoId): FutureProvider<List<CuotaPago>>

Todos siguen el patrón AsyncNotifier del contexto.
```

---

## PROMPT — Para corregir errores

```
Estoy trabajando en Capital Pro (Flutter). Tengo este error:

[PEGA EL ERROR AQUÍ]

Contexto del proyecto:
- Riverpod AsyncNotifierProvider para estado
- go_router para navegación
- sqflite con DatabaseHelper.instance (singleton)
- AppColors / AppStrings / AppTextStyles para UI
- AppFormatters para moneda y fechas guatemaltecas
- Usuario.toTitleCase() para nombres con mayúscula automática
- Cliente.crear() factory para crear clientes con Title Case

Por favor:
1. Explica la causa del error
2. Muestra el código corregido completo
3. Indica si afecta otros archivos
```
