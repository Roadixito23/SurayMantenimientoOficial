import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../services/data_service.dart';
import '../../../../services/chilean_utils.dart';
import '../widgets/bus_form_shared.dart';

/// Mobile layout del formulario de bus - Fullscreen con scroll vertical
class BusFormMobileLayout extends StatefulWidget {
  final Bus? bus;

  const BusFormMobileLayout({Key? key, this.bus}) : super(key: key);

  @override
  State<BusFormMobileLayout> createState() => _BusFormMobileLayoutState();
}

class _BusFormMobileLayoutState extends State<BusFormMobileLayout> {
  final _formKey = GlobalKey<FormState>();
  late BusFormData _formData;
  bool _isLoading = false;

  // Control de secciones expandidas
  int _expandedSection =
      0; // 0 = Información, 1 = Mantenimiento, 2 = Revisión Técnica

  @override
  void initState() {
    super.initState();
    _formData = BusFormData.fromBus(widget.bus);
  }

  @override
  void dispose() {
    _formData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bus != null;

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
                          isEditing ? 'Editar Vehículo' : 'Nuevo Vehículo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isEditing)
                          Text(
                            widget.bus!.identificadorDisplay,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
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

          // Content con ExpansionTiles (mejor interacción táctil)
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
                      content: _buildInformacionSection(),
                    ),
                    // Mantenimiento
                    _buildExpandableCard(
                      index: 1,
                      icon: Icons.build_circle,
                      title: 'Mantenimiento',
                      content: _buildMantenimientoSection(),
                    ),
                    // Revisión Técnica
                    _buildExpandableCard(
                      index: 2,
                      icon: Icons.assignment_turned_in,
                      title: 'Revisión Técnica',
                      content: _buildDocumentosSection(),
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
                      onPressed: _isLoading ? null : _guardarBus,
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
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identificador
          TextFormField(
            controller: _formData.identificadorController,
            decoration: InputDecoration(
              labelText: 'Identificador',
              hintText: 'Ej: 45, BUS01, M001',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.tag),
              helperText: 'Hasta 9 caracteres (opcional)',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 9,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length > 9) {
                return 'Máximo 9 caracteres';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Patente
          TextFormField(
            controller: _formData.patenteController,
            decoration: InputDecoration(
              labelText: 'Patente/Identificador Principal',
              hintText: 'Ej: AB-CD-12',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.confirmation_number),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La patente/identificador es requerido';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Marca
          TextFormField(
            controller: _formData.marcaController,
            decoration: InputDecoration(
              labelText: 'Marca',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.branding_watermark),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La marca es requerida';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Modelo
          TextFormField(
            controller: _formData.modeloController,
            decoration: InputDecoration(
              labelText: 'Modelo',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.model_training),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El modelo es requerido';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Año
          TextFormField(
            controller: _formData.anioController,
            decoration: InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El año es requerido';
              }
              final anio = int.tryParse(value);
              final currentYear = DateTime.now().year;
              if (anio == null || anio < 1900 || anio > currentYear + 2) {
                return 'Año inválido (1900-${currentYear + 2})';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Capacidad Pasajeros
          TextFormField(
            controller: _formData.capacidadPasajerosController,
            decoration: InputDecoration(
              labelText: 'Capacidad Pasajeros',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.people),
              suffixText: 'asientos',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La capacidad es requerida';
              }
              final capacidad = int.tryParse(value);
              if (capacidad == null || capacidad < 1 || capacidad > 200) {
                return 'Capacidad inválida (1-200)';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Ubicación Actual
          TextFormField(
            controller: _formData.ubicacionController,
            decoration: InputDecoration(
              labelText: 'Ubicación Actual',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Ej: Terminal Norte, Taller',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 16),

          // Kilometraje
          TextFormField(
            controller: _formData.kilometrajeController,
            decoration: InputDecoration(
              labelText: 'Kilometraje',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.speed),
              suffixText: 'km',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16),

          // Número de Chasis
          TextFormField(
            controller: _formData.numeroChasisController,
            decoration: InputDecoration(
              labelText: 'Número de Chasis (VIN)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.tag),
              hintText: 'WDB9301761234567',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),

          // Número de Motor
          TextFormField(
            controller: _formData.numeroMotorController,
            decoration: InputDecoration(
              labelText: 'Número de Motor',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.settings),
              hintText: 'OM926LA123456',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 16),

          // Estado
          DropdownButtonFormField<EstadoBus>(
            value: _formData.estado,
            decoration: InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.info),
            ),
            items: EstadoBus.values.map((estado) {
              String label;
              IconData icon;
              Color color;

              switch (estado) {
                case EstadoBus.disponible:
                  label = 'Disponible';
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case EstadoBus.enReparacion:
                  label = 'En Reparación';
                  icon = Icons.build;
                  color = Colors.orange;
                  break;
                case EstadoBus.fueraDeServicio:
                  label = 'Fuera de Servicio';
                  icon = Icons.cancel;
                  color = Colors.red;
                  break;
              }

              return DropdownMenuItem(
                value: estado,
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData.estado = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMantenimientoSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Configuración básica para el sistema de mantenimiento',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Tipo de Motor
          DropdownButtonFormField<TipoMotor>(
            value: _formData.tipoMotor,
            decoration: InputDecoration(
              labelText: 'Tipo de Motor',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.settings),
            ),
            items: TipoMotor.values.map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Row(
                  children: [
                    Icon(Icons.local_gas_station,
                        size: 20, color: Colors.brown),
                    SizedBox(width: 8),
                    Text('Diésel'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData.tipoMotor = value!;
              });
            },
          ),
          SizedBox(height: 16),

          // Promedio Kilómetros Mensuales
          TextFormField(
            controller: _formData.promedioKmController,
            decoration: InputDecoration(
              labelText: 'Promedio km/mes',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.trending_up),
              suffixText: 'km/mes',
              helperText: 'Para calcular fechas de mantenimiento',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 16),

          // Estado actual (solo para edición)
          if (widget.bus != null)
            BusFormShared.buildEstadoMantenimientoActual(widget.bus!),
        ],
      ),
    );
  }

  Widget _buildDocumentosSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revisión Técnica - Campo de texto con formato dd/mm/aa
          TextFormField(
            controller: _formData.fechaRevisionController,
            decoration: InputDecoration(
              labelText: 'Vencimiento Revisión Técnica',
              hintText: 'dd/mm/aa',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.assignment_turned_in),
              helperText: 'Formato: dd/mm/aa (ej: 15/06/26)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _DateInputFormatter(),
            ],
            onChanged: (value) {
              _parseFechaRevision(value);
            },
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length == 8) {
                final fecha = _parseFechaFromString(value);
                if (fecha == null) {
                  return 'Fecha inválida';
                }
              }
              return null;
            },
          ),
          if (_formData.fechaRevisionTecnica != null) ...[
            SizedBox(height: 16),
            BusFormShared.buildRevisionTecnicaStatus(
                _formData.fechaRevisionTecnica),
          ],
          SizedBox(height: 16),

          // Información del registro (solo para edición)
          if (widget.bus != null)
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
                    'Fecha de registro: ${ChileanUtils.formatDate(widget.bus!.fechaRegistro)}',
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.history,
                    'Mantenciones: ${widget.bus!.historialMantenciones.length}',
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.build,
                    'Repuestos asignados: ${widget.bus!.repuestosAsignados.length}',
                  ),
                  if (widget.bus!.mantenimientoPreventivo != null) ...[
                    SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.build_circle,
                      'Total mantenimientos: ${widget.bus!.totalMantenimientosRealizados}',
                    ),
                  ],
                ],
              ),
            ),
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

