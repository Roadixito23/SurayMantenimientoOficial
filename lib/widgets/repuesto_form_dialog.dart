import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repuesto.dart';
import '../services/data_service.dart';

class RepuestoFormDialog extends StatefulWidget {
  final RepuestoCatalogo? repuesto;

  RepuestoFormDialog({this.repuesto});

  @override
  _RepuestoFormDialogState createState() => _RepuestoFormDialogState();
}

class _RepuestoFormDialogState extends State<RepuestoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _codigoController;
  late TextEditingController _descripcionController;
  late TextEditingController _fabricanteController;
  late TextEditingController _numeroOEMController;
  late TextEditingController _precioController;
  late TextEditingController _observacionesController;

  late SistemaVehiculo _sistema;
  late TipoRepuesto _tipo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.repuesto?.nombre ?? '');
    _codigoController = TextEditingController(text: widget.repuesto?.codigo ?? '');
    _descripcionController = TextEditingController(text: widget.repuesto?.descripcion ?? '');
    _fabricanteController = TextEditingController(text: widget.repuesto?.fabricante ?? '');
    _numeroOEMController = TextEditingController(text: widget.repuesto?.numeroOEM ?? '');
    _precioController = TextEditingController(text: widget.repuesto?.precioReferencial?.toString() ?? '');
    _observacionesController = TextEditingController(text: widget.repuesto?.observaciones ?? '');

    _sistema = widget.repuesto?.sistema ?? SistemaVehiculo.motor;
    _tipo = widget.repuesto?.tipo ?? TipoRepuesto.original;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _descripcionController.dispose();
    _fabricanteController.dispose();
    _numeroOEMController.dispose();
    _precioController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.repuesto != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.add,
            color: Color(0xFF1565C0),
          ),
          SizedBox(width: 8),
          Text(isEditing ? 'Editar Repuesto' : 'Nuevo Repuesto'),
        ],
      ),
      content: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica
                Text(
                  'Información Básica',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
                SizedBox(height: 16),

                // Nombre y código
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Repuesto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _codigoController,
                        decoration: InputDecoration(
                          labelText: 'Código',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El código es requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Sistema y tipo
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SistemaVehiculo>(
                        value: _sistema,
                        decoration: InputDecoration(
                          labelText: 'Sistema',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: SistemaVehiculo.values.map((sistema) {
                          return DropdownMenuItem(
                            value: sistema,
                            child: Text(_getSistemaLabel(sistema)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _sistema = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TipoRepuesto>(
                        value: _tipo,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                        items: TipoRepuesto.values.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Text(_getTipoLabel(tipo)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipo = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Información del proveedor
                Text(
                  'Información del Proveedor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
                SizedBox(height: 16),

                // Fabricante y número OEM
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fabricanteController,
                        decoration: InputDecoration(
                          labelText: 'Fabricante',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.factory),
                          hintText: 'Opcional',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numeroOEMController,
                        decoration: InputDecoration(
                          labelText: 'Número OEM',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'Opcional',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Precio referencial
                TextFormField(
                  controller: _precioController,
                  decoration: InputDecoration(
                    labelText: 'Precio Referencial (CLP)',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'Opcional',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 24),

                // Observaciones
                Text(
                  'Información Adicional',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _observacionesController,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Notas adicionales, precauciones, instrucciones...',
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
          onPressed: _isLoading ? null : _guardarRepuesto,
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
              : Text('Guardar'),
        ),
      ],
    );
  }

  String _getSistemaLabel(SistemaVehiculo sistema) {
    switch (sistema) {
      case SistemaVehiculo.motor:
        return 'Motor';
      case SistemaVehiculo.transmision:
        return 'Transmisión';
      case SistemaVehiculo.frenos:
        return 'Frenos';
      case SistemaVehiculo.suspension:
        return 'Suspensión';
      case SistemaVehiculo.electrico:
        return 'Sistema Eléctrico';
      case SistemaVehiculo.neumaticos:
        return 'Neumáticos y Ruedas';
      case SistemaVehiculo.carroceria:
        return 'Carrocería';
      case SistemaVehiculo.climatizacion:
        return 'Climatización';
      case SistemaVehiculo.combustible:
        return 'Sistema de Combustible';
      case SistemaVehiculo.refrigeracion:
        return 'Refrigeración';
    }
  }

  String _getTipoLabel(TipoRepuesto tipo) {
    switch (tipo) {
      case TipoRepuesto.original:
        return 'Original (OEM)';
      case TipoRepuesto.alternativo:
        return 'Alternativo';
      case TipoRepuesto.generico:
        return 'Genérico';
    }
  }

  void _guardarRepuesto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    try {
      final repuesto = RepuestoCatalogo(
        id: widget.repuesto?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().toUpperCase(),
        descripcion: _descripcionController.text.trim(),
        sistema: _sistema,
        tipo: _tipo,
        fabricante: _fabricanteController.text.trim().isEmpty ? null : _fabricanteController.text.trim(),
        numeroOEM: _numeroOEMController.text.trim().isEmpty ? null : _numeroOEMController.text.trim(),
        precioReferencial: _precioController.text.isEmpty ? null : int.parse(_precioController.text),
        observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
        fechaActualizacion: DateTime.now(),
      );

      if (widget.repuesto == null) {
        await DataService.addRepuestoCatalogo(repuesto);
      } else {
        await DataService.updateRepuestoCatalogo(repuesto);
      }

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.repuesto == null
                ? 'Repuesto ${repuesto.nombre} agregado al catálogo'
                : 'Repuesto ${repuesto.nombre} actualizado en el catálogo',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el repuesto: $e'),
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
}