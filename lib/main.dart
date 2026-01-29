import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Archivo generado por FlutterFire CLI
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

// =====================================================================
// === COLORES CORPORATIVOS SURAY v2.0.23 ==============================
// =====================================================================
class SurayColors {
  static const Color azulMarinoProfundo = Color(0xFF1A3B5C); // Color principal
  static const Color naranjaQuemado = Color(0xFFD97236); // Color secundario/acentos
  static const Color grisAntracita = Color(0xFF4A5568); // Elementos secundarios
  static const Color blancoHumo = Color(0xFFF7FAFC); // Fondos

  // Variaciones útiles
  static const Color azulMarinoClaro = Color(0xFF2C5F8D);
  static const Color naranjaQuemadoClaro = Color(0xFFE69563);
  static const Color grisAntracitaClaro = Color(0xFF6B7280);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Iniciando aplicación...');

    // Inicializar Firebase usando la configuración automática
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente para ${DefaultFirebaseOptions.currentPlatform.projectId}');

    // Dar un pequeño delay para asegurar que Firebase esté completamente inicializado
    await Future.delayed(Duration(milliseconds: 500));

    // Inicializar datos de ejemplo si no existen
    print('📊 Verificando datos de ejemplo...');
    await FirebaseService.initializeSampleData();
    print('✅ Datos de ejemplo verificados/inicializados');

    // Inicializar usuarios predeterminados
    print('👤 Verificando usuarios predeterminados...');
    await AuthService.initializeDefaultUsers();
    print('✅ Usuarios predeterminados verificados/inicializados');

    print('🎉 Aplicación lista para usar');
  } catch (e) {
    print('❌ Error al inicializar la aplicación: $e');

    // En caso de error, mostrar información útil
    if (e.toString().contains('API key not valid')) {
      print('🔑 Error de API Key: Problema con la configuración de Firebase');
    } else if (e.toString().contains('project')) {
      print('📁 Error de proyecto: Verifica la configuración en Firebase Console');
    } else if (e.toString().contains('network')) {
      print('🌐 Error de red: Verifica tu conexión a internet');
    } else if (e.toString().contains('channel-error')) {
      print('⚠️ Error de canal: Continuando con inicialización retardada...');
    }
  }

  runApp(BusManagementApp());
}

class BusManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión de Buses - Suray v2.0.23',
      // Builder para ajustar el zoom y hacer la app responsive
      builder: (context, child) {
        return MediaQuery(
          // Ajustar el textScaleFactor para compensar el escalado de Windows
          // Si Windows está al 150%, necesitamos reducir el texto a ~0.67 (1/1.5)
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.67, 1.0),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SurayColors.azulMarinoProfundo,
          primary: SurayColors.azulMarinoProfundo,
          secondary: SurayColors.naranjaQuemado,
          tertiary: SurayColors.grisAntracita,
          surface: SurayColors.blancoHumo,
          background: SurayColors.blancoHumo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: SurayColors.blancoHumo,
        fontFamily: 'Roboto',

        // =====================================================================
        // === AppBar Theme - Azul Marino con sombra moderna ===================
        // =====================================================================
        appBarTheme: AppBarTheme(
          backgroundColor: SurayColors.azulMarinoProfundo,
          foregroundColor: SurayColors.blancoHumo,
          elevation: 0,
          centerTitle: true,
          shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.3),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: SurayColors.blancoHumo,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        // =====================================================================
        // === Botones con animaciones y colores corporativos ==================
        // =====================================================================
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SurayColors.azulMarinoProfundo,
            foregroundColor: SurayColors.blancoHumo,
            elevation: 2,
            shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.4),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ).copyWith(
            // Animación hover para web
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return SurayColors.naranjaQuemado.withOpacity(0.2);
                }
                if (states.contains(MaterialState.pressed)) {
                  return SurayColors.naranjaQuemado.withOpacity(0.3);
                }
                return null;
              },
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: SurayColors.azulMarinoProfundo,
            side: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: SurayColors.azulMarinoProfundo,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // =====================================================================
        // === Cards con sombras modernas y animación =========================
        // =====================================================================
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.15),
          margin: EdgeInsets.all(8),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: SurayColors.grisAntracita.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),

        // =====================================================================
        // === Inputs modernos con bordes corporativos ========================
        // =====================================================================
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SurayColors.grisAntracita.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SurayColors.azulMarinoProfundo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: TextStyle(color: SurayColors.grisAntracita),
          hintStyle: TextStyle(color: SurayColors.grisAntracita.withOpacity(0.6)),
        ),

        // =====================================================================
        // === Chips con colores corporativos ==================================
        // =====================================================================
        chipTheme: ChipThemeData(
          backgroundColor: SurayColors.grisAntracita.withOpacity(0.1),
          selectedColor: SurayColors.azulMarinoProfundo,
          secondarySelectedColor: SurayColors.naranjaQuemado,
          labelStyle: TextStyle(color: SurayColors.azulMarinoProfundo),
          secondaryLabelStyle: TextStyle(color: SurayColors.blancoHumo),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
        ),

        // =====================================================================
        // === Scrollbar visible y personalizado con colores corporativos =====
        // =====================================================================
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all(true),
          thickness: MaterialStateProperty.all(14),
          trackColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.1)),
          trackBorderColor: MaterialStateProperty.all(SurayColors.grisAntracita.withOpacity(0.2)),
          thumbColor: MaterialStateProperty.all(SurayColors.azulMarinoProfundo.withOpacity(0.7)),
          radius: Radius.circular(8),
          interactive: true,
        ),

        // =====================================================================
        // === Diálogos modernos ================================================
        // =====================================================================
        dialogTheme: DialogThemeData(
          elevation: 8,
          shadowColor: SurayColors.azulMarinoProfundo.withOpacity(0.2),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: TextStyle(
            color: SurayColors.azulMarinoProfundo,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),

        // =====================================================================
        // === Progress indicators con color corporativo =======================
        // =====================================================================
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: SurayColors.azulMarinoProfundo,
          circularTrackColor: SurayColors.grisAntracita.withOpacity(0.2),
        ),

        // =====================================================================
        // === Floating Action Button con naranja quemado =====================
        // =====================================================================
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: SurayColors.naranjaQuemado,
          foregroundColor: SurayColors.blancoHumo,
          elevation: 6,
          highlightElevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // =====================================================================
        // === Divisores con gris antracita ====================================
        // =====================================================================
        dividerTheme: DividerThemeData(
          color: SurayColors.grisAntracita.withOpacity(0.2),
          thickness: 1,
          space: 20,
        ),

        // =====================================================================
        // === Lista de tiles modernos =========================================
        // =====================================================================
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: _AppInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget para manejar la inicialización de la app
class _AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() async {
    try {
      // Dar tiempo para que Firebase se inicialice completamente
      await Future.delayed(Duration(milliseconds: 1000));

      // Verificar que Firebase esté funcionando
      print('🔍 Probando conexión con Firestore...');
      await FirebaseService.getBuses(); // Test simple
      print('✅ Conexión con Firestore exitosa');

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error en verificación: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: SurayColors.azulMarinoProfundo,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(32),
            elevation: 8,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error de Conexión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No se pudo conectar con Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: SurayColors.grisAntracita),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Verifica que Firestore esté habilitado en tu proyecto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: SurayColors.grisAntracitaClaro),
                  ),
                  SizedBox(height: 16),
                  ExpansionTile(
                    title: Text('Ver detalles del error',
                      style: TextStyle(color: SurayColors.azulMarinoProfundo)),
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isInitialized = false;
                          });
                          _checkInitialization();
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Reintentar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Continuar sin Firebase (modo offline)
                          setState(() {
                            _isInitialized = true;
                            _errorMessage = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SurayColors.naranjaQuemado,
                        ),
                        icon: Icon(Icons.offline_bolt),
                        label: Text('Modo Offline'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: SurayColors.azulMarinoProfundo,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SurayColors.azulMarinoProfundo,
                SurayColors.azulMarinoClaro,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado con efecto de pulso
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0F2744), // azulMarinoOscuro (igual que login)
                              Color(0xFF2A4A6B), // azulMedio (igual que login)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: SurayColors.naranjaQuemado.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40),
                Text(
                  'Sistema de Gestión de Buses',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: SurayColors.blancoHumo,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: SurayColors.naranjaQuemado,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: SurayColors.naranjaQuemado.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'Suray - Mantenimiento y Control',
                    style: TextStyle(
                      fontSize: 18,
                      color: SurayColors.blancoHumo,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 50),
                Text(
                  'Conectando con Firebase...',
                  style: TextStyle(
                    fontSize: 16,
                    color: SurayColors.blancoHumo.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(SurayColors.naranjaQuemado),
                  strokeWidth: 4,
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SurayColors.blancoHumo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SurayColors.blancoHumo.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud,
                        size: 16,
                        color: SurayColors.blancoHumo.withOpacity(0.7),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'v2.0.23 • Proyecto: mant-suray',
                        style: TextStyle(
                          fontSize: 12,
                          color: SurayColors.blancoHumo.withOpacity(0.7),
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
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

    // Si está inicializado, mostrar LoginScreen
    return LoginScreen();
  }
}