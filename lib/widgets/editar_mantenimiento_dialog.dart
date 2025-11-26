import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus.dart';
import '../models/mantenimiento_preventivo.dart';
import '../models/tipo_mantenimiento_personalizado.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import 'tipo_mantenimiento_selector.dart';

class EditarMantenimientoDialog extends StatefulWidget {
  final Bus bus;
  final RegistroMantenimiento registroParaEditar;
  final Function() onMantenimientoGuardado;

  const EditarMantenimientoDialog({
    Key? key,
    required this.bus,
    required this.registroParaEditar,
    required this.onMantenimientoGuardado,
  }) : super(key: key);

  @override
  _EditarMantenimientoDialogState createState() =>
      _EditarMantenimientoDialogState();
}

class _EditarMantenimientoDialogState extends State<EditarMantenimientoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kilometrajeController;
  late TextEditingController _tecnicoController;
  late TextEditingController _observacionesController;
  late TextEditingController _marcaRepuestoController;

  DateTime _fechaMantenimiento = DateTime.now();
  String _tituloMantenimiento = '';
  TipoMantenimiento _tipoMantenimiento = TipoMantenimiento.preventivo;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final registro = widget.registroParaEditar;

    _kilometrajeController = TextEditingController(text: registro.kilometrajeUltimoCambio.toString());
    _tecnicoController = TextEditingController(text: registro.tecnicoResponsable ?? '');
    _observacionesController = TextEditingController(text: registro.observaciones ?? '');
    _marcaRepuestoController = TextEditingController(text: registro.marcaRepuesto ?? '');

    _fechaMantenimiento = registro.fechaUltimoCambio;
    _tituloMantenimiento = registro.descripcionTipo;
    _tipoMantenimiento = registro.tipoMantenimientoEfectivo;
  }

  @override
  void dispose() {
    _kilometrajeController.dispose();
    _tecnicoController.dispose();
    _observacionesController.dispose();
    _marcaRepuestoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final registroActualizado = RegistroMantenimiento(
        id: widget.registroParaEditar.id,
        fechaUltimoCambio: _fechaMantenimiento,
        kilometrajeUltimoCambio: double.parse(_kilometrajeController.text),
        tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty ? null : _marcaRepuestoController.text.trim(),
        tipoMantenimiento: _tipoMantenimiento,
        tituloPersonalizado: _tituloMantenimiento,
        // Campos que no se editan pero se mantienen
        tipoFiltro: widget.registroParaEditar.tipoFiltro,
        tipoMantenimientoPersonalizadoId: widget.registroParaEditar.tipoMantenimientoPersonalizadoId,
      );

      await DataService.updateMantenimientoRegistro(widget.bus.id, registroActualizado);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mantenimiento actualizado exitosamente'), backgroundColor: Colors.green),
      );

      widget.onMantenimientoGuardado();
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar cambios: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Icon(Icons.edit, color: Color(0xFF1565C0)),
        SizedBox(width: 8),
        Text('Editar Mantenimiento'),
      ]),
      content: Container(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // No se puede cambiar el tipo de un mantenimiento ya registrado, solo sus detalles.
                // Por eso, mostramos la información del tipo pero no el selector completo.
                Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tipo de Mantenimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Título: $_tituloMantenimiento'),
                        Text('Categoría: ${_tipoMantenimiento.name}'),
                      ],
                    )
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _kilometrajeController,
                  decoration: InputDecoration(
                    labelText: 'Kilometraje de Referencia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v == null || v.isEmpty) ? 'El kilometraje es requerido' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _tecnicoController,
                  decoration: InputDecoration(
                    labelText: 'Técnico Responsable',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _marcaRepuestoController,
                  decoration: InputDecoration(
                    labelText: 'Marca del Repuesto/Material (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.branding_watermark),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _guardarCambios,
          child: _isLoading ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)) : Text('Guardar Cambios'),
        ),
      ],
    );
  }
}