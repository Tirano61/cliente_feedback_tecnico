import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cliente_feedback_tecnico/core/di/app_dependencies.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/pages/login_page.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/pages/nueva_orden_servicio_page.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';

void main() {
  final deps = AppDependencies.create();
  runApp(App(deps: deps));
}

class App extends StatelessWidget {
  final AppDependencies deps;
  static const Color _azulOscuro = Color(0xFF0B2A4A);
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const App({required this.deps, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            deps.loginUseCase,
            deps.restaurarSesionUseCase,
            deps.cerrarSesionUseCase,
            sesionExpirada: deps.apiClient.sesionExpirada,
          )..add(const AppStarted()),
        ),
        BlocProvider(
          create: (_) => CatalogoBloc(deps.obtenerCatalogosUseCase),
        ),
        BlocProvider(
          create: (_) => ServicioBloc(
            deps.cargarServicioUseCase,
            deps.obtenerMisServiciosUseCase,
            deps.buscarClientesUseCase,
            deps.crearClienteRapidoUseCase,
            deps.obtenerCotizacionActualUseCase,
            deps.buscarRepuestosUseCase,
            deps.generarPdfOrdenServicioUseCase,
            deps.subirDocumentoFirmadoUseCase,
            deps.encolarDocumentoPendienteUseCase,
            deps.obtenerDocumentosPendientesUseCase,
            deps.quitarDocumentoPendienteUseCase,
          ),
        ),
        BlocProvider(
          create: (_) => LiquidacionesBloc(
            deps.obtenerMisLiquidacionesUseCase,
            deps.obtenerItemsLiquidacionUseCase,
          ),
        ),
      ],
      child: MaterialApp(
          title: 'Feedback Tecnico',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _azulOscuro,
              brightness: Brightness.light,
            ).copyWith(
              primary: _azulOscuro,
              secondary: const Color(0xFF1D4E89),
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
            appBarTheme: const AppBarTheme(
              backgroundColor: _azulOscuro,
              foregroundColor: Colors.white,
              centerTitle: false,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: _azulOscuro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: _azulOscuro,
              foregroundColor: Colors.white,
            ),
          ),
          home: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) => current is AuthUnauthenticated,
            listener: (context, state) {
              if (state is! AuthUnauthenticated) {
                return;
              }

              // Al cerrar sesion la app vuelve al login: hay que soltar las
              // pantallas apiladas encima (mis servicios, liquidaciones).
              _navigatorKey.currentState?.popUntil((route) => route.isFirst);

              final mensaje = state.mensaje;
              if (mensaje != null && mensaje.isNotEmpty) {
                _messengerKey.currentState
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(mensaje)));
              }
            },
            builder: (context, state) {
              if (state is AuthInitial || state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is AuthAuthenticated) {
                return const NuevaOrdenServicioPage();
              }
              return const LoginPage();
            },
          ),
        ),
    );
  }
}





