import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cliente_feedback_tecnico/core/di/app_dependencies.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/pages/login_page.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/pages/nueva_orden_servicio_page.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';

void main() {
  final deps = AppDependencies.create();
  runApp(App(deps: deps));
}

class App extends StatelessWidget {
  final AppDependencies deps;
  static const Color _azulOscuro = Color(0xFF0B2A4A);

  const App({required this.deps, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(deps.loginUseCase)..add(const AppStarted()),
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
          ),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<CatalogoBloc>().add(const CargarCatalogos());
          }
        },
        child: MaterialApp(
          title: 'Feedback Tecnico',
          debugShowCheckedModeBanner: false,
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
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
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
      ),
    );
  }
}





