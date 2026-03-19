# Capital Pro — Prompts listos por módulo

> Usa siempre junto con CAPITAL_PRO_CONTEXT.md

---

## PROMPT 00 — Registro mejorado (3 pasos) + Recuperar contraseña

```
Genera las pantallas de auth mejoradas para Capital Pro:

1. lib/screens/auth/registro_screen.dart — Registro en 3 pasos (PageView o Stepper):
   PASO 1: nombre (Title Case onChanged) + teléfono + contraseña + confirmar
   PASO 2: Seleccionar pregunta 1 (DropdownButtonFormField de kPreguntasSeguridad)
           + respuesta 1 + Seleccionar pregunta 2 + respuesta 2
   PASO 3: "¿Cuánto capital tienes disponible para prestar?"
           Campo Q (numérico, monto > 0)
           Texto aclaratorio: "Puedes cambiarlo después en Configuración"
   
   Al finalizar: guarda usuario + preguntas (hash SHA-256 de respuestas) + capital
   → SnackBar éxito → context.go(AppRoutes.login)
   NO auto-login

2. lib/screens/auth/recuperar_password_screen.dart:
   PASO 1: Campo teléfono → busca usuario en DB
   PASO 2: Muestra pregunta 1 del usuario → campo respuesta
           Valida hash → si incorrecto, error
   PASO 3: Muestra pregunta 2 → campo respuesta
           Valida hash → si incorrecto, error
   PASO 4: Nueva contraseña + confirmar → actualiza en DB
   → SnackBar "Contraseña actualizada" → context.go(AppRoutes.login)

   En login_screen.dart agregar TextButton "¿Olvidaste tu contraseña?"
   que navega a AppRoutes.recuperarPassword

Reglas:
- Respuestas guardadas en minúsculas y con SHA-256
- Todos los if con llaves {}
- Usar AppValidators, AppColors, AppStrings
- LoadingButton para todos los botones de acción
- AppSnackBar para todos los mensajes
```

## PROMPT 0B — Dashboard mejorado con capital y acciones rápidas

```
Actualiza lib/screens/dashboard/dashboard_screen.dart con:

1. HEADER mejorado:
   - Saludo + nombre usuario
   - "Capital disponible: Q XX,XXX.XX" (de sesionActualProvider.capitalInicial)
   - Fecha actual en formato largo
   - Ícono de campana (notificaciones)

2. ACCIONES RÁPIDAS (Row de 3 cards horizontales con ícono + texto):
   [👤 Nuevo Cliente] [📋 Préstamo] [🧮 Simulador]
   → context.push(AppRoutes.nuevoCliente)
   → context.push(AppRoutes.nuevoPrestamo)
   → context.push(AppRoutes.simulador)

3. GRID 2x3 de StatCards (resumenFinancieroProvider):
   - Interés del mes (suma de intereses cobrados en pagos del mes)
   - Clientes activos (totalClientes de resumen)
   - Préstamos activos
   - Préstamos vencidos
   - Cobrado este mes
   - Saldo pendiente total

4. Gráfica de barras, últimos pagos, próximos a vencer (igual que antes)

5. NavigationBar de 6 destinos (igual que antes)
6. SpeedDial FAB (igual que antes)
```

## PROMPT 0C — Simulador de préstamos

