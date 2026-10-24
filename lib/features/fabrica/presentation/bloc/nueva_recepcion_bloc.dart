import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_recepcion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nueva_recepcion_state.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NuevaRecepcionBloc extends Bloc<NuevaRecepcionEvent, NuevaRecepcionState> {
	final CrearRecepcionUseCase _crearRecepcionUseCase;
	final BuscarClientesUseCase _buscarClientesUseCase;

	/// Una busqueda nueva deja sin efecto la que siga en vuelo.
	int _secuenciaClientes = 0;

	NuevaRecepcionBloc(
		this._crearRecepcionUseCase,
		this._buscarClientesUseCase,
	) : super(const NuevaRecepcionState()) {
		on<NuevaRecepcionIniciada>(_onIniciada);
		on<NuevaRecepcionBuscarClienteSolicitado>(_onBuscarCliente);
		on<NuevaRecepcionClienteSeleccionado>(_onClienteSeleccionado);
		on<NuevaRecepcionCambiada>(_onCambiada);
		on<NuevaRecepcionGuardada>(_onGuardada);
	}

	void _onIniciada(
		NuevaRecepcionIniciada event,
		Emitter<NuevaRecepcionState> emit,
	) {
		_secuenciaClientes++;
		emit(const NuevaRecepcionState());
	}

	Future<void> _onBuscarCliente(
		NuevaRecepcionBuscarClienteSolicitado event,
		Emitter<NuevaRecepcionState> emit,
	) async {
		final consulta = ++_secuenciaClientes;
		final query = event.query.trim();
		if (query.isEmpty) {
			emit(state.copyWith(buscandoClientes: false, clientesEncontrados: const []));
			return;
		}

		emit(state.copyWith(buscandoClientes: true));

		String? error;
		try {
			final clientes = await _buscarClientesUseCase.ejecutar(query);
			if (consulta != _secuenciaClientes || emit.isDone) {
				return;
			}
			emit(
				state.copyWith(
					buscandoClientes: false,
					clientesEncontrados: clientes,
					errorMensaje:
							clientes.isEmpty ? 'No se encontraron clientes para "$query".' : null,
				),
			);
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudieron buscar clientes.';
		}

		if (consulta == _secuenciaClientes && !emit.isDone) {
			emit(state.copyWith(buscandoClientes: false, errorMensaje: error));
		}
	}

	void _onClienteSeleccionado(
		NuevaRecepcionClienteSeleccionado event,
		Emitter<NuevaRecepcionState> emit,
	) {
		_secuenciaClientes++;
		emit(
			state.copyWith(
				clienteSeleccionado: event.cliente,
				clientesEncontrados: const [],
				buscandoClientes: false,
			),
		);
	}

	void _onCambiada(
		NuevaRecepcionCambiada event,
		Emitter<NuevaRecepcionState> emit,
	) {
		emit(
			state.copyWith(
				indicadorNroSerie: event.indicadorNroSerie,
				indicadorProductoId: event.indicadorProductoId,
				limpiarProducto: event.limpiarProducto,
				queLlego: event.queLlego,
				sintomaReportado: event.sintomaReportado,
				observaciones: event.observaciones,
			),
		);
	}

	Future<void> _onGuardada(
		NuevaRecepcionGuardada event,
		Emitter<NuevaRecepcionState> emit,
	) async {
		if (state.guardando) {
			return;
		}

		final cliente = state.clienteSeleccionado;
		final nroSerie = state.indicadorNroSerie.trim();
		final queLlego = state.queLlego.trim();
		final sintoma = state.sintomaReportado.trim();
		final faltantes = [
			if (cliente == null) 'cliente',
			if (nroSerie.isEmpty) 'número de serie del indicador',
			if (queLlego.isEmpty) 'qué llegó',
			if (sintoma.isEmpty) 'qué reporta el cliente',
		];
		if (faltantes.isNotEmpty) {
			// Si toca "Guardar" otra vez sin cambios, el aviso tiene que volver a salir.
			emit(state.copyWith());
			emit(state.copyWith(errorMensaje: 'Falta completar: ${faltantes.join(', ')}.'));
			return;
		}

		final observaciones = state.observaciones.trim();
		emit(state.copyWith(guardando: true));

		try {
			final recepcion = await _crearRecepcionUseCase.ejecutar(
				NuevaRecepcion(
					clienteId: cliente!.id,
					indicadorNroSerie: nroSerie,
					indicadorProductoId: state.indicadorProductoId,
					queLlego: queLlego,
					sintomaReportado: sintoma,
					observaciones: observaciones.isEmpty ? null : observaciones,
				),
			);
			emit(state.copyWith(guardando: false, recepcionCreada: recepcion));
		} on ReglaFabricaException catch (e) {
			// Se conserva todo lo cargado: el tecnico corrige y vuelve a guardar.
			final recepcionId = e.extra['recepcionId'];
			if (e.codigo == CodigoReglaFabrica.recepcionAbierta &&
					recepcionId is String &&
					recepcionId.isNotEmpty) {
				final numero = e.extra['numero'];
				emit(
					state.copyWith(
						guardando: false,
						recepcionAbierta: RecepcionAbiertaExistente(
							recepcionId: recepcionId,
							numero: numero is num ? numero.toInt() : null,
							mensaje: e.mensaje,
						),
					),
				);
				return;
			}
			emit(state.copyWith(guardando: false, errorMensaje: e.mensaje));
		} on ServerException catch (e) {
			emit(state.copyWith(guardando: false, errorMensaje: e.mensaje));
		} catch (_) {
			emit(
				state.copyWith(
					guardando: false,
					errorMensaje: 'No se pudo registrar la recepción.',
				),
			);
		}
	}
}
