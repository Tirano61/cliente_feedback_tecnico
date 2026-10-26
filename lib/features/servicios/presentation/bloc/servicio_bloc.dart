import 'dart:convert';
import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/core/error/failures.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_asignaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/asignacion_pendiente.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/solicitudes_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/errors/regla_fabrica_exception.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/presentation/bloc/asignacion_unidad_state.dart'
		show normalizarSerie;
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/descargar_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cliente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_enlace_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/quitar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/subir_documento_firmado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/politica_firma_canal.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/solicitud_documento_firmado.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/errors/valores_orden_rechazados_exception.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/cambios_pieza_formulario.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/campos_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/filtro_estado_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/precarga_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// Lo primero que falta para guardar la orden.
typedef _Faltante = ({CampoFormularioServicio campo, String mensaje});

class ServicioBloc extends Bloc<ServicioEvent, ServicioState> {
	static const Set<String> _partesFallaronPermitidas = {
		'indicador',
		'celda',
		'app_movil',
		'app_pc',
		'tablet',
		'web',
		'otro',
	};
	static const Uuid _uuid = Uuid();

	/// Tope de consultas de documento por carga del listado de mis servicios.
	static const int _maximoVerificacionesPdf = 20;
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
	final SubirDocumentoFirmadoUseCase _subirDocumentoFirmadoUseCase;
	final EncolarDocumentoPendienteUseCase _encolarDocumentoPendienteUseCase;
	final ObtenerDocumentosPendientesUseCase _obtenerDocumentosPendientesUseCase;
	final QuitarDocumentoPendienteUseCase _quitarDocumentoPendienteUseCase;
	final ObtenerEnlacePdfDocumentoUseCase _obtenerEnlacePdfDocumentoUseCase;
	final DescargarPdfDocumentoUseCase _descargarPdfDocumentoUseCase;
	final ObtenerClienteUseCase _obtenerClienteUseCase;
	final AsignarUnidadUseCase _asignarUnidadUseCase;
	final BuscarUnidadesUseCase _buscarUnidadesUseCase;
	final GuardarAsignacionPendienteUseCase _guardarAsignacionPendienteUseCase;
	final ObtenerAsignacionesPendientesUseCase _obtenerAsignacionesPendientesUseCase;
	final QuitarAsignacionPendienteUseCase _quitarAsignacionPendienteUseCase;
	final List<SolicitudDocumentoFirmado> _documentosPendientes = <SolicitudDocumentoFirmado>[];

	/// Cambios de placa/celda de servicios ya guardados que no se registraron.
	/// Tambien se guardan en el dispositivo; si no se puede escribir, quedan
	/// en memoria mientras dure la sesion.
	final List<AsignacionPendiente> _asignacionesPendientes = <AsignacionPendiente>[];

	/// Lectura de los cambios pendientes guardados, una sola vez por sesion.
	Future<void>? _lecturaAsignacionesPendientes;

	/// Las escrituras en el dispositivo van de a una y en orden.
	Future<void> _escrituraAsignacionesPendientes = Future<void>.value();
	bool _reintentandoAsignaciones = false;

	/// Identifica cada fila de cambio de placa/celda del formulario.
	int _ultimoIdCambioPieza = 0;

	/// Un formulario nuevo o una consulta mas reciente del mismo tipo deja sin
	/// efecto la lista de reacondicionadas que siga en vuelo.
	final Map<TipoUnidad, int> _secuenciaReacondicionadas = <TipoUnidad, int>{};

	/// Ordenes cuyo PDF confirmo el backend aunque el listado no lo traiga.
	final Set<String> _serviciosConPdfConfirmado = <String>{};

	/// Ordenes ya consultadas en esta carga del listado, para no repetir el GET.
	final Set<String> _serviciosPdfVerificados = <String>{};
	int _secuenciaEfectoPdf = 0;

	/// Cada "Guardar" rechazado por validacion lleva un token distinto.
	int _secuenciaAvisoValidacion = 0;

	/// Cada consulta nueva de mis servicios (recarga, busqueda o filtro) deja
	/// sin efecto las respuestas que sigan en vuelo: si el tecnico tipeo otra
	/// letra o cambio el filtro, la respuesta vieja ya no es lo que esta mirando.
	int _secuenciaMisServicios = 0;

	/// Pausa antes de mandar la busqueda, para no pegarle al backend por tecla.
	static const Duration _esperaBusquedaMisServicios = Duration(milliseconds: 400);

	ServicioBloc(
		this._cargarServicioUseCase,
		this._obtenerMisServiciosUseCase,
		this._buscarClientesUseCase,
		this._crearClienteRapidoUseCase,
		this._obtenerCotizacionActualUseCase,
		this._buscarRepuestosUseCase,
		this._generarPdfOrdenServicioUseCase,
		this._subirDocumentoFirmadoUseCase,
		this._encolarDocumentoPendienteUseCase,
		this._obtenerDocumentosPendientesUseCase,
		this._quitarDocumentoPendienteUseCase,
		this._obtenerEnlacePdfDocumentoUseCase,
		this._descargarPdfDocumentoUseCase,
		this._obtenerClienteUseCase,
		this._asignarUnidadUseCase,
		this._buscarUnidadesUseCase,
		this._guardarAsignacionPendienteUseCase,
		this._obtenerAsignacionesPendientesUseCase,
		this._quitarAsignacionPendienteUseCase,
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
		on<ServicioCambioPiezaAgregado>(_onServicioCambioPiezaAgregado);
		on<ServicioCambioPiezaCambiado>(_onServicioCambioPiezaCambiado);
		on<ServicioCambioPiezaReacondicionadaElegida>(_onServicioCambioPiezaReacondicionadaElegida);
		on<ServicioCambioPiezaQuitado>(_onServicioCambioPiezaQuitado);
		on<ServicioReacondicionadasSolicitadas>(_onServicioReacondicionadasSolicitadas);
		on<ServicioAsignacionesPendientesReintentadas>(_onServicioAsignacionesPendientesReintentadas);
		on<ServicioAsignacionPendienteDescartada>(_onServicioAsignacionPendienteDescartada);
		on<ServicioGuardarPressed>(_onServicioGuardarPressed);
		on<ServicioDocumentoSubidaSolicitada>(_onServicioDocumentoSubidaSolicitada);
		on<ServicioDocumentoPendientesReintentarSolicitado>(
			_onServicioDocumentoPendientesReintentarSolicitado,
		);
		on<ServicioDocumentoSubirAhoraSolicitado>(_onServicioDocumentoSubirAhoraSolicitado);
		on<MisServiciosSolicitados>(_onMisServiciosSolicitados);
		on<MisServiciosDisponibilidadPdfSolicitada>(
			_onMisServiciosDisponibilidadPdfSolicitada,
		);
		on<MisServiciosFiltroEstadoCambiado>(_onMisServiciosFiltroEstadoCambiado);
		on<MisServiciosBusquedaCambiada>(_onMisServiciosBusquedaCambiada);
		on<MisServiciosSiguientePaginaSolicitada>(
			_onMisServiciosSiguientePaginaSolicitada,
		);
		on<ServicioDocumentoPdfVerSolicitado>(_onServicioDocumentoPdfVerSolicitado);
		on<ServicioDocumentoEnlacePdfCopiarSolicitado>(
			_onServicioDocumentoEnlacePdfCopiarSolicitado,
		);
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
				_aplicarReglasDeCanal(
				actual.copyWith(
				fechaHoraServicio: fechaHoraServicio,
				timezoneIana: timezoneIana,
				utcOffsetMinutos: utcOffsetMinutos,
				canal: actual.canalFijo ? null : event.canal,
				clienteId: event.clienteId,
				lugarProvinciaId: event.zonaId,
				lugarDetalle: event.lugarDetalle,
				equipoNroSerie: event.equipoNroSerie,
				equipoModelo: event.equipoModelo,
				equipoModeloProductoId: event.equipoModeloProductoId,
				equipoUbicacion: event.equipoUbicacion,
				equipoAnio: event.equipoAnio,
				partesFallaronTexto: event.partesFallaronTexto,
				km: event.km,
				precioServicioUsd: event.precioServicioUsd,
				sintoma: event.sintoma,
				diagnosticoCatIdsSeleccionados: event.diagnosticoCatIdsSeleccionados,
				diagnosticoDetalle: event.diagnosticoDetalle,
				resolucionIdsSeleccionados: event.resolucionIdsSeleccionados,
				observaciones: event.observaciones,
				productosFallaSeleccionados: event.productosFallaSeleccionados,
				errorMensaje: null,
				exitoMensaje: null,
				),
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
			// Mientras se esperaba la respuesta el tecnico pudo seguir cargando:
			// se parte del estado actual, no del capturado antes del await.
			final antes = _recalcularFacturacion(_estadoFormularioActual());
			final despues = _recalcularFacturacion(
				antes.copyWith(
					cargandoFacturacion: false,
					cotizacionDolarSnapshot: cotizacion.cotizacionDolar,
					valorKmUsdSnapshot: cotizacion.valorKmUsd,
					repuestosDisponibles: const [],
					buscandoRepuestos: false,
					errorMensaje: null,
				),
			);

			emit(
				despues.copyWith(
					avisoValores: _avisoPorActualizacionDeValores(antes, despues),
				),
			);
		} on ServerException catch (e) {
			emit(
				_recalcularFacturacion(
					_estadoFormularioActual().copyWith(
						cargandoFacturacion: false,
						errorMensaje: e.mensaje,
					),
				),
			);
		} catch (_) {
			emit(
				_recalcularFacturacion(
					_estadoFormularioActual().copyWith(
						cargandoFacturacion: false,
						errorMensaje: 'No se pudo inicializar la facturacion.',
					),
				),
			);
		}
	}

