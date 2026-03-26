import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServicioBloc extends Bloc<ServicioEvent, ServicioState> {
	static const Set<String> _partesFallaronPermitidas = {
		'indicador',
		'celda',
		'app_movil',
		'app_pc',
		'tablet',
		'otro',
	};

	final CargarServicioUseCase _cargarServicioUseCase;
	final ObtenerMisServiciosUseCase _obtenerMisServiciosUseCase;
	final BuscarClientesUseCase _buscarClientesUseCase;
	final CrearClienteRapidoUseCase _crearClienteRapidoUseCase;

	ServicioBloc(
		this._cargarServicioUseCase,
		this._obtenerMisServiciosUseCase,
		this._buscarClientesUseCase,
		this._crearClienteRapidoUseCase,
	) : super(const ServicioFormularioState()) {
		on<ServicioFormularioCambiado>(_onServicioFormularioCambiado);
		on<ServicioBuscarClienteSolicitado>(_onServicioBuscarClienteSolicitado);
		on<ServicioClienteSeleccionado>(_onServicioClienteSeleccionado);
		on<ServicioCrearClienteRapidoSolicitado>(_onServicioCrearClienteRapidoSolicitado);
		on<ServicioGuardarPressed>(_onServicioGuardarPressed);
		on<MisServiciosSolicitados>(_onMisServiciosSolicitados);
		on<ServicioFormularioReiniciado>(_onServicioFormularioReiniciado);
	}

	ServicioFormularioState _estadoFormularioActual() {
		if (state is ServicioFormularioState) {
			return state as ServicioFormularioState;
		}
		return const ServicioFormularioState();
	}

	void _onServicioFormularioCambiado(
		ServicioFormularioCambiado event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();

		emit(
			actual.copyWith(
				canal: event.canal,
				clienteId: event.clienteId,
				lugarProvinciaId: event.zonaId,
				lugarDetalle: event.lugarDetalle,
				equipoNroSerie: event.equipoNroSerie,
				equipoModelo: event.equipoModelo,
				equipoUbicacion: event.equipoUbicacion,
				equipoAnio: event.equipoAnio,
				partesFallaronTexto: event.partesFallaronTexto,
				km: event.km,
				sintoma: event.sintoma,
				diagnosticoCatIdsSeleccionados: event.diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle: event.diagnosticoDetalle,
				resolucionId: event.resolucionId,
				observaciones: event.observaciones,
				productoIdsSeleccionados: event.productoIdsSeleccionados,
				errorMensaje: null,
				exitoMensaje: null,
			),
		);
	}

	Future<void> _onServicioBuscarClienteSolicitado(
		ServicioBuscarClienteSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		final query = event.query.trim();

		if (query.isEmpty) {
			emit(
				actual.copyWith(
					buscandoClientes: false,
					clientesEncontrados: const [],
					errorMensaje: null,
					exitoMensaje: null,
				),
			);
			return;
		}

		emit(
			actual.copyWith(
				buscandoClientes: true,
				errorMensaje: null,
				exitoMensaje: null,
			),
		);

		try {
			final clientes = await _buscarClientesUseCase.ejecutar(query);
			emit(
				actual.copyWith(
					buscandoClientes: false,
					clientesEncontrados: clientes,
					errorMensaje:
							clientes.isEmpty ? 'No se encontraron clientes para "$query".' : null,
				),
			);
		} on ServerException catch (e) {
			emit(
				actual.copyWith(
					buscandoClientes: false,
					errorMensaje: e.mensaje,
				),
			);
		} catch (_) {
			emit(
				actual.copyWith(
					buscandoClientes: false,
					errorMensaje: 'No se pudieron buscar clientes.',
				),
			);
		}
	}

	void _onServicioClienteSeleccionado(
		ServicioClienteSeleccionado event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		emit(
			actual.copyWith(
				clienteSeleccionado: event.cliente,
				clienteId: event.cliente.id,
				clientesEncontrados: const [],
				errorMensaje: null,
				exitoMensaje: null,
			),
		);
	}

	Future<void> _onServicioCrearClienteRapidoSolicitado(
		ServicioCrearClienteRapidoSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		emit(
			actual.copyWith(
				creandoCliente: true,
				errorMensaje: null,
				exitoMensaje: null,
			),
		);

		try {
			final dynamic payload = jsonDecode(event.payloadJson);
			if (payload is! Map<String, dynamic>) {
				emit(
					actual.copyWith(
						creandoCliente: false,
						errorMensaje: 'El alta rapida debe enviarse como JSON objeto.',
					),
				);
				return;
			}

			final cliente = await _crearClienteRapidoUseCase.ejecutar(payload);
			emit(
				actual.copyWith(
					creandoCliente: false,
					clienteSeleccionado: cliente,
					clienteId: cliente.id,
					clientesEncontrados: [cliente],
					exitoMensaje: 'Cliente creado y seleccionado.',
				),
			);
		} on FormatException {
			emit(
				actual.copyWith(
					creandoCliente: false,
					errorMensaje: 'JSON invalido para alta rapida de cliente.',
				),
			);
		} on ServerException catch (e) {
			emit(
				actual.copyWith(
					creandoCliente: false,
					errorMensaje: e.mensaje,
				),
			);
		} catch (_) {
			emit(
				actual.copyWith(
					creandoCliente: false,
					errorMensaje: 'No se pudo crear el cliente.',
				),
			);
		}
	}

	Future<void> _onServicioGuardarPressed(
		ServicioGuardarPressed event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		final errorValidacion = _validarFormulario(actual);
		if (errorValidacion != null) {
			emit(actual.copyWith(errorMensaje: errorValidacion, exitoMensaje: null));
			return;
		}

		emit(actual.copyWith(guardando: true, errorMensaje: null, exitoMensaje: null));

		try {
			final servicio = _mapearServicio(actual);
			await _cargarServicioUseCase.ejecutar(servicio);
			emit(
				const ServicioFormularioState(
					exitoMensaje: 'Orden de servicio creada correctamente.',
				),
			);
		} on ServerException catch (e) {
			emit(actual.copyWith(guardando: false, errorMensaje: e.mensaje));
		} catch (_) {
			emit(
				actual.copyWith(
					guardando: false,
					errorMensaje: 'No se pudo guardar la orden de servicio.',
				),
			);
		}
	}

	Future<void> _onMisServiciosSolicitados(
		MisServiciosSolicitados event,
		Emitter<ServicioState> emit,
	) async {
		emit(const MisServiciosLoading());
		try {
			final servicios = await _obtenerMisServiciosUseCase.ejecutar();
			emit(MisServiciosLoaded(servicios: servicios));
		} on ServerException catch (e) {
			emit(ServicioError(mensaje: e.mensaje));
		} catch (_) {
			emit(const ServicioError(mensaje: 'No se pudieron cargar los servicios.'));
		}
	}

	void _onServicioFormularioReiniciado(
		ServicioFormularioReiniciado event,
		Emitter<ServicioState> emit,
	) {
		emit(const ServicioFormularioState());
	}

	String? _validarFormulario(ServicioFormularioState estado) {
		if (estado.canal == null) {
			return 'Selecciona el canal del servicio.';
		}
		if (estado.clienteId.trim().isEmpty) {
			return 'Debes seleccionar un cliente.';
		}
		if (estado.lugarProvinciaId.trim().isEmpty) {
			return 'Selecciona la provincia/zona del servicio.';
		}
		if (estado.lugarDetalle.trim().isEmpty) {
			return 'Completa el detalle del lugar.';
		}
		if (estado.equipoNroSerie.trim().isEmpty) {
			return 'Completa el numero de serie del equipo.';
		}
		if (estado.equipoModelo.trim().isEmpty) {
			return 'Completa el modelo del equipo.';
		}
		if (estado.equipoUbicacion.trim().isEmpty) {
			return 'Completa la ubicacion del equipo.';
		}
		final equipoAnio = int.tryParse(estado.equipoAnio.trim());
		if (equipoAnio == null || equipoAnio <= 0) {
			return 'Completa un anio de equipo valido.';
		}
		if (_partesFallaronDesdeTexto(estado.partesFallaronTexto).isEmpty) {
			return 'Indica al menos una parte que fallo.';
		}
		final km = int.tryParse(estado.km.trim());
		if (km == null || km < 0) {
			return 'Completa los kilometros con un valor numerico valido.';
		}
		if (estado.sintoma.trim().isEmpty) {
			return 'Completa el sintoma reportado.';
		}
		if (estado.diagnosticoDetalle.trim().isEmpty) {
			return 'Completa el detalle tecnico del diagnostico.';
		}
		if (estado.diagnosticoCatIdsSeleccionados.isEmpty) {
			return 'Selecciona al menos una categoria de diagnostico.';
		}
		if (estado.resolucionId.trim().isEmpty) {
			return 'Selecciona una resolucion.';
		}
		if (estado.productoIdsSeleccionados.isEmpty) {
			return 'Selecciona al menos un producto en Partes que mostraban falla.';
		}
		return null;
	}

	Servicio _mapearServicio(ServicioFormularioState estado) {
		return Servicio(
			id: '',
			canal: estado.canal!,
			clienteId: estado.clienteId.trim(),
			lugarProvinciaId: estado.lugarProvinciaId.trim(),
			lugarDetalle: estado.lugarDetalle.trim(),
			equipoNroSerie: estado.equipoNroSerie.trim(),
			equipoModelo: estado.equipoModelo.trim(),
			equipoUbicacion: estado.equipoUbicacion.trim(),
			equipoAnio: int.parse(estado.equipoAnio.trim()),
			partesFallaron: _partesFallaronDesdeTexto(estado.partesFallaronTexto),
			km: int.parse(estado.km.trim()),
			sintoma: estado.sintoma.trim(),
			diagnosticoDetalle: estado.diagnosticoDetalle.trim(),
			diagnosticoCatIds: estado.diagnosticoCatIdsSeleccionados,
			resolucionId: estado.resolucionId.trim(),
			observaciones: estado.observaciones.trim().isEmpty
					? null
					: estado.observaciones.trim(),
			productoIds: estado.productoIdsSeleccionados,
		);
	}

	List<String> _partesFallaronDesdeTexto(String texto) {
		return texto
				.split(RegExp(r'[\n,;]'))
				.map(_normalizarParteFallada)
				.where((item) => item.isNotEmpty)
				.toSet()
				.toList();
	}

	String _normalizarParteFallada(String valorCrudo) {
		final valor = valorCrudo.toLowerCase().trim();
		if (valor.isEmpty) {
			return '';
		}

		final valorNormalizado = valor.replaceAll(' ', '_').replaceAll('-', '_');
		if (_partesFallaronPermitidas.contains(valorNormalizado)) {
			return valorNormalizado;
		}

		if (valor.contains('indicador')) {
			return 'indicador';
		}
		if (valor.contains('celda')) {
			return 'celda';
		}
		if (valor.contains('app') && (valor.contains('movil') || valor.contains('mobile'))) {
			return 'app_movil';
		}
		if (valor.contains('movil') || valor.contains('mobile') || valor.contains('celular')) {
			return 'app_movil';
		}
		if (valor.contains('app') && valor.contains('pc')) {
			return 'app_pc';
		}
		if (valor.contains('pc') || valor.contains('web') || valor.contains('escritorio')) {
			return 'app_pc';
		}
		if (valor.contains('tablet')) {
			return 'tablet';
		}

		return 'otro';
	}
}