```
Genera lib/screens/simulador/simulador_screen.dart para Capital Pro.

CAMPOS DE ENTRADA:
- Monto del préstamo (Q) — TextFormField numérico
- Tasa de interés mensual (%) — default 7.0, editable
- Plazo en meses — Slider 1 a 60 con texto del valor
- Fecha del primer pago — InkWell que abre DatePicker (default: próximo mes día 1)

PREVIEW EN TIEMPO REAL (se actualiza con onChanged/onChangeEnd):
  Cuota mensual: Q X,XXX.XX
  Total intereses: Q X,XXX.XX
  Total a pagar: Q X,XXX.XX

BOTÓN: [Calcular tabla completa]
→ Genera y muestra TablaAmortizacion(cuotas)

TABLA DE AMORTIZACIÓN (widget TablaAmortizacion):
┌────┬────────────┬──────────┬──────────┬──────────┬──────────┐
│ No.│ Fecha pago │  Cuota   │ Capital  │ Interés  │  Saldo   │
├────┼────────────┼──────────┼──────────┼──────────┼──────────┤
│  1 │ 01/Feb/25  │ Q 1,050  │ Q 800    │ Q 250    │ Q 4,200  │
└────┴────────────┴──────────┴──────────┴──────────┴──────────┘
Usar SingleChildScrollView horizontal + DataTable de Flutter

BOTÓN al final de tabla: [Crear préstamo con estos datos]
→ context.push('/prestamos/nuevo') pasando los datos como extra en go_router

Usa CuotaPago.generarTabla() para calcular las cuotas.
Usa AppFormatters.moneda(), AppFormatters.fechaCorta()
```

## PROMPT 0D — Clientes activos e inactivos separados

```
Genera el módulo de clientes separado por estado para Capital Pro.

1. lib/screens/clientes/clientes_screen.dart — ACTIVOS
   - Tab superior o botón para ir a inactivos: "Ver historial de clientes"
   - Lista solo de clientes con estado='activo'
   - Búsqueda por nombre, apellido, teléfono, DPI
   - ClienteAvatar + nombre + teléfono + número de préstamos activos
   - Swipe derecha → WhatsApp con mensaje de saludo
   - Swipe izquierda → ConfirmDialog → marcar como inactivo
   - Tap → /clientes/:id
   - FAB → /clientes/nuevo
   - EmptyState con icono e instrucción si lista vacía

2. lib/screens/clientes/clientes_inactivos_screen.dart — HISTORIAL
   - AppBar: "Historial de clientes"
   - Lista de clientes con estado='inactivo' o 'finalizado'
   - Badge de estado: "Finalizado" (verde) o "Inactivo" (gris)
   - Tap → /clientes/:id (con historial completo de pagos)
   - Botón "Nuevo préstamo" en detalle si estado='finalizado'
   - EmptyState si no hay historial

3. lib/screens/clientes/form_cliente_screen.dart — FORMULARIO
   Campos:
   - Foto circular (image_picker: cámara o galería)
   - nombre* (Title Case onChanged)
   - apellido* (Title Case onChanged)
   - telefono* (FilteringTextInputFormatter.digitsOnly + max 8)
   - telefono_referencia (opcional, 8 dígitos, "Número de referencia/familiar")
   - dpi (DpiInputFormatter + validator 13 dígitos)
   - email (opcional)
   - direccion (opcional)
   
   Al guardar:
   → CarpetaService.instance.generarPDFPerfil(cliente)
   → WhatsAppService.enviarMensaje(tel, mensajeBienvenida, context)
   → AppSnackBar.exito con "Cliente guardado. PDF generado."
   → ref.invalidate(clientesProvider) + context.pop()

4. lib/screens/clientes/detalle_cliente_screen.dart
   TabBar con 3 tabs:
   - "Info": avatar grande + todos los datos + botón WhatsApp
   - "Préstamos": lista de PrestamoCard + FAB nuevo préstamo
   - "Pagos": lista de PagoListTile + historial completo
   
   Si estado='finalizado' → banner verde "✓ Préstamo finalizado — Apto para nuevo crédito"
   Si estado='inactivo'   → banner gris "Sin préstamos activos"
```

## PROMPT 0E — Préstamos con tasa 7% y BottomSheet de confirmación

