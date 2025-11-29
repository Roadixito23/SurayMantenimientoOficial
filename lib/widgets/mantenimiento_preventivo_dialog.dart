import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../widgets/tipo_mantenimiento_selector.dart';

class MantenimientoPreventivoDialog extends StatefulWidget {
  final Bus bus;
  final Function()? onMantenimientoRegistrado;

  MantenimientoPreventivoDialog({
    required this.bus,
    this.onMantenimientoRegistrado,
  });

  @override
  _MantenimientoPreventivoDialogState createState() => _MantenimientoPreventivoDialogState();
}

class _MantenimientoPreventivoDialogState extends State<MantenimientoPreventivoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tecnicoController;
  late TextEditingController _observacionesController;
  late TextEditingController _marcaRepuestoController;

  // Campos para tipos personalizados
  TipoMantenimiento _tipoMantenimiento = TipoMantenimiento.preventivo;
  String _tituloMantenimiento = '';
  String? _descripcionMantenimiento;

  TipoMotor _tipoMotor = TipoMotor.diesel;
  bool _isLoading = false;

  // Fecha del mantenimiento seleccionable
  DateTime _fechaMantenimiento = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tecnicoController = TextEditingController();
    _observacionesController = TextEditingController();
    _marcaRepuestoController = TextEditingController();

    // Cargar configuración actual del bus
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.build_circle, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar Mantenimiento'),
                Text(
                  '${widget.bus.identificadorDisplay}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: 700,
        constraints: BoxConstraints(maxHeight: 800),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado actual del bus
                _buildEstadoActualWidget(),
                SizedBox(height: 20),

                // Selector de tipo de mantenimiento personalizado
                Text(
                  'Tipo de Mantenimiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
                SizedBox(height: 12),

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

                // Información del mantenimiento anterior personalizado
                _buildUltimoMantenimientoPersonalizadoWidget(),

                SizedBox(height: 20),

                // Fecha del mantenimiento
                Text(
                  'Fecha del Mantenimiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
                SizedBox(height: 12),

                InkWell(
                  onTap: _seleccionarFechaMantenimiento,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha en que se realizó el mantenimiento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.edit),
                      helperText: 'Toca para cambiar la fecha',
                    ),
                    child: Text(
                      ChileanUtils.formatDate(_fechaMantenimiento),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Técnico responsable
                TextFormField(
                  controller: _tecnicoController,
                  decoration: InputDecoration(
                    labelText: 'Técnico Responsable',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                SizedBox(height: 16),

                // Marca del repuesto
                TextFormField(
                  controller: _marcaRepuestoController,
                  decoration: InputDecoration(
                    labelText: 'Marca del Repuesto/Material (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.branding_watermark),
                    hintText: 'Ej: Mann Filter, Bosch, etc.',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                SizedBox(height: 16),

                // Observaciones
                TextFormField(
                  controller: _observacionesController,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Detalles del mantenimiento realizado...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _registrarMantenimiento,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Text('Registrar Mantenimiento'),
        ),
      ],
    );
  }

  Widget _buildEstadoActualWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blue[700]),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.bus.identificadorDisplay} - ${widget.bus.marca} ${widget.bus.modelo}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    if (widget.bus.ubicacionActual != null)
                      Text('Ubicación: ${widget.bus.ubicacionActual}', style: TextStyle(fontSize: 12)),
                    if (widget.bus.kilometraje != null)
                      Text('Kilometraje actual: ${widget.bus.kilometraje!.round()} km', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              _buildEstadoChip(),
            ],
          ),

          SizedBox(height: 12),

          // Estadísticas de mantenimientos
          if (widget.bus.totalMantenimientosRealizados > 0) ...[
            Text(
              'Historial de Mantenimientos:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[700]),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: widget.bus.estadisticasMantenimientosPorTipo.entries.map((entry) {
                if (entry.value == 0) return SizedBox.shrink();
                return Chip(
                  avatar: Icon(_getIconoTipo(entry.key), size: 14, color: Colors.white),
                  label: Text(
                    '${_getLabelTipo(entry.key)}: ${entry.value}',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: _getColorTipo(entry.key),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ] else ...[
            Text(
              'Sin mantenimientos registrados',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Widget _buildUltimoMantenimientoPersonalizadoWidget() {
    final ultimoMantenimiento = widget.bus.ultimoMantenimiento;

    if (ultimoMantenimiento == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Este bus no tiene historial de mantenimientos registrados',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconoTipo(ultimoMantenimiento.tipoMantenimientoEfectivo),
                  color: _getColorTipo(ultimoMantenimiento.tipoMantenimientoEfectivo)),
              SizedBox(width: 8),
              Text(
                'Último Mantenimiento Realizado',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('Tipo: ${ultimoMantenimiento.descripcionTipo}'),
          Text('Fecha: ${ChileanUtils.formatDate(ultimoMantenimiento.fechaUltimoCambio)}'),
          Text('Kilometraje: ${ultimoMantenimiento.kilometrajeUltimoCambio.round()} km'),
          if (ultimoMantenimiento.tecnicoResponsable != null)
            Text('Técnico: ${ultimoMantenimiento.tecnicoResponsable}'),
          if (ultimoMantenimiento.marcaRepuesto != null)
            Text('Marca: ${ultimoMantenimiento.marcaRepuesto}'),
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

    // Validar que se haya seleccionado un título
    if (_tituloMantenimiento.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe especificar el título del mantenimiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el kilometraje actual del bus
      final kilometrajeReferencia = widget.bus.kilometraje ?? 0.0;

      // Configurar mantenimiento preventivo básico si es necesario
      if (widget.bus.mantenimientoPreventivo == null) {
        await DataService.configurarMantenimientoPreventivo(
          busId: widget.bus.id,
          tipoMotor: _tipoMotor,
        );
      }

      // ✅ NUEVO: Verificar si es un filtro crítico y usar método especializado
      final filtrosCriticos = ['Filtro de Aceite', 'Filtro de Aire', 'Filtro de Combustible'];

      if (filtrosCriticos.contains(_tituloMantenimiento.trim())) {
        // Usar método especializado para filtros críticos
        await DataService.registrarMantenimientoFiltroCritico(
          busId: widget.bus.id,
          tituloFiltro: _tituloMantenimiento.trim(),
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty ? null : _marcaRepuestoController.text.trim(),
        );

        print('✅ Filtro crítico registrado con seguimiento de kilometraje');
      } else {
        // Usar método estándar para otros tipos de mantenimiento
        await DataService.registrarMantenimientoPersonalizado(
          busId: widget.bus.id,
          tituloMantenimiento: _tituloMantenimiento.trim(),
          descripcionMantenimiento: _descripcionMantenimiento,
          tipoMantenimiento: _tipoMantenimiento,
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty ? null : _marcaRepuestoController.text.trim(),
        );
      }

      Navigator.pop(context, true);

      // ✅ MENSAJE DIFERENCIADO para filtros críticos
      final mensaje = filtrosCriticos.contains(_tituloMantenimiento.trim())
          ? 'Filtro crítico "${_tituloMantenimiento}" registrado para ${widget.bus.identificadorDisplay}. Ahora se monitoreará automáticamente.'
          : 'Mantenimiento "${_tituloMantenimiento}" registrado para ${widget.bus.identificadorDisplay}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: filtrosCriticos.contains(_tituloMantenimiento.trim()) ? Colors.orange : Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Llamar al callback para refrescar el estado
      widget.onMantenimientoRegistrado?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar mantenimiento: $e'),
          backgroundColor: Colors.red,
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

  // Métodos de utilidad
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