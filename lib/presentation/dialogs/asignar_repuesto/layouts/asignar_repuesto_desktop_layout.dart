import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/repuesto.dart';
import '../../../../models/repuesto_asignado.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';

class AsignarRepuestoDesktopLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onRepuestoAsignado;

  const AsignarRepuestoDesktopLayout({
    Key? key,
    required this.bus,
    this.onRepuestoAsignado,
  }) : super(key: key);

  @override
  State<AsignarRepuestoDesktopLayout> createState() => _AsignarRepuestoDesktopLayoutState();
}

class _AsignarRepuestoDesktopLayoutState extends State<AsignarRepuestoDesktopLayout> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cantidadController;
  late TextEditingController _ubicacionController;
  late TextEditingController _observacionesController;
  late TextEditingController _tecnicoController;
  late TextEditingController _busquedaController;

  RepuestoCatalogo? _repuestoSeleccionado;
  DateTime? _fechaInstalacion;
  DateTime? _proximoCambio;
  bool _instalado = false;
  bool _isLoading = false;
  String _filtroSistema = 'Todos';
  String _filtroBusqueda = '';

  List<RepuestoCatalogo> _catalogoRepuestos = [];
  List<RepuestoCatalogo> _repuestosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(text: '1');
    _ubicacionController = TextEditingController();
    _observacionesController = TextEditingController();
    _tecnicoController = TextEditingController();
    _busquedaController = TextEditingController();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _ubicacionController.dispose();
    _observacionesController.dispose();
    _tecnicoController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  void _cargarCatalogo() async {
    final catalogo = await DataService.getCatalogoRepuestos();
    setState(() {
      _catalogoRepuestos = catalogo;
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    var repuestos = List<RepuestoCatalogo>.from(_catalogoRepuestos);

    if (_filtroSistema != 'Todos') {
      repuestos = repuestos.where((r) => r.sistemaLabel == _filtroSistema).toList();
    }

    if (_filtroBusqueda.isNotEmpty) {
      final busquedaLower = _filtroBusqueda.toLowerCase();
      repuestos = repuestos.where((r) =>
      r.nombre.toLowerCase().contains(busquedaLower) ||
          r.codigo.toLowerCase().contains(busquedaLower) ||
          r.descripcion.toLowerCase().contains(busquedaLower)
      ).toList();
    }

    setState(() {
      _repuestosFiltrados = repuestos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_box, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Text('Asignar Repuesto a ${widget.bus.patente}'),
          ),
        ],
      ),
      content: Container(
        width: 800,
        height: 600,
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel izquierdo - Selección de repuesto
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar Repuesto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Filtros
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              labelText: 'Buscar repuesto',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _filtroBusqueda = value;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: _filtroSistema,
                            decoration: InputDecoration(
                              labelText: 'Sistema',
                              border: OutlineInputBorder(),
                            ),
                            items: _getSistemasDisponibles()
                                .map((sistema) => DropdownMenuItem(
                              value: sistema,
                              child: Text(sistema, style: TextStyle(fontSize: 12)),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _filtroSistema = value!;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Lista de repuestos
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _repuestosFiltrados.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No se encontraron repuestos'),
                            ],
                          ),
                        )
                            : ListView.builder(
                          itemCount: _repuestosFiltrados.length,
                          itemBuilder: (context, index) {
                            final repuesto = _repuestosFiltrados[index];
                            final isSelected = _repuestoSeleccionado?.id == repuesto.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blue[50],
                              leading: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _getSistemaColor(repuesto.sistema),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getSistemaIcon(repuesto.sistema),
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                repuesto.nombre,
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${repuesto.codigo} - ${repuesto.sistemaLabel}', style: TextStyle(fontSize: 12)),
                                  if (repuesto.precioReferencial != null)
                                    Text(
                                      ChileanUtils.formatCurrency(repuesto.precioReferencial!),
                                      style: TextStyle(fontSize: 12, color: Colors.green),
                                    ),
                                ],
                              ),
                              trailing: isSelected ? Icon(Icons.check_circle, color: Colors.blue) : null,
                              onTap: () {
                                setState(() {
                                  _repuestoSeleccionado = repuesto;
                                  _ubicacionController.text = _getUbicacionSugerida(repuesto.sistema);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // Panel derecho - Detalles de asignación
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles de Asignación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      SizedBox(height: 16),

                      if (_repuestoSeleccionado != null) ...[
                        // Información del repuesto seleccionado
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _repuestoSeleccionado!.nombre,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Código: ${_repuestoSeleccionado!.codigo}'),
                              Text('Sistema: ${_repuestoSeleccionado!.sistemaLabel}'),
                              if (_repuestoSeleccionado!.fabricante != null)
                                Text('Fabricante: ${_repuestoSeleccionado!.fabricante}'),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Formulario de asignación
                        TextFormField(
                          controller: _cantidadController,
                          decoration: InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La cantidad es requerida';
                            }
                            final cantidad = int.tryParse(value);
                            if (cantidad == null || cantidad <= 0) {
                              return 'Cantidad inválida';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),

                        TextFormField(
                          controller: _ubicacionController,
                          decoration: InputDecoration(
                            labelText: 'Ubicación en el vehículo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Ej: Motor, Eje delantero, etc.',
                          ),
                        ),
                        SizedBox(height: 12),

                        TextFormField(
                          controller: _tecnicoController,
                          decoration: InputDecoration(
                            labelText: 'Técnico responsable',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 12),

                        CheckboxListTile(
                          title: Text('Repuesto ya instalado'),
                          subtitle: Text('Marcar si el repuesto ya está instalado en el vehículo'),
                          value: _instalado,
                          onChanged: (value) {
                            setState(() {
                              _instalado = value!;
                              if (_instalado) {
                                _fechaInstalacion = DateTime.now();
                              } else {
                                _fechaInstalacion = null;
                                _proximoCambio = null;
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),

                        if (_instalado) ...[
                          SizedBox(height: 12),
                          InkWell(
                            onTap: _seleccionarFechaInstalacion,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Fecha de instalación',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _fechaInstalacion != null
                                    ? ChileanUtils.formatDate(_fechaInstalacion!)
                                    : 'Seleccionar fecha',
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          InkWell(
                            onTap: _seleccionarFechaProximoCambio,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Próximo cambio (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                              child: Text(
                                _proximoCambio != null
                                    ? ChileanUtils.formatDate(_proximoCambio!)
                                    : 'Seleccionar fecha',
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 12),
                        TextFormField(
                          controller: _observacionesController,
                          decoration: InputDecoration(
                            labelText: 'Observaciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                            hintText: 'Notas adicionales sobre la asignación...',
                          ),
                          maxLines: 3,
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.arrow_back, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Selecciona un repuesto',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Busca y selecciona un repuesto de la lista para continuar',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _repuestoSeleccionado == null ? null : _asignarRepuesto,
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
              : Text('Asignar Repuesto'),
        ),
      ],
    );
  }

  List<String> _getSistemasDisponibles() {
    final sistemas = <String>{'Todos'};
    for (final repuesto in _catalogoRepuestos) {
      sistemas.add(repuesto.sistemaLabel);
    }
    return sistemas.toList()..sort();
  }

  Color _getSistemaColor(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return Colors.red;
      case SistemaVehiculo.frenos:
        return Colors.orange;
      case SistemaVehiculo.transmision:
        return Colors.purple;
      case SistemaVehiculo.electrico:
        return Colors.yellow[700]!;
      case SistemaVehiculo.suspension:
        return Colors.green;
      case SistemaVehiculo.neumaticos:
        return Colors.black;
      case SistemaVehiculo.carroceria:
        return Colors.blue;
      case SistemaVehiculo.climatizacion:
        return Colors.cyan;
      case SistemaVehiculo.combustible:
        return Colors.brown;
      case SistemaVehiculo.refrigeracion:
        return Colors.lightBlue;
    }
  }

  IconData _getSistemaIcon(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return Icons.settings;
      case SistemaVehiculo.frenos:
        return Icons.disc_full;
      case SistemaVehiculo.transmision:
        return Icons.settings_applications;
      case SistemaVehiculo.electrico:
        return Icons.electrical_services;
      case SistemaVehiculo.suspension:
        return Icons.compare_arrows;
      case SistemaVehiculo.neumaticos:
        return Icons.tire_repair;
      case SistemaVehiculo.carroceria:
        return Icons.directions_bus;
      case SistemaVehiculo.climatizacion:
        return Icons.ac_unit;
      case SistemaVehiculo.combustible:
        return Icons.local_gas_station;
      case SistemaVehiculo.refrigeracion:
        return Icons.thermostat;
    }
  }

  String _getUbicacionSugerida(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return 'Compartimento Motor';
      case SistemaVehiculo.frenos:
        return 'Sistema Frenos';
      case SistemaVehiculo.transmision:
        return 'Caja Transmisión';
      case SistemaVehiculo.electrico:
        return 'Tablero Eléctrico';
      case SistemaVehiculo.suspension:
        return 'Eje Delantero';
      case SistemaVehiculo.neumaticos:
        return 'Ruedas';
      case SistemaVehiculo.carroceria:
        return 'Carrocería';
      case SistemaVehiculo.climatizacion:
        return 'Sistema A/C';
      case SistemaVehiculo.combustible:
        return 'Tanque Combustible';
      case SistemaVehiculo.refrigeracion:
        return 'Radiador';
    }
  }

  void _seleccionarFechaInstalacion() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInstalacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Fecha de instalación',
    );

    if (fecha != null) {
      setState(() {
        _fechaInstalacion = fecha;
      });
    }
  }

  void _seleccionarFechaProximoCambio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _proximoCambio ?? DateTime.now().add(Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
      helpText: 'Próximo cambio programado',
    );

    if (fecha != null) {
      setState(() {
        _proximoCambio = fecha;
      });
    }
  }

  void _asignarRepuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_repuestoSeleccionado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repuestoAsignado = RepuestoAsignado(
        id: '${widget.bus.id}_${_repuestoSeleccionado!.id}_${DateTime.now().millisecondsSinceEpoch}',
        repuestoCatalogoId: _repuestoSeleccionado!.id,
        busId: widget.bus.id,
        fechaAsignacion: DateTime.now(),
        cantidad: int.parse(_cantidadController.text),
        ubicacionBus: _ubicacionController.text.trim().isEmpty ? null : _ubicacionController.text.trim(),
        fechaInstalacion: _fechaInstalacion,
        proximoCambio: _proximoCambio,
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        instalado: _instalado,
        tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
      );

      await DataService.addRepuestoAsignado(repuestoAsignado);

      if (mounted) {
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_repuestoSeleccionado!.nombre} asignado a ${widget.bus.patente}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        widget.onRepuestoAsignado?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar repuesto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
