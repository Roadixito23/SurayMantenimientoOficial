import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantencion.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';
import '../../../../main.dart';

class HistorialMantencionMobileLayout extends StatefulWidget {
  final Bus bus;

  HistorialMantencionMobileLayout({required this.bus});

  @override
  _HistorialMantencionMobileLayoutState createState() => _HistorialMantencionMobileLayoutState();
}

class _HistorialMantencionMobileLayoutState extends State<HistorialMantencionMobileLayout> {
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

    mantenciones.sort((a, b) => b.fecha.compareTo(a.fecha));
    return mantenciones;
  }

  void _editarMantencion(Mantencion mantencion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MantencionFormSheet(
        bus: _bus,
        mantencion: mantencion,
        onGuardar: (Mantencion updatedMantencion) async {
          setState(() {
            final index = _bus.historialMantenciones.indexWhere((m) => m.id == updatedMantencion.id);
            if (index != -1) {
              _bus.historialMantenciones[index] = updatedMantencion;
            }
          });
          await DataService.updateBus(_bus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mantenimiento actualizado'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadBusData();
        },
      ),
    );
  }

  void _eliminarMantencion(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Eliminar este mantenimiento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _bus.historialMantenciones.removeWhere((m) => m.id == id);
      });
      await DataService.updateBus(_bus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mantenimiento eliminado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historial Mantenimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_bus.identificadorDisplay, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [SurayColors.azulMarinoProfundo, SurayColors.azulMarinoProfundo.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      decoration: InputDecoration(
                        labelText: 'Filtrar',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                      items: ['Todas', 'Completadas', 'En progreso'].map((value) {
                        return DropdownMenuItem(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (value) => setState(() => _filtroEstado = value!),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _MantencionFormSheet(
                        bus: _bus,
                        onGuardar: (Mantencion nuevaMantencion) async {
                          setState(() {
                            _bus.historialMantenciones.add(nuevaMantencion);
                          });
                          await DataService.updateBus(_bus);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mantenimiento agregado'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadBusData();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SurayColors.azulMarinoProfundo,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _mantencionesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text('No hay mantenimientos registrados', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _mantencionesFiltradas.length,
                    itemBuilder: (context, index) => _buildMantencionCard(_mantencionesFiltradas[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMantencionCard(Mantencion mantencion) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: mantencion.completada ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    mantencion.completada ? 'Completada' : 'En Progreso',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  backgroundColor: mantencion.completada ? Colors.green : Colors.orange,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  ChileanUtils.formatDate(mantencion.fecha),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              mantencion.descripcion,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.build, size: 14, color: Colors.grey[600]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mantencion.repuestosUsados.isEmpty ? 'Sin repuestos' : mantencion.repuestosUsados.join(', '),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (mantencion.costoTotal != null) ...[
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    '\$${ChileanUtils.formatCurrency(mantencion.costoTotal!)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editarMantencion(mantencion),
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Editar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _eliminarMantencion(mantencion.id),
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MantencionFormSheet extends StatefulWidget {
  final Bus bus;
  final Mantencion? mantencion;
  final Function(Mantencion) onGuardar;

  _MantencionFormSheet({required this.bus, this.mantencion, required this.onGuardar});

  @override
  __MantencionFormSheetState createState() => __MantencionFormSheetState();
}

class __MantencionFormSheetState extends State<_MantencionFormSheet> {
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
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repuestosUsados = _repuestosController.text
          .split(',')
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList();

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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  widget.mantencion == null ? 'Nueva Mantención' : 'Editar Mantención',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty ? 'Ingrese descripción' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _repuestosController,
                          decoration: InputDecoration(
                            labelText: 'Repuestos (separados por coma)',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _costoController,
                          decoration: InputDecoration(
                            labelText: 'Costo Total (opcional)',
                            prefixText: '\$',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        SizedBox(height: 16),
                        InkWell(
                          onTap: () => _seleccionarFecha(context),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: SurayColors.azulMarinoProfundo),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fecha', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      Text(ChileanUtils.formatDate(_fechaSeleccionada),
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.edit, color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Completada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                              Switch(
                                value: _completada,
                                onChanged: (value) => setState(() => _completada = value),
                                activeColor: SurayColors.azulMarinoProfundo,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Cancelar'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _guardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SurayColors.azulMarinoProfundo,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
