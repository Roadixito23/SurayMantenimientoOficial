import 'package:flutter/material.dart';
import '../main.dart';

// =====================================================================
// === WIDGETS ANIMADOS MODERNOS v3.02 ==============================
// =====================================================================

/// Widget con animación de hover para interacciones en web
class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final double hoverElevation;
  final Duration duration;
  final Curve curve;
  final BorderRadius? borderRadius;
  final Color? hoverColor;

  const AnimatedHoverCard({
    Key? key,
    required this.child,
    this.onTap,
    this.elevation = 2,
    this.hoverElevation = 8,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.borderRadius,
    this.hoverColor,
  }) : super(key: key);

  @override
  _AnimatedHoverCardState createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        decoration: BoxDecoration(
          color: _isHovered
            ? (widget.hoverColor ?? SurayColors.blancoHumo)
            : Colors.white,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SurayColors.azulMarinoProfundo.withOpacity(0.15),
              blurRadius: _isHovered ? widget.hoverElevation * 2 : widget.elevation * 2,
              offset: Offset(0, _isHovered ? widget.hoverElevation / 2 : widget.elevation / 2),
            ),
          ],
          border: Border.all(
            color: _isHovered
              ? SurayColors.naranjaQuemado.withOpacity(0.5)
              : SurayColors.grisAntracita.withOpacity(0.1),
            width: _isHovered ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            splashColor: SurayColors.naranjaQuemado.withOpacity(0.2),
            highlightColor: SurayColors.naranjaQuemado.withOpacity(0.1),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Botón animado con efecto de escala
class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleOnPress;
  final Duration duration;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const AnimatedScaleButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.scaleOnPress = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleOnPress : 1.0,
        duration: widget.duration,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? SurayColors.azulMarinoProfundo,
            foregroundColor: widget.foregroundColor ?? SurayColors.blancoHumo,
            padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget con efecto fade-in al aparecer
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeIn,
  }) : super(key: key);

  @override
  _FadeInWidgetState createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// Widget con efecto slide-in desde la izquierda
class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double offsetX;

  const SlideInWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.offsetX = -1.0,
  }) : super(key: key);

  @override
  _SlideInWidgetState createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset(widget.offsetX, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

/// Badge personalizado con colores corporativos
class SurayBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final EdgeInsets? padding;

  const SurayBadge({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? SurayColors.azulMarinoProfundo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? SurayColors.azulMarinoProfundo).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: textColor ?? SurayColors.blancoHumo,
            ),
            SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? SurayColors.blancoHumo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Divisor corporativo con estilo
class SurayDivider extends StatelessWidget {
  final double height;
  final double thickness;
  final Color? color;
  final String? label;

  const SurayDivider({
    Key? key,
    this.height = 20,
    this.thickness = 1,
    this.color,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return Row(
        children: [
          Expanded(
            child: Divider(
              height: height,
              thickness: thickness,
              color: color ?? SurayColors.grisAntracita.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: TextStyle(
                color: SurayColors.grisAntracita,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              height: height,
              thickness: thickness,
              color: color ?? SurayColors.grisAntracita.withOpacity(0.2),
            ),
          ),
        ],
      );
    }

    return Divider(
      height: height,
      thickness: thickness,
      color: color ?? SurayColors.grisAntracita.withOpacity(0.2),
    );
  }
}

/// Loading indicator corporativo
class SurayLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const SurayLoadingIndicator({
    Key? key,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? SurayColors.naranjaQuemado,
            ),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: SurayColors.grisAntracita,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
