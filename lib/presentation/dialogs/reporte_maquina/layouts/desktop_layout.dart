import 'dart:core';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/bus.dart';
import '../../../../services/data_service.dart';
import '../../../../main.dart';

class ReporteMaquinaDesktopLayout extends StatefulWidget {
  const ReporteMaquinaDesktopLayout({Key? key}) : super(key: key);

  @override
  _ReporteMaquinaDesktopLayoutState createState() =>
      _ReporteMaquinaDesktopLayoutState();
}

class _ReporteMaquinaDesktopLayoutState
    extends State<ReporteMaquinaDesktopLayout> {
  final _searchController = TextEditingController();
  List<Bus> _busesEncontrados = [];
  Bus? _busSeleccionado;
  String _tipoReporte = 'Diario';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarMaquina() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final buses = await DataService.getBuses();

      // Buscar por patente o número de máquina (identificador)
      final resultados = buses.where((bus) {
        final patente = bus.patente.toLowerCase();
        final identificador = bus.identificador?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return patente.contains(searchQuery) ||
            identificador.contains(searchQuery);
      }).toList();

      setState(() {
        _busesEncontrados = resultados;
        _isSearching = false;
      });

      if (resultados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('No se encontraron máquinas con ese criterio'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Error al buscar: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _generarReportePDF() {
    if (_busSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Por favor selecciona una máquina'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final bus = _busSeleccionado!;
    final fechaActual = DateTime.now();

    // Calcular fechas según el tipo de reporte
    DateTime fechaInicio;
    String periodoTexto;

    switch (_tipoReporte) {
      case 'Diario':
        fechaInicio =
            DateTime(fechaActual.year, fechaActual.month, fechaActual.day);
        periodoTexto =
            'Diario - ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Semanal':
        fechaInicio = fechaActual.subtract(Duration(days: 7));
        periodoTexto =
            'Semanal - ${DateFormat('dd/MM/yyyy').format(fechaInicio)} a ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Quincenal':
        fechaInicio = fechaActual.subtract(Duration(days: 15));
        periodoTexto =
            'Quincenal - ${DateFormat('dd/MM/yyyy').format(fechaInicio)} a ${DateFormat('dd/MM/yyyy').format(fechaActual)}';
        break;
      case 'Mensual':
        fechaInicio =
            DateTime(fechaActual.year, fechaActual.month - 1, fechaActual.day);
        periodoTexto =
            'Mensual - ${DateFormat('MMMM yyyy', 'es').format(fechaActual)}';
        break;
      default:
        fechaInicio = fechaActual;
        periodoTexto = 'Reporte';
    }

    // Generar HTML del reporte
    final htmlContent =
        _generarHTMLReporte(bus, periodoTexto, fechaInicio, fechaActual);

    // Enviar directamente a cola de impresión
    _abrirVentanaImpresion(htmlContent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.print, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Enviando a cola de impresión. Puedes guardar como PDF desde el diálogo de impresión.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _abrirVentanaImpresion(String htmlContent) {
    if (kIsWeb) {
      // Crear un blob con el contenido HTML
      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Abrir la ventana con el HTML como blob URL
      final printWindowBase =
          html.window.open(url, 'PRINT', 'height=600,width=800');

      if (printWindowBase != null) {
        // Cast explícito de WindowBase a Window para acceder a print()
        final printWindow = printWindowBase as html.Window;

        // Esperar a que cargue el documento y luego imprimir
        Future.delayed(Duration(milliseconds: 1000), () {
          printWindow.print();
          // Revocar el URL del blob después de imprimir
          html.Url.revokeObjectUrl(url);
        });
      }
    }
  }

  String _generarHTMLReporte(
      Bus bus, String periodoTexto, DateTime fechaInicio, DateTime fechaFin) {
    final fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final revisionTecnicaFecha = bus.fechaRevisionTecnica != null
        ? DateFormat('dd/MM/yyyy').format(bus.fechaRevisionTecnica!)
        : 'No registrada';

    final diasVencer = bus.diasParaVencimientoRevision;
    final estadoRevision = bus.revisionTecnicaVencida
        ? '<span style="color: red; font-weight: bold;">VENCIDA</span>'
        : bus.revisionTecnicaProximaAVencer
            ? '<span style="color: orange; font-weight: bold;">Próxima a vencer ($diasVencer días)</span>'
            : '<span style="color: green;">Vigente ($diasVencer días)</span>';

    final kmActual = bus.kilometraje?.toStringAsFixed(0) ?? 'No registrado';
    final kmIdeal =
        bus.kilometrajeIdeal?.toStringAsFixed(0) ?? 'No configurado';

    return '''
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reporte de Máquina - ${bus.patente}</title>
      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          color: #2C3E50;
          padding: 20px;
          background: white;
        }
        
        .container {
          max-width: 800px;
          margin: 0 auto;
          background: white;
        }
        
        .header {
          text-align: center;
          padding: 20px 0;
          border-bottom: 3px solid #003B5C;
          margin-bottom: 30px;
        }
        
        .header h1 {
          color: #003B5C;
          font-size: 28px;
          margin-bottom: 10px;
        }
        
        .header .subtitle {
          color: #555;
          font-size: 14px;
        }
        
        .info-section {
          margin-bottom: 25px;
          padding: 15px;
          background: #f8f9fa;
          border-left: 4px solid #003B5C;
        }
        
        .info-section h2 {
          color: #003B5C;
          font-size: 18px;
          margin-bottom: 15px;
          border-bottom: 2px solid #003B5C;
          padding-bottom: 8px;
        }
        
        .info-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 15px;
        }
        
        .info-item {
          padding: 10px;
          background: white;
          border-radius: 5px;
        }
        
        .info-label {
          font-size: 12px;
          color: #666;
          margin-bottom: 5px;
          font-weight: 600;
          text-transform: uppercase;
        }
        
        .info-value {
          font-size: 16px;
          color: #2C3E50;
          font-weight: bold;
        }
        
        .status-alert {
          padding: 12px;
          margin: 10px 0;
          border-radius: 5px;
          font-weight: bold;
        }
        
        .status-danger {
          background: #fee;
          border: 1px solid #fcc;
          color: #c00;
        }
        
        .status-warning {
          background: #fff3cd;
          border: 1px solid #ffc107;
          color: #856404;
        }
        
        .status-success {
          background: #d4edda;
          border: 1px solid #c3e6cb;
          color: #155724;
        }
        
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 15px 0;
          background: white;
        }
        
        th, td {
          padding: 12px;
          text-align: left;
          border: 1px solid #ddd;
        }
        
        th {
          background: #003B5C;
          color: white;
          font-weight: 600;
        }
        
        tr:nth-child(even) {
          background: #f8f9fa;
        }
        
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 2px solid #003B5C;
          text-align: center;
          font-size: 12px;
          color: #666;
        }
        
        .logo {
          max-width: 150px;
          margin-bottom: 10px;
        }
        
        @media print {
          body {
            padding: 0;
          }
          
          .container {
            max-width: 100%;
          }
          
          .info-section {
            page-break-inside: avoid;
          }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🚌 REPORTE DE MÁQUINA</h1>
          <div class="subtitle">Buses Suray - Sistema de Gestión</div>
          <div class="subtitle">Generado: $fechaActual</div>
        </div>
        
        <!-- Información de la máquina -->
        <div class="info-section">
          <h2>📋 Información de la Máquina</h2>
          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Patente</div>
              <div class="info-value">${bus.patente}</div>
            </div>
            <div class="info-item">
              <div class="info-label">N° Máquina</div>
              <div class="info-value">${bus.identificador ?? 'No asignado'}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Marca</div>
              <div class="info-value">${bus.marca}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Modelo</div>
              <div class="info-value">${bus.modelo}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Año</div>
              <div class="info-value">${bus.anio}</div>
            </div>
            <div class="info-item">
              <div class="info-label">Capacidad</div>
              <div class="info-value">${bus.capacidadPasajeros} pasajeros</div>
            </div>
          </div>
        </div>
        
        <!-- Periodo del reporte -->
        <div class="info-section">
          <h2>📅 Periodo del Reporte</h2>
          <div class="info-item">
            <div class="info-value">$periodoTexto</div>
          </div>
        </div>
        
        <!-- Estado de Revisión Técnica -->
        <div class="info-section">
          <h2>🔧 Revisión Técnica</h2>
          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Fecha de Revisión</div>
              <div class="info-value">$revisionTecnicaFecha</div>
            </div>
            <div class="info-item">
              <div class="info-label">Estado</div>
              <div class="info-value">$estadoRevision</div>
            </div>
          </div>
        </div>
        
        <!-- Kilometraje -->
        <div class="info-section">
          <h2>📊 Kilometraje</h2>
          <div class="info-grid">
            <div class="info-item">
              <div class="info-label">Kilometraje Actual</div>
              <div class="info-value">$kmActual km</div>
            </div>
            <div class="info-item">
              <div class="info-label">Kilometraje Ideal</div>
              <div class="info-value">$kmIdeal km</div>
            </div>
          </div>
        </div>
        
        <!-- Estado General -->
        <div class="info-section">
          <h2>⚙️ Estado General</h2>
          <div class="info-item">
            <div class="info-label">Información de la máquina</div>
            <div class="info-value">${bus.patente} - ${bus.marca} ${bus.modelo}</div>
          </div>
        </div>
        
        <!-- Resumen de Alertas -->
        ${bus.revisionTecnicaVencida || bus.revisionTecnicaProximaAVencer ? '''
        <div class="info-section">
          <h2>⚠️ Alertas y Notificaciones</h2>
          ${bus.revisionTecnicaVencida ? '<div class="status-alert status-danger">⛔ Revisión Técnica VENCIDA - Requiere atención inmediata</div>' : ''}
          ${bus.revisionTecnicaProximaAVencer && !bus.revisionTecnicaVencida ? '<div class="status-alert status-warning">⚠️ Revisión Técnica próxima a vencer - Programar renovación</div>' : ''}
        </div>
        ''' : ''}
        
        <div class="footer">
          <p><strong>Buses Suray</strong></p>
          <p>Sistema de Gestión de Flota - Puerto Aysén</p>
          <p>Este reporte fue generado automáticamente el $fechaActual</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: SurayColors.azulMarinoProfundo,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generar Reporte de Máquina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.grisAntracita,
                  ),
                ),
                Text(
                  'Busca y genera reportes PDF',
                  style: TextStyle(
                    fontSize: 12,
                    color: SurayColors.grisAntracitaClaro,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscador
              Text(
                'Buscar Máquina',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SurayColors.grisAntracita,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Patente o N° de máquina',
                        hintStyle:
                            TextStyle(color: SurayColors.grisAntracitaClaro),
                        prefixIcon: Icon(Icons.search,
                            color: SurayColors.grisAntracitaClaro),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: SurayColors.grisAntracitaClaro),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: SurayColors.azulMarinoProfundo, width: 2),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onSubmitted: (_) => _buscarMaquina(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _buscarMaquina,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SurayColors.azulMarinoProfundo,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSearching
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.search),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Resultados de búsqueda
              if (_busesEncontrados.isNotEmpty) ...[
                Text(
                  'Resultados (${_busesEncontrados.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SurayColors.grisAntracita,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: SurayColors.grisAntracitaClaro),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _busesEncontrados.length,
                    itemBuilder: (context, index) {
                      final bus = _busesEncontrados[index];
                      final isSelected = _busSeleccionado?.id == bus.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                            SurayColors.azulMarinoProfundo.withOpacity(0.1),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SurayColors.azulMarinoProfundo
                                : SurayColors.grisAntracita.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: isSelected
                                ? Colors.white
                                : SurayColors.grisAntracita,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          bus.patente,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? SurayColors.azulMarinoProfundo
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${bus.identificador ?? 'Sin N°'} • ${bus.marca} ${bus.modelo}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: SurayColors.azulMarinoProfundo)
                            : null,
                        onTap: () => setState(() => _busSeleccionado = bus),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Tipo de reporte
              if (_busSeleccionado != null) ...[
                Text(
                  'Tipo de Reporte',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SurayColors.grisAntracita,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      ['Diario', 'Semanal', 'Quincenal', 'Mensual'].map((tipo) {
                    final isSelected = _tipoReporte == tipo;
                    return ChoiceChip(
                      label: Text(tipo),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _tipoReporte = tipo);
                      },
                      selectedColor: SurayColors.azulMarinoProfundo,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : SurayColors.grisAntracita,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),

                // Información de la máquina seleccionada
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SurayColors.azulMarinoProfundo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SurayColors.azulMarinoProfundo.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: SurayColors.azulMarinoProfundo,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Máquina seleccionada',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SurayColors.azulMarinoProfundo,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_busSeleccionado!.patente} • ${_busSeleccionado!.identificador ?? 'Sin N°'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: SurayColors.grisAntracita,
                        ),
                      ),
                      Text(
                        '${_busSeleccionado!.marca} ${_busSeleccionado!.modelo} (${_busSeleccionado!.anio})',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.grisAntracitaClaro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: SurayColors.grisAntracita),
          ),
        ),
        ElevatedButton(
          onPressed: _busSeleccionado == null ? null : _generarReportePDF,
          style: ElevatedButton.styleFrom(
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 18),
              SizedBox(width: 8),
              Text('Generar PDF'),
            ],
          ),
        ),
      ],
    );
  }
}
