import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cliente_feedback_tecnico/core/di/app_dependencies.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/pages/login_page.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_bloc.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/pages/nuevo_caso_page.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_event.dart';

void main() {
  final deps = AppDependencies.create();
  runApp(App(deps: deps));
}

class App extends StatelessWidget {
  final AppDependencies deps;

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
          create: (_) => CasoBloc(
            deps.cargarCasoUseCase,
            deps.obtenerMisCasosUseCase,
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
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is AuthAuthenticated) {
                return const NuevoCasoPage();
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}




