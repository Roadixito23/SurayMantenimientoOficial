import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/auth_service.dart';
import '../../../../screens/main_screen.dart';
import '../login_colors.dart';
import '../../../widgets/login/login_widgets.dart';

// =====================================================================
// === LOGIN MOBILE LAYOUT =============================================
// =====================================================================
// Layout optimizado para móviles (< 600px)
// Formulario vertical con logo grande y campos expandidos

class LoginMobileLayout extends StatelessWidget {
  final TextEditingController usuarioController;
  final TextEditingController contrasenaController;
  final GlobalKey<FormState> formKey;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final AnimationController fadeController;
  final AnimationController slideController;
  final VoidCallback onTogglePassword;
  final Function(bool) onSetLoading;
  final Function(String?) onSetError;

  const LoginMobileLayout({
    Key? key,
    required this.usuarioController,
    required this.contrasenaController,
    required this.formKey,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.fadeController,
    required this.slideController,
    required this.onTogglePassword,
    required this.onSetLoading,
    required this.onSetError,
  }) : super(key: key);

  Future<void> _login(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    onSetLoading(true);
    onSetError(null);

    try {
      final usuario = await AuthService.login(
        usuarioController.text.trim(),
        contrasenaController.text,
      );

      if (usuario != null) {
        TextInput.finishAutofillContext();

        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MainScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        onSetError('Usuario o contraseña incorrectos');
        onSetLoading(false);
      }
    } catch (e) {
      onSetError('Error al iniciar sesión: $e');
      onSetLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeIn,
    );

    final slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOut,
    ));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LoginColors.azulMarinoOscuro,
              LoginColors.azulMedio,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo grande para móvil
                      AnimatedLogo(size: 80),
                      SizedBox(height: 32),

                      // Título
                      Text(
                        'Sistema de Gestión\nde Buses',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Suray - Mantenimiento y Control',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 48),

                      // Card de login
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: LoginColors.azulMarinoOscuro
                                  .withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: AutofillGroup(
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Campo de usuario
                                  LoginTextField(
                                    controller: usuarioController,
                                    label: 'Usuario',
                                    icon: Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingrese su usuario';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),

                                  // Campo de contraseña
                                  LoginPasswordField(
                                    controller: contrasenaController,
                                    obscurePassword: obscurePassword,
                                    onToggleVisibility: onTogglePassword,
                                  ),
                                  SizedBox(height: 12),

                                  // Mensaje de error
                                  if (errorMessage != null)
                                    ErrorMessage(message: errorMessage!),

                                  SizedBox(height: 32),

                                  // Botón de login
                                  LoginButton(
                                    isLoading: isLoading,
                                    onPressed: () => _login(context),
                                    fullWidth: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