  void _parseFechaRevision(String value) {
    final fecha = _parseFechaFromString(value);
    setState(() {
      _formData.fechaRevisionTecnica = fecha;
    });
  }

  DateTime? _parseFechaFromString(String value) {
    // Formato esperado: dd/mm/aa (8 caracteres con slashes)
    if (value.length != 8) return null;

    try {
      final parts = value.split('/');
      if (parts.length != 3) return null;

      final dia = int.parse(parts[0]);
      final mes = int.parse(parts[1]);
      int anio = int.parse(parts[2]);

      // Convertir año de 2 dígitos a 4 dígitos
      // Asumimos que 00-50 es 2000-2050 y 51-99 es 1951-1999
      if (anio <= 50) {
        anio = 2000 + anio;
      } else {
        anio = 1900 + anio;
      }

      // Validar rangos
      if (dia < 1 || dia > 31) return null;
      if (mes < 1 || mes > 12) return null;

      final fecha = DateTime(anio, mes, dia);
      // Verificar que la fecha sea válida (ej: no 31 de febrero)
      if (fecha.day != dia || fecha.month != mes) return null;

      return fecha;
    } catch (e) {
      return null;
    }
  }

  void _guardarBus() async {
    if (!_formKey.currentState!.validate()) return;

    final patenteUnica = await BusFormShared.validarPatenteUnica(
      _formData.patenteController.text.trim(),
      widget.bus?.id,
      DataService.getBuses,
    );
    if (!patenteUnica) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya existe un vehículo con esta patente'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final identificadorUnico = await BusFormShared.validarIdentificadorUnico(
      _formData.identificadorController.text.trim(),
      widget.bus?.id,
      DataService.getBuses,
    );
    if (!identificadorUnico) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya existe un vehículo con este identificador'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    try {
      // Crear o actualizar configuración de mantenimiento preventivo
      MantenimientoPreventivo? mantenimientoPreventivo;
      if (widget.bus?.mantenimientoPreventivo != null) {
        mantenimientoPreventivo = widget.bus!.mantenimientoPreventivo!.copyWith(
          tipoMotor: _formData.tipoMotor,
        );
      } else {
        mantenimientoPreventivo = MantenimientoPreventivo(
          busId: widget.bus?.id ?? '',
          tipoMotor: _formData.tipoMotor,
          fechaCreacion: DateTime.now(),
        );
      }

