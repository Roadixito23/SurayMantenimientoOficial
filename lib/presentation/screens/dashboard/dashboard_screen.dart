import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import '../../../services/data_service.dart';
import 'layouts/dashboard_mobile_layout.dart';
import 'layouts/dashboard_desktop_layout.dart';

// =====================================================================
// === DASHBOARD SCREEN - Punto de entrada responsive =================
// =====================================================================
// Esta pantalla delega el renderizado a los layouts específicos
// según el tamaño de la pantalla

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDataIfNeeded();
  }

  Future<void> _initializeDataIfNeeded() async {
    final buses = await DataService.getBuses();
    if (buses.isEmpty) {
      await DataService.initializeSampleData();
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Método para refrescar el dashboard desde cualquier layout
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => DashboardMobileLayout(onRefresh: refresh),
      desktop: (context) => DashboardDesktopLayout(onRefresh: refresh),
    );
  }
}

