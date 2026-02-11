import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/login/login_colors.dart';

// =====================================================================
// === LOGIN WIDGETS - Widgets compartidos para layouts ===============
// =====================================================================
// Widgets reutilizables para las diferentes versiones del login

/// Logo animado con gradiente
class AnimatedLogo extends StatelessWidget {
  final double size;

  const AnimatedLogo({Key? key, this.size = 60}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(size * 0.33),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LoginColors.azulMarinoOscuro,
                  LoginColors.azulMedio,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LoginColors.naranjaSuave.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus,
              size: size,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Campo de texto para login (usuario)
class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;

  const LoginTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 16),
      autofillHints: [AutofillHints.username],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: LoginColors.azulMedio),
        prefixIcon: Icon(icon, color: LoginColors.azulMedio),
        filled: true,
        fillColor: LoginColors.grisAzuladoClaro.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: LoginColors.grisAzuladoClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: LoginColors.grisAzuladoClaro, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: LoginColors.azulMedio, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

/// Campo de contraseña para login
class LoginPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;

  const LoginPasswordField({
    Key? key,
    required this.controller,
    required this.obscurePassword,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscurePassword,
      keyboardType: TextInputType.number,
      autofillHints: [AutofillHints.password],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        if (value.length != 8) {
          return 'La contraseña debe tener 8 dígitos';
        }
        return null;
      },
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Contraseña (8 dígitos)',
        labelStyle: TextStyle(color: LoginColors.azulMedio),
        prefixIcon: Icon(Icons.lock, color: LoginColors.azulMedio),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: LoginColors.azulMedio,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: LoginColors.grisAzuladoClaro.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: LoginColors.grisAzuladoClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: LoginColors.grisAzuladoClaro, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: LoginColors.azulMedio, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}

/// Botón de login
class LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final bool fullWidth;

  const LoginButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginColors.azulMarinoOscuro,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: LoginColors.azulMarinoOscuro.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Iniciando sesión...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Mensaje de error
class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