	/// Si ya habia valores cargados y cambiaron, avisa al tecnico: el total que
	/// pudo haber visto el cliente ya no es el mismo. La primera carga
	/// (valores en 0) no genera aviso.
	AvisoValoresOrden? _avisoPorActualizacionDeValores(
		ServicioFormularioState antes,
		ServicioFormularioState despues,
	) {
		final cambios = <String>[];
		if (antes.cotizacionDolarSnapshot > 0 &&
				!_mismoValor(antes.cotizacionDolarSnapshot, despues.cotizacionDolarSnapshot)) {
			cambios.add(
				'Cotizacion del dolar: ${_formatearValorAviso(antes.cotizacionDolarSnapshot)} -> ${_formatearValorAviso(despues.cotizacionDolarSnapshot)} ARS',
			);
		}
		if (antes.valorKmUsdSnapshot > 0 &&
				!_mismoValor(antes.valorKmUsdSnapshot, despues.valorKmUsdSnapshot)) {
			cambios.add(
				'Valor del km: ${_formatearValorAviso(antes.valorKmUsdSnapshot)} -> ${_formatearValorAviso(despues.valorKmUsdSnapshot)} USD',
			);
		}
		if (cambios.isEmpty) {
			return null;
		}
		return AvisoValoresOrden(
			ordenRechazada: false,
			titulo: 'Se actualizaron los valores',
			mensaje:
					'Cambiaron los valores con los que se calculo la orden. Si ya le mostraste el total al cliente, mostrale el total nuevo antes de guardar.',
			cambios: cambios,
			totalAnteriorArs: antes.totalFinalArs,
			totalNuevoArs: despues.totalFinalArs,
		);
	}

	/// La orden no se guardo porque algun valor ya no es el vigente. Se
	/// actualiza el formulario con los valores vigentes (sin perder nada de lo
	/// cargado), se recalcula el total y se avisa al tecnico. No se reintenta
	/// solo: el cliente tiene que ver el total nuevo antes de volver a guardar.
	ServicioFormularioState _aplicarRechazoDeValores(
		ServicioFormularioState estado,
		ValoresOrdenRechazadosException rechazo,
	) {
		final cambios = <String>[];
		var cotizacion = estado.cotizacionDolarSnapshot;
		var valorKmUsd = estado.valorKmUsdSnapshot;
		var repuestos = List<RepuestoSeleccionado>.of(estado.repuestosSeleccionados);

		for (final item in rechazo.items) {
			switch (item.codigo) {
				case CodigoRechazoValores.cotizacionInvalida:
					{
						final vigente = item.valorVigente;
						if (vigente != null && vigente > 0) {
							cambios.add(
								'Cotizacion del dolar: ${_formatearValorAviso(cotizacion)} -> ${_formatearValorAviso(vigente)} ARS',
							);
							cotizacion = vigente;
						}
					}
				case CodigoRechazoValores.tarifaKmInvalida:
					{
						final vigente = item.valorVigente;
						if (vigente != null && vigente > 0) {
							cambios.add(
								'Valor del km: ${_formatearValorAviso(valorKmUsd)} -> ${_formatearValorAviso(vigente)} USD',
							);
							valorKmUsd = vigente;
						}
					}
				case CodigoRechazoValores.precioRepuestoDesactualizado:
					{
						final vigente = item.valorVigente;
						final indice = repuestos.indexWhere(
							(seleccionado) => seleccionado.repuesto.id == item.repuestoId,
						);
						if (vigente != null && indice >= 0) {
							final seleccionado = repuestos[indice];
							cambios.add(
								'${_nombreRepuestoAviso(seleccionado, item)}: ${_formatearValorAviso(seleccionado.repuesto.precioUsd)} -> ${_formatearValorAviso(vigente)} USD',
							);
							repuestos[indice] = seleccionado.copyWith(
								repuesto: Repuesto(
									id: seleccionado.repuesto.id,
									codigo: seleccionado.repuesto.codigo,
									nombre: seleccionado.repuesto.nombre,
									precioUsd: vigente,
								),
							);
						}
					}
				case CodigoRechazoValores.repuestoInactivo:
				case CodigoRechazoValores.repuestoInexistente:
					{
						final indice = repuestos.indexWhere(
							(seleccionado) => seleccionado.repuesto.id == item.repuestoId,
						);
						final motivo = item.codigo == CodigoRechazoValores.repuestoInactivo
								? 'dado de baja en el catalogo'
								: 'no existe en el catalogo';
						if (indice >= 0) {
							cambios.add(
								'${_nombreRepuestoAviso(repuestos[indice], item)}: se quito de la orden ($motivo)',
							);
							repuestos = [...repuestos]..removeAt(indice);
						}
					}
			}
		}

		final recalculado = _recalcularFacturacion(
			estado.copyWith(
				guardando: false,
				cotizacionDolarSnapshot: cotizacion,
				valorKmUsdSnapshot: valorKmUsd,
				repuestosSeleccionados: repuestos,
			),
		);

		return recalculado.copyWith(
			avisoValores: AvisoValoresOrden(
				ordenRechazada: true,
				titulo: 'La orden NO se guardo',
				mensaje: cambios.isEmpty
						? rechazo.mensaje
						: 'Cambiaron valores con los que se calculo la orden. La orden ya se actualizo con los valores vigentes: mostrale el total nuevo al cliente y volve a guardar.',
				cambios: cambios.isEmpty
						? const ['Toca "Actualizar valores" en Facturación para traer los valores vigentes.']
						: cambios,
				totalAnteriorArs: estado.totalFinalArs,
				totalNuevoArs: recalculado.totalFinalArs,
			),
		);
	}

	String _nombreRepuestoAviso(RepuestoSeleccionado seleccionado, ValorRechazado item) {
		final codigo = seleccionado.repuesto.codigo.trim();
		final nombre = seleccionado.repuesto.nombre.trim();
		if (codigo.isEmpty && nombre.isEmpty) {
			return item.descripcion ?? 'Repuesto';
		}
		return 'Repuesto $codigo - $nombre';
	}

	bool _mismoValor(double a, double b) {
		return (a * 10000).round() == (b * 10000).round();
	}

