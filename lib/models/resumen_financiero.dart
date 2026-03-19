class ResumenFinanciero {
  final double totalCobradoMes;
  final double totalPrestado;
  final double saldoPendiente;
  final double interesDelMes;
  final int prestamosActivos;
  final int prestamosVencidos;
  final int totalClientes;
  final int clientesNuevosMes;
  final double tasaMorosidad;
  final Map<String, double> pagosPorMes;
  final Map<String, double> prestamosPorMes;
  final double interesesTotales;
  final double totalCobrado;

  ResumenFinanciero({
    this.totalCobradoMes = 0,
    this.totalPrestado = 0,
    this.saldoPendiente = 0,
    this.interesDelMes = 0,
    this.prestamosActivos = 0,
    this.prestamosVencidos = 0,
    this.totalClientes = 0,
    this.clientesNuevosMes = 0,
    this.tasaMorosidad = 0,
    this.pagosPorMes = const {},
    this.prestamosPorMes = const {},
    this.interesesTotales = 0,
    this.totalCobrado = 0,
  });
}
