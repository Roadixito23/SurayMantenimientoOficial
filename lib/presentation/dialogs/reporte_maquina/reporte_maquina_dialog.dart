import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'layouts/desktop_layout.dart';
import 'layouts/mobile_layout.dart';

/// Dialog responsive para generar reportes de máquina en PDF
/// Desktop: AlertDialog 500px con búsqueda y selección
/// Mobile: Fullscreen con diseño vertical optimizado
class ReporteMaquinaDialog extends StatelessWidget {
  const ReporteMaquinaDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReporteMaquinaDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => ReporteMaquinaMobileLayout(),
      desktop: (_) => ReporteMaquinaDesktopLayout(),
    );
  }
}