	String _formatearValorAviso(double valor) {
		final conCuatro = valor.toStringAsFixed(4);
		final conDos = valor.toStringAsFixed(2);
		return double.parse(conCuatro) == double.parse(conDos) ? conDos : conCuatro;
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
		Map<String, dynamic>? payloadCliente;
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
			payloadCliente = payload;

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
			final cuit = (payloadCliente?['cuit'] ?? '').toString().trim();
			final mensajeBackend = e.mensaje.toLowerCase();
			final yaExiste = e.statusCode == 400 && mensajeBackend.contains('cliente ya existe');
			final mensajeMostrar = yaExiste
					? (cuit.isNotEmpty
							? 'El cliente con el CUIT: $cuit ya existe.'
							: 'El cliente ya existe.')
					: e.mensaje;
			emit(
				actual.copyWith(
					creandoCliente: false,
					errorMensaje: mensajeMostrar,
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

	Future<void> _onServicioCambioPiezaAgregado(
		ServicioCambioPiezaAgregado event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		final tipo = event.tipo;
		if (!actual.requiereDatosDeCampo ||
				actual.guardando ||
				!CambioPiezaFormulario.tipos.contains(tipo)) {
			return;
		}
		emit(
			actual.copyWith(
				cambiosPieza: [
					...actual.cambiosPieza,
					CambioPiezaFormulario(id: ++_ultimoIdCambioPieza, tipo: tipo),
				],
			),
		);
		await _asegurarReacondicionadas(emit, tipo);
	}

	Future<void> _onServicioCambioPiezaCambiado(
		ServicioCambioPiezaCambiado event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		final cambio = _cambioPieza(actual, event.id);
		if (cambio == null || actual.guardando) {
			return;
		}

		// El modelo es del tipo: si cambia ya no vale.
		final tipo = event.tipo;
		final cambioTipo =
				tipo != null && tipo != cambio.tipo && CambioPiezaFormulario.tipos.contains(tipo);
		emit(
			actual.copyWith(
				cambiosPieza: _reemplazarCambioPieza(
					actual.cambiosPieza,
					cambio.copyWith(
						tipo: cambioTipo ? tipo : null,
						nroSerie: event.nroSerie,
						productoId: event.productoId,
						limpiarProducto: event.limpiarProducto || (cambioTipo && event.productoId == null),
						retiradaNroSerie: event.retiradaNroSerie,
					),
				),
			),
		);
		if (cambioTipo) {
			await _asegurarReacondicionadas(emit, tipo);
		}
	}

	void _onServicioCambioPiezaReacondicionadaElegida(
		ServicioCambioPiezaReacondicionadaElegida event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		final cambio = _cambioPieza(actual, event.id);
		final unidad = event.unidad;
		if (cambio == null || actual.guardando || unidad.tipo != cambio.tipo) {
			return;
		}
		emit(
			actual.copyWith(
				cambiosPieza: _reemplazarCambioPieza(
					actual.cambiosPieza,
					cambio.copyWith(
						nroSerie: unidad.nroSerie,
						productoId: unidad.producto?.id,
						limpiarProducto: unidad.producto == null,
					),
				),
			),
		);
	}

	void _onServicioCambioPiezaQuitado(
		ServicioCambioPiezaQuitado event,
		Emitter<ServicioState> emit,
	) {
		final actual = _estadoFormularioActual();
		if (actual.guardando) {
			return;
		}
		emit(
			actual.copyWith(
				cambiosPieza: actual.cambiosPieza.where((c) => c.id != event.id).toList(),
			),
		);
	}

	Future<void> _onServicioReacondicionadasSolicitadas(
		ServicioReacondicionadasSolicitadas event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		if (actual.reacondicionadas[event.tipo]?.cargando == true) {
			return;
		}
		await _cargarReacondicionadas(emit, event.tipo);
	}

	CambioPiezaFormulario? _cambioPieza(ServicioFormularioState estado, int id) {
		return estado.cambiosPieza.where((c) => c.id == id).firstOrNull;
	}

	List<CambioPiezaFormulario> _reemplazarCambioPieza(
		List<CambioPiezaFormulario> cambios,
		CambioPiezaFormulario nuevo,
	) {
		return cambios.map((c) => c.id == nuevo.id ? nuevo : c).toList();
	}

	/// Las reacondicionadas de un tipo se piden una vez por formulario (o de
	/// nuevo si la ultima vez fallo).
	Future<void> _asegurarReacondicionadas(Emitter<ServicioState> emit, TipoUnidad tipo) async {
		final actuales = _estadoFormularioActual().reacondicionadas[tipo];
		if (actuales != null && actuales.error == null) {
			return;
		}
		await _cargarReacondicionadas(emit, tipo);
	}

	Future<void> _cargarReacondicionadas(Emitter<ServicioState> emit, TipoUnidad tipo) async {
		final consulta = (_secuenciaReacondicionadas[tipo] ?? 0) + 1;
		_secuenciaReacondicionadas[tipo] = consulta;

		void emitir(ReacondicionadasPieza reacondicionadas) {
			final actual = state;
			if (emit.isDone ||
					_secuenciaReacondicionadas[tipo] != consulta ||
					actual is! ServicioFormularioState) {
				return;
			}
			emit(
				actual.copyWith(
					reacondicionadas: {...actual.reacondicionadas, tipo: reacondicionadas},
				),
			);
		}

		emitir(const ReacondicionadasPieza.cargando());
		String error;
		try {
			final pagina = await _buscarUnidadesUseCase.ejecutar(
				pagina: 1,
				tipo: tipo,
				estado: EstadoUnidad.reacondicionadaDisponible,
			);
			emitir(ReacondicionadasPieza(unidades: pagina.items, total: pagina.total));
			return;
		} on ServerException catch (e) {
			error = e.mensaje;
		} on NetworkException catch (e) {
			error = e.mensaje;
		} catch (_) {
			error = 'No se pudieron cargar las piezas reacondicionadas.';
		}
		emitir(ReacondicionadasPieza(error: error));
	}

	void _invalidarReacondicionadas() {
		for (final tipo in CambioPiezaFormulario.tipos) {
			_secuenciaReacondicionadas[tipo] = (_secuenciaReacondicionadas[tipo] ?? 0) + 1;
		}
	}

	/// Registra en el indicador del equipo cada cambio de placa/celda del
	/// servicio de campo recien guardado. Null si no hay cambios.
	///
	/// Cada cambio queda guardado como pendiente antes de pedirlo: si la app se
	/// cierra en el medio, se reintenta desde Mis servicios. Nunca lanza: el
	/// servicio ya esta guardado y lo que falle queda pendiente.
	Future<ResultadoCambiosPieza?> _registrarCambiosPieza(
		ServicioFormularioState estado,
		String servicioId,
	) async {
		final servicio = servicioId.trim();
		if (!estado.requiereDatosDeCampo || estado.cambiosPieza.isEmpty || servicio.isEmpty) {
			return null;
		}

		await _asegurarAsignacionesPendientesLeidas();
		final indicador = estado.equipoNroSerie.trim();
		final productoIndicador = estado.equipoModeloProductoId.trim();
		final pendientes = estado.cambiosPieza.map((cambio) {
			final retirada = cambio.retiradaNroSerie.trim();
			return AsignacionPendiente(
				solicitud: SolicitudAsignacion(
					indicadorNroSerie: indicador,
					tipo: cambio.tipo,
					nroSerie: cambio.nroSerie.trim(),
					productoId: cambio.productoId,
					indicadorProductoId: productoIndicador.isEmpty ? null : productoIndicador,
					retiradaNroSerie: retirada.isEmpty ? null : retirada,
					servicioId: servicio,
				),
			);
		}).toList();

		for (final pendiente in pendientes) {
			await _recordarAsignacionPendiente(pendiente);
		}
		// En orden: dos placas en el mismo indicador se ponen una despues de otra.
		final resultados = <ResultadoCambioPieza>[];
		for (final pendiente in pendientes) {
			resultados.add(await _intentarAsignacion(pendiente, reintento: false));
		}
		return ResultadoCambiosPieza(servicioId: servicio, cambios: resultados);
	}

	/// Si sale bien deja de estar pendiente; si no, queda pendiente con el
	/// mensaje del backend.
	Future<ResultadoCambioPieza> _intentarAsignacion(
		AsignacionPendiente pendiente, {
		required bool reintento,
	}) async {
		final solicitud = pendiente.solicitud;
		String mensaje;
		try {
			final asignacion = await _asignarUnidadUseCase.ejecutar(solicitud);
			await _olvidarAsignacionPendiente(pendiente.clave);
			return ResultadoCambioPieza(solicitud: solicitud, asignacion: asignacion);
		} on ReglaFabricaException catch (e) {
			// En un reintento, que la pieza ya este en ese indicador quiere decir
			// que el intento anterior llego al backend aunque se perdio la respuesta.
			if (reintento && e.codigo == CodigoReglaFabrica.unidadYaInstalada) {
				await _olvidarAsignacionPendiente(pendiente.clave);
				return ResultadoCambioPieza(solicitud: solicitud);
			}
			mensaje = e.mensaje;
		} on ServerException catch (e) {
			mensaje = e.mensaje;
		} on NetworkException catch (e) {
			mensaje = e.mensaje;
		} catch (_) {
			mensaje = 'No se pudo registrar el cambio de pieza. Revisá la conexión y reintentá.';
		}
		await _recordarAsignacionPendiente(pendiente.conError(mensaje));
		return ResultadoCambioPieza(solicitud: solicitud, error: mensaje);
	}

	Future<void> _onServicioAsignacionesPendientesReintentadas(
		ServicioAsignacionesPendientesReintentadas event,
		Emitter<ServicioState> emit,
	) async {
		if (_reintentandoAsignaciones) {
			return;
		}
		_reintentandoAsignaciones = true;
		try {
			await _asegurarAsignacionesPendientesLeidas();
			final servicioId = event.servicioId?.trim();
			final aReintentar = _asignacionesPendientes
					.where((p) => servicioId == null || p.servicioId == servicioId)
					.toList();

			_emitirReintentoAsignaciones(emit, reintentando: true);
			final resultados = <ResultadoCambioPieza>[];
			for (final pendiente in aReintentar) {
				resultados.add(await _intentarAsignacion(pendiente, reintento: true));
			}
			_emitirReintentoAsignaciones(emit, reintentando: false, resultados: resultados);
		} finally {
			_reintentandoAsignaciones = false;
		}
	}

	/// En Mis servicios actualiza la lista de pendientes y avisa; en el aviso de
	/// exito del formulario, el resultado de cada cambio.
	void _emitirReintentoAsignaciones(
		Emitter<ServicioState> emit, {
		required bool reintentando,
		List<ResultadoCambioPieza>? resultados,
	}) {
		final actual = state;
		if (emit.isDone) {
			return;
		}
		if (actual is MisServiciosLoaded) {
			emit(
				resultados == null
						? actual.copyWith(
								reintentandoAsignaciones: reintentando,
								limpiarMensajePendientes: true,
							)
						: actual.copyWith(
								asignacionesPendientes: List.unmodifiable(_asignacionesPendientes),
								reintentandoAsignaciones: reintentando,
								mensajePendientes: _mensajeReintentoAsignaciones(resultados),
							),
			);
			return;
		}
		final resultado = actual is ServicioFormularioState ? actual.resultadoCambiosPieza : null;
		if (actual is! ServicioFormularioState || resultado == null) {
			return;
		}
		emit(
			actual.copyWith(
				resultadoCambiosPieza: resultados == null
						? resultado.copyWith(reintentando: reintentando)
						: resultado.conReintentos(resultados),
			),
		);
	}

	String _mensajeReintentoAsignaciones(List<ResultadoCambioPieza> resultados) {
		if (resultados.isEmpty) {
			return 'No hay cambios de placa/celda pendientes.';
		}
		final pendientes = resultados.where((r) => r.pendiente).toList();
		if (pendientes.isNotEmpty) {
			return 'Quedaron ${pendientes.length} cambio(s) de placa/celda sin registrar: '
					'${pendientes.first.error}';
		}
		const registrados = 'Cambios de placa/celda registrados.';
		return resultados.any((r) => r.textosRetiradas.isNotEmpty)
				? '$registrados ${ResultadoCambiosPieza.recordatorioRetiradas}'
				: registrados;
	}

	Future<void> _onServicioAsignacionPendienteDescartada(
		ServicioAsignacionPendienteDescartada event,
		Emitter<ServicioState> emit,
	) async {
		if (_reintentandoAsignaciones) {
			return;
		}
		await _asegurarAsignacionesPendientesLeidas();
		await _olvidarAsignacionPendiente(event.clave);
		final actual = state;
		if (!emit.isDone && actual is MisServiciosLoaded) {
			emit(
				actual.copyWith(
					asignacionesPendientes: List.unmodifiable(_asignacionesPendientes),
					mensajePendientes: 'Cambio de placa/celda descartado: no se va a registrar.',
				),
			);
		}
	}

	Future<void> _asegurarAsignacionesPendientesLeidas() {
		return _lecturaAsignacionesPendientes ??= _leerAsignacionesPendientes();
	}

	Future<void> _leerAsignacionesPendientes() async {
		try {
			final guardadas = await _obtenerAsignacionesPendientesUseCase.ejecutar();
			for (final guardada in guardadas) {
				// Lo que ya esta en memoria es mas nuevo que lo guardado.
				if (!_asignacionesPendientes.any((p) => p.clave == guardada.clave)) {
					_asignacionesPendientes.add(guardada);
				}
			}
		} catch (_) {
			// Sin lo guardado se sigue con lo que haya en memoria.
		}
	}

	Future<void> _recordarAsignacionPendiente(AsignacionPendiente pendiente) {
		final indice = _asignacionesPendientes.indexWhere((p) => p.clave == pendiente.clave);
		if (indice < 0) {
			_asignacionesPendientes.add(pendiente);
		} else {
			_asignacionesPendientes[indice] = pendiente;
		}
		return _enColaAsignacionesPendientes(
			() => _guardarAsignacionPendienteUseCase.ejecutar(pendiente),
		);
	}

	Future<void> _olvidarAsignacionPendiente(String clave) {
		_asignacionesPendientes.removeWhere((p) => p.clave == clave);
		return _enColaAsignacionesPendientes(() => _quitarAsignacionPendienteUseCase.ejecutar(clave));
	}

	/// Un error al escribir no corta el flujo: el pendiente sigue en memoria.
	Future<void> _enColaAsignacionesPendientes(Future<void> Function() escritura) {
		return _escrituraAsignacionesPendientes = _escrituraAsignacionesPendientes.then((_) async {
			try {
				await escritura();
			} catch (_) {
				// Queda en memoria.
			}
		});
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

		final faltante = _validarFormulario(estadoConClave);
		if (faltante != null) {
			// El token nuevo hace que el mismo error, tocando "Guardar" otra vez,
			// se vuelva a avisar (el estado ya no es igual al anterior).
			emit(
				estadoConClave.copyWith(
					errorMensaje: faltante.mensaje,
					avisoValidacion: AvisoValidacionFormulario(
						token: ++_secuenciaAvisoValidacion,
						campo: faltante.campo,
						mensaje: faltante.mensaje,
					),
				),
			);
			return;
		}

		emit(estadoConClave.copyWith(guardando: true, errorMensaje: null, exitoMensaje: null));

		try {
			final servicio = _mapearServicio(estadoConClave);
			final orden = await _cargarServicioUseCase.ejecutar(servicio);
			// El servicio ya existe: lo que sigue no lo vuelve a crear. Un cambio
			// de placa/celda que falle queda pendiente para reintentarlo solo.
			final resultadoCambios = await _registrarCambiosPieza(estadoConClave, orden.servicioId);
			final fechaHoraOrden = orden.fechaHoraServicio ?? estadoConClave.fechaHoraServicio;
			final fechaHoraTexto = fechaHoraOrden == null
					? null
					: _formatearFechaHoraLocal(fechaHoraOrden);
			final pendientesCambios = resultadoCambios?.pendientes ?? 0;
			final avisoCambios = pendientesCambios == 0
					? ''
					: ' $pendientesCambios cambio(s) de placa/celda no se registraron: quedaron pendientes para reintentar.';
			final mensajeExitoBase = orden.replayed
					? 'Orden recuperada por idempotencia (${orden.servicioId})${fechaHoraTexto == null ? '' : ' - Fecha y hora: $fechaHoraTexto'}.$avisoCambios'
					: 'Orden de servicio creada correctamente (${orden.servicioId})${fechaHoraTexto == null ? '' : ' - Fecha y hora: $fechaHoraTexto'}.$avisoCambios';
			String mensajeExito = mensajeExitoBase;
			final nombreArchivoPdf = 'orden_servicio_${orden.servicioId}.pdf';
			Uint8List? pdfBytes;

			try {
				pdfBytes = await _generarPdfOrdenServicioUseCase.ejecutar(orden);
			} catch (_) {
				mensajeExito = '$mensajeExitoBase PDF no generado en este intento.';
			}

			// Las reacondicionadas que se usaron ya no estan disponibles.
			_invalidarReacondicionadas();

			emit(
				_crearEstadoFormularioInicial().copyWith(
					exitoMensaje: mensajeExito,
					ordenActual: orden,
					canal: orden.servicio.canal,
					pdfOrdenBytes: pdfBytes,
					pdfOrdenNombre: nombreArchivoPdf,
					documentosPendientes: _documentosPendientes.length,
					resultadoCambiosPieza: resultadoCambios,
				),
			);
		} on ValoresOrdenRechazadosException catch (e) {
			// La idempotencyKey se conserva: el rechazo no la consume en el backend.
			emit(_aplicarRechazoDeValores(estadoConClave, e));
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

	Future<void> _onServicioDocumentoSubidaSolicitada(
		ServicioDocumentoSubidaSolicitada event,
		Emitter<ServicioState> emit,
	) async {
		final actual = _estadoFormularioActual();
		if (event.pdfBytes.isEmpty) {
			emit(
				actual.copyWith(
					errorMensaje: 'El PDF es obligatorio para subir el documento.',
					exitoMensaje: null,
				),
			);
			return;
		}

		final firmaPermitida = PoliticaFirmaCanal.firmaHabilitada(event.canal);
		final firmaNombre = event.firmaClienteNombre?.trim();
		final firmaDocumento = event.firmaClienteDocumento?.trim();
		final firmaFecha = event.firmaFechaHora;
		final firmaTrazoPng = event.firmaClienteTrazoPng;
		final intentoConFirma =
				(firmaNombre ?? '').isNotEmpty ||
				(firmaDocumento ?? '').isNotEmpty ||
				firmaFecha != null;

		if (!firmaPermitida && intentoConFirma) {
			emit(
				actual.copyWith(
					errorMensaje:
						'Esta orden no admite firma. Se enviara solo el PDF.',
					exitoMensaje: null,
				),
			);
		}

		if (firmaPermitida && intentoConFirma) {
			if ((firmaNombre ?? '').isEmpty || firmaFecha == null) {
				emit(
					actual.copyWith(
						errorMensaje:
							'Si se informa firma, nombre del firmante y fecha son obligatorios.',
						exitoMensaje: null,
					),
				);
				return;
			}
			if (firmaTrazoPng == null || firmaTrazoPng.isEmpty) {
				emit(
					actual.copyWith(
						errorMensaje: 'Debes capturar la firma del cliente en pantalla.',
						exitoMensaje: null,
					),
				);
				return;
			}
		}

		var pdfBytesDocumento = event.pdfBytes;
		if (firmaPermitida && intentoConFirma) {
			final orden = event.orden ?? actual.ordenActual;
			if (orden == null) {
				emit(
					actual.copyWith(
						errorMensaje:
							'No se encontro la orden para generar el PDF con firma. Reintenta guardando de nuevo.',
						exitoMensaje: null,
					),
				);
				return;
			}

			try {
				pdfBytesDocumento = await _generarPdfOrdenServicioUseCase.ejecutar(
					orden,
					firmaClienteTrazoPng: firmaTrazoPng,
					firmaClienteNombre: firmaNombre,
					firmaClienteDocumento: firmaDocumento,
					firmaFechaHora: firmaFecha,
				);
			} catch (_) {
				emit(
					actual.copyWith(
						errorMensaje: 'No se pudo generar el PDF con la firma del cliente.',
						exitoMensaje: null,
					),
				);
				return;
			}
		}

		final solicitud = SolicitudDocumentoFirmado(
			servicioId: event.servicioId,
			canal: event.canal,
			pdfBytes: pdfBytesDocumento,
			nombreArchivoPdf: event.nombreArchivoPdf,
			rutaPdfLocal: event.rutaPdfLocal,
			firmaClienteNombre: firmaPermitida ? firmaNombre : null,
			firmaClienteDocumento: firmaPermitida ? firmaDocumento : null,
			firmaFechaHora: firmaPermitida ? firmaFecha : null,
		);

		emit(
			actual.copyWith(
				subiendoDocumento: true,
				errorMensaje: null,
				exitoMensaje: null,
			),
		);

		try {
			final orden = await _subirDocumentoFirmadoUseCase.ejecutar(solicitud);
			final estadoOrden = orden.estadoOrden.trim().toLowerCase();
			final mensaje = estadoOrden == 'firmada'
					? 'Firma registrada y documento subido correctamente.'
					: 'Documento subido correctamente sin firma.';

			emit(
				actual.copyWith(
					subiendoDocumento: false,
					ordenActual: orden,
					exitoMensaje: mensaje,
					errorMensaje: null,
					documentosPendientes: _documentosPendientes.length,
				),
			);
		} on ServerException catch (e) {
			if (_esErrorFirmaNoPermitida(e.mensaje)) {
				emit(
					actual.copyWith(
						subiendoDocumento: false,
						errorMensaje:
							'Esta orden no admite firma. Se enviara solo el PDF.',
						exitoMensaje: null,
					),
				);
				add(
					ServicioDocumentoSubidaSolicitada(
						servicioId: event.servicioId,
						orden: event.orden,
						canal: event.canal,
						pdfBytes: event.pdfBytes,
						nombreArchivoPdf: event.nombreArchivoPdf,
						rutaPdfLocal: event.rutaPdfLocal,
					),
				);
				return;
			}

			await _encolarDocumentoPendiente(solicitud);
			emit(
				actual.copyWith(
					subiendoDocumento: false,
					errorMensaje:
						'No se pudo subir el documento: ${e.mensaje} Se guardo pendiente para reintento.',
					exitoMensaje: null,
					documentosPendientes: _documentosPendientes.length,
				),
			);
		} catch (_) {
			await _encolarDocumentoPendiente(solicitud);
			emit(
				actual.copyWith(
					subiendoDocumento: false,
					errorMensaje:
						'Sin conexion. El envio quedo pendiente para reintento.',
					exitoMensaje: null,
					documentosPendientes: _documentosPendientes.length,
				),
			);
		}
	}

	Future<void> _onServicioDocumentoPendientesReintentarSolicitado(
		ServicioDocumentoPendientesReintentarSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		await _cargarPendientesDesdeStorage();

		if (state is MisServiciosLoaded) {
			final actual = state as MisServiciosLoaded;
			if (_documentosPendientes.isEmpty) {
				emit(
					actual.copyWith(
						reintentandoPendientes: false,
						documentosPendientes: 0,
						mensajePendientes: 'No hay documentos pendientes para reenviar.',
					),
				);
				return;
			}

			emit(
				actual.copyWith(
					reintentandoPendientes: true,
					documentosPendientes: _documentosPendientes.length,
					limpiarMensajePendientes: true,
				),
			);

			final pendientes = List<SolicitudDocumentoFirmado>.from(_documentosPendientes);
			for (final solicitud in pendientes) {
				try {
					await _subirDocumentoFirmadoUseCase.ejecutar(solicitud);
					await _quitarDocumentoPendiente(solicitud.servicioId);
				} catch (_) {
					break;
				}
			}

			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					reintentandoPendientes: false,
					documentosPendientes: _documentosPendientes.length,
					mensajePendientes: _documentosPendientes.isEmpty
							? 'Documentos pendientes reenviados correctamente.'
							: 'Quedaron ${_documentosPendientes.length} documento(s) pendientes.',
				),
			);
			return;
		}

		final actual = _estadoFormularioActual();
		if (_documentosPendientes.isEmpty) {
			emit(
				actual.copyWith(
					exitoMensaje: 'No hay documentos pendientes para reenviar.',
					errorMensaje: null,
					documentosPendientes: 0,
				),
			);
			return;
		}

		emit(
			actual.copyWith(
				subiendoDocumento: true,
				errorMensaje: null,
				exitoMensaje: null,
			),
		);

		final pendientes = List<SolicitudDocumentoFirmado>.from(_documentosPendientes);
		for (final solicitud in pendientes) {
			try {
				await _subirDocumentoFirmadoUseCase.ejecutar(solicitud);
				await _quitarDocumentoPendiente(solicitud.servicioId);
			} catch (_) {
				break;
			}
		}

		emit(
			actual.copyWith(
				subiendoDocumento: false,
				documentosPendientes: _documentosPendientes.length,
				exitoMensaje: _documentosPendientes.isEmpty
						? 'Documentos pendientes reenviados correctamente.'
						: null,
				errorMensaje: _documentosPendientes.isEmpty
						? null
						: 'Quedaron ${_documentosPendientes.length} documento(s) pendientes.',
			),
		);
	}

	Future<void> _onMisServiciosSolicitados(
		MisServiciosSolicitados event,
		Emitter<ServicioState> emit,
	) async {
		// Recargar vuelve a la primera pagina pero no le borra al tecnico la
		// busqueda ni el filtro que estaba mirando: se mandan de nuevo.
		final anterior = state is MisServiciosLoaded
				? state as MisServiciosLoaded
				: null;
		final filtroEstado = anterior?.filtroEstado ?? FiltroEstadoServicio.todos;
		final busqueda = anterior?.busqueda ?? '';
		final consulta = ++_secuenciaMisServicios;

		emit(const MisServiciosLoading());
		try {
			await _cargarPendientesDesdeStorage();
			await _asegurarAsignacionesPendientesLeidas();
			final pagina = await _obtenerMisServiciosUseCase.ejecutar(
				pagina: 1,
				busqueda: busqueda,
				aprobado: filtroEstado.aprobado,
			);
			if (consulta != _secuenciaMisServicios) {
				return;
			}

			// Recargar habilita volver a preguntar por el PDF de cada orden.
			_serviciosPdfVerificados.clear();

			emit(
				MisServiciosLoaded(
					servicios: pagina.servicios,
					serviciosConPdfConfirmado: Set<String>.from(_serviciosConPdfConfirmado),
					filtroEstado: filtroEstado,
					busqueda: busqueda,
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					documentosPendientes: _documentosPendientes.length,
					asignacionesPendientes: List.unmodifiable(_asignacionesPendientes),
				),
			);
			add(const MisServiciosDisponibilidadPdfSolicitada());
		} on ServerException catch (e) {
			if (consulta == _secuenciaMisServicios) {
				emit(ServicioError(mensaje: e.mensaje));
			}
		} catch (_) {
			if (consulta == _secuenciaMisServicios) {
				emit(const ServicioError(mensaje: 'No se pudieron cargar los servicios.'));
			}
		}
	}

	/// Vuelve a pedir la primera pagina con la busqueda y el filtro vigentes,
	/// sin sacar de pantalla el listado (ni el campo de busqueda) mientras tanto.
	Future<void> _consultarPrimeraPaginaMisServicios(
		Emitter<ServicioState> emit, {
		Duration? espera,
	}) async {
		final consulta = ++_secuenciaMisServicios;
		if (espera != null) {
			await Future<void>.delayed(espera);
			if (consulta != _secuenciaMisServicios) {
				return;
			}
		}

		if (emit.isDone || state is! MisServiciosLoaded) {
			return;
		}
		final vigente = state as MisServiciosLoaded;
		emit(
			vigente.copyWith(
				actualizando: true,
				cargandoMas: false,
				limpiarErrorListado: true,
				limpiarErrorPaginacion: true,
			),
		);

		try {
			final pagina = await _obtenerMisServiciosUseCase.ejecutar(
				pagina: 1,
				busqueda: vigente.busqueda,
				aprobado: vigente.filtroEstado.aprobado,
			);
			if (consulta != _secuenciaMisServicios) {
				return;
			}

			_emitirEnMisServicios(
				emit,
				(actual) => actual.copyWith(
					servicios: pagina.servicios,
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					actualizando: false,
				),
			);
			if (!isClosed) {
				add(const MisServiciosDisponibilidadPdfSolicitada());
			}
		} on ServerException catch (e) {
			_cerrarConsultaMisServiciosConError(emit, consulta, e.mensaje);
		} catch (_) {
			_cerrarConsultaMisServiciosConError(
				emit,
				consulta,
				'No se pudieron cargar los servicios.',
			);
		}
	}

	/// Si falla la consulta con la busqueda/filtro nuevos, el listado anterior
	/// no corresponde a lo que pide el tecnico: se vacia y se muestra el error.
	void _cerrarConsultaMisServiciosConError(
		Emitter<ServicioState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuenciaMisServicios) {
			return;
		}

		_emitirEnMisServicios(
			emit,
			(actual) => actual.copyWith(
				servicios: const <Servicio>[],
				total: 0,
				pagina: 0,
				totalPaginas: 0,
				actualizando: false,
				errorListado: mensaje,
			),
		);
	}

	Future<void> _onMisServiciosSiguientePaginaSolicitada(
		MisServiciosSiguientePaginaSolicitada event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		if (actual.cargandoMas || actual.actualizando || !actual.hayMasPaginas) {
			return;
		}
		if (actual.errorPaginacion != null && !event.reintento) {
			return;
		}

		final consulta = _secuenciaMisServicios;
		emit(actual.copyWith(cargandoMas: true, limpiarErrorPaginacion: true));

		try {
			final pagina = await _obtenerMisServiciosUseCase.ejecutar(
				pagina: actual.pagina + 1,
				busqueda: actual.busqueda,
				aprobado: actual.filtroEstado.aprobado,
			);
			if (consulta != _secuenciaMisServicios) {
				return;
			}

			_emitirEnMisServicios(emit, (vigente) {
				// El backend pagina por createdAt DESC: si entro un servicio nuevo
				// entre pagina y pagina, el offset se corre y uno se repite.
				final idsCargados = vigente.servicios.map((s) => s.id).toSet();
				return vigente.copyWith(
					servicios: [
						...vigente.servicios,
						...pagina.servicios.where((s) => !idsCargados.contains(s.id)),
					],
					total: pagina.total,
					pagina: pagina.pagina,
					totalPaginas: pagina.totalPaginas,
					cargandoMas: false,
				);
			});
			if (!isClosed) {
				add(const MisServiciosDisponibilidadPdfSolicitada());
			}
		} on ServerException catch (e) {
			_cerrarPaginaMisServiciosConError(emit, consulta, e.mensaje);
		} catch (_) {
			_cerrarPaginaMisServiciosConError(
				emit,
				consulta,
				'No se pudieron cargar mas servicios.',
			);
		}
	}

	void _cerrarPaginaMisServiciosConError(
		Emitter<ServicioState> emit,
		int consulta,
		String mensaje,
	) {
		if (consulta != _secuenciaMisServicios) {
			return;
		}

		_emitirEnMisServicios(
			emit,
			(vigente) => vigente.copyWith(
				cargandoMas: false,
				errorPaginacion: mensaje,
			),
		);
	}

	/// El listado de GET /servicios/mios no siempre trae el documento, asi que
	/// para las ordenes sin documento se consulta GET /servicios/:id/documento.
	Future<void> _onMisServiciosDisponibilidadPdfSolicitada(
		MisServiciosDisponibilidadPdfSolicitada event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final candidatos = <String>[];
		for (final servicio in (state as MisServiciosLoaded).servicios) {
			final servicioId = servicio.id.trim();
			if (servicioId.isEmpty) {
				continue;
			}
			if (_serviciosPdfVerificados.contains(servicioId)) {
				continue;
			}
			if (servicio.tieneDocumentoCargado) {
				continue;
			}

			candidatos.add(servicioId);
			if (candidatos.length == _maximoVerificacionesPdf) {
				break;
			}
		}

		if (candidatos.isEmpty) {
			return;
		}

		await Future.wait(
			candidatos.map((servicioId) async {
				try {
					final enlace = await _obtenerEnlacePdfDocumentoUseCase.ejecutar(
						servicioId,
					);
					if ((enlace ?? '').trim().isNotEmpty) {
						_serviciosConPdfConfirmado.add(servicioId);
					}
				} catch (_) {
					// Error puntual: se reintenta al recargar el listado. Si fue un 401
					// el ApiClient ya aviso que la sesion expiro.
				} finally {
					_serviciosPdfVerificados.add(servicioId);
				}
			}),
		);

		_emitirEnMisServicios(
			emit,
			(vigente) => vigente.copyWith(
				serviciosConPdfConfirmado: Set<String>.from(_serviciosConPdfConfirmado),
			),
		);
	}

	Future<void> _onMisServiciosFiltroEstadoCambiado(
		MisServiciosFiltroEstadoCambiado event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		if (actual.filtroEstado == event.filtro) {
			return;
		}

		emit(actual.copyWith(filtroEstado: event.filtro));
		await _consultarPrimeraPaginaMisServicios(emit);
	}

	Future<void> _onMisServiciosBusquedaCambiada(
		MisServiciosBusquedaCambiada event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		if (actual.busqueda == event.texto) {
			return;
		}

		// El texto se guarda tal cual para que el campo no salte, pero el
		// backend ignora los espacios de los bordes: si solo cambiaron esos, la
		// consulta en vuelo (o la ultima) sigue sirviendo.
		emit(actual.copyWith(busqueda: event.texto));
		if (actual.busqueda.trim() == event.texto.trim()) {
			return;
		}

		await _consultarPrimeraPaginaMisServicios(
			emit,
			espera: _esperaBusquedaMisServicios,
		);
	}

	Future<void> _onServicioDocumentoPdfVerSolicitado(
		ServicioDocumentoPdfVerSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		final servicioId = event.servicio.id.trim();
		if (servicioId.isEmpty) {
			emit(
				actual.copyWith(
					mensajePendientes: 'Servicio invalido para abrir PDF.',
				),
			);
			return;
		}

		if (actual.servicioIdDescargandoPdf != null) {
			return;
		}

		emit(
			actual.copyWith(
				servicioIdDescargandoPdf: servicioId,
				limpiarMensajePendientes: true,
			),
		);

		try {
			final pdfBytes = await _descargarPdfDocumentoUseCase.ejecutar(servicioId);

			if (pdfBytes == null) {
				_cerrarFlujoPdfMisServicios(
					emit,
					mensaje: 'Esta orden aun no tiene PDF disponible.',
				);
				return;
			}

			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					limpiarServicioIdDescargandoPdf: true,
					pdfParaAbrir: PdfOrdenParaAbrir(
						token: _proximoTokenEfectoPdf(),
						servicioId: servicioId,
						nombreArchivo: 'orden_servicio_$servicioId.pdf',
						bytes: pdfBytes,
					),
				),
			);
		} on ServerException catch (e) {
			_cerrarFlujoPdfMisServicios(emit, mensaje: e.mensaje);
		} catch (_) {
			_cerrarFlujoPdfMisServicios(
				emit,
				mensaje: 'Error al abrir el PDF. Intenta nuevamente.',
			);
		}
	}

