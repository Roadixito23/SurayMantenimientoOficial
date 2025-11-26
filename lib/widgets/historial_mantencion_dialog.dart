import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus.dart';
import '../models/mantencion.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';

class HistorialMantencionDialog extends StatefulWidget {
  final Bus bus;

  HistorialMantencionDialog({required this.bus});

  @override
  _HistorialMantencionDialogState createState() => _HistorialMantencionDialogState();
}

class _HistorialMantencionDialogState extends State<HistorialMantencionDialog> {
  late Bus _bus;
  String _filtroEstado = 'Todas';

  @override
  void initState() {
    super.initState();
    _bus = widget.bus;
  }

  List<Mantencion> get _mantencionesFiltradas {
    var mantenciones = _bus.historialMantenciones;

    if (_filtroEstado == 'Completadas') {
      mantenciones = mantenciones.where((m) => m.completada).toList();
    } else if (_filtroEstado == 'En progreso') {
      mantenciones = mantenciones.where((m) => !m.completada).toList();
    }

    // Ordenar por fecha descendente (más recientes primero)
    mantenciones.sort((a, b) => b.fecha.compareTo(a.fecha));

    return mantenciones;
  }

  // Función para editar una mantención (ya existente)
  void _editarMantencion(Mantencion mantencion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _MantencionFormDialog(
          bus: _bus,
          mantencion: mantencion,
          onGuardar: (Mantencion updatedMantencion) async {
            setState(() {
              // Actualizar la mantención en la lista del bus
              final index = _bus.historialMantenciones.indexWhere((m) => m.id == updatedMantencion.id);
              if (index != -1) {
                _bus.historialMantenciones[index] = updatedMantencion;
              }
            });
            await DataService.updateBus(_bus); // Guardar cambios en Firebase
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mantenimiento actualizado exitosamente.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    ).then((_) {
      // Recargar los datos del bus después de cerrar el diálogo de edición
      _loadBusData();
    });
  }

  // Función para eliminar una mantención
  void _eliminarMantencion(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar este registro de mantenimiento? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _bus.historialMantenciones.removeWhere((m) => m.id == id);
      });
      await DataService.updateBus(_bus); // Guardar cambios en Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mantenimiento eliminado exitosamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBusData() async {
    final updatedBus = await DataService.getBusById(widget.bus.id);
    if (updatedBus != null) {
      setState(() {
        _bus = updatedBus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.history, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Historial de Mantenimiento',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7, // Ajuste para web
        height: MediaQuery.of(context).size.height * 0.7,
        constraints: BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: <String>['Todas', 'Completadas', 'En progreso']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _filtroEstado = newValue!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return _MantencionFormDialog(
                            bus: _bus,
                            onGuardar: (Mantencion nuevaMantencion) async {
                              setState(() {
                                _bus.historialMantenciones.add(nuevaMantencion);
                              });
                              await DataService.updateBus(_bus);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Mantenimiento agregado exitosamente.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          );
                        },
                      ).then((_) {
                        _loadBusData(); // Recargar datos al cerrar el diálogo
                      });
                    },
                    icon: Icon(Icons.add_circle),
                    label: Text('Nueva Mantención'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _mantencionesFiltradas.isEmpty
                  ? Center(child: Text('No hay mantenimientos registrados.'))
                  : ListView.builder(
                itemCount: _mantencionesFiltradas.length,
                itemBuilder: (context, index) {
                  final mantencion = _mantencionesFiltradas[index];
                  return _buildMantencionItem(mantencion);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildMantencionItem(Mantencion mantencion) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    mantencion.completada ? 'Completada' : 'En Progreso',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: mantencion.completada ? Colors.green : Colors.orange,
                ),
                Text(
                  'Fecha: ${ChileanUtils.formatDate(mantencion.fecha)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Descripción: ${mantencion.descripcion}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Repuestos usados: ${mantencion.repuestosUsados.isEmpty ? 'Ninguno' : mantencion.repuestosUsados.join(', ')}',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            if (mantencion.costoTotal != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Costo Total: \$${ChileanUtils.formatCurrency(mantencion.costoTotal!)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarMantencion(mantencion),
                  tooltip: 'Editar Mantenimiento',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarMantencion(mantencion.id),
                  tooltip: 'Eliminar Mantenimiento',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _MantencionFormDialog (Ya existía, pero se asegura su uso consistente)
// -----------------------------------------------------------------------------
class _MantencionFormDialog extends StatefulWidget {
  final Bus bus;
  final Mantencion? mantencion; // Nullable para indicar si es nueva o edición
  final Function(Mantencion) onGuardar;

  _MantencionFormDialog({
    required this.bus,
    this.mantencion,
    required this.onGuardar,
  });

  @override
  __MantencionFormDialogState createState() => __MantencionFormDialogState();
}

class __MantencionFormDialogState extends State<_MantencionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descripcionController;
  late TextEditingController _repuestosController;
  late TextEditingController _costoController;
  late DateTime _fechaSeleccionada;
  late bool _completada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(text: widget.mantencion?.descripcion ?? '');
    _repuestosController = TextEditingController(text: widget.mantencion?.repuestosUsados.join(', ') ?? '');
    _costoController = TextEditingController(text: widget.mantencion?.costoTotal?.toString() ?? '');
    _fechaSeleccionada = widget.mantencion?.fecha ?? DateTime.now();
    _completada = widget.mantencion?.completada ?? false;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _repuestosController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    try {
      final repuestosUsados = _repuestosController.text
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList();

      // Manejar el costo, permitiendo valores vacíos
      final costoText = _costoController.text.trim();
      final costoTotal = costoText.isEmpty ? null : int.parse(costoText);

      final mantencion = Mantencion(
        id: widget.mantencion?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        fecha: _fechaSeleccionada,
        descripcion: _descripcionController.text.trim(),
        repuestosUsados: repuestosUsados,
        costoTotal: costoTotal,
        completada: _completada,
      );

      widget.onGuardar(mantencion);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar mantenimiento: $e'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.mantencion == null ? 'Nueva Mantención' : 'Editar Mantención'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del Mantenimiento',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _repuestosController,
                decoration: InputDecoration(
                  labelText: 'Repuestos usados (separados por coma)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _costoController,
                decoration: InputDecoration(
                  labelText: 'Costo Total (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Fecha: ${ChileanUtils.formatDate(_fechaSeleccionada)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _seleccionarFecha(context),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Completada:'),
                  SizedBox(width: 8),
                  Switch(
                    value: _completada,
                    onChanged: (bool value) {
                      setState(() {
                        _completada = value;
                      });
                    },
                  ),
                ],
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
          onPressed: _isLoading ? null : _guardar,
          child: _isLoading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}