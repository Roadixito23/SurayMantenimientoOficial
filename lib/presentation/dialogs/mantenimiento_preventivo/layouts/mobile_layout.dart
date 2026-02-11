import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';
import '../../../../widgets/tipo_mantenimiento_selector.dart';
import '../../../../main.dart';

class MantenimientoPreventivoMobileLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onMantenimientoRegistrado;

  MantenimientoPreventivoMobileLayout({
    required this.bus,
    this.onMantenimientoRegistrado,
  });

  @override
  _MantenimientoPreventivoMobileLayoutState createState() =>
      _MantenimientoPreventivoMobileLayoutState();
}

class _MantenimientoPreventivoMobileLayoutState
    extends State<MantenimientoPreventivoMobileLayout> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tecnicoController;
  late TextEditingController _observacionesController;
  late TextEditingController _marcaRepuestoController;

  TipoMantenimiento _tipoMantenimiento = TipoMantenimiento.preventivo;
  String _tituloMantenimiento = '';
  String? _descripcionMantenimiento;

  TipoMotor _tipoMotor = TipoMotor.diesel;
  bool _isLoading = false;

  DateTime _fechaMantenimiento = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tecnicoController = TextEditingController();
    _observacionesController = TextEditingController();
    _marcaRepuestoController = TextEditingController();

    if (widget.bus.mantenimientoPreventivo != null) {
      _tipoMotor = widget.bus.mantenimientoPreventivo!.tipoMotor;
    }
  }

  @override
  void dispose() {
    _tecnicoController.dispose();
    _observacionesController.dispose();
    _marcaRepuestoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar Mantenimiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.bus.identificadorDisplay,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SurayColors.azulMarinoProfundo,
                SurayColors.azulMarinoProfundo.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado actual del bus
                    _buildEstadoActualWidget(),
                    SizedBox(height: 20),

                    // Selector de tipo de mantenimiento
                    Text(
                      'Tipo de Mantenimiento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SurayColors.grisAntracita,
                      ),
                    ),
                    SizedBox(height: 8),

                    TipoMantenimientoSelector(
                      tipoMantenimientoInicial: _tipoMantenimiento,
                      tituloInicial: _tituloMantenimiento,
                      descripcionInicial: _descripcionMantenimiento,
                      onChanged: (tipoBase, titulo, descripcion) {
                        setState(() {
                          _tipoMantenimiento = tipoBase;
                          _tituloMantenimiento = titulo;
                          _descripcionMantenimiento = descripcion;
                        });
                      },
                    ),

                    SizedBox(height: 20),

                    // Último mantenimiento
                    _buildUltimoMantenimientoWidget(),

                    SizedBox(height: 20),

                    // Fecha del mantenimiento
                    Text(
                      'Fecha del Mantenimiento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SurayColors.grisAntracita,
                      ),
                    ),
                    SizedBox(height: 8),

                    InkWell(
                      onTap: _seleccionarFechaMantenimiento,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: SurayColors.azulMarinoProfundo),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha del mantenimiento',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    ChileanUtils.formatDate(
                                        _fechaMantenimiento),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Técnico responsable
                    TextFormField(
                      controller: _tecnicoController,
                      decoration: InputDecoration(
                        labelText: 'Técnico Responsable',
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: SurayColors.azulMarinoProfundo, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),

                    SizedBox(height: 16),

                    // Marca del repuesto
                    TextFormField(
                      controller: _marcaRepuestoController,
                      decoration: InputDecoration(
                        labelText: 'Marca del Repuesto/Material',
                        hintText: 'Ej: Mann Filter, Bosch...',
                        hintStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.branding_watermark),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: SurayColors.azulMarinoProfundo, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),

                    SizedBox(height: 16),

                    // Observaciones
                    TextFormField(
                      controller: _observacionesController,
                      decoration: InputDecoration(
                        labelText: 'Observaciones',
                        hintText: 'Detalles del mantenimiento...',
                        hintStyle: TextStyle(fontSize: 13),
                        prefixIcon: Icon(Icons.note),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: SurayColors.azulMarinoProfundo, width: 2),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Botones de acción fijos
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registrarMantenimiento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SurayColors.azulMarinoProfundo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Registrar',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoActualWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.directions_bus, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bus.identificadorDisplay,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue[900]),
                    ),
                    Text(
                      '${widget.bus.marca} ${widget.bus.modelo}',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              _buildEstadoChip(),
            ],
          ),
          if (widget.bus.kilometraje != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: Colors.blue[700]),
                SizedBox(width: 6),
                Text(
                  'Kilometraje: ${widget.bus.kilometraje!.round()} km',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (widget.bus.totalMantenimientosRealizados > 0) ...[
            SizedBox(height: 12),
            Text(
              'Historial:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Colors.blue[700]),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.bus.estadisticasMantenimientosPorTipo.entries
                  .map((entry) {
                if (entry.value == 0) return SizedBox.shrink();
                return Chip(
                  avatar: Icon(_getIconoTipo(entry.key),
                      size: 12, color: Colors.white),
                  label: Text(
                    '${_getLabelTipo(entry.key)}: ${entry.value}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: _getColorTipo(entry.key),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoChip() {
    Color color;
    String label;
    IconData icon;

    switch (widget.bus.estado) {
      case EstadoBus.disponible:
        color = Colors.green;
        label = 'Disponible';
        icon = Icons.check_circle;
        break;
      case EstadoBus.enReparacion:
        color = Colors.orange;
        label = 'En Reparación';
        icon = Icons.build;
        break;
      case EstadoBus.fueraDeServicio:
        color = Colors.red;
        label = 'Fuera de Servicio';
        icon = Icons.cancel;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildUltimoMantenimientoWidget() {
    final ultimoMantenimiento = widget.bus.ultimoMantenimiento;

    if (ultimoMantenimiento == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin historial de mantenimientos',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconoTipo(ultimoMantenimiento.tipoMantenimientoEfectivo),
                color: _getColorTipo(
                    ultimoMantenimiento.tipoMantenimientoEfectivo),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Último Mantenimiento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildInfoRow('Tipo', ultimoMantenimiento.descripcionTipo),
          _buildInfoRow('Fecha',
              ChileanUtils.formatDate(ultimoMantenimiento.fechaUltimoCambio)),
          _buildInfoRow('Km',
              '${ultimoMantenimiento.kilometrajeUltimoCambio.round()} km'),
          if (ultimoMantenimiento.tecnicoResponsable != null)
            _buildInfoRow('Técnico', ultimoMantenimiento.tecnicoResponsable!),
          if (ultimoMantenimiento.marcaRepuesto != null)
            _buildInfoRow('Marca', ultimoMantenimiento.marcaRepuesto!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _seleccionarFechaMantenimiento() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaMantenimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha del mantenimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fecha != null) {
      setState(() {
        _fechaMantenimiento = fecha;
      });
    }
  }

  void _registrarMantenimiento() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tituloMantenimiento.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Especifica el título del mantenimiento'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final kilometrajeReferencia = widget.bus.kilometraje ?? 0.0;

      if (widget.bus.mantenimientoPreventivo == null) {
        await DataService.configurarMantenimientoPreventivo(
          busId: widget.bus.id,
          tipoMotor: _tipoMotor,
        );
      }

      final filtrosCriticos = [
        'Filtro de Aceite',
        'Filtro de Aire',
        'Filtro de Combustible'
      ];

      if (filtrosCriticos.contains(_tituloMantenimiento.trim())) {
        await DataService.registrarMantenimientoFiltroCritico(
          busId: widget.bus.id,
          tituloFiltro: _tituloMantenimiento.trim(),
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty
              ? null
              : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty
              ? null
              : _marcaRepuestoController.text.trim(),
        );
      } else {
        await DataService.registrarMantenimientoPersonalizado(
          busId: widget.bus.id,
          tituloMantenimiento: _tituloMantenimiento.trim(),
          descripcionMantenimiento: _descripcionMantenimiento,
          tipoMantenimiento: _tipoMantenimiento,
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty
              ? null
              : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty
              ? null
              : _marcaRepuestoController.text.trim(),
        );
      }

      Navigator.pop(context, true);

      final mensaje = filtrosCriticos.contains(_tituloMantenimiento.trim())
          ? 'Filtro "${_tituloMantenimiento}" registrado con monitoreo automático'
          : 'Mantenimiento "${_tituloMantenimiento}" registrado';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: filtrosCriticos.contains(_tituloMantenimiento.trim())
              ? Colors.orange
              : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      widget.onMantenimientoRegistrado?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconoTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Icons.handyman;
      case TipoMantenimiento.rutinario:
        return Icons.schedule;
      case TipoMantenimiento.preventivo:
        return Icons.build_circle;
    }
  }

  Color _getColorTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return Color(0xFFE53E3E);
      case TipoMantenimiento.rutinario:
        return Color(0xFF3182CE);
      case TipoMantenimiento.preventivo:
        return Color(0xFF38A169);
    }
  }

  String _getLabelTipo(TipoMantenimiento tipo) {
    switch (tipo) {
      case TipoMantenimiento.correctivo:
        return 'Correctivo';
      case TipoMantenimiento.rutinario:
        return 'Rutinario';
      case TipoMantenimiento.preventivo:
        return 'Preventivo';
    }
  }
}
