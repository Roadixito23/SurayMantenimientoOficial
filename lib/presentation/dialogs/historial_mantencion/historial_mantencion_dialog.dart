import 'package:flutter/material.dart';
import '../../../models/bus.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'layouts/desktop_layout.dart';
import 'layouts/mobile_layout.dart';

class HistorialMantencionDialog extends StatelessWidget {
  final Bus bus;

  const HistorialMantencionDialog({Key? key, required this.bus}) : super(key: key);

  static Future<void> show(BuildContext context, {required Bus bus}) {
    return showDialog(
      context: context,
      builder: (context) => HistorialMantencionDialog(bus: bus),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => HistorialMantencionMobileLayout(bus: bus),
      desktop: (_) => HistorialMantencionDesktopLayout(bus: bus),
    );
  }
}