      final bus = Bus(
        id: widget.bus?.id ?? '',
        identificador: _formData.identificadorController.text.trim().isEmpty
            ? null
            : _formData.identificadorController.text.toUpperCase().trim(),
        patente: _formData.patenteController.text.toUpperCase().trim(),
        marca: _formData.marcaController.text.trim(),
        modelo: _formData.modeloController.text.trim(),
        anio: int.parse(_formData.anioController.text),
        estado: _formData.estado,
        historialMantenciones: widget.bus?.historialMantenciones ?? [],
        repuestosAsignados: widget.bus?.repuestosAsignados ?? [],
        historialReportes: widget.bus?.historialReportes ?? [],
        fechaRegistro: widget.bus?.fechaRegistro ?? DateTime.now(),
        fechaRevisionTecnica: _formData.fechaRevisionTecnica,
        numeroChasis: _formData.numeroChasisController.text.trim().isEmpty
            ? null
            : _formData.numeroChasisController.text.trim(),
        numeroMotor: _formData.numeroMotorController.text.trim().isEmpty
            ? null
            : _formData.numeroMotorController.text.trim(),
        capacidadPasajeros:
            int.parse(_formData.capacidadPasajerosController.text),
        ubicacionActual: _formData.ubicacionController.text.trim().isEmpty
            ? null
            : _formData.ubicacionController.text.trim(),
        kilometraje: _formData.kilometrajeController.text.trim().isEmpty
            ? null
            : double.parse(_formData.kilometrajeController.text),
        mantenimientoPreventivo: mantenimientoPreventivo,
        promedioKmMensuales: double.parse(_formData.promedioKmController.text),
        ultimaActualizacionKm: DateTime.now(),
      );

      if (widget.bus == null) {
        await DataService.addBus(bus);
      } else {
        await DataService.updateBus(bus);
      }

      Navigator.of(context).pop(bus);

      final displayName =
          bus.identificador != null && bus.identificador!.isNotEmpty
              ? '${bus.identificador} (${bus.patente})'
              : bus.patente;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bus == null
                ? 'Vehículo $displayName agregado exitosamente'
                : 'Vehículo $displayName actualizado exitosamente',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el vehículo: $e'),
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

/// Formateador de entrada para fechas en formato dd/mm/aa
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Solo permitir hasta 6 dígitos (ddmmaa)
    if (text.length > 6) {
      return oldValue;
    }

    // Formatear con slashes
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