```
Genera el módulo de préstamos para Capital Pro.

1. lib/screens/prestamos/form_prestamo_screen.dart
   - Si clienteId en query → preseleccionar cliente
   - Si datos precargados desde simulador → usar esos valores
   
   Campos:
   - Cliente* (DropdownButtonFormField con búsqueda, filtra clientesProvider)
   - Monto original* (numérico, AppValidators.monto)
   - Tasa de interés* (numérico %, DEFAULT 7.0 — editable)
   - Plazo* (Slider 1-60 meses + Text del valor actual)
   - Fecha inicio* (DatePicker, default hoy)
   - Garantía (opcional)
   - Notas (opcional)
   
   PREVIEW EN TIEMPO REAL (Card que se actualiza):
     Cuota mensual | Total intereses | Total a pagar | Fecha vencimiento
   
   Al presionar [Guardar préstamo]:
   → Mostrar BottomSheet de CONFIRMACIÓN con:
     Cliente, Monto, Tasa, Plazo
     Cuota mensual, Total intereses, Total a pagar
     Fecha inicio, Fecha vencimiento
     [Cancelar] [Confirmar préstamo]
   
   Al confirmar:
   → ref.read(prestamosProvider.notifier).crear(prestamo, cuotas)
   → CarpetaService.generarPDFTablaPagos(cliente, prestamo, cuotas)
   → WhatsAppService.enviarMensaje(tel, mensajePrestamoAprobado(...), context)
   → AppSnackBar.exito "Préstamo creado. PDF generado."
   → context.pop()

2. lib/screens/prestamos/prestamos_screen.dart
   Header: 3 StatCards (Total prestado | Activos | Vencidos)
   FilterChips: Todos | Activos | Vencidos | Pagados
   Lista con prestamosFiltradosProvider + PrestamoCard
   FAB → /prestamos/nuevo
   Pull to refresh

3. lib/screens/prestamos/detalle_prestamo_screen.dart
   AppBar + botón editar
   Card resumen del préstamo con LinearProgressIndicator
   TABLA DE CUOTAS completa (cuotasPrestamoProvider(id))
   Usando DataTable o ListView con TablaAmortizacion widget
   Botón "Registrar pago" → /pagos/nuevo?prestamoId=X&clienteId=Y
   Banner rojo si vencido
   Botón "Generar finiquito" si saldo = 0
```

## PROMPT 0F — Pagos con comprobante foto y WhatsApp automático

```
Genera el módulo de pagos para Capital Pro.

1. lib/screens/pagos/pagos_screen.dart
   Header: 3 StatCards (Cobrado mes | Pendiente | Completados mes)
   FilterChips: Todos | Pendiente | Completado | Cancelado
   SearchBar por cliente o concepto
   Lista con pagosFiltradosProvider + PagoListTile
   Swipe para eliminar con ConfirmDialog
   FAB → /pagos/nuevo
   Pull to refresh

2. lib/screens/pagos/form_pago_screen.dart
   Si clienteId en query → preseleccionar cliente
   Si prestamoId en query → preseleccionar préstamo y cuota actual
   
   Campos:
   - Cliente* (Dropdown, lista de clientesProvider)
   - Préstamo (Dropdown opcional — filtra préstamos activos del cliente)
   - Al seleccionar préstamo → mostrar cuota actual y saldo pendiente
   - Monto* (numérico, default = cuota mensual si hay préstamo)
   - Fecha* (DatePicker, default hoy)
   
   MÉTODO DE PAGO (SegmentedButton 2 opciones):
   [💵 Efectivo]  [🏦 Transferencia/Depósito]
   
   Si Transferencia → mostrar:
     "Comprobante de pago:" + botón imagen
     → image_picker: cámara o galería
     → preview circular de la imagen seleccionada
   
   - Concepto* (TextFormField, auto-fill "Cuota No. X" si hay préstamo)
   - Notas (opcional)
   
   Al guardar:
   → crear pago en DB
   → si tiene prestamoId → PrestamoRepository.registrarPago(id, monto)
   → marcar cuota en tabla_pagos como pagada
   → CarpetaService.generarReciboPago(pago, cliente, cuota, prestamo)
   → WhatsAppService.enviarMensaje(cliente.telefono, mensajeConfirmacion, ctx)
   → si préstamo pagado → CarpetaService.generarFiniquito(cliente, prestamo)
   → AppSnackBar con mensaje y botón "Compartir recibo"
   → ref.invalidate(pagosProvider) + ref.invalidate(prestamosProvider)
   → context.pop()

3. lib/screens/pagos/detalle_pago_screen.dart
   Card datos del pago
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