	Future<void> _onServicioDocumentoEnlacePdfCopiarSolicitado(
		ServicioDocumentoEnlacePdfCopiarSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		final servicioId = event.servicio.id.trim();
		if (servicioId.isEmpty) {
			emit(
				actual.copyWith(
					mensajePendientes: 'Servicio invalido para obtener enlace PDF.',
				),
			);
			return;
		}

		if (actual.servicioIdCopiandoEnlacePdf != null) {
			return;
		}

		emit(
			actual.copyWith(
				servicioIdCopiandoEnlacePdf: servicioId,
				limpiarMensajePendientes: true,
			),
		);

		try {
			final enlace = await _obtenerEnlacePdfDocumentoUseCase.ejecutar(servicioId);

			if ((enlace ?? '').trim().isEmpty) {
				_cerrarFlujoPdfMisServicios(
					emit,
					mensaje: 'Esta orden aun no tiene enlace PDF.',
				);
				return;
			}

			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					limpiarServicioIdCopiandoEnlacePdf: true,
					enlacePdfParaCopiar: EnlacePdfParaCopiar(
						token: _proximoTokenEfectoPdf(),
						servicioId: servicioId,
						enlace: enlace!.trim(),
					),
					mensajePendientes: 'Enlace del PDF copiado. Ya podes compartirlo.',
				),
			);
		} on ServerException catch (e) {
			_cerrarFlujoPdfMisServicios(emit, mensaje: e.mensaje);
		} catch (_) {
			_cerrarFlujoPdfMisServicios(
				emit,
				mensaje: 'Error al obtener enlace PDF. Intenta nuevamente.',
			);
		}
	}

	Future<void> _onServicioDocumentoSubirAhoraSolicitado(
		ServicioDocumentoSubirAhoraSolicitado event,
		Emitter<ServicioState> emit,
	) async {
		if (state is! MisServiciosLoaded) {
			return;
		}

		final actual = state as MisServiciosLoaded;
		final servicio = event.servicio;
		final servicioId = servicio.id.trim();
		if (servicioId.isEmpty) {
			emit(
				actual.copyWith(
					mensajePendientes:
						'No se puede subir PDF porque la orden no tiene identificador.',
				),
			);
			return;
		}

		emit(
			actual.copyWith(
				servicioIdSubiendoPdf: servicioId,
				limpiarMensajePendientes: true,
			),
		);

		final ordenGenerada = OrdenServicioRespuesta.desdeServicio(
			servicio,
			idempotencyKeyRespaldo: _generarIdempotencyKey(),
		);

		Uint8List pdfBytes;
		try {
			pdfBytes = await _generarPdfOrdenServicioUseCase.ejecutar(ordenGenerada);
		} catch (_) {
			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					limpiarServicioIdSubiendoPdf: true,
					mensajePendientes:
						'No se pudo generar el PDF de la orden $servicioId.',
				),
			);
			return;
		}

		final solicitud = SolicitudDocumentoFirmado(
			servicioId: servicioId,
			canal: servicio.canal,
			pdfBytes: pdfBytes,
			nombreArchivoPdf: 'orden_servicio_$servicioId.pdf',
			rutaPdfLocal: 'memoria://ordenes/orden_servicio_$servicioId.pdf',
		);

		try {
			final ordenActualizada = await _subirDocumentoFirmadoUseCase.ejecutar(solicitud);
			await _cargarPendientesDesdeStorage();
			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					servicios: vigente.servicios
							.map(
								(item) => item.id == servicioId ? ordenActualizada.servicio : item,
							)
							.toList(),
					documentosPendientes: _documentosPendientes.length,
					limpiarServicioIdSubiendoPdf: true,
					mensajePendientes:
						'PDF de la orden $servicioId subido correctamente.',
				),
			);
		} on ServerException catch (e) {
			await _encolarDocumentoPendiente(solicitud);
			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					documentosPendientes: _documentosPendientes.length,
					limpiarServicioIdSubiendoPdf: true,
					mensajePendientes:
						'No se pudo subir el PDF de la orden $servicioId: ${e.mensaje}. Quedo pendiente para reintento.',
				),
			);
		} catch (_) {
			await _encolarDocumentoPendiente(solicitud);
			_emitirEnMisServicios(
				emit,
				(vigente) => vigente.copyWith(
					documentosPendientes: _documentosPendientes.length,
					limpiarServicioIdSubiendoPdf: true,
					mensajePendientes:
						'Sin conexion. El PDF de la orden $servicioId quedo pendiente para reintento.',
				),
			);
		}
	}

	/// Emite sobre el estado vigente del listado y no sobre la copia capturada
	/// antes de los awaits: mientras corre un flujo de PDF puede haber
	/// terminado la verificacion de disponibilidad y no hay que pisarla.
	void _emitirEnMisServicios(
		Emitter<ServicioState> emit,
		MisServiciosLoaded Function(MisServiciosLoaded vigente) construir,
	) {
		if (emit.isDone || state is! MisServiciosLoaded) {
			return;
		}

		emit(construir(state as MisServiciosLoaded));
	}

	/// Cierra un flujo de PDF del listado: apaga los indicadores y deja el aviso.
	void _cerrarFlujoPdfMisServicios(
		Emitter<ServicioState> emit, {
		required String mensaje,
	}) {
		_emitirEnMisServicios(
			emit,
			(vigente) => vigente.copyWith(
				limpiarServicioIdDescargandoPdf: true,
				limpiarServicioIdCopiandoEnlacePdf: true,
				mensajePendientes: mensaje,
			),
		);
	}

	int _proximoTokenEfectoPdf() {
		_secuenciaEfectoPdf += 1;
		return _secuenciaEfectoPdf;
	}

	Future<void> _onServicioFormularioReiniciado(
		ServicioFormularioReiniciado event,
		Emitter<ServicioState> emit,
	) async {
		await _cargarPendientesDesdeStorage();
		await _asegurarAsignacionesPendientesLeidas();
		_invalidarReacondicionadas();
		// El aviso de exito del servicio anterior sigue mostrando sus cambios de
		// placa/celda mientras el formulario arranca de nuevo.
		final anterior = state;
		final inicial = _crearEstadoFormularioInicial().copyWith(
			documentosPendientes: _documentosPendientes.length,
			resultadoCambiosPieza:
					anterior is ServicioFormularioState ? anterior.resultadoCambiosPieza : null,
		);
		final precarga = event.precarga;
		emit(precarga == null ? inicial : _aplicarPrecarga(inicial, precarga));
		add(const ServicioFacturacionInicializada());
		await _completarClientePrecargado(emit, precarga?.cliente);
	}

	/// La precarga trae el cliente como lo conoce quien abrio el formulario (en
	/// una recepcion: id, nombre y CUIT). Se completa con `GET /clientes/:id`
	/// para que el resumen y el PDF tengan contacto, telefono y localidad. Si
	/// falla queda lo que vino; si el tecnico ya eligio otro cliente, no se toca.
	Future<void> _completarClientePrecargado(
		Emitter<ServicioState> emit,
		Cliente? cliente,
	) async {
		final clienteId = (cliente?.id ?? '').trim();
		if (clienteId.isEmpty) {
			return;
		}

		Cliente completo;
		try {
			completo = await _obtenerClienteUseCase.ejecutar(clienteId);
		} catch (_) {
			return;
		}

		final actual = state;
		if (emit.isDone ||
				actual is! ServicioFormularioState ||
				actual.clienteSeleccionado?.id != clienteId ||
				completo.id != clienteId) {
			return;
		}
		emit(actual.copyWith(clienteSeleccionado: completo));
	}

	ServicioFormularioState _aplicarPrecarga(
		ServicioFormularioState estado,
		PrecargaFormularioServicio precarga,
	) {
		final cliente = precarga.cliente;
		return _aplicarReglasDeCanal(
			estado.copyWith(
				canal: precarga.canal,
				canalFijo: true,
				clienteSeleccionado: cliente,
				clienteId: cliente?.id,
				equipoNroSerie: precarga.equipoNroSerie.trim(),
				equipoModelo: precarga.equipoModelo.trim(),
				equipoModeloProductoId: precarga.equipoModeloProductoId?.trim(),
				sintoma: precarga.sintoma.trim(),
			),
		);
	}

	Future<void> _cargarPendientesDesdeStorage() async {
		final pendientes = await _obtenerDocumentosPendientesUseCase.ejecutar();
		_documentosPendientes
			..clear()
			..addAll(pendientes);
	}

	Future<void> _encolarDocumentoPendiente(SolicitudDocumentoFirmado solicitud) async {
		await _encolarDocumentoPendienteUseCase.ejecutar(solicitud);
		await _cargarPendientesDesdeStorage();
	}

	Future<void> _quitarDocumentoPendiente(String servicioId) async {
		await _quitarDocumentoPendienteUseCase.ejecutar(servicioId);
		await _cargarPendientesDesdeStorage();
	}

	bool _esErrorFirmaNoPermitida(String mensaje) {
		final texto = mensaje.toLowerCase();
		return texto.contains('firma') &&
				(texto.contains('canal') || texto.contains('remoto') || texto.contains('fabrica'));
	}

	/// Provincia, lugar de atencion, km y cambios de placa/celda solo existen en
	/// `canal = campo`. Al pasar a remoto o fabrica se limpian para no arrastrar datos cargados
	/// antes del cambio de canal: el backend resuelve el lugar y el payload
	/// viaja sin esas claves.
	ServicioFormularioState _aplicarReglasDeCanal(ServicioFormularioState estado) {
		if (estado.requiereDatosDeCampo) {
			return estado;
		}

		return estado.copyWith(
			lugarProvinciaId: '',
			lugarDetalle: '',
			km: '',
			cambiosPieza: const [],
		);
	}

	/// Lo primero que falta para guardar: el campo (dice en que paso esta) y
	/// el mensaje. Null si se puede guardar.
	_Faltante? _validarFormulario(ServicioFormularioState estado) {
		if (estado.canal == null) {
			return (campo: CampoFormularioServicio.canal, mensaje: 'Selecciona el canal del servicio.');
		}
		if (estado.clienteId.trim().isEmpty) {
			return (campo: CampoFormularioServicio.cliente, mensaje: 'Debes seleccionar un cliente.');
		}
		if (estado.requiereDatosDeCampo) {
			if (estado.lugarProvinciaId.trim().isEmpty) {
				return (campo: CampoFormularioServicio.zona, mensaje: 'Selecciona la provincia/zona del servicio.');
			}
			if (estado.lugarDetalle.trim().isEmpty) {
				return (campo: CampoFormularioServicio.lugarDetalle, mensaje: 'Completa el detalle del lugar.');
			}
		}
		if (estado.equipoNroSerie.trim().isEmpty) {
			return (campo: CampoFormularioServicio.equipoNroSerie, mensaje: 'Completa el numero de serie del equipo.');
		}
		if (estado.equipoModelo.trim().isEmpty) {
			return (campo: CampoFormularioServicio.equipoModelo, mensaje: 'Completa el modelo del equipo.');
		}
		if (estado.equipoUbicacion.trim().isEmpty) {
			return (campo: CampoFormularioServicio.equipoUbicacion, mensaje: 'Completa la ubicación del equipo.');
		}
		final equipoAnio = int.tryParse(estado.equipoAnio.trim());
		if (equipoAnio == null || equipoAnio <= 0) {
			return (campo: CampoFormularioServicio.equipoAnio, mensaje: 'Completa un año de equipo válido.');
		}
		if (_partesFallaronDesdeTexto(estado.partesFallaronTexto).isEmpty) {
			return (campo: CampoFormularioServicio.partesFallaron, mensaje: 'Indica al menos una parte que fallo.');
		}
		if (estado.requiereDatosDeCampo && estado.km.trim().isEmpty) {
			return (campo: CampoFormularioServicio.km, mensaje: 'Completa los kilometros recorridos.');
		}
		final km = _doubleDesdeTexto(estado.km, valorPorDefecto: 0);
		if (km < 0) {
			return (campo: CampoFormularioServicio.km, mensaje: 'Completa los kilometros con un valor numerico valido.');
		}
		// En campo el backend genera la liquidacion del tecnico por tipo de
		// salida segun los km: con 0 km rechaza la orden.
		if (estado.requiereDatosDeCampo && _kmFacturables(estado) <= 0) {
			return (campo: CampoFormularioServicio.km, mensaje: 'En un servicio de campo los kilometros tienen que ser mayores a 0.');
		}
		final precioServicioUsd = _doubleDesdeTexto(
			estado.precioServicioUsd,
			valorPorDefecto: 0,
		);
		final hayFacturacionAdicional =
				km > 0 || estado.repuestosSeleccionados.isNotEmpty;
		if (precioServicioUsd < 0) {
			return (campo: CampoFormularioServicio.precioServicio, mensaje: 'Completa el precio del servicio con un valor numerico valido.');
		}
		if (hayFacturacionAdicional && precioServicioUsd <= 0) {
			return (campo: CampoFormularioServicio.precioServicio, mensaje: 'Ingresa el precio del servicio para incluir el item mano de obra en la facturacion.');
		}
		final hayFacturacion = precioServicioUsd > 0 || hayFacturacionAdicional;
		if (hayFacturacion && estado.cotizacionDolarSnapshot <= 0) {
			return (campo: CampoFormularioServicio.valoresFacturacion, mensaje: 'No se cargo la cotizacion del dolar. Toca "Actualizar valores" en Facturación antes de guardar.');
		}
		if (km > 0 && estado.valorKmUsdSnapshot <= 0) {
			return (campo: CampoFormularioServicio.valoresFacturacion, mensaje: 'No se cargo el valor del km. Toca "Actualizar valores" en Facturación antes de guardar.');
		}
		if (estado.sintoma.trim().isEmpty) {
			return (campo: CampoFormularioServicio.sintoma, mensaje: 'Completa el sintoma reportado.');
		}
		if (estado.diagnosticoDetalle.trim().isEmpty) {
			return (campo: CampoFormularioServicio.diagnosticoDetalle, mensaje: 'Completa el detalle tecnico del diagnostico.');
		}
		if (estado.diagnosticoCatIdsSeleccionados.isEmpty) {
			return (campo: CampoFormularioServicio.diagnosticoCategoria, mensaje: 'Selecciona al menos una categoria de diagnostico.');
		}
		if (estado.resolucionIdsSeleccionados.isEmpty) {
			return (campo: CampoFormularioServicio.resolucion, mensaje: 'Selecciona al menos una resolucion.');
		}
		if (_productosFallaNormalizados(estado.productosFallaSeleccionados).isEmpty) {
			return (campo: CampoFormularioServicio.productosFalla, mensaje: 'Selecciona al menos un producto en Partes que mostraban falla.');
		}
		return _validarCambiosPieza(estado);
	}

	/// Cada cambio necesita el numero de serie de la pieza que se pone, y una
	/// pieza no puede aparecer dos veces (ni puesta y sacada a la vez). El resto
	/// lo valida el backend al registrar cada cambio.
	_Faltante? _validarCambiosPieza(ServicioFormularioState estado) {
		if (!estado.requiereDatosDeCampo) {
			return null;
		}
		final cambios = estado.cambiosPieza;
		final vistas = <String>{};
		for (var i = 0; i < cambios.length; i++) {
			final cambio = cambios[i];
			final cual = cambios.length == 1 ? '' : ' (cambio ${i + 1})';
			final puesta = normalizarSerie(cambio.nroSerie);
			final retirada = normalizarSerie(cambio.retiradaNroSerie);
			if (puesta.isEmpty) {
				return (campo: CampoFormularioServicio.cambiosPieza, mensaje: 'Completa el número de serie de la ${cambio.nombreTipo} que se pone$cual.');
			}
			if (puesta == retirada) {
				return (campo: CampoFormularioServicio.cambiosPieza, mensaje: 'La pieza que se saca no puede ser la misma que se pone$cual.');
			}
			for (final serie in [puesta, retirada]) {
				if (serie.isNotEmpty && !vistas.add(serie)) {
					return (campo: CampoFormularioServicio.cambiosPieza, mensaje: 'La pieza $serie está dos veces en los cambios de placa/celda.');
				}
			}
		}
		return null;
	}

	Servicio _mapearServicio(ServicioFormularioState estado) {
		final estadoRecalculado = _recalcularFacturacion(estado);
		final clienteSeleccionado = estadoRecalculado.clienteSeleccionado;
		final productosFalla = _productosFallaNormalizados(
			estadoRecalculado.productosFallaSeleccionados,
		);
		final kmCantidad = _kmFacturables(estadoRecalculado);
		final precioServicioUsd = _doubleDesdeTexto(
			estadoRecalculado.precioServicioUsd,
			valorPorDefecto: 0,
		);
		// Las mismas lineas que se ven en pantalla: lo que se guarda es lo que
		// vio el cliente.
		final facturacionItems = estadoRecalculado.itemsFacturacion;
		final incluyeFacturacion =
				precioServicioUsd > 0 ||
				kmCantidad > 0 ||
				estadoRecalculado.repuestosSeleccionados.isNotEmpty;
		final partesFallaron = productosFalla
				.map((item) => item.parteFallo)
				.where((item) => item.isNotEmpty)
				.toSet()
				.toList();

		final esCampo = estadoRecalculado.requiereDatosDeCampo;

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
			clienteNombre: _textoClienteOpcional(clienteSeleccionado?.nombre),
			clienteCuit: _textoClienteOpcional(clienteSeleccionado?.cuit),
			clienteTelefono: _textoClienteOpcional(clienteSeleccionado?.telefono),
			clienteLocalidad: _textoClienteOpcional(clienteSeleccionado?.localidad),
			clienteContacto: _textoClienteOpcional(clienteSeleccionado?.contacto),
			lugarProvinciaId: esCampo ? estadoRecalculado.lugarProvinciaId.trim() : null,
			lugarDetalle: esCampo ? estadoRecalculado.lugarDetalle.trim() : null,
			equipoNroSerie: estadoRecalculado.equipoNroSerie.trim(),
			equipoModelo: estadoRecalculado.equipoModelo.trim(),
			equipoUbicacion: estadoRecalculado.equipoUbicacion.trim(),
			equipoAnio: int.parse(estadoRecalculado.equipoAnio.trim()),
			partesFallaron: partesFallaron,
			km: esCampo ? kmCantidad.toInt() : null,
			sintoma: estadoRecalculado.sintoma.trim(),
			diagnosticoDetalle: estadoRecalculado.diagnosticoDetalle.trim(),
			diagnosticoCatIds: estadoRecalculado.diagnosticoCatIdsSeleccionados,
			resolucionIds: estadoRecalculado.resolucionIdsSeleccionados,
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

	String? _textoClienteOpcional(String? valor) {
		final normalizado = (valor ?? '').trim();
		return normalizado.isEmpty ? null : normalizado;
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

	/// Km que se facturan: enteros, igual que el `km` de la orden, para que
	/// `facturacion.kmCantidad` coincida con `km` y la linea de viatico sea la
	/// misma en pantalla y en el backend.
	double _kmFacturables(ServicioFormularioState estado) {
		final km = _doubleDesdeTexto(estado.km, valorPorDefecto: 0);
		if (km <= 0) {
			return 0;
		}
		return km.roundToDouble();
	}

	/// Todos los importes salen de las lineas de facturacion: primero se arman
	/// las lineas (las mismas que se muestran y se mandan) y los subtotales son
	/// la suma de esas lineas. Asi el total de pantalla es exactamente el que
	/// guarda el backend.
	ServicioFormularioState _recalcularFacturacion(ServicioFormularioState estado) {
		final items = _construirItemsFacturacion(estado, _kmFacturables(estado));

		double sumarUsd(bool Function(FacturacionItem item) filtro) => _redondear2(
					items.where(filtro).fold(0.0, (acumulado, item) => acumulado + item.subtotalUsd),
				);
		double sumarArs(bool Function(FacturacionItem item) filtro) => _redondear2(
					items.where(filtro).fold(0.0, (acumulado, item) => acumulado + item.subtotalArs),
				);

		final subtotalKmUsd = sumarUsd((item) => item.tipoItem == 'viatico');
		final subtotalKmArs = sumarArs((item) => item.tipoItem == 'viatico');
		final subtotalServicioUsd = sumarUsd((item) => item.tipoItem == 'mano_obra');
		final subtotalServicioArs = sumarArs((item) => item.tipoItem == 'mano_obra');
		final subtotalRepuestosUsd = sumarUsd((item) => item.tipoItem == 'repuesto');
		final subtotalRepuestosArs = sumarArs((item) => item.tipoItem == 'repuesto');
		final subtotalBrutoUsd = sumarUsd((_) => true);
		final subtotalBrutoArs = sumarArs((_) => true);

		final ivaPorcentaje = _doubleDesdeTexto(estado.ivaPorcentaje, valorPorDefecto: 21);
		final descuentoPorcentaje = _doubleDesdeTexto(
			estado.descuentoPorcentaje,
			valorPorDefecto: 0,
		);
		final factorDescuento = (1 - (descuentoPorcentaje / 100)).clamp(0.0, 1.0);
		final subtotalGeneralUsd = subtotalBrutoUsd;
		final subtotalGeneralArs = subtotalBrutoArs;

		final totalConIvaArs = _redondear2(
			subtotalGeneralArs * (1 + (ivaPorcentaje / 100)),
		);
		final totalFinalArs = _redondear2(totalConIvaArs * factorDescuento);

		return estado.copyWith(
			subtotalKmUsd: subtotalKmUsd,
			subtotalKmArs: subtotalKmArs,
			subtotalServicioUsd: subtotalServicioUsd,
			subtotalServicioArs: subtotalServicioArs,
			subtotalRepuestosUsd: subtotalRepuestosUsd,
			subtotalRepuestosArs: subtotalRepuestosArs,
			subtotalGeneralUsd: subtotalGeneralUsd,
			subtotalGeneralArs: subtotalGeneralArs,
			totalConIvaArs: totalConIvaArs,
			totalFinalArs: totalFinalArs,
			itemsFacturacion: items,
			// copyWith limpia los mensajes de un solo uso si no se pasan: recalcular
			// no tiene que borrar el error o aviso que trae el estado.
			errorMensaje: estado.errorMensaje,
			exitoMensaje: estado.exitoMensaje,
			avisoValores: estado.avisoValores,
		);
	}

	List<FacturacionItem> _construirItemsFacturacion(
		ServicioFormularioState estado,
		double kmCantidad,
	) {
		final items = <FacturacionItem>[];
		final precioServicioUsd = _doubleDesdeTexto(
			estado.precioServicioUsd,
			valorPorDefecto: 0,
		);

		if (precioServicioUsd > 0) {
			final precioServicioArs = _redondear2(
				precioServicioUsd * estado.cotizacionDolarSnapshot,
			);
			items.add(
				FacturacionItem(
					tipoItem: 'mano_obra',
					referenciaId: null,
					descripcion: 'Servicio tecnico',
					cantidad: 1,
					precioUnitarioUsd: precioServicioUsd,
					precioUnitarioArs: precioServicioArs,
					subtotalUsd: precioServicioUsd,
					subtotalArs: precioServicioArs,
				),
			);
		}

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
		if (valor.contains('web')) {
			return 'web';
		}
		if (valor.contains('app') && valor.contains('pc')) {
			return 'app_pc';
		}
		if (valor.contains('pc') || valor.contains('escritorio')) {
			return 'app_pc';
		}
		if (valor.contains('tablet')) {
			return 'tablet';
		}

		return 'otro';
	}
}


