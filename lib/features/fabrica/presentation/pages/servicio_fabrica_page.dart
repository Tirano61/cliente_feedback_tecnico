import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_bloc.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/recepcion_detalle_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/servicio_fabrica_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/precarga_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/widgets/formulario_servicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// El formulario de servicio de siempre, con canal fabrica fijo y los datos de
/// la recepcion. Al guardar, la vinculacion la hace el detalle de la recepcion.
class ServicioFabricaPage extends StatelessWidget {
	final String recepcionId;
	final int numeroRecepcion;
	final PrecargaFormularioServicio precarga;

	const ServicioFabricaPage({
		required this.recepcionId,
		required this.numeroRecepcion,
		required this.precarga,
		super.key,
	});

	@override
	Widget build(BuildContext context) {
		return BlocProvider<ServicioBloc>.value(
			value: context.read<ServicioFabricaBloc>(),
			child: BlocBuilder<ServicioBloc, ServicioState>(
				buildWhen: (anterior, actual) => _guardando(anterior) != _guardando(actual),
				builder: (context, state) {
					// Si se sale mientras se guarda, el servicio se crea y nadie lo vincula.
					return PopScope(
						canPop: !_guardando(state),
						child: Scaffold(
							appBar: AppBar(title: Text('Servicio de fábrica · Recepción N° $numeroRecepcion')),
							body: Padding(
								padding: const EdgeInsets.all(4),
								child: FormularioServicio(
									precarga: precarga,
									onOrdenGuardada: (orden) {
										context.read<RecepcionDetalleBloc>().add(
											RecepcionServicioGuardado(
												recepcionId: recepcionId,
												servicioId: orden.servicioId,
											),
										);
										Navigator.of(context).pop();
									},
								),
							),
						),
					);
				},
			),
		);
	}

	static bool _guardando(ServicioState state) {
		return state is ServicioFormularioState && state.guardando;
	}
}
