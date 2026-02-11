import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/bus.dart';
import '../../../services/chilean_utils.dart';
import '../../../main.dart';

// =====================================================================
// === WIDGETS COMPARTIDOS - Pantalla de Buses =========================
// =====================================================================
// Widgets reutilizados en layouts mobile y desktop

// ---------------------------------------------------------------------
// Badge de estado del bus
// ---------------------------------------------------------------------
class EstadoBusBadge extends StatelessWidget {
  final Bus bus;
  final bool compact;

  const EstadoBusBadge({
    Key? key,
    required this.bus,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color c;
    IconData ic;
    String lbl;
    switch (bus.estado) {
      case EstadoBus.disponible:
        c = Colors.green;
        ic = Icons.check_circle;
        lbl = 'Disponible';
        break;
      case EstadoBus.enReparacion:
        c = SurayColors.naranjaQuemado;
        ic = Icons.build;
        lbl = 'En Reparación';
        break;
      default:
        c = Colors.red;
        ic = Icons.cancel;
        lbl = 'Fuera de Servicio';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: compact ? 12 : 14, color: c),
          SizedBox(width: compact ? 4 : 6),
          Text(
            lbl,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Indicador de revisión técnica
// ---------------------------------------------------------------------
class RevisionTecnicaIndicator extends StatelessWidget {
  final Bus bus;
  final bool showLabel;

  const RevisionTecnicaIndicator({
    Key? key,
    required this.bus,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bus.fechaRevisionTecnica == null) {
      return Text(
        'No registrada',
        style: TextStyle(
          fontSize: 13,
          color: SurayColors.grisAntracitaClaro,
        ),
      );
    }

    Color textColor = Colors.green;
    IconData icon = Icons.verified;
    if (bus.revisionTecnicaVencida) {
      textColor = Colors.red;
      icon = Icons.warning;
    } else if (bus.revisionTecnicaProximaAVencer) {
      textColor = SurayColors.naranjaQuemado;
      icon = Icons.schedule;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textColor),
        SizedBox(width: 4),
        Text(
          ChileanUtils.formatDate(bus.fechaRevisionTecnica!),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Card de bus para móvil
// ---------------------------------------------------------------------
class BusCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;

  const BusCard({
    Key? key,
    required this.bus,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: SurayColors.naranjaQuemado.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: ID/Patente + Estado
              Row(
                children: [
                  // Ícono bus
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: SurayColors.azulMarinoProfundo,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  // Patente + Marca/Modelo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.patente,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SurayColors.azulMarinoProfundo,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${bus.marca} ${bus.modelo} (${bus.anio})',
                          style: TextStyle(
                            fontSize: 13,
                            color: SurayColors.grisAntracita,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estado
                  EstadoBusBadge(bus: bus, compact: true),
                ],
              ),
              SizedBox(height: 10),
              // Divider decorativo
              Container(
                height: 1,
                color: SurayColors.grisAntracitaClaro.withOpacity(0.2),
              ),
              SizedBox(height: 10),
              // Fila inferior: Km + Revisión + Flecha
              Row(
                children: [
                  // Kilometraje
                  Expanded(
                    child: _buildInfoChip(
                      Icons.speed,
                      bus.kilometraje != null
                          ? '${_formatKilometraje(bus.kilometraje!)} km'
                          : 'Sin km',
                      bus.kilometraje != null
                          ? SurayColors.azulMarinoProfundo
                          : SurayColors.grisAntracitaClaro,
                    ),
                  ),
                  SizedBox(width: 8),
                  // Revisión técnica
                  Expanded(
                    child: _buildRevisionChip(),
                  ),
                  SizedBox(width: 8),
                  // Flecha de acción
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SurayColors.naranjaQuemado.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: SurayColors.naranjaQuemado,
                      size: 14,
                    ),
                  ),
                ],
              ),
              // Alertas de mantenimiento (si hay)
              if (bus.tieneMantenimientosVencidos ||
                  bus.tieneMantenimientosUrgentes) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.tieneMantenimientosVencidos
                        ? Colors.red.withOpacity(0.1)
                        : SurayColors.naranjaQuemado.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: bus.tieneMantenimientosVencidos
                          ? Colors.red.withOpacity(0.3)
                          : SurayColors.naranjaQuemado.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: bus.tieneMantenimientosVencidos
                            ? Colors.red
                            : SurayColors.naranjaQuemado,
                      ),
                      SizedBox(width: 4),
                      Text(
                        bus.tieneMantenimientosVencidos
                            ? 'Mantenimiento vencido'
                            : 'Mantenimiento próximo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: bus.tieneMantenimientosVencidos
                              ? Colors.red
                              : SurayColors.naranjaQuemado,
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
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRevisionChip() {
    if (bus.fechaRevisionTecnica == null) {
      return _buildInfoChip(
        Icons.assignment_late,
        'Sin revisión',
        SurayColors.grisAntracitaClaro,
      );
    }

    Color c = Colors.green;
    IconData icon = Icons.verified;
    if (bus.revisionTecnicaVencida) {
      c = Colors.red;
      icon = Icons.warning;
    } else if (bus.revisionTecnicaProximaAVencer) {
      c = SurayColors.naranjaQuemado;
      icon = Icons.schedule;
    }

    return _buildInfoChip(
      icon,
      ChileanUtils.formatDate(bus.fechaRevisionTecnica!),
      c,
    );
  }

  String _formatKilometraje(double km) {
    final formatador = NumberFormat("#,##0", "es_CL");
    return formatador.format(km);
  }
}

// ---------------------------------------------------------------------
// Paginación adaptativa
// ---------------------------------------------------------------------
class BusesPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool compact;
  final ValueChanged<int> onPageChanged;

  const BusesPagination({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    this.compact = false,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return SizedBox.shrink();

    if (compact) {
      return _buildCompactPagination();
    }
    return _buildFullPagination();
  }

  /// Paginación compacta para móvil
  Widget _buildCompactPagination() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            color: currentPage > 0
                ? SurayColors.azulMarinoProfundo
                : SurayColors.grisAntracitaClaro,
            onPressed: currentPage > 0
                ? () => onPageChanged(currentPage - 1)
                : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: SurayColors.azulMarinoProfundo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SurayColors.azulMarinoProfundo,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.chevron_right),
            color: currentPage < totalPages - 1
                ? SurayColors.azulMarinoProfundo
                : SurayColors.grisAntracitaClaro,
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Paginación completa para desktop
  Widget _buildFullPagination() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: SurayColors.grisAntracita.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Página ${currentPage + 1} de $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: SurayColors.azulMarinoProfundo,
            ),
          ),
          Spacer(),
          _buildNavButton(
            icon: Icons.first_page,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(0),
          ),
          SizedBox(width: 8),
          _buildNavButton(
            icon: Icons.chevron_left,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(currentPage - 1),
          ),
          SizedBox(width: 16),
          ...List.generate(
            totalPages > 10 ? 10 : totalPages,
            (i) {
              final pageIndex = totalPages > 10
                  ? (currentPage > 5 ? currentPage - 5 + i : i)
                  : i;
              if (pageIndex >= totalPages) return SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPage == pageIndex
                        ? SurayColors.azulMarinoProfundo
                        : SurayColors.blancoHumo,
                    foregroundColor: currentPage == pageIndex
                        ? SurayColors.blancoHumo
                        : SurayColors.azulMarinoProfundo,
                    minimumSize: Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => onPageChanged(pageIndex),
                  child: Text('${pageIndex + 1}'),
                ),
              );
            },
          ),
          SizedBox(width: 16),
          _buildNavButton(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(currentPage + 1),
          ),
          SizedBox(width: 8),
          _buildNavButton(
            icon: Icons.last_page,
            enabled: currentPage < totalPages - 1,
            onPressed: () => onPageChanged(totalPages - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: enabled
          ? SurayColors.azulMarinoProfundo
          : SurayColors.grisAntracitaClaro,
      onPressed: enabled ? onPressed : null,
    );
  }
}

// ---------------------------------------------------------------------
// Diálogo de acciones del bus (usado por ambos layouts)
// ---------------------------------------------------------------------
void showBusActionsDialog({
  required BuildContext context,
  required Bus bus,
  required void Function(BuildContext, Bus) onActualizarKilometraje,
  required void Function(BuildContext, Bus) onActualizarRevisionTecnica,
  required void Function(BuildContext, Bus) onRegistrarMantenimiento,
  required void Function(BuildContext, Bus) onAsignarRepuesto,
  required void Function(BuildContext, Bus) onMostrarHistorial,
  required void Function(BuildContext, {Bus? bus}) onEditarBus,
  required void Function(String) onEliminarBus,
}) {
  showDialog(
    context: context,
    barrierColor: SurayColors.azulMarinoProfundo.withOpacity(0.5),
    builder: (ctx) {
      final screenSize = MediaQuery.of(ctx).size;
      final isSmallScreen =
          screenSize.width < 600 || screenSize.height < 700;
      final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 450.0;
      final maxDialogHeight =
          screenSize.height * (isSmallScreen ? 0.85 : 0.75);

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 24,
                  vertical: isSmallScreen ? 20 : 40,
                ),
                child: Container(
                  width: dialogWidth,
                  constraints: BoxConstraints(maxHeight: maxDialogHeight),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: SurayColors.azulMarinoProfundo.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con gradiente
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              SurayColors.azulMarinoProfundo,
                              SurayColors.azulMarinoClaro,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                color: SurayColors.blancoHumo,
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Acciones',
                                    style: TextStyle(
                                      color: SurayColors.blancoHumo
                                          .withOpacity(0.9),
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    bus.patente,
                                    style: TextStyle(
                                      color: SurayColors.blancoHumo,
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: SurayColors.blancoHumo),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Contenido con scroll
                      Flexible(
                        child: Scrollbar(
                          thumbVisibility: true,
                          thickness: 6,
                          radius: Radius.circular(10),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                    'Acciones Principales', isSmallScreen),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.speed,
                                  label: 'Actualizar Kilometraje',
                                  description: 'Registrar kilómetros actuales',
                                  color: SurayColors.azulMarinoProfundo,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onActualizarKilometraje(context, bus);
                                  },
                                ),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.verified_user,
                                  label: 'Actualizar Revisión Técnica',
                                  description:
                                      'Registrar nueva fecha de revisión',
                                  color: Color(0xFF00897B),
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onActualizarRevisionTecnica(context, bus);
                                  },
                                ),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.assignment,
                                  label: 'Registrar Mantenimiento',
                                  description: 'Crear nuevo registro',
                                  color: SurayColors.naranjaQuemado,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onRegistrarMantenimiento(context, bus);
                                  },
                                ),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.build_circle,
                                  label: 'Asignar Repuesto',
                                  description: 'Vincular repuestos al bus',
                                  color: SurayColors.azulMarinoClaro,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onAsignarRepuesto(context, bus);
                                  },
                                ),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.history,
                                  label: 'Historial Completo',
                                  description: 'Ver todos los registros',
                                  color: Color(0xFF607D8B),
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onMostrarHistorial(context, bus);
                                  },
                                ),
                                // Divisor
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: SurayColors.grisAntracitaClaro
                                            .withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'Otras Opciones',
                                        style: TextStyle(
                                          color: SurayColors.grisAntracita
                                              .withOpacity(0.6),
                                          fontSize: isSmallScreen ? 11 : 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: SurayColors.grisAntracitaClaro
                                            .withOpacity(0.3),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                _buildActionOption(
                                  icon: Icons.edit,
                                  label: 'Editar Bus',
                                  description: 'Modificar información',
                                  color: SurayColors.grisAntracita,
                                  iconSize: 18,
                                  isSecondary: true,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onEditarBus(context, bus: bus);
                                  },
                                ),
                                SizedBox(height: 8),
                                _buildActionOption(
                                  icon: Icons.delete_forever,
                                  label: 'Eliminar Bus',
                                  description: 'Borrar permanentemente',
                                  color: Colors.red.shade700,
                                  iconSize: 18,
                                  isSecondary: true,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onEliminarBus(bus.id);
                                  },
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// --- Helpers internos para el diálogo ---

Widget _buildSectionTitle(String title, bool isSmallScreen) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SurayColors.azulMarinoProfundo,
              SurayColors.azulMarinoClaro,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w600,
          color: SurayColors.azulMarinoProfundo,
        ),
      ),
    ],
  );
}

Widget _buildActionOption({
  required IconData icon,
  required String label,
  String? description,
  required Color color,
  required VoidCallback onTap,
  double iconSize = 22,
  bool isSecondary = false,
  bool isSmallScreen = false,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withOpacity(0.2),
      highlightColor: color.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isSecondary ? 0.15 : 0.25),
            width: isSecondary ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSecondary ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSecondary
                      ? [color, color]
                      : [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSecondary ? iconSize - 2 : iconSize,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? (isSecondary ? 13 : 14)
                          : (isSecondary ? 14 : 15),
                      fontWeight:
                          isSecondary ? FontWeight.w500 : FontWeight.w600,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  if (description != null && !isSecondary) ...[
                    SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w400,
                        color: color.withOpacity(0.6),
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.7),
                size: isSecondary ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
