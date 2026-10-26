import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/asignar_unidad_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/buscar_unidades_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/guardar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/obtener_asignaciones_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/application/quitar_asignacion_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/infrastructure/repositories/fabrica_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_clientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/buscar_repuestos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/crear_cliente_rapido_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/descargar_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/encolar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/generar_pdf_orden_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cotizacion_actual_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_documentos_pendientes_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_enlace_pdf_documento_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/quitar_documento_pendiente_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/subir_documento_firmado_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/producto_falla.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/repuesto.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_cliente_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _zonaId = '33333333-3333-4333-8333-333333333333';
const String _diagnosticoId = '44444444-4444-4444-8444-444444444444';
const String _resolucionId = '66666666-6666-4666-8666-666666666666';
const String _productoId = '88888888-8888-4888-8888-888888888888';
const String _repuestoCeldaId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _repuestoCableId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

const Repuesto _celda = Repuesto(
	id: _repuestoCeldaId,
	codigo: 'CEL-01',
	nombre: 'Celda de carga',
	precioUsd: 120.75,
);
const Repuesto _cable = Repuesto(
	id: _repuestoCableId,
	codigo: 'CAB-02',
	nombre: 'Cable indicador',
	precioUsd: 15,
);

final Map<String, dynamic> _respuestaAlta = {
	'replayed': false,
	'servicioId': '99999999-9999-4999-8999-999999999999',
	'idempotencyKey': '2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f',
	'estadoOrden': 'cerrada',
	'version': 1,
	'servicio': {'canal': 'campo', 'clienteId': _clienteId},
};

http.Response _rechazo409(String codigo, String mensaje, List<Map<String, dynamic>> items) {
	return http.Response(
		jsonEncode({
			'statusCode': 409,
			'error': 'Conflict',
			'codigo': codigo,
			'mensaje': mensaje,
			'message': mensaje,
			'items': items,
		}),
		409,
	);
}

/// Backend simulado: GET /cotizacion y /tarifa-km devuelven los valores
/// vigentes del momento y cada POST /servicios responde con lo que diga
/// `respuestasAlta` (en orden). Guarda los bodies que llegaron.
class _Escenario {
	double cotizacion;
	double valorKmUsd;
	final List<http.Response Function()> respuestasAlta;
	final List<Map<String, dynamic>> bodiesAlta = [];

	late final SecureStorageEnMemoria _storage;
	late final ApiClient _apiClient;
	late final ServicioBloc bloc;

	_Escenario({
		this.cotizacion = 1535.5,
		this.valorKmUsd = 0.75,
		List<http.Response Function()>? respuestasAlta,
	}) : respuestasAlta = respuestasAlta ?? [] {
		_storage = SecureStorageEnMemoria();
		_apiClient = ApiClient(
			MockClient((request) async {
				final path = request.url.path;
				if (request.method == 'POST' && path.endsWith('/servicios')) {
					bodiesAlta.add(jsonDecode(request.body) as Map<String, dynamic>);
					final indice = bodiesAlta.length - 1;
					if (indice < this.respuestasAlta.length) {
						return this.respuestasAlta[indice]();
					}
					return http.Response(jsonEncode(_respuestaAlta), 201);
				}
				if (request.method == 'GET' && path.endsWith('/cotizacion')) {
					return http.Response(jsonEncode({'valor': cotizacion}), 200);
				}
				if (request.method == 'GET' && path.endsWith('/tarifa-km')) {
					return http.Response(jsonEncode({'valorKmUsd': valorKmUsd}), 200);
				}
				return http.Response('{}', 404);
			}),
			_storage,
		);
		final repositorio = ServicioRepositoryImpl(_apiClient, _storage);
		final fabrica = FabricaRepositoryImpl(_apiClient, _storage);
		bloc = ServicioBloc(
			CargarServicioUseCase(repositorio),
			ObtenerMisServiciosUseCase(repositorio),
			BuscarClientesUseCase(repositorio),
			CrearClienteRapidoUseCase(repositorio),
			ObtenerCotizacionActualUseCase(repositorio),
			BuscarRepuestosUseCase(repositorio),
			GenerarPdfOrdenServicioUseCase(),
			SubirDocumentoFirmadoUseCase(repositorio),
			EncolarDocumentoPendienteUseCase(repositorio),
			ObtenerDocumentosPendientesUseCase(repositorio),
			QuitarDocumentoPendienteUseCase(repositorio),
			ObtenerEnlacePdfDocumentoUseCase(repositorio),
			DescargarPdfDocumentoUseCase(repositorio),
			ObtenerClienteUseCase(repositorio),
			AsignarUnidadUseCase(fabrica),
			BuscarUnidadesUseCase(fabrica),
			GuardarAsignacionPendienteUseCase(fabrica),
			ObtenerAsignacionesPendientesUseCase(fabrica),
			QuitarAsignacionPendienteUseCase(fabrica),
		);
	}

