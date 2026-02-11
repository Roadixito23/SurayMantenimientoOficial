import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../../models/bus.dart';
import '../../../services/data_service.dart';
import '../../../services/chilean_utils.dart';
import '../../../main.dart';
import '../../dialogs/bus_form/bus_form_dialog.dart';
import '../../dialogs/historial_completo/historial_completo_dialog.dart';
import '../../dialogs/mantenimiento_preventivo/mantenimiento_preventivo_dialog.dart';
import '../../dialogs/asignar_repuesto/asignar_repuesto_dialog.dart';
import '../../dialogs/ver_repuestos/ver_repuestos_dialog.dart';
import '../../../widgets/actualizar_kilometraje_dialog.dart';
import '../../widgets/buses/buses_widgets.dart';
import 'layouts/buses_desktop_layout.dart';
import 'layouts/buses_mobile_layout.dart';

// =====================================================================
// === BUSES SCREEN - Punto de entrada responsive =====================
// =====================================================================
// Maneja estado, stream de datos, diálogos y delega renderizado
// al layout correspondiente según el tamaño de pantalla

class BusesScreen extends StatefulWidget {
  @override
  _BusesScreenState createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen>
    with TickerProviderStateMixin {
  // --- STATE & CONTROLLERS ---
  late AnimationController _fadeAnimationController;

  int _currentPage = 0;
  int _itemsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // --- ORDENAMIENTO ---
  List<Bus> _ordenarBuses(List<Bus> buses) {
    buses.sort((a, b) => a.patente.compareTo(b.patente));
    return buses;
  }

  // --- CALLBACK: cambiar página ---
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  // --- CALLBACK: tap en un bus (abre diálogo de acciones) ---
  void _onBusTap(Bus bus) {
    showBusActionsDialog(
      context: context,
      bus: bus,
      onActualizarKilometraje: _actualizarKilometraje,
      onActualizarRevisionTecnica: _actualizarRevisionTecnica,
      onRegistrarMantenimiento: _registrarMantenimiento,
      onAsignarRepuesto: _asignarRepuesto,
      onVerRepuestos: _verRepuestos,
      onMostrarHistorial: _mostrarHistorialCompleto,
      onEditarBus: _mostrarDialogoBus,
      onEliminarBus: _eliminarBus,
    );
  }
  

  // --- REFRESH para mobile pull-to-refresh ---
  Future<void> _onRefresh() async {
    // El stream se actualiza automáticamente, pero forzamos rebuild
    setState(() {});
    await Future.delayed(Duration(milliseconds: 300));
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoBus(context),
        icon: Icon(Icons.add),
        label: Text('Nuevo Bus'),
        backgroundColor: SurayColors.naranjaQuemado,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<List<Bus>>(
        stream: DataService.getBusesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final allBuses = _ordenarBuses(snapshot.data ?? []);
          final total = allBuses.length;
          final totalPages = (total / _itemsPerPage).ceil();
          if (_currentPage >= totalPages && totalPages > 0) {
            _currentPage = totalPages - 1;
          }

          final start = (_currentPage * _itemsPerPage).clamp(0, total);
          final end = ((start + _itemsPerPage)).clamp(0, total);
          final pageBuses = allBuses.sublist(start, end);

          return FadeTransition(
            opacity: _fadeAnimationController,
            child: ResponsiveBuilder(
              mobile: (context) => BusesMobileLayout(
                pageBuses: pageBuses,
                totalItems: total,
                currentPage: _currentPage,
                totalPages: totalPages > 0 ? totalPages : 1,
                onPageChanged: _onPageChanged,
                onBusTap: _onBusTap,
                onRefresh: _onRefresh,
              ),
              desktop: (context) => BusesDesktopLayout(
                pageBuses: pageBuses,
                totalItems: total,
                currentPage: _currentPage,
                totalPages: totalPages > 0 ? totalPages : 1,
                onPageChanged: _onPageChanged,
                onBusTap: _onBusTap,
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================================================================
  // === ESTADOS DE CARGA / ERROR =====================================
  // ===================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: SurayColors.azulMarinoProfundo,
            strokeWidth: 4,
          ),
          SizedBox(height: 24),
          Text(
            'Cargando buses...',
            style: TextStyle(
              color: SurayColors.grisAntracita,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(32),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error al cargar buses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: SurayColors.azulMarinoProfundo,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: SurayColors.grisAntracita),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reconectando...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SurayColors.azulMarinoProfundo,
                foregroundColor: SurayColors.blancoHumo,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // === ACCIONES / DIÁLOGOS ==========================================
  // ===================================================================

  void _mostrarDialogoBus(BuildContext context, {Bus? bus}) {
    BusFormDialog.show(context, bus: bus).then((result) async {
      if (result == null) return;
      try {
        if (bus == null) {
          await DataService.addBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bus creado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          await DataService.updateBus(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bus actualizado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  void _registrarMantenimiento(BuildContext context, Bus bus) {
    MantenimientoPreventivoDialog.show(context, bus: bus);
  }

  void _actualizarKilometraje(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: ActualizarKilometrajeDialog(bus: bus),
            ),
          );
        },
      ),
    );
  }

  void _actualizarRevisionTecnica(BuildContext context, Bus bus) {
    final TextEditingController fechaController = TextEditingController();
    DateTime? fechaSeleccionada = bus.fechaRevisionTecnica;

    if (fechaSeleccionada != null) {
      fechaController.text = ChileanUtils.formatDate(fechaSeleccionada);
    }

    showDialog(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (ctx) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revisión Técnica',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bus.patente,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualizar fecha de revisión técnica',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: SurayColors.grisAntracita,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: fechaController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha de Revisión Técnica',
                          hintText: 'Seleccione una fecha',
                          prefixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF00897B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color(0xFF00897B), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color(0xFF00897B).withOpacity(0.3),
                                width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Color(0xFF00897B), width: 2),
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: fechaSeleccionada ??
                                DateTime.now().add(Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 730)),
                            locale: Locale('es', 'CL'),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Color(0xFF00897B),
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: SurayColors.grisAntracita,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            fechaSeleccionada = picked;
                            fechaController.text =
                                ChileanUtils.formatDate(picked);
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      if (fechaSeleccionada != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF00897B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Color(0xFF00897B).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF00897B), size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vigencia hasta: ${ChileanUtils.formatDate(fechaSeleccionada!)}',
                                  style: TextStyle(
                                    color: Color(0xFF00897B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: SurayColors.grisAntracita),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (fechaSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Por favor seleccione una fecha'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final busActualizado = bus.copyWith(
                          fechaRevisionTecnica: fechaSeleccionada,
                        );
                        await DataService.updateBus(busActualizado);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                    'Revisión técnica actualizada correctamente'),
                              ],
                            ),
                            backgroundColor: Color(0xFF00897B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 8),
                        Text('Guardar'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _asignarRepuesto(BuildContext context, Bus bus) {
    AsignarRepuestoDialog.show(
      context,
      bus: bus,
      onRepuestoAsignado: () {
        // Refresh data
        setState(() {});
      },
    );
  }

  void _verRepuestos(BuildContext context, Bus bus) {
    VerRepuestosDialog.show(
      context,
      bus: bus,
      onRepuestoModificado: () {
        // Refresh data si es necesario
        setState(() {});
      },
    );
  }

  void _mostrarHistorialCompleto(BuildContext context, Bus bus) {
    HistorialCompletoDialog.show(context, bus: bus);
  }

  Future<void> _eliminarBus(String id) async {
    final bus = await DataService.getBusById(id);
    if (bus == null) return;

    final conf = await showDialog<bool>(
      context: context,
      barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Confirmar eliminación'),
                  ],
                ),
                content: Text(
                  '¿Estás seguro de eliminar el bus ${bus.patente}?\n\nEsta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 15),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(_, false),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(_, true),
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (conf == true) {
      try {
        await DataService.deleteBus(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus eliminado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

// =====================================================================
// === DIÁLOGO DE CONFIGURACIÓN DE MANTENIMIENTO ======================
// =====================================================================

class MaintenanceConfigDialog extends StatefulWidget {
  final VoidCallback? onConfigChanged;

  MaintenanceConfigDialog({this.onConfigChanged});

  @override
  _MaintenanceConfigDialogState createState() =>
      _MaintenanceConfigDialogState();
}

class _MaintenanceConfigDialogState extends State<MaintenanceConfigDialog> {
  late TextEditingController _kmController;
  late TextEditingController _diasController;

  @override
  void initState() {
    super.initState();
    _kmController = TextEditingController(
        text: MantenimientoConfig.kilometrajeIdeal.toString());
    _diasController = TextEditingController(
        text: MantenimientoConfig.diasFechaIdeal.toString());
  }

  @override
  void dispose() {
    _kmController.dispose();
    _diasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SurayColors.azulMarinoProfundo,
              SurayColors.azulMarinoClaro,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.settings, color: SurayColors.blancoHumo),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Configuración de Mantenimiento',
                style: TextStyle(
                  color: SurayColors.blancoHumo,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalos de Mantenimiento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: SurayColors.azulMarinoProfundo,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Configura los intervalos para calcular el kilometraje ideal y la fecha ideal de mantenimiento.',
                      style: TextStyle(
                        fontSize: 14,
                        color: SurayColors.grisAntracita,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kilometraje ideal para mantenimiento',
                  suffixText: 'km',
                  prefixIcon:
                      Icon(Icons.speed, color: SurayColors.azulMarinoProfundo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Intervalo en kilómetros entre mantenimientos',
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _diasController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Días ideales para mantenimiento',
                  suffixText: 'días',
                  prefixIcon: Icon(Icons.calendar_today,
                      color: SurayColors.azulMarinoProfundo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Intervalo en días entre mantenimientos',
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SurayColors.naranjaQuemado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SurayColors.naranjaQuemado.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: SurayColors.naranjaQuemado),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los cambios se aplicarán inmediatamente a todos los buses en la tabla.',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.naranjaQuemado,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveConfig,
          style: ElevatedButton.styleFrom(
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: SurayColors.blancoHumo,
          ),
          child: Text('Guardar'),
        ),
      ],
    );
  }

  void _saveConfig() {
    final km = int.tryParse(_kmController.text);
    final dias = int.tryParse(_diasController.text);

    if (km == null || km <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El kilometraje debe ser un número positivo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (dias == null || dias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Los días deben ser un número positivo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    MantenimientoConfig.kilometrajeIdeal = km;
    MantenimientoConfig.diasFechaIdeal = dias;

    widget.onConfigChanged?.call();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuración guardada exitosamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
