import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Archivo generado por FlutterFire CLI
import 'screens/main_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Iniciando aplicación...');

    // Inicializar Firebase usando la configuración automática
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente para ${DefaultFirebaseOptions.currentPlatform.projectId}');

    // Inicializar datos de ejemplo si no existen
    print('📊 Verificando datos de ejemplo...');
    await FirebaseService.initializeSampleData();
    print('✅ Datos de ejemplo verificados/inicializados');

    print('🎉 Aplicación lista para usar');
  } catch (e) {
    print('❌ Error crítico al inicializar la aplicación: $e');

    // En caso de error, mostrar información útil
    if (e.toString().contains('API key not valid')) {
      print('🔑 Error de API Key: Problema con la configuración de Firebase');
    } else if (e.toString().contains('project')) {
      print('📁 Error de proyecto: Verifica la configuración en Firebase Console');
    } else if (e.toString().contains('network')) {
      print('🌐 Error de red: Verifica tu conexión a internet');
    }
  }

  runApp(BusManagementApp());
}

class BusManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión de Buses - Suray',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF1565C0),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        // Tema personalizado para chips
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[200]!,
          selectedColor: Color(0xFF1565C0),
          secondarySelectedColor: Color(0xFF1565C0),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // =====================================================================
        // === ✅ MEJORA: TEMA DE SCROLLBAR PARA HACERLO MÁS VISIBLE ============
        // =====================================================================
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: MaterialStateProperty.all(true), // Siempre visible
          thickness: MaterialStateProperty.all(12), // Más grueso (12px)
          trackColor: MaterialStateProperty.all(Colors.grey[300]),
          trackBorderColor: MaterialStateProperty.all(Colors.grey[400]),
          thumbColor: MaterialStateProperty.all(Color(0xFF1565C0).withOpacity(0.7)),
          radius: Radius.circular(6),
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
        backgroundColor: Color(0xFF1565C0),
        body: Center(
          child: Card(
            margin: EdgeInsets.all(32),
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
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Verifica que Firestore esté habilitado en tu proyecto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ExpansionTile(
                    title: Text('Ver detalles del error'),
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
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
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isInitialized = false;
                          });
                          _checkInitialization();
                        },
                        child: Text('Reintentar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Continuar sin Firebase (modo offline)
                          setState(() {
                            _isInitialized = true;
                            _errorMessage = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text('Continuar sin datos'),
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
        backgroundColor: Color(0xFF1565C0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🚌',
                  style: TextStyle(fontSize: 64),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Sistema de Gestión de Buses',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Suray - Mantenimiento y Control',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Conectando con Firebase...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Proyecto: mant-suray',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MainScreen();
  }
}