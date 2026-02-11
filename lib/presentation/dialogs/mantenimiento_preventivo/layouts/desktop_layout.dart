import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../models/bus.dart';
import '../../../../models/mantenimiento_preventivo.dart';
import '../../../../models/tipo_mantenimiento_personalizado.dart';
import '../../../../services/data_service.dart';
import '../../../../main.dart';

class MantenimientoPreventivoDesktopLayout extends StatefulWidget {
  final Bus bus;
  final Function()? onMantenimientoRegistrado;

  MantenimientoPreventivoDesktopLayout({
    required this.bus,
    this.onMantenimientoRegistrado,
  });

  @override
  _MantenimientoPreventivoDesktopLayoutState createState() =>
      _MantenimientoPreventivoDesktopLayoutState();
}

class _MantenimientoPreventivoDesktopLayoutState
    extends State<MantenimientoPreventivoDesktopLayout> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tecnicoController;
  late TextEditingController _observacionesController;
  late TextEditingController _marcaRepuestoController;
  late TextEditingController _alarmaKmController;
  late TextEditingController _tituloPersonalizadoController;
  late TextEditingController _fechaController;

  TipoMantenimiento _tipoMantenimiento = TipoMantenimiento.preventivo;
  String _tituloMantenimiento = '';

  TipoMotor _tipoMotor = TipoMotor.diesel;
  bool _isLoading = false;
  bool _configurarAlarma = false;
  DateTime _fechaMantenimiento = DateTime.now();

  final List<Map<String, dynamic>> _tiposMantenimiento = [
    {'titulo': 'Filtro de Aceite', 'icon': Icons.opacity, 'color': Color(0xFFFF9800), 'tipo': TipoMantenimiento.preventivo},
    {'titulo': 'Filtro de Aire', 'icon': Icons.air, 'color': Color(0xFF2196F3), 'tipo': TipoMantenimiento.preventivo},
    {'titulo': 'Filtro de Combustible', 'icon': Icons.local_gas_station, 'color': Color(0xFF4CAF50), 'tipo': TipoMantenimiento.preventivo},
    {'titulo': 'Cambio de Aceite', 'icon': Icons.water_drop, 'color': Color(0xFF795548), 'tipo': TipoMantenimiento.preventivo},
    {'titulo': 'Frenos', 'icon': Icons.pan_tool, 'color': Color(0xFFE53935), 'tipo': TipoMantenimiento.correctivo},
    {'titulo': 'Neumáticos', 'icon': Icons.tire_repair, 'color': Color(0xFF424242), 'tipo': TipoMantenimiento.rutinario},
    {'titulo': 'Batería', 'icon': Icons.battery_charging_full, 'color': Color(0xFF9C27B0), 'tipo': TipoMantenimiento.correctivo},
    {'titulo': 'Otro', 'icon': Icons.more_horiz, 'color': Color(0xFF607D8B), 'tipo': TipoMantenimiento.preventivo},
  ];

  @override
  void initState() {
    super.initState();
    _tecnicoController = TextEditingController();
    _observacionesController = TextEditingController();
    _marcaRepuestoController = TextEditingController();
    _alarmaKmController = TextEditingController(text: '5000');
    _tituloPersonalizadoController = TextEditingController();
    _fechaController = TextEditingController();

    // Prellenar con fecha actual en formato dd/mm/aa
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final a = (now.year % 100).toString().padLeft(2, '0');
    _fechaController.text = '$d/$m/$a';

    if (widget.bus.mantenimientoPreventivo != null) {
      _tipoMotor = widget.bus.mantenimientoPreventivo!.tipoMotor;
    }
  }

  @override
  void dispose() {
    _tecnicoController.dispose();
    _observacionesController.dispose();
    _marcaRepuestoController.dispose();
    _alarmaKmController.dispose();
    _tituloPersonalizadoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipoMantenimientoGrid(),
                      SizedBox(height: 20),
                      if (_tituloMantenimiento == 'Otro') ...[
                        _buildCampoPersonalizado(),
                        SizedBox(height: 20),
                      ],
                      _buildFormularioCompacto(),
                      SizedBox(height: 20),
                      _buildAlarmaSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formatador = NumberFormat("#,##0", "es_CL");
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [SurayColors.azulMarinoProfundo, SurayColors.azulMarinoClaro],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.build_circle, color: Colors.white, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar Mantenimiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.bus.identificadorDisplay,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.bus.kilometraje != null) ...[
                      Text(' • ', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      Icon(Icons.speed, size: 14, color: Colors.white.withOpacity(0.8)),
                      SizedBox(width: 4),
                      Text(
                        '${formatador.format(widget.bus.kilometraje!)} km',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoMantenimientoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Mantenimiento',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SurayColors.grisAntracita),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: _tiposMantenimiento.length,
          itemBuilder: (context, index) {
            final tipo = _tiposMantenimiento[index];
            final isSelected = _tituloMantenimiento == tipo['titulo'];
            
            return InkWell(
              onTap: () {
                setState(() {
                  _tituloMantenimiento = tipo['titulo'];
                  _tipoMantenimiento = tipo['tipo'];
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? (tipo['color'] as Color).withOpacity(0.15) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? tipo['color'] : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tipo['icon'], color: isSelected ? tipo['color'] : Colors.grey[500], size: 28),
                    SizedBox(height: 6),
                    Text(
                      tipo['titulo'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? tipo['color'] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCampoPersonalizado() {
    return TextFormField(
      controller: _tituloPersonalizadoController,
      decoration: InputDecoration(
        labelText: 'Nombre del mantenimiento',
        hintText: 'Ej: Revisión de suspensión',
        prefixIcon: Icon(Icons.edit, color: SurayColors.azulMarinoProfundo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildFormularioCompacto() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fechaController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _DateInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'dd/mm/aa',
                  helperText: 'ej: 15/06/26',
                  prefixIcon: Icon(Icons.calendar_today, size: 20, color: SurayColors.azulMarinoProfundo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (value) {
                  final fecha = _parseFechaFromString(value);
                  if (fecha != null) {
                    setState(() => _fechaMantenimiento = fecha);
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length == 8) {
                    final fecha = _parseFechaFromString(value);
                    if (fecha == null) return 'Fecha inválida';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tecnicoController,
                decoration: InputDecoration(
                  labelText: 'Técnico',
                  hintText: 'Responsable',
                  prefixIcon: Icon(Icons.person, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _marcaRepuestoController,
          decoration: InputDecoration(
            labelText: 'Marca/Material (opcional)',
            hintText: 'Ej: Mann Filter, Bosch',
            prefixIcon: Icon(Icons.inventory_2, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _observacionesController,
          decoration: InputDecoration(
            labelText: 'Observaciones (opcional)',
            hintText: 'Notas adicionales...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.notes, size: 20),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildAlarmaSection() {
    final kmActual = widget.bus.kilometraje ?? 0.0;
    final kmAlarmaExtra = double.tryParse(_alarmaKmController.text) ?? 0.0;
    final kmAlarmaTotal = kmActual + kmAlarmaExtra;
    final formatador = NumberFormat("#,##0", "es_CL");

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _configurarAlarma ? Colors.amber[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _configurarAlarma ? Colors.amber[300]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: _configurarAlarma ? Colors.amber[700] : Colors.grey[500],
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Programar recordatorio',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _configurarAlarma ? Colors.amber[800] : Colors.grey[700],
                  ),
                ),
              ),
              Switch(
                value: _configurarAlarma,
                onChanged: (v) => setState(() => _configurarAlarma = v),
                activeColor: Colors.amber[700],
              ),
            ],
          ),
          if (_configurarAlarma) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _alarmaKmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'En cuántos km',
                      suffixText: 'km',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('Alarma en', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      Text(
                        '${formatador.format(kmAlarmaTotal)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text('km', style: TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[700])),
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
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseFechaFromString(String value) {
    if (value.length != 8) return null;
    try {
      final parts = value.split('/');
      if (parts.length != 3) return null;
      final dia = int.parse(parts[0]);
      final mes = int.parse(parts[1]);
      int anio = int.parse(parts[2]);
      anio = anio <= 50 ? 2000 + anio : 1900 + anio;
      if (dia < 1 || dia > 31 || mes < 1 || mes > 12) return null;
      final fecha = DateTime(anio, mes, dia);
      if (fecha.day != dia || fecha.month != mes) return null;
      return fecha;
    } catch (e) {
      return null;
    }
  }

  void _registrarMantenimiento() async {
    if (_tituloMantenimiento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona el tipo de mantenimiento'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kilometrajeReferencia = widget.bus.kilometraje ?? 0.0;

      if (widget.bus.mantenimientoPreventivo == null) {
        await DataService.configurarMantenimientoPreventivo(busId: widget.bus.id, tipoMotor: _tipoMotor);
      }

      final filtrosCriticos = ['Filtro de Aceite', 'Filtro de Aire', 'Filtro de Combustible'];
      final titulo = _tituloMantenimiento == 'Otro' 
          ? _tituloPersonalizadoController.text.trim() 
          : _tituloMantenimiento;

      if (titulo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingresa el nombre del mantenimiento'), backgroundColor: Colors.orange),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (filtrosCriticos.contains(titulo)) {
        await DataService.registrarMantenimientoFiltroCritico(
          busId: widget.bus.id,
          tituloFiltro: titulo,
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty ? null : _marcaRepuestoController.text.trim(),
        );
      } else {
        await DataService.registrarMantenimientoPersonalizado(
          busId: widget.bus.id,
          tituloMantenimiento: titulo,
          descripcionMantenimiento: null,
          tipoMantenimiento: _tipoMantenimiento,
          kilometrajeActual: kilometrajeReferencia,
          fechaMantenimiento: _fechaMantenimiento,
          tecnicoResponsable: _tecnicoController.text.trim().isEmpty ? null : _tecnicoController.text.trim(),
          observaciones: _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
          marcaRepuesto: _marcaRepuestoController.text.trim().isEmpty ? null : _marcaRepuestoController.text.trim(),
        );
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mantenimiento "$titulo" registrado'), backgroundColor: Colors.green),
      );
      widget.onMantenimientoRegistrado?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