	ServicioFormularioState get estado => bloc.state as ServicioFormularioState;

	/// Lo que hace la app al entrar a Facturacion o con "Actualizar valores".
	Future<ServicioFormularioState> actualizarValores() async {
		final listo = bloc.stream.firstWhere(
			(estado) => estado is ServicioFormularioState && !estado.cargandoFacturacion,
		);
		bloc.add(const ServicioFacturacionInicializada());
		return await listo as ServicioFormularioState;
	}

	Future<void> cargarOrdenDeCampo({
		String km = '120',
		String precioServicioUsd = '80',
		List<Repuesto> repuestos = const [_celda],
	}) async {
		bloc.add(
			ServicioFormularioCambiado(
				canal: Canal.campo,
				clienteId: _clienteId,
				zonaId: _zonaId,
				lugarDetalle: 'Cestari 14',
				km: km,
				equipoNroSerie: 'SN-001',
				equipoModelo: 'ST455',
				equipoUbicacion: 'Tolva principal',
				equipoAnio: '2021',
				precioServicioUsd: precioServicioUsd,
				sintoma: 'Pesa mal',
				diagnosticoDetalle: 'Celda con humedad',
				diagnosticoCatIdsSeleccionados: const [_diagnosticoId],
				resolucionIdsSeleccionados: const [_resolucionId],
				partesFallaronTexto: 'Celda',
				productosFallaSeleccionados: [
					ProductoFalla(parteFallo: 'Celda', productoFallaId: _productoId),
				],
			),
		);
		for (final repuesto in repuestos) {
			bloc.add(ServicioRepuestoAgregado(repuesto: repuesto));
		}
		// Los eventos sincronicos ya se procesaron cuando el bloc emite el ultimo.
		await Future<void>.delayed(Duration.zero);
	}

	/// Toca "Guardar" y espera el resultado: exito, error o aviso de valores.
	Future<ServicioFormularioState> guardar() async {
		final resultado = bloc.stream.firstWhere(
			(estado) =>
					estado is ServicioFormularioState &&
					!estado.guardando &&
					(estado.exitoMensaje != null ||
							estado.errorMensaje != null ||
							estado.avisoValores != null),
		);
		bloc.add(const ServicioGuardarPressed());
		return await resultado as ServicioFormularioState;
	}

	Future<void> cerrar() async {
		await bloc.close();
		await _apiClient.dispose();
	}
}

double _sumar(List<dynamic> items, String campo) {
	return items.fold<double>(
		0,
		(acumulado, item) => acumulado + ((item as Map<String, dynamic>)[campo] as num).toDouble(),
	);
}

