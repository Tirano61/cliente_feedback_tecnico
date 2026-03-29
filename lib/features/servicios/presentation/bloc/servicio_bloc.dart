import 'dart:convert';
import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ServicioBloc extends Bloc<ServicioEvent, ServicioState> {
	static const Set<String> _partesFallaronPermitidas = {
		'indicador',
		'celda',
		'app_movil',
		'app_pc',
		'tablet',
		'otro',
	};
	static const Uuid _uuid = Uuid();
	static final RegExp _uuidRegex = RegExp(
		r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
	);

	final CargarServicioUseCase _cargarServicioUseCase;
	final ObtenerMisServiciosUseCase _obtenerMisServiciosUseCase;
	final BuscarClientesUseCase _buscarClientesUseCase;
	final CrearClienteRapidoUseCase _crearClienteRapidoUseCase;
	final ObtenerCotizacionActualUseCase _obtenerCotizacionActualUseCase;
	final BuscarRepuestosUseCase _buscarRepuestosUseCase;
	final GenerarPdfOrdenServicioUseCase _generarPdfOrdenServicioUseCase;

	ServicioBloc(
		this._cargarServicioUseCase,
		this._obtenerMisServiciosUseCase,
		this._buscarClientesUseCase,
		this._crearClienteRapidoUseCase,
		this._obtenerCotizacionActualUseCase,
		this._buscarRepuestosUseCase,
		this._generarPdfOrdenServicioUseCase,
	) : super(_crearEstadoFormularioInicial()) {
		on<ServicioFormularioCambiado>(_onServicioFormularioCambiado);
		on<ServicioBuscarClienteSolicitado>(_onServicioBuscarClienteSolicitado);
		on<ServicioClienteSeleccionado>(_onServicioClienteSeleccionado);
		on<ServicioCrearClienteRapidoSolicitado>(_onServicioCrearClienteRapidoSolicitado);
		on<ServicioFacturacionInicializada>(_onServicioFacturacionInicializada);
		on<ServicioBuscarRepuestosSolicitado>(_onServicioBuscarRepuestosSolicitado);
		on<ServicioRepuestoAgregado>(_onServicioRepuestoAgregado);
		on<ServicioRepuestoCantidadCambiada>(_onServicioRepuestoCantidadCambiada);
		on<ServicioRepuestoEliminado>(_onServicioRepuestoEliminado);
		on<ServicioFacturacionParametrosCambiados>(_onServicioFacturacionParametrosCambiados);
		on<ServicioGuardarPressed>(_onServicioGuardarPressed);
		on<MisServiciosSolicitados>(_onMisServiciosSolicitados);
		on<ServicioFormularioReiniciado>(_onServicioFormularioReiniciado);
	}

	static ServicioFormularioState _crearEstadoFormularioInicial() {
		final fechaHoraServicio = DateTime.now();
		final timezoneIana = _resolverTimezoneIanaDesdeFecha(fechaHoraServicio);
		return ServicioFormularioState(
			fechaHoraServicio: fechaHoraServicio,
			timezoneIana: timezoneIana,
			utcOffsetMinutos: fechaHoraServicio.timeZoneOffset.inMinutes,
		);
	}

	static String _resolverTimezoneIanaDesdeFecha(DateTime fechaHora) {
		final zona = fechaHora.timeZoneName.trim();
		if (zona.contains('/')) {
			return zona;
		}
		final zonaNormalizada = zona.toLowerCase();
		if (zonaNormalizada.contains('argentina')) {
			return 'America/Argentina/Buenos_Aires';
		}
		if (zonaNormalizada == 'art') {
			return 'America/Argentina/Buenos_Aires';
		}
		if (zonaNormalizada == '-03' || zonaNormalizada == 'utc-3' || zonaNormalizada == 'gmt-3') {
			return 'America/Argentina/Buenos_Aires';
		}
		return 'America/Argentina/Buenos_Aires';
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
		final fechaHoraServicio = actual.fechaHoraServicio ?? DateTime.now();
		final timezoneIana = actual.timezoneIana.trim().isEmpty
				? _resolverTimezoneIana()
				: actual.timezoneIana.trim();
		final utcOffsetMinutos = actual.utcOffsetMinutos ?? fechaHoraServicio.timeZoneOffset.inMinutes;

		emit(
			_recalcularFacturacion(
				actual.copyWith(
				fechaHoraServicio: fechaHoraServicio,
				timezoneIana: timezoneIana,
				utcOffsetMinutos: utcOffsetMinutos,
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
				productosFallaSeleccionados: event.productosFallaSeleccionados,
				errorMensaje: null,
				exitoMensaje: null,
				),
			),
		);
	}

	Future<void> _onServicioFacturacionInicializada(
		ServicioFacturacionInicializada event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		emit(
			_recalcularFacturacion(
				actual.copyWith(
					cargandoFacturacion: true,
					errorMensaje: null,
					exitoMensaje: null,
				),
			),
		);

		try {
			final cotizacion = await _obtenerCotizacionActualUseCase.ejecutar();
			final repuestos = await _buscarRepuestosUseCase.ejecutar('');

			emit(
				_recalcularFacturacion(
					actual.copyWith(
						cargandoFacturacion: false,
						cotizacionDolarSnapshot: cotizacion.cotizacionDolar,
						valorKmUsdSnapshot: cotizacion.valorKmUsd,
						repuestosDisponibles: repuestos,
						buscandoRepuestos: false,
						errorMensaje: null,
					),
				),
			);
		} on ServerException catch (e) {
			emit(
				_recalcularFacturacion(
					actual.copyWith(
						cargandoFacturacion: false,
						errorMensaje: e.mensaje,
					),
				),
			);
		} catch (_) {
			emit(
				_recalcularFacturacion(
					actual.copyWith(
						cargandoFacturacion: false,
						errorMensaje: 'No se pudo inicializar la facturacion.',
					),
				),
			);
		}
	}

	Future<void> _onServicioBuscarRepuestosSolicitado(
		ServicioBuscarRepuestosSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		final query = event.query.trim();

		if (query.isEmpty) {
			emit(
				actual.copyWith(
					buscandoRepuestos: false,
					repuestosDisponibles: const [],
					errorMensaje: null,
				),
			);
			return;
		}

		emit(
			actual.copyWith(
				buscandoRepuestos: true,
				errorMensaje: null,
			),
		);

		try {
			final repuestos = await _buscarRepuestosUseCase.ejecutar(query);
			emit(
				actual.copyWith(
					buscandoRepuestos: false,
					repuestosDisponibles: repuestos,
				),
			);
		} on ServerException catch (e) {
			emit(
				actual.copyWith(
					buscandoRepuestos: false,
					errorMensaje: e.mensaje,
				),
			);
		} catch (_) {
			emit(
				actual.copyWith(
					buscandoRepuestos: false,
					errorMensaje: 'No se pudieron cargar repuestos.',
				),
			);
		}
	}

	void _onServicioRepuestoAgregado(
		ServicioRepuestoAgregado event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		if (actual.repuestosSeleccionados.any((item) => item.repuesto.id == event.repuesto.id)) {
			return;
		}

		final seleccionados = [...actual.repuestosSeleccionados, RepuestoSeleccionado(repuesto: event.repuesto, cantidad: 1)];
		emit(_recalcularFacturacion(actual.copyWith(repuestosSeleccionados: seleccionados)));
	}

	void _onServicioRepuestoCantidadCambiada(
		ServicioRepuestoCantidadCambiada event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		final cantidad = _doubleDesdeTexto(event.cantidad, valorPorDefecto: 1);
		final cantidadNormalizada = cantidad <= 0 ? 1.0 : cantidad;

		final seleccionados = actual.repuestosSeleccionados
				.map(
					(item) => item.repuesto.id == event.repuestoId
							? item.copyWith(cantidad: cantidadNormalizada)
							: item,
				)
				.toList();

		emit(_recalcularFacturacion(actual.copyWith(repuestosSeleccionados: seleccionados)));
	}

	void _onServicioRepuestoEliminado(
		ServicioRepuestoEliminado event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		final seleccionados = actual.repuestosSeleccionados
				.where((item) => item.repuesto.id != event.repuestoId)
				.toList();
		emit(_recalcularFacturacion(actual.copyWith(repuestosSeleccionados: seleccionados)));
	}

	void _onServicioFacturacionParametrosCambiados(
		ServicioFacturacionParametrosCambiados event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		emit(
			_recalcularFacturacion(
				actual.copyWith(
					ivaPorcentaje: event.ivaPorcentaje,
					descuentoPorcentaje: event.descuentoPorcentaje,
				),
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
		final actual = _recalcularFacturacion(_estadoFormularioActual());
		final idempotencyKeyActual = actual.idempotencyKey.trim();
		final idempotencyKey = _esUuidValido(idempotencyKeyActual)
				? idempotencyKeyActual
				: _generarIdempotencyKey();
		final fechaHoraServicio = actual.fechaHoraServicio ?? DateTime.now();
		final timezoneIana = actual.timezoneIana.trim().isEmpty
				? _resolverTimezoneIana()
				: actual.timezoneIana.trim();
		final utcOffsetMinutos = actual.utcOffsetMinutos ?? fechaHoraServicio.timeZoneOffset.inMinutes;
		final estadoConClave = actual.copyWith(
			idempotencyKey: idempotencyKey,
			fechaHoraServicio: fechaHoraServicio,
			timezoneIana: timezoneIana,
			utcOffsetMinutos: utcOffsetMinutos,
		);

		final errorValidacion = _validarFormulario(estadoConClave);
		if (errorValidacion != null) {
			emit(estadoConClave.copyWith(errorMensaje: errorValidacion, exitoMensaje: null));
			return;
		}

		emit(estadoConClave.copyWith(guardando: true, errorMensaje: null, exitoMensaje: null));

		try {
			final servicio = _mapearServicio(estadoConClave);
			final orden = await _cargarServicioUseCase.ejecutar(servicio);
			final fechaHoraOrden = orden.fechaHoraServicio ?? estadoConClave.fechaHoraServicio;
			final fechaHoraTexto = fechaHoraOrden == null
					? null
					: _formatearFechaHoraLocal(fechaHoraOrden);
			final mensajeExitoBase = orden.replayed
					? 'Orden recuperada por idempotencia (${orden.servicioId})${fechaHoraTexto == null ? '' : ' - Fecha y hora: $fechaHoraTexto'}.'
					: 'Orden de servicio creada correctamente (${orden.servicioId})${fechaHoraTexto == null ? '' : ' - Fecha y hora: $fechaHoraTexto'}.';
			String mensajeExito = mensajeExitoBase;
			final nombreArchivoPdf = 'orden_servicio_${orden.servicioId}.pdf';
			Uint8List? pdfBytes;

			try {
				pdfBytes = await _generarPdfOrdenServicioUseCase.ejecutar(orden);
			} catch (_) {
				mensajeExito = '$mensajeExitoBase PDF no generado en este intento.';
			}

			emit(
				_crearEstadoFormularioInicial().copyWith(
					exitoMensaje: mensajeExito,
					pdfOrdenBytes: pdfBytes,
					pdfOrdenNombre: nombreArchivoPdf,
				),
			);
		} on ServerException catch (e) {
			emit(estadoConClave.copyWith(guardando: false, errorMensaje: e.mensaje));
		} catch (_) {
			emit(
				estadoConClave.copyWith(
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
		emit(_crearEstadoFormularioInicial());
		add(const ServicioFacturacionInicializada());
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
		final km = _doubleDesdeTexto(estado.km, valorPorDefecto: 0);
		if (km < 0) {
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
		if (_productosFallaNormalizados(estado.productosFallaSeleccionados).isEmpty) {
			return 'Selecciona al menos un producto en Partes que mostraban falla.';
		}
		return null;
	}

	Servicio _mapearServicio(ServicioFormularioState estado) {
		final estadoRecalculado = _recalcularFacturacion(estado);
		final productosFalla = _productosFallaNormalizados(
			estadoRecalculado.productosFallaSeleccionados,
		);
		final kmCantidad = _doubleDesdeTexto(estadoRecalculado.km, valorPorDefecto: 0);
		final facturacionItems = _construirItemsFacturacion(estadoRecalculado, kmCantidad);
		final incluyeFacturacion = kmCantidad > 0 || estadoRecalculado.repuestosSeleccionados.isNotEmpty;
		final partesFallaron = productosFalla
				.map((item) => item.parteFallo)
				.where((item) => item.isNotEmpty)
				.toSet()
				.toList();

		return Servicio(
			id: '',
			idempotencyKey: estadoRecalculado.idempotencyKey.trim(),
			fechaHoraServicio: estadoRecalculado.fechaHoraServicio,
			timezoneIana: estadoRecalculado.timezoneIana.trim().isEmpty
					? null
					: estadoRecalculado.timezoneIana.trim(),
			utcOffsetMinutos: estadoRecalculado.utcOffsetMinutos,
			canal: estadoRecalculado.canal!,
			clienteId: estadoRecalculado.clienteId.trim(),
			lugarProvinciaId: estadoRecalculado.lugarProvinciaId.trim(),
			lugarDetalle: estadoRecalculado.lugarDetalle.trim(),
			equipoNroSerie: estadoRecalculado.equipoNroSerie.trim(),
			equipoModelo: estadoRecalculado.equipoModelo.trim(),
			equipoUbicacion: estadoRecalculado.equipoUbicacion.trim(),
			equipoAnio: int.parse(estadoRecalculado.equipoAnio.trim()),
			partesFallaron: partesFallaron,
			km: kmCantidad.round(),
			sintoma: estadoRecalculado.sintoma.trim(),
			diagnosticoDetalle: estadoRecalculado.diagnosticoDetalle.trim(),
			diagnosticoCatIds: estadoRecalculado.diagnosticoCatIdsSeleccionados,
			resolucionId: estadoRecalculado.resolucionId.trim(),
			observaciones: estadoRecalculado.observaciones.trim().isEmpty
					? null
					: estadoRecalculado.observaciones.trim(),
			productosFalla: productosFalla,
			facturacion: incluyeFacturacion
					? Facturacion(
							cotizacionDolarSnapshot: estadoRecalculado.cotizacionDolarSnapshot,
							valorKmUsdSnapshot: estadoRecalculado.valorKmUsdSnapshot,
							kmCantidad: kmCantidad,
							subtotalKmUsd: estadoRecalculado.subtotalKmUsd,
							subtotalKmArs: estadoRecalculado.subtotalKmArs,
							subtotalGeneralUsd: estadoRecalculado.subtotalGeneralUsd,
							subtotalGeneralArs: estadoRecalculado.subtotalGeneralArs,
							ivaPorcentaje: _doubleDesdeTexto(
								estadoRecalculado.ivaPorcentaje,
								valorPorDefecto: 21,
							),
							totalConIvaArs: estadoRecalculado.totalConIvaArs,
							descuentoPorcentaje: _doubleDesdeTexto(
								estadoRecalculado.descuentoPorcentaje,
								valorPorDefecto: 0,
							),
							totalFinalArs: estadoRecalculado.totalFinalArs,
							version: 1,
						)
					: null,
			facturacionItems: incluyeFacturacion ? facturacionItems : const <FacturacionItem>[],
		);
	}

	String _generarIdempotencyKey() {
		return _uuid.v4();
	}

	bool _esUuidValido(String valor) {
		if (valor.isEmpty) {
			return false;
		}
		return _uuidRegex.hasMatch(valor);
	}

	String _resolverTimezoneIana() {
		return _resolverTimezoneIanaDesdeFecha(DateTime.now());
	}

	String _formatearFechaHoraLocal(DateTime fechaHora) {
		final dia = fechaHora.day.toString().padLeft(2, '0');
		final mes = fechaHora.month.toString().padLeft(2, '0');
		final anio = fechaHora.year.toString();
		final hora = fechaHora.hour.toString().padLeft(2, '0');
		final minuto = fechaHora.minute.toString().padLeft(2, '0');
		return '$dia/$mes/$anio $hora:$minuto';
	}

	ServicioFormularioState _recalcularFacturacion(ServicioFormularioState estado) {
		final kmCantidad = _doubleDesdeTexto(estado.km, valorPorDefecto: 0);
		final cotizacion = estado.cotizacionDolarSnapshot;
		final valorKmUsd = estado.valorKmUsdSnapshot;

		final subtotalKmUsd = _redondear2(kmCantidad * valorKmUsd);
		final subtotalKmArs = _redondear2(subtotalKmUsd * cotizacion);
		final subtotalRepuestosUsd = _redondear2(
			estado.repuestosSeleccionados.fold(
				0,
				(acumulado, item) => acumulado + (item.cantidad * item.repuesto.precioUsd),
			),
		);
		final subtotalRepuestosArs = _redondear2(subtotalRepuestosUsd * cotizacion);
		final subtotalGeneralUsd = _redondear2(subtotalKmUsd + subtotalRepuestosUsd);
		final subtotalGeneralArs = _redondear2(subtotalKmArs + subtotalRepuestosArs);

		final ivaPorcentaje = _doubleDesdeTexto(estado.ivaPorcentaje, valorPorDefecto: 21);
		final descuentoPorcentaje = _doubleDesdeTexto(
			estado.descuentoPorcentaje,
			valorPorDefecto: 0,
		);

		final totalConIvaArs = _redondear2(
			subtotalGeneralArs * (1 + (ivaPorcentaje / 100)),
		);
		final totalFinalArs = _redondear2(
			totalConIvaArs * (1 - (descuentoPorcentaje / 100)),
		);

		return estado.copyWith(
			subtotalKmUsd: subtotalKmUsd,
			subtotalKmArs: subtotalKmArs,
			subtotalRepuestosUsd: subtotalRepuestosUsd,
			subtotalRepuestosArs: subtotalRepuestosArs,
			subtotalGeneralUsd: subtotalGeneralUsd,
			subtotalGeneralArs: subtotalGeneralArs,
			totalConIvaArs: totalConIvaArs,
			totalFinalArs: totalFinalArs,
		);
	}

	List<FacturacionItem> _construirItemsFacturacion(
		ServicioFormularioState estado,
		double kmCantidad,
	) {
		final items = <FacturacionItem>[];

		if (kmCantidad > 0) {
			final precioKmArs = _redondear2(estado.valorKmUsdSnapshot * estado.cotizacionDolarSnapshot);
			items.add(
				FacturacionItem(
					tipoItem: 'viatico',
					referenciaId: null,
					descripcion: 'Viatico por km',
					cantidad: kmCantidad,
					precioUnitarioUsd: estado.valorKmUsdSnapshot,
					precioUnitarioArs: precioKmArs,
					subtotalUsd: _redondear2(kmCantidad * estado.valorKmUsdSnapshot),
					subtotalArs: _redondear2(kmCantidad * precioKmArs),
				),
			);
		}

		for (final item in estado.repuestosSeleccionados) {
			final precioArs = _redondear2(item.repuesto.precioUsd * estado.cotizacionDolarSnapshot);
			items.add(
				FacturacionItem(
					tipoItem: 'repuesto',
					referenciaId: item.repuesto.id,
					descripcion: '${item.repuesto.codigo} - ${item.repuesto.nombre}',
					cantidad: item.cantidad,
					precioUnitarioUsd: item.repuesto.precioUsd,
					precioUnitarioArs: precioArs,
					subtotalUsd: _redondear2(item.cantidad * item.repuesto.precioUsd),
					subtotalArs: _redondear2(item.cantidad * precioArs),
				),
			);
		}

		return items;
	}

	double _doubleDesdeTexto(String valor, {required double valorPorDefecto}) {
		final normalizado = valor.trim().replaceAll(',', '.');
		if (normalizado.isEmpty) {
			return valorPorDefecto;
		}
		return double.tryParse(normalizado) ?? valorPorDefecto;
	}

	double _redondear2(double valor) {
		return (valor * 100).roundToDouble() / 100;
	}

	List<ProductoFalla> _productosFallaNormalizados(List<ProductoFalla> productosFalla) {
		return productosFalla
				.map(
					(item) => ProductoFalla(
						parteFallo: _normalizarParteFallada(item.parteFallo),
						productoFallaId: item.productoFallaId.trim(),
					),
				)
				.where(
					(item) =>
						item.parteFallo.isNotEmpty && item.productoFallaId.isNotEmpty,
				)
				.toList();
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


