import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../../core/constants/breakpoints.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'layouts/desktop_layout.dart';
import 'layouts/mobile_layout.dart';

/// Dialog para mostrar el historial completo de un bus (mantenimientos + reportes)
/// En desktop: AlertDialog grande con filtros y tabla
/// En mobile: FullScreen con filtros colapsables y lista vertical
class HistorialCompletoDialog extends StatelessWidget {
  final Bus bus;

  const HistorialCompletoDialog({Key? key, required this.bus})
      : super(key: key);

  static Future<void> show(BuildContext context, {required Bus bus}) {
    final width = MediaQuery.of(context).size.width;

    if (width < Breakpoints.tablet) {
      // Mobile: fullscreen
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistorialCompletoDialog(bus: bus),
          fullscreenDialog: true,
        ),
      );
    } else {
      // Desktop: dialog
      return showDialog(
        context: context,
        builder: (context) => HistorialCompletoDialog(bus: bus),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => HistorialCompletoMobileLayout(bus: bus),
      desktop: (context) => HistorialCompletoDesktopLayout(bus: bus),
    );
  }
}
