import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bus.dart';
import '../services/data_service.dart';
import '../services/chilean_utils.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SurayColors.blancoHumo,
      body: Column(
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          _buildSearchBar(),
          SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Bus>>(
              future: DataService.getBuses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: SurayColors.azulMarinoProfundo,
                          strokeWidth: 4,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando flota...',
                          style: TextStyle(
                            color: SurayColors.grisAntracita,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                var buses = snapshot.data ?? [];

                // Filtrar buses si hay texto de búsqueda
                if (_filtroTexto.isNotEmpty) {
                  final txt = _filtroTexto.toLowerCase();
                  buses = buses.where((b) =>
                    b.patente.toLowerCase().contains(txt) ||
                    (b.identificador?.toLowerCase().contains(txt) ?? false) ||
                    b.marca.toLowerCase().contains(txt) ||
                    b.modelo.toLowerCase().contains(txt)
                  ).toList();
                }

                // Ordenar por patente
                buses.sort((a, b) => a.patente.compareTo(b.patente));

                if (buses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 80,
                          color: SurayColors.grisAntracitaClaro,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _filtroTexto.isEmpty
                              ? 'No hay buses registrados'
                              : 'No se encontraron buses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: SurayColors.azulMarinoProfundo,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildBusesList(buses);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SurayColors.azulMarinoProfundo,
            SurayColors.azulMarinoClaro,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SurayColors.naranjaQuemado,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: SurayColors.naranjaQuemado.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.home,
              color: SurayColors.blancoHumo,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.blancoHumo,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vista rápida de la flota',
                  style: TextStyle(
                    fontSize: 16,
                    color: SurayColors.blancoHumo.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Bus>>(
            future: DataService.getBuses(),
            builder: (context, snap) {
              if (!snap.hasData) return SizedBox.shrink();
              final total = snap.data!.length;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SurayColors.naranjaQuemado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$total ${total == 1 ? "BUS" : "BUSES"}',
                  style: TextStyle(
                    color: SurayColors.blancoHumo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Buscar buses',
          hintText: 'Patente, ID, marca, modelo...',
          prefixIcon: Icon(Icons.search, color: SurayColors.azulMarinoProfundo),
          suffixIcon: _filtroTexto.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: SurayColors.grisAntracita),
            onPressed: () {
              _searchController.clear();
              setState(() => _filtroTexto = '');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (v) => setState(() => _filtroTexto = v),
      ),
    );
  }

  Widget _buildBusesList(List<Bus> buses) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 :
                         MediaQuery.of(context).size.width > 1000 ? 3 : 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          return _buildBusCard(buses[index]);
        },
      ),
    );
  }

  Widget _buildBusCard(Bus bus) {
    Color revisionColor = Colors.green;
    String revisionText = 'Al día';
    IconData revisionIcon = Icons.check_circle;

    if (bus.fechaRevisionTecnica != null) {
      if (bus.revisionTecnicaVencida) {
        revisionColor = Colors.red;
        revisionText = 'VENCIDA';
        revisionIcon = Icons.error;
      } else if (bus.revisionTecnicaProximaAVencer) {
        revisionColor = SurayColors.naranjaQuemado;
        revisionText = 'PRÓXIMA A VENCER';
        revisionIcon = Icons.warning;
      }
    } else {
      revisionColor = SurayColors.grisAntracita;
      revisionText = 'NO REGISTRADA';
      revisionIcon = Icons.help_outline;
    }

    Color estadoColor;
    switch (bus.estado) {
      case EstadoBus.disponible:
        estadoColor = Colors.green;
        break;
      case EstadoBus.enReparacion:
        estadoColor = SurayColors.naranjaQuemado;
        break;
      default:
        estadoColor = Colors.red;
    }

    return Card(
      elevation: 3,
      shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: estadoColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Acción al hacer click en la tarjeta (opcional)
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header con patente y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.patente,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: SurayColors.azulMarinoProfundo,
                          ),
                        ),
                        if (bus.identificador != null) ...[
                          SizedBox(height: 2),
                          Text(
                            bus.identificador!,
                            style: TextStyle(
                              fontSize: 13,
                              color: SurayColors.grisAntracita,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: estadoColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: estadoColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Marca y modelo
              Text(
                '${bus.marca} ${bus.modelo}',
                style: TextStyle(
                  fontSize: 14,
                  color: SurayColors.grisAntracita,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 4),

              // Año
              Text(
                'Año ${bus.anio}',
                style: TextStyle(
                  fontSize: 12,
                  color: SurayColors.grisAntracitaClaro,
                ),
              ),

              Spacer(),

              // Revisión técnica
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: revisionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: revisionColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      revisionIcon,
                      size: 16,
                      color: revisionColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rev. Técnica',
                            style: TextStyle(
                              fontSize: 10,
                              color: revisionColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            bus.fechaRevisionTecnica != null
                                ? ChileanUtils.formatDate(bus.fechaRevisionTecnica!)
                                : revisionText,
                            style: TextStyle(
                              fontSize: 12,
                              color: revisionColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
