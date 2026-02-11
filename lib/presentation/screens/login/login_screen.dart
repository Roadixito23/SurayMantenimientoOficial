import 'package:flutter/material.dart';
import '../../widgets/responsive/responsive_builder.dart';
import 'layouts/login_mobile_layout.dart';
import 'layouts/login_desktop_layout.dart';

// =====================================================================
// === LOGIN SCREEN - Punto de entrada responsive =====================
// =====================================================================
// Esta pantalla delega el renderizado a los layouts específicos
// según el tamaño de la pantalla

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    // Animación de fade-in
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Animación de slide-in
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  void setErrorMessage(String? message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => LoginMobileLayout(
        usuarioController: _usuarioController,
        contrasenaController: _contrasenaController,
        formKey: _formKey,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        fadeController: _fadeController,
        slideController: _slideController,
        onTogglePassword: togglePasswordVisibility,
        onSetLoading: setLoading,
        onSetError: setErrorMessage,
      ),
      desktop: (context) => LoginDesktopLayout(
        usuarioController: _usuarioController,
        contrasenaController: _contrasenaController,
        formKey: _formKey,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        fadeController: _fadeController,
        slideController: _slideController,
        onTogglePassword: togglePasswordVisibility,
        onSetLoading: setLoading,
        onSetError: setErrorMessage,
      ),
    );
  }
}
