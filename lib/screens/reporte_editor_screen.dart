import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../models/bus.dart';
import '../models/reporte_diario.dart';

class ReporteEditorScreen extends StatefulWidget {
  final ReporteDiario? reporteBase;

  ReporteEditorScreen({this.reporteBase});

  @override
  _ReporteEditorScreenState createState() => _ReporteEditorScreenState();
}

class _ReporteEditorScreenState extends State<ReporteEditorScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _autorController;
  late TextEditingController _contenidoController;
  late FocusNode _contenidoFocusNode;

  DateTime _fechaReporte = DateTime.now();
  String _numeroReporte = '';
  List<String> _busesSeleccionados = [];

  // Estado del formato
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  int _fontSize = 14;
  TextAlign _textAlign = TextAlign.left;

  // Control de selección de texto
  int _selectionStart = 0;
  int _selectionEnd = 0;

  bool _modoVistaPrevia = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeNumeroReporte();
  }

  void _initializeControllers() {
    _tituloController = TextEditingController(
        text: widget.reporteBase?.observaciones.split('\n').first ?? 'Reporte Diario de Taller'
    );
    _autorController = TextEditingController(
        text: widget.reporteBase?.autor ?? ''
    );
    _contenidoController = TextEditingController(
        text: widget.reporteBase?.observaciones ?? ''
    );
    _contenidoFocusNode = FocusNode();

    if (widget.reporteBase != null) {
      _fechaReporte = widget.reporteBase!.fecha;
      _numeroReporte = widget.reporteBase!.numeroReporte;
      _busesSeleccionados = List.from(widget.reporteBase!.busesAtendidos);
    }

    _contenidoController.addListener(_onTextChanged);
  }

  void _initializeNumeroReporte() async {
    if (widget.reporteBase == null) {
      final numeroGenerado = await DataService.generarNumeroReporte(_fechaReporte);
      if (_contenidoController.text.isEmpty) {
        _contenidoController.text = _getPlantillaReporte();
      }
      setState(() {
        _numeroReporte = numeroGenerado;
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    _contenidoController.dispose();
    _contenidoFocusNode.dispose();
    super.dispose();
  }

  String _getPlantillaReporte() {
    return '''REPORTE DIARIO DE TALLER

Fecha: ${ChileanUtils.formatDate(_fechaReporte)}
Número de Reporte: $_numeroReporte

RESUMEN DE ACTIVIDADES:

• 

BUSES ATENDIDOS:

• 

OBSERVACIONES TÉCNICAS:

• 

MATERIALES UTILIZADOS:

• 

PRÓXIMAS ACCIONES:

• 

COMENTARIOS ADICIONALES:

• 

''';
  }

  void _onTextChanged() {
    setState(() {
      _selectionStart = _contenidoController.selection.start;
      _selectionEnd = _contenidoController.selection.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cargando Editor...', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF1565C0),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editor de Reportes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1565C0),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_modoVistaPrevia ? Icons.edit : Icons.preview, color: Colors.white),
            onPressed: () => setState(() => _modoVistaPrevia = !_modoVistaPrevia),
            tooltip: _modoVistaPrevia ? 'Editar' : 'Vista Previa',
          ),
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _guardarReporte,
            tooltip: 'Guardar Reporte',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del reporte
          _buildReporteHeader(),

          // Toolbar de formato (solo en modo edición)
          if (!_modoVistaPrevia) _buildFormatToolbar(),

          // Área de contenido
          Expanded(
            child: _modoVistaPrevia ? _buildVistaPrevia() : _buildEditor(),
          ),

          // Panel de buses (solo en modo edición)
          if (!_modoVistaPrevia) _buildBusesPanel(),
        ],
      ),
    );
  }

  Widget _buildReporteHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título del Reporte',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _autorController,
                  decoration: InputDecoration(
                    labelText: 'Autor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.numbers, color: Colors.blue[800], size: 16),
                    SizedBox(width: 8),
                    Text(
                      'N° $_numeroReporte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              InkWell(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 8),
                      Text(ChileanUtils.formatDate(_fechaReporte)),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Chip(
                label: Text(
                  '${_busesSeleccionados.length} buses seleccionados',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: _busesSeleccionados.isEmpty ? Colors.grey : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Formato de texto
            _buildFormatButton(
              icon: Icons.format_bold,
              isActive: _isBold,
              onPressed: _toggleBold,
              tooltip: 'Negrita',
            ),
            _buildFormatButton(
              icon: Icons.format_italic,
              isActive: _isItalic,
              onPressed: _toggleItalic,
              tooltip: 'Cursiva',
            ),
            _buildFormatButton(
              icon: Icons.format_underlined,
              isActive: _isUnderline,
              onPressed: _toggleUnderline,
              tooltip: 'Subrayado',
            ),

            _buildDivider(),

            // Tamaño de fuente
            Text('Tamaño: ', style: TextStyle(fontSize: 12)),
            DropdownButton<int>(
              value: _fontSize,
              items: [10, 12, 14, 16, 18, 20, 24]
                  .map((size) => DropdownMenuItem(
                value: size,
                child: Text('$size'),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _fontSize = value!),
              underline: SizedBox(),
            ),

            _buildDivider(),

            // Alineación
            _buildFormatButton(
              icon: Icons.format_align_left,
              isActive: _textAlign == TextAlign.left,
              onPressed: () => setState(() => _textAlign = TextAlign.left),
              tooltip: 'Alinear izquierda',
            ),
            _buildFormatButton(
              icon: Icons.format_align_center,
              isActive: _textAlign == TextAlign.center,
              onPressed: () => setState(() => _textAlign = TextAlign.center),
              tooltip: 'Centrar',
            ),
            _buildFormatButton(
              icon: Icons.format_align_right,
              isActive: _textAlign == TextAlign.right,
              onPressed: () => setState(() => _textAlign = TextAlign.right),
              tooltip: 'Alinear derecha',
            ),

            _buildDivider(),

            // Acciones especiales
            ElevatedButton.icon(
              onPressed: _insertarBus,
              icon: Icon(Icons.directions_bus, size: 16),
              label: Text('Importar Bus', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _insertarPlantilla,
              icon: Icon(Icons.insert_drive_file, size: 16),
              label: Text('Plantilla', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _limpiarFormato,
              icon: Icon(Icons.format_clear, size: 16),
              label: Text('Limpiar', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isActive ? Border.all(color: Colors.blue[300]!) : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.blue[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey[300],
      margin: EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contenidoController,
                focusNode: _contenidoFocusNode,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Escriba el contenido del reporte aquí...',
                ),
                style: TextStyle(
                  fontSize: _fontSize.toDouble(),
                  fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                ),
                textAlign: _textAlign,
                onChanged: (value) => _onTextChanged(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaPrevia() {
    return Container(
      padding: EdgeInsets.all(24),
      color: Colors.grey[50],
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado del reporte
                Center(
                  child: Column(
                    children: [
                      Text(
                        _tituloController.text.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 200,
                        color: Color(0xFF1565C0),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reporte N° $_numeroReporte',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Fecha: ${ChileanUtils.formatDate(_fechaReporte)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Autor: ${_autorController.text}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Buses atendidos
                if (_busesSeleccionados.isNotEmpty) ...[
                  Text(
                    'BUSES ATENDIDOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: 8),
                  FutureBuilder<List<Widget>>(
                    future: _buildBusChipsForPreview(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: snapshot.data!,
                          ),
                        );
                      }
                      return CircularProgressIndicator();
                    },
                  ),
                  SizedBox(height: 24),
                ],

                // Contenido del reporte
                Text(
                  'CONTENIDO DEL REPORTE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _contenidoController.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Firma
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('_' * 30),
                        SizedBox(height: 4),
                        Text(
                          _autorController.text,
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Técnico Responsable',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('_' * 30),
                        SizedBox(height: 4),
                        Text(
                          'Supervisor de Taller',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Visto Bueno',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusesPanel() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Seleccionar Buses para el Reporte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Spacer(),
                FutureBuilder<List<Bus>>(
                  future: DataService.getBusesParaReportes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox.shrink();
                    final buses = snapshot.data!;
                    return TextButton(
                      onPressed: () {
                        setState(() {
                          if (_busesSeleccionados.length == buses.length) {
                            _busesSeleccionados.clear();
                          } else {
                            _busesSeleccionados = buses.map((b) => b.patente).toList();
                          }
                        });
                      },
                      child: Text(
                        _busesSeleccionados.length == buses.length
                            ? 'Deseleccionar todos'
                            : 'Seleccionar todos',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Bus>>(
              future: DataService.getBusesParaReportes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final buses = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    final isSelected = _busesSeleccionados.contains(bus.patente);

                    return CheckboxListTile(
                      title: Text(
                        bus.patente,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${bus.marca} ${bus.modelo} (${bus.anio})'),
                      secondary: _buildEstadoIcon(bus.estado),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _busesSeleccionados.add(bus.patente);
                          } else {
                            _busesSeleccionados.remove(bus.patente);
                          }
                        });
                      },
                      dense: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIcon(EstadoBus estado) {
    IconData icon;
    Color color;

    switch (estado) {
      case EstadoBus.disponible:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case EstadoBus.enReparacion:
        icon = Icons.build;
        color = Colors.orange;
        break;
      case EstadoBus.fueraDeServicio:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  Future<List<Widget>> _buildBusChipsForPreview() async {
    final buses = await DataService.getBuses();
    return _busesSeleccionados.map((patente) {
      final bus = buses.firstWhere(
            (b) => b.patente == patente,
        orElse: () => Bus(
          id: '',
          patente: patente,
          marca: '',
          modelo: '',
          anio: 0,
          estado: EstadoBus.disponible,
          historialMantenciones: [],
          fechaRegistro: DateTime.now(),
        ),
      );
      return Chip(
        label: Text(
          '${bus.patente} (${bus.marca} ${bus.modelo})',
          style: TextStyle(fontSize: 12),
        ),
        backgroundColor: Colors.white,
      );
    }).toList();
  }

  // Funciones de formato
  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
  }

  void _limpiarFormato() {
    setState(() {
      _isBold = false;
      _isItalic = false;
      _isUnderline = false;
      _fontSize = 14;
      _textAlign = TextAlign.left;
    });
  }

  void _insertarBus() async {
    final buses = await DataService.getBusesParaReportes();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Importar Información de Bus'),
        content: Container(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              return ListTile(
                leading: _buildEstadoIcon(bus.estado),
                title: Text(bus.patente, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${bus.marca} ${bus.modelo} (${bus.anio})'),
                onTap: () {
                  _insertarInfoBus(bus);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _insertarInfoBus(Bus bus) {
    final infoBus = '''

=== INFORMACIÓN DEL BUS ${bus.patente} ===
Marca: ${bus.marca}
Modelo: ${bus.modelo}
Año: ${bus.anio}
Estado: ${_getEstadoLabel(bus.estado)}
${bus.ubicacionActual != null ? 'Ubicación: ${bus.ubicacionActual}' : ''}
${bus.kilometraje != null ? 'Kilometraje: ${bus.kilometraje} km' : ''}
${bus.numeroChasis != null ? 'Chasis: ${bus.numeroChasis}' : ''}
${bus.numeroMotor != null ? 'Motor: ${bus.numeroMotor}' : ''}

''';

    final currentText = _contenidoController.text;
    final selection = _contenidoController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      infoBus,
    );

    _contenidoController.text = newText;
    _contenidoController.selection = TextSelection.collapsed(
      offset: selection.start + infoBus.length,
    );

    // Agregar el bus a la selección si no está ya
    if (!_busesSeleccionados.contains(bus.patente)) {
      setState(() {
        _busesSeleccionados.add(bus.patente);
      });
    }
  }

  String _getEstadoLabel(EstadoBus estado) {
    switch (estado) {
      case EstadoBus.disponible:
        return 'Disponible';
      case EstadoBus.enReparacion:
        return 'En Reparación';
      case EstadoBus.fueraDeServicio:
        return 'Fuera de Servicio';
    }
  }

  void _insertarPlantilla() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar Plantilla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.build, color: Colors.blue),
              title: Text('Mantenimiento Preventivo'),
              subtitle: Text('Plantilla para mantenimiento rutinario'),
              onTap: () {
                _insertarTexto(_getPlantillaMantenimiento());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Reparación Correctiva'),
              subtitle: Text('Plantilla para reparaciones'),
              onTap: () {
                _insertarTexto(_getPlantillaReparacion());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.green),
              title: Text('Inspección Técnica'),
              subtitle: Text('Plantilla para inspecciones'),
              onTap: () {
                _insertarTexto(_getPlantillaInspeccion());
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _getPlantillaMantenimiento() {
    return '''

=== MANTENIMIENTO PREVENTIVO ===

ACTIVIDADES REALIZADAS:
• Cambio de aceite de motor
• Revisión de filtros (aceite, aire, combustible)
• Inspección de frenos
• Verificación de niveles de fluidos
• Revisión de neumáticos y presión

ESTADO GENERAL:
• Sistema de motor: ✓ Normal
• Sistema de frenos: ✓ Normal  
• Sistema eléctrico: ✓ Normal
• Carrocería: ✓ Normal

PRÓXIMO MANTENIMIENTO:
• Fecha estimada: [FECHA]
• Kilometraje: [KM]

''';
  }

  String _getPlantillaReparacion() {
    return '''

=== REPARACIÓN CORRECTIVA ===

PROBLEMA DETECTADO:
• Descripción del problema:
• Síntomas observados:
• Código de error (si aplica):

DIAGNÓSTICO:
• Causa raíz del problema:
• Componentes afectados:

REPARACIÓN REALIZADA:
• Procedimiento aplicado:
• Repuestos utilizados:
• Tiempo de reparación:

VERIFICACIÓN:
• Pruebas realizadas:
• Resultado de las pruebas:

ESTADO FINAL:
• Bus operativo: [SÍ/NO]
• Observaciones:

''';
  }

  String _getPlantillaInspeccion() {
    return '''

=== INSPECCIÓN TÉCNICA ===

REVISIÓN VISUAL:
• Carrocería exterior: 
• Interior del vehículo:
• Compartimento motor:

SISTEMAS MECÁNICOS:
• Motor: 
• Transmisión:
• Frenos:
• Suspensión:
• Dirección:

SISTEMAS ELÉCTRICOS:
• Luces y señalización:
• Sistema de arranque:
• Alternador y batería:

DOCUMENTACIÓN:
• Revisión técnica vigente: [SÍ/NO]
• Seguro vigente: [SÍ/NO]
• Documentos al día: [SÍ/NO]

RECOMENDACIONES:
• Acciones inmediatas:
• Acciones programadas:

''';
  }

  void _insertarTexto(String texto) {
    final currentText = _contenidoController.text;
    final selection = _contenidoController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      texto,
    );

    _contenidoController.text = newText;
    _contenidoController.selection = TextSelection.collapsed(
      offset: selection.start + texto.length,
    );
  }

  void _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaReporte,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      final nuevoNumero = await DataService.generarNumeroReporte(fecha);
      setState(() {
        _fechaReporte = fecha;
        _numeroReporte = nuevoNumero;
      });
    }
  }

  void _guardarReporte() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El título del reporte es requerido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_autorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El autor del reporte es requerido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_contenidoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El contenido del reporte es requerido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 500));

    try {
      final reporte = ReporteDiario(
        id: widget.reporteBase?.id ?? '',
        fecha: _fechaReporte,
        numeroReporte: _numeroReporte,
        observaciones: _contenidoController.text,
        busesAtendidos: _busesSeleccionados,
        autor: _autorController.text,
      );

      if (widget.reporteBase == null) {
        await DataService.addReporte(reporte);
      } else {
        await DataService.updateReporte(reporte);
      }

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte $_numeroReporte guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}