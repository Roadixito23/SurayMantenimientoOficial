import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/repuesto.dart';
import '../../../../services/data_service.dart';

/// Mobile layout del formulario de repuesto - Fullscreen con scroll vertical
class RepuestoFormMobileLayout extends StatefulWidget {
  final RepuestoCatalogo? repuesto;

  const RepuestoFormMobileLayout({Key? key, this.repuesto}) : super(key: key);

  @override
  State<RepuestoFormMobileLayout> createState() =>
      _RepuestoFormMobileLayoutState();
}

class _RepuestoFormMobileLayoutState extends State<RepuestoFormMobileLayout> {
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

  // Control de secciones expandidas
  int _expandedSection = 0; // 0 = Básica, 1 = Proveedor, 2 = Adicional

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.repuesto?.nombre ?? '');
    _codigoController =
        TextEditingController(text: widget.repuesto?.codigo ?? '');
    _descripcionController =
        TextEditingController(text: widget.repuesto?.descripcion ?? '');
    _fabricanteController =
        TextEditingController(text: widget.repuesto?.fabricante ?? '');
    _numeroOEMController =
        TextEditingController(text: widget.repuesto?.numeroOEM ?? '');
    _precioController = TextEditingController(
        text: widget.repuesto?.precioReferencial?.toString() ?? '');
    _observacionesController =
        TextEditingController(text: widget.repuesto?.observaciones ?? '');

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3B5C), Color(0xFF2C5F8D)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFD97236),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Repuesto' : 'Nuevo Repuesto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isEditing)
                          Text(
                            widget.repuesto!.nombre,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Content con secciones expandibles
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Información Básica
                    _buildExpandableCard(
                      index: 0,
                      icon: Icons.info,
                      title: 'Información Básica',
                      content: _buildInformacionBasicaSection(),
                    ),
                    // Información del Proveedor
                    _buildExpandableCard(
                      index: 1,
                      icon: Icons.factory,
                      title: 'Información del Proveedor',
                      content: _buildProveedorSection(),
                    ),
                    // Información Adicional
                    _buildExpandableCard(
                      index: 2,
                      icon: Icons.note_add,
                      title: 'Información Adicional',
                      content: _buildAdicionalSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarRepuesto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Guardar'),
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

  Widget _buildExpandableCard({
    required int index,
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    final isExpanded = _expandedSection == index;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header clickeable
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? -1 : index;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: Color(0xFF1565C0)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          AnimatedCrossFade(
            firstChild: SizedBox.shrink(),
            secondChild: content,
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionBasicaSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del Repuesto
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del Repuesto',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
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
          SizedBox(height: 16),

          // Código
          TextFormField(
            controller: _codigoController,
            decoration: InputDecoration(
              labelText: 'Código',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
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
          SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
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

          // Sistema
          DropdownButtonFormField<SistemaVehiculo>(
            value: _sistema,
            decoration: InputDecoration(
              labelText: 'Sistema',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
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
          SizedBox(height: 16),

          // Tipo
          DropdownButtonFormField<TipoRepuesto>(
            value: _tipo,
            decoration: InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
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
        ],
      ),
    );
  }

  Widget _buildProveedorSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fabricante
          TextFormField(
            controller: _fabricanteController,
            decoration: InputDecoration(
              labelText: 'Fabricante',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.factory),
              helperText: 'Opcional',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16),

          // Número OEM
          TextFormField(
            controller: _numeroOEMController,
            decoration: InputDecoration(
              labelText: 'Número OEM',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.tag),
              helperText: 'Opcional',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),

          // Precio referencial
          TextFormField(
            controller: _precioController,
            decoration: InputDecoration(
              labelText: 'Precio Referencial (CLP)',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.attach_money),
              helperText: 'Opcional',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildAdicionalSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Observaciones
          TextFormField(
            controller: _observacionesController,
            decoration: InputDecoration(
              labelText: 'Observaciones',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.note),
              helperText: 'Notas adicionales, precauciones, instrucciones...',
            ),
            maxLines: 4,
          ),

          // Información del repuesto (solo para edición)
          if (widget.repuesto != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Registro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Última actualización: ${_formatDate(widget.repuesto!.fechaActualizacion)}',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
        id: widget.repuesto?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().toUpperCase(),
        descripcion: _descripcionController.text.trim(),
        sistema: _sistema,
        tipo: _tipo,
        fabricante: _fabricanteController.text.trim().isEmpty
            ? null
            : _fabricanteController.text.trim(),
        numeroOEM: _numeroOEMController.text.trim().isEmpty
            ? null
            : _numeroOEMController.text.trim(),
        precioReferencial:
            _precioController.text.isEmpty ? null : int.parse(_precioController.text),
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el repuesto: $e'),
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
}