void main() {
	// El alta genera el PDF de la orden: sin binding el cargador de fuentes
	// ensucia la salida del test.
	TestWidgetsFlutterBinding.ensureInitialized();

	group('valores con los que se calculo la orden', () {
		test('manda la cotizacion y el valor del km que vio el cliente', () async {
			final escenario = _Escenario(cotizacion: 1535.5, valorKmUsd: 0.75);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.errorMensaje, isNull);
			final facturacion = escenario.bodiesAlta.single['facturacion'] as Map<String, dynamic>;
			expect(facturacion['cotizacionDolarSnapshot'], 1535.5);
			expect(facturacion['valorKmUsdSnapshot'], 0.75);
		});

		test('el total de pantalla es la suma de las mismas lineas que se mandan', () async {
			// 120 km x 0.75 USD con 1535.5: calcular el km en USD y despues pasar a
			// pesos da 138195.00; la linea (120 x 1151.63) da 138195.60. Antes la
			// pantalla mostraba una cosa y el backend recibia otra.
			final escenario = _Escenario(cotizacion: 1535.5, valorKmUsd: 0.75);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();
			final pantalla = escenario.estado;

			await escenario.guardar();
			await escenario.cerrar();

			final body = escenario.bodiesAlta.single;
			final facturacion = body['facturacion'] as Map<String, dynamic>;
			final items = body['facturacionItems'] as List<dynamic>;

			expect(pantalla.subtotalKmArs, 138195.6);
			expect(
				pantalla.subtotalGeneralArs,
				closeTo(_sumar(items, 'subtotalArs'), 0.001),
			);
			expect(facturacion['subtotalGeneralArs'], pantalla.subtotalGeneralArs);
			expect(facturacion['totalFinalArs'], pantalla.totalFinalArs);
			expect(
				pantalla.itemsFacturacion.map((item) => item.subtotalArs).toList(),
				items.map((item) => (item as Map<String, dynamic>)['subtotalArs']).toList(),
			);
		});

		test('los km se facturan enteros y coinciden con el km de la orden', () async {
			final escenario = _Escenario();
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo(km: '120.6');

			await escenario.guardar();
			await escenario.cerrar();

			final body = escenario.bodiesAlta.single;
			final facturacion = body['facturacion'] as Map<String, dynamic>;
			expect(body['km'], 121);
			expect(facturacion['kmCantidad'], 121);
		});

		test('en campo no deja guardar con 0 km', () async {
			final escenario = _Escenario();
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo(km: '0');

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.errorMensaje, contains('mayores a 0'));
			expect(escenario.bodiesAlta, isEmpty);
		});

		test('sin cotizacion cargada no deja guardar una orden con cobro', () async {
			final escenario = _Escenario();
			await escenario.cargarOrdenDeCampo();

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.errorMensaje, contains('Actualizar valores'));
			expect(escenario.bodiesAlta, isEmpty);
		});
	});

	group('rechazo por valores que cambiaron', () {
		test('cotizacion vencida: no se guarda, se actualiza y se avisa con el total nuevo', () async {
			final escenario = _Escenario(
				cotizacion: 1535.5,
				respuestasAlta: [
					() => _rechazo409(
								'COTIZACION_INVALIDA',
								'La cotizacion del dolar con la que se calculo la orden ya no es valida.',
								[
									{
										'codigo': 'COTIZACION_INVALIDA',
										'campo': 'cotizacionDolarSnapshot',
										'valorEnviado': 1535.5,
										'valorVigente': 1600,
									},
								],
							),
				],
			);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();
			final totalMostrado = escenario.estado.totalFinalArs;

			final estado = await escenario.guardar();

			expect(estado.exitoMensaje, isNull);
			expect(estado.errorMensaje, isNull);
			final aviso = estado.avisoValores!;
			expect(aviso.ordenRechazada, isTrue);
			expect(aviso.titulo, contains('NO se guardo'));
			expect(aviso.cambios.single, contains('1535.50 -> 1600.00'));
			expect(aviso.totalAnteriorArs, totalMostrado);
			expect(aviso.totalNuevoArs, estado.totalFinalArs);
			expect(aviso.totalNuevoArs, greaterThan(totalMostrado));

			// No se pierde nada de lo cargado.
			expect(estado.cotizacionDolarSnapshot, 1600);
			expect(estado.clienteId, _clienteId);
			expect(estado.sintoma, 'Pesa mal');
			expect(estado.repuestosSeleccionados.single.repuesto.id, _repuestoCeldaId);

			await escenario.cerrar();
		});

		test('al volver a guardar manda los valores nuevos con la misma idempotencyKey', () async {
			final escenario = _Escenario(
				respuestasAlta: [
					() => _rechazo409('COTIZACION_INVALIDA', 'Cotizacion vencida', [
								{
									'codigo': 'COTIZACION_INVALIDA',
									'campo': 'cotizacionDolarSnapshot',
									'valorEnviado': 1535.5,
									'valorVigente': 1600,
								},
							]),
				],
			);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();

			await escenario.guardar();
			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.exitoMensaje, isNotNull);
			expect(escenario.bodiesAlta, hasLength(2));
			final primero = escenario.bodiesAlta[0];
			final segundo = escenario.bodiesAlta[1];
			expect(segundo['idempotencyKey'], primero['idempotencyKey']);
			expect(
				(segundo['facturacion'] as Map<String, dynamic>)['cotizacionDolarSnapshot'],
				1600,
			);
		});

		test('valor del km vencido: se actualiza el viatico', () async {
			final escenario = _Escenario(
				valorKmUsd: 0.75,
				respuestasAlta: [
					() => _rechazo409('TARIFA_KM_INVALIDA', 'El valor del km ya no es valido.', [
								{
									'codigo': 'TARIFA_KM_INVALIDA',
									'campo': 'valorKmUsdSnapshot',
									'valorEnviado': 0.75,
									'valorVigente': 0.8,
								},
							]),
				],
			);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.valorKmUsdSnapshot, 0.8);
			expect(estado.subtotalKmUsd, 96);
			expect(estado.avisoValores!.cambios.single, contains('Valor del km'));
		});

		test('precio de repuesto cambiado y repuesto dado de baja', () async {
			final escenario = _Escenario(
				respuestasAlta: [
					() => _rechazo409(
								'REPUESTO_INACTIVO',
								'La orden tiene repuestos que no coinciden con el catalogo vigente',
								[
									{
										'codigo': 'PRECIO_REPUESTO_DESACTUALIZADO',
										'repuestoId': _repuestoCeldaId,
										'descripcion': 'CEL-01 - Celda de carga',
										'precioEnviadoUsd': 120.75,
										'precioVigenteUsd': 130,
									},
									{
										'codigo': 'REPUESTO_INACTIVO',
										'repuestoId': _repuestoCableId,
										'descripcion': 'CAB-02 - Cable indicador',
										'precioEnviadoUsd': 15,
										'precioVigenteUsd': 15,
									},
								],
							),
				],
			);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo(repuestos: const [_celda, _cable]);

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.repuestosSeleccionados, hasLength(1));
			expect(estado.repuestosSeleccionados.single.repuesto.precioUsd, 130);
			final cambios = estado.avisoValores!.cambios;
			expect(cambios, hasLength(2));
			expect(cambios[0], contains('120.75 -> 130.00'));
			expect(cambios[1], contains('se quito de la orden'));
			expect(cambios[1], contains('dado de baja'));
		});

		test('un 409 que no es de valores sigue siendo un error comun', () async {
			final escenario = _Escenario(
				respuestasAlta: [
					() => http.Response(
								jsonEncode({
									'statusCode': 409,
									'error': 'Conflict',
									'message': 'idempotencyKey ya usada con otro contenido',
								}),
								409,
							),
				],
			);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();

			final estado = await escenario.guardar();
			await escenario.cerrar();

			expect(estado.avisoValores, isNull);
			expect(estado.errorMensaje, 'idempotencyKey ya usada con otro contenido');
		});
	});

	group('actualizar valores antes de mostrar el total', () {
		test('la primera carga no avisa', () async {
			final escenario = _Escenario();
			final estado = await escenario.actualizarValores();
			await escenario.cerrar();

			expect(estado.cotizacionDolarSnapshot, 1535.5);
			expect(estado.avisoValores, isNull);
		});

		test('si la cotizacion cambio desde la ultima carga, avisa con el total nuevo', () async {
			final escenario = _Escenario(cotizacion: 1535.5);
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();
			final totalAnterior = escenario.estado.totalFinalArs;

			escenario.cotizacion = 1550;
			final estado = await escenario.actualizarValores();
			await escenario.cerrar();

			final aviso = estado.avisoValores!;
			expect(aviso.ordenRechazada, isFalse);
			expect(aviso.cambios.single, contains('1535.50 -> 1550.00'));
			expect(aviso.totalAnteriorArs, totalAnterior);
			expect(aviso.totalNuevoArs, estado.totalFinalArs);
		});

		test('si no cambio nada, no avisa', () async {
			final escenario = _Escenario();
			await escenario.actualizarValores();
			await escenario.cargarOrdenDeCampo();

			final estado = await escenario.actualizarValores();
			await escenario.cerrar();

			expect(estado.avisoValores, isNull);
		});
	});
}
