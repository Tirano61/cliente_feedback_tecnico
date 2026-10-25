import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/crear_ingreso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_event.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/nuevo_ingreso_state.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NuevoIngresoBloc extends Bloc<NuevoIngresoEvent, NuevoIngresoState> {
	final CrearIngresoUseCase _crearIngresoUseCase;
	final BuscarClientesUseCase _buscarClientesUseCase;
	final CrearClienteRapidoUseCase _crearClienteRapidoUseCase;

	/// Una busqueda nueva deja sin efecto la que siga en vuelo.
	int _secuenciaClientes = 0;

	NuevoIngresoBloc(
		this._crearIngresoUseCase,
		this._buscarClientesUseCase,
		this._crearClienteRapidoUseCase,
	) : super(const NuevoIngresoState()) {
		on<NuevoIngresoIniciado>(_onIniciado);
		on<NuevoIngresoBuscarClienteSolicitado>(_onBuscarCliente);
		on<NuevoIngresoClienteSeleccionado>(_onClienteSeleccionado);
		on<NuevoIngresoClienteRapidoSolicitado>(_onClienteRapidoSolicitado);
		on<NuevoIngresoCambiado>(_onCambiado);
		on<NuevoIngresoPiezaInstaladaElegida>(_onPiezaInstaladaElegida);
		on<NuevoIngresoGuardado>(_onGuardado);
	}

	void _onIniciado(
		NuevoIngresoIniciado event,
		Emitter<NuevoIngresoState> emit,
	) {
		_secuenciaClientes++;
		emit(NuevoIngresoState(recepcion: event.recepcion));
	}

	Future<void> _onBuscarCliente(
		NuevoIngresoBuscarClienteSolicitado event,
		Emitter<NuevoIngresoState> emit,
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
		NuevoIngresoClienteSeleccionado event,
		Emitter<NuevoIngresoState> emit,
	) {
		_secuenciaClientes++;
		emit(
			state.copyWith(
				clienteOrigen: event.cliente,
				clientesEncontrados: const [],
				buscandoClientes: false,
			),
		);
	}

	Future<void> _onClienteRapidoSolicitado(
		NuevoIngresoClienteRapidoSolicitado event,
		Emitter<NuevoIngresoState> emit,
	) async {
		if (state.creandoCliente) {
			return;
		}

		final cuit = event.cuit.trim();
		final nombre = event.nombre.trim();
		final faltantes = [
			if (cuit.isEmpty) 'CUIT',
			if (nombre.isEmpty) 'nombre',
		];
		if (faltantes.isNotEmpty) {
			emit(state.copyWith(errorAltaCliente: 'Falta completar: ${faltantes.join(', ')}.'));
			return;
		}

		// Body de POST /clientes: los opcionales vacios no se mandan.
		final payload = <String, dynamic>{
			'cuit': cuit,
			'nombre': nombre,
			if (event.contacto.trim().isNotEmpty) 'contacto': event.contacto.trim(),
			if (event.telefono.trim().isNotEmpty) 'telefono': event.telefono.trim(),
			if (event.localidad.trim().isNotEmpty) 'localidad': event.localidad.trim(),
		};
		emit(state.copyWith(creandoCliente: true, limpiarErrorAltaCliente: true));

		String error;
		try {
			final cliente = await _crearClienteRapidoUseCase.ejecutar(payload);
			// Una busqueda que siga en vuelo ya no corresponde.
			_secuenciaClientes++;
			emit(
				state.copyWith(
					creandoCliente: false,
					clienteOrigen: cliente,
					clientesEncontrados: const [],
					buscandoClientes: false,
					clienteCreado: cliente,
				),
			);
			return;
		} on ServerException catch (e) {
			final yaExiste =
					e.statusCode == 400 && e.mensaje.toLowerCase().contains('cliente ya existe');
			error = yaExiste ? 'El cliente con el CUIT: $cuit ya existe.' : e.mensaje;
		} catch (_) {
			error = 'No se pudo crear el cliente.';
		}

		emit(state.copyWith(creandoCliente: false, errorAltaCliente: error));
	}

	void _onCambiado(
		NuevoIngresoCambiado event,
		Emitter<NuevoIngresoState> emit,
	) {
		// El modelo elegido es de placa o de celda: si cambia el tipo ya no vale.
		final cambioTipo = event.tipo != null && event.tipo != state.tipo;
		emit(
			state.copyWith(
				tipo: event.tipo,
				nroSerie: event.nroSerie,
				productoId: event.productoId,
				limpiarProducto: event.limpiarProducto || (cambioTipo && event.productoId == null),
				indicadorNroSerie: event.indicadorNroSerie,
				observacionTecnico: event.observacionTecnico,
			),
		);
	}

	void _onPiezaInstaladaElegida(
		NuevoIngresoPiezaInstaladaElegida event,
		Emitter<NuevoIngresoState> emit,
	) {
		final pieza = event.pieza;
		if (!NuevoIngresoState.tiposIngresables.contains(pieza.tipo)) {
			return;
		}
		emit(
			state.copyWith(
				tipo: pieza.tipo,
				nroSerie: pieza.nroSerie,
				productoId: pieza.producto?.id,
				limpiarProducto: pieza.producto == null,
			),
		);
	}

	Future<void> _onGuardado(
		NuevoIngresoGuardado event,
		Emitter<NuevoIngresoState> emit,
	) async {
		if (state.guardando) {
			return;
		}

		final recepcion = state.recepcion;
		final tipo = state.tipo;
		final cliente = state.clienteOrigen;
		final nroSerie = state.nroSerie.trim();
		final observacion = state.observacionTecnico.trim();
		final faltantes = [
			if (tipo == null) 'tipo de pieza',
			if (nroSerie.isEmpty) 'número de serie',
			if (recepcion == null && cliente == null) 'cliente o sucursal de origen',
			if (observacion.isEmpty) 'qué observó el técnico',
		];
		if (faltantes.isNotEmpty) {
			// Si toca "Guardar" otra vez sin cambios, el aviso tiene que volver a salir.
			emit(state.copyWith());
			emit(state.copyWith(errorMensaje: 'Falta completar: ${faltantes.join(', ')}.'));
			return;
		}

		// Con recepcion, cliente e indicador salen de ella: no se mandan.
		final indicador = state.indicadorNroSerie.trim();
		emit(state.copyWith(guardando: true));

		try {
			final ingreso = await _crearIngresoUseCase.ejecutar(
				NuevoIngreso(
					tipo: tipo!,
					nroSerie: nroSerie,
					productoId: state.productoId,
					recepcionId: recepcion?.recepcionId,
					clienteOrigenId: recepcion == null ? cliente!.id : null,
					indicadorNroSerie: recepcion == null && indicador.isNotEmpty ? indicador : null,
					observacionTecnico: observacion,
				),
			);
			emit(state.copyWith(guardando: false, ingresoCreado: ingreso));
		} on ReglaFabricaException catch (e) {
			// Se conserva todo lo cargado: el tecnico corrige y vuelve a guardar.
			final ingresoId = e.extra['ingresoId'];
			if (e.codigo == CodigoReglaFabrica.ingresoAbierto &&
					ingresoId is String &&
					ingresoId.isNotEmpty) {
				final numero = e.extra['numero'];
				emit(
					state.copyWith(
						guardando: false,
						ingresoAbierto: IngresoAbiertoExistente(
							ingresoId: ingresoId,
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
			emit(state.copyWith(guardando: false, errorMensaje: 'No se pudo registrar el ingreso.'));
		}
	}
}
