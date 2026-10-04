import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
import 'package:cliente_feedback_tecnico/core/api/api_constants.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/cerrar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/login_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/application/restaurar_sesion_use_case.dart';
import 'package:cliente_feedback_tecnico/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_state.dart';
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
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/filtro_estado_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/jwt_de_prueba.dart';
import '../../support/secure_storage_en_memoria.dart';

const String _servicioId = '11111111-1111-4111-8111-111111111111';

/// Un item de GET /servicios/mios sin documento: es candidato a que el bloc
/// pregunte por su PDF.
final Map<String, dynamic> _servicioSinDocumento = {
	'id': _servicioId,
	'canal': 'campo',
	'clienteId': '22222222-2222-4222-8222-222222222222',
	'equipoNroSerie': 'SN-900',
	'equipoModelo': 'ST455',
	'sintoma': 'No pesa',
	'km': 40,
};

/// GET /servicios/mios con el shape del contrato: `data` + `meta`.
http.Response _respuestaPagina(
	List<Map<String, dynamic>> items, {
	int page = 1,
	int totalPages = 1,
	int? total,
}) {
	return http.Response(
		jsonEncode({
			'data': items,
			'meta': {
				'page': page,
				'limit': 20,
				'total': total ?? items.length,
				'totalPages': totalPages,
			},
		}),
		200,
	);
}

class _Entorno {
	final SecureStorageEnMemoria storage;
	final ApiClient apiClient;
	final ServicioBloc servicioBloc;

	_Entorno({
		required this.storage,
		required this.apiClient,
		required this.servicioBloc,
	});

	Future<void> cerrar() async {
		await servicioBloc.close();
		await apiClient.dispose();
	}
}

_Entorno _armarEntorno(MockClient client) {
	final storage = SecureStorageEnMemoria();
	final apiClient = ApiClient(client, storage);
	final repositorio = ServicioRepositoryImpl(apiClient, storage);

	return _Entorno(
		storage: storage,
		apiClient: apiClient,
		servicioBloc: ServicioBloc(
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
		),
	);
}

/// AuthBloc autenticado y enchufado al mismo ApiClient, tal como lo arma
/// main.dart. Sirve para comprobar que el 401 termina en el login.
Future<AuthBloc> _authBlocAutenticado(_Entorno entorno) async {
	entorno.storage.valores['jwt_token'] = jwtConExpiracion(
		DateTime.now().toUtc().add(const Duration(hours: 8)),
	);
	entorno.storage.valores['usuario_sesion'] = jsonEncode({
		'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
		'fullName': 'Juan Perez',
		'email': 'tecnico@empresa.com',
		'roles': ['tecnico'],
	});

	final authRepository = AuthRepositoryImpl(entorno.apiClient, entorno.storage);
	final authBloc = AuthBloc(
		LoginUseCase(authRepository),
		RestaurarSesionUseCase(authRepository),
		CerrarSesionUseCase(authRepository),
		sesionExpirada: entorno.apiClient.sesionExpirada,
	);

	authBloc.add(const AppStarted());
	await authBloc.stream.firstWhere((estado) => estado is AuthAuthenticated);

	return authBloc;
}

MisServiciosLoaded _comoListado(ServicioState state) {
	expect(state, isA<MisServiciosLoaded>());
	return state as MisServiciosLoaded;
}

/// Mismo item pero con documento: el bloc no vuelve a preguntar por su PDF.
final Map<String, dynamic> _servicioConDocumento = {
	..._servicioSinDocumento,
	'documento': {'pdfUrl': 'https://cdn.ejemplo/orden.pdf'},
};

/// Deja el bloc en MisServiciosLoaded pasando por el evento real.
Future<MisServiciosLoaded> _cargarListado(_Entorno entorno) async {
	final cargado = entorno.servicioBloc.stream.firstWhere(
		(estado) => estado is MisServiciosLoaded,
	);
	entorno.servicioBloc.add(const MisServiciosSolicitados());
	return _comoListado(await cargado);
}

void main() {
	group('disponibilidad de PDF del listado', () {
		test('confirma el PDF de las ordenes que llegan sin documento', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioSinDocumento]);
					}
					if (request.url.path.endsWith('/servicios/$_servicioId/documento')) {
						return http.Response(
							jsonEncode({
								'documento': {'pdfUrl': '/servicios/$_servicioId/documento/pdf'},
							}),
							200,
						);
					}
					return http.Response('{}', 404);
				}),
			);

			final confirmado = entorno.servicioBloc.stream.firstWhere(
				(estado) =>
					estado is MisServiciosLoaded &&
					estado.serviciosConPdfConfirmado.contains(_servicioId),
			);
			entorno.servicioBloc.add(const MisServiciosSolicitados());

			final listado = _comoListado(await confirmado);
			expect(listado.tienePdfDisponible(listado.servicios.single), isTrue);

			await entorno.cerrar();
		});

		test('un 401 al verificar el PDF cierra la sesion', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioSinDocumento]);
					}
					return http.Response('{"message":"Unauthorized"}', 401);
				}),
			);
			final authBloc = await _authBlocAutenticado(entorno);

			final deslogueado = authBloc.stream.firstWhere(
				(estado) => estado is AuthUnauthenticated,
			);
			entorno.servicioBloc.add(const MisServiciosSolicitados());

			expect(
				((await deslogueado) as AuthUnauthenticated).mensaje,
				'Tu sesion expiro. Volve a ingresar.',
			);
			expect(entorno.storage.valores, isEmpty);

			await authBloc.close();
			await entorno.cerrar();
		});
	});

	group('ver / guardar PDF', () {
		test('deja los bytes del PDF como efecto para la vista', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					if (request.url.path.endsWith('/documento/pdf')) {
						return http.Response.bytes([37, 80, 68, 70], 200);
					}
					return http.Response('{}', 404);
				}),
			);
			final listado = await _cargarListado(entorno);

			final conEfecto = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.pdfParaAbrir != null,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoPdfVerSolicitado(servicio: listado.servicios.single),
			);

			final efecto = _comoListado(await conEfecto).pdfParaAbrir!;
			expect(efecto.servicioId, _servicioId);
			expect(efecto.nombreArchivo, 'orden_servicio_$_servicioId.pdf');
			expect(efecto.bytes, [37, 80, 68, 70]);

			await entorno.cerrar();
		});

		test('un 404 avisa que todavia no hay PDF y no deja efecto', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response('{"message":"Not Found"}', 404);
				}),
			);
			final listado = await _cargarListado(entorno);

			final conAviso = entorno.servicioBloc.stream.firstWhere(
				(estado) =>
					estado is MisServiciosLoaded && estado.mensajePendientes != null,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoPdfVerSolicitado(servicio: listado.servicios.single),
			);

			final conError = _comoListado(await conAviso);
			expect(conError.mensajePendientes, 'Esta orden aun no tiene PDF disponible.');
			expect(conError.pdfParaAbrir, isNull);
			expect(conError.servicioIdDescargandoPdf, isNull);

			await entorno.cerrar();
		});

		test('un 401 al descargar el PDF cierra la sesion', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response('{"message":"Unauthorized"}', 401);
				}),
			);
			final authBloc = await _authBlocAutenticado(entorno);
			final listado = await _cargarListado(entorno);

			final deslogueado = authBloc.stream.firstWhere(
				(estado) => estado is AuthUnauthenticated,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoPdfVerSolicitado(servicio: listado.servicios.single),
			);

			await deslogueado;
			expect(entorno.storage.valores, isEmpty);

			await authBloc.close();
			await entorno.cerrar();
		});
	});

	group('copiar enlace del PDF', () {
		test('deja el enlace absoluto como efecto tal cual lo manda el backend', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response(
						jsonEncode({
							'documento': {'pdfUrl': 'https://cdn.ejemplo/orden-firmada.pdf'},
						}),
						200,
					);
				}),
			);
			final listado = await _cargarListado(entorno);

			final conEfecto = entorno.servicioBloc.stream.firstWhere(
				(estado) =>
					estado is MisServiciosLoaded && estado.enlacePdfParaCopiar != null,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoEnlacePdfCopiarSolicitado(
					servicio: listado.servicios.single,
				),
			);

			final conEnlace = _comoListado(await conEfecto);
			expect(
				conEnlace.enlacePdfParaCopiar!.enlace,
				'https://cdn.ejemplo/orden-firmada.pdf',
			);
			expect(
				conEnlace.mensajePendientes,
				'Enlace del PDF copiado. Ya podes compartirlo.',
			);

			await entorno.cerrar();
		});

		test('convierte el enlace relativo del backend en absoluto', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response(
						jsonEncode({
							'documento': {'pdfUrl': '/servicios/$_servicioId/documento/pdf'},
						}),
						200,
					);
				}),
			);
			final listado = await _cargarListado(entorno);

			final conEfecto = entorno.servicioBloc.stream.firstWhere(
				(estado) =>
					estado is MisServiciosLoaded && estado.enlacePdfParaCopiar != null,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoEnlacePdfCopiarSolicitado(
					servicio: listado.servicios.single,
				),
			);

			expect(
				_comoListado(await conEfecto).enlacePdfParaCopiar!.enlace,
				'${ApiConstants.baseUrl}/servicios/$_servicioId/documento/pdf',
			);

			await entorno.cerrar();
		});

		test('una orden sin enlace avisa y no deja efecto', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response(jsonEncode({'documento': {}}), 200);
				}),
			);
			final listado = await _cargarListado(entorno);

			final conAviso = entorno.servicioBloc.stream.firstWhere(
				(estado) =>
					estado is MisServiciosLoaded && estado.mensajePendientes != null,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoEnlacePdfCopiarSolicitado(
					servicio: listado.servicios.single,
				),
			);

			final sinEnlace = _comoListado(await conAviso);
			expect(sinEnlace.mensajePendientes, 'Esta orden aun no tiene enlace PDF.');
			expect(sinEnlace.enlacePdfParaCopiar, isNull);
			expect(sinEnlace.servicioIdCopiandoEnlacePdf, isNull);

			await entorno.cerrar();
		});

		test('un 401 al pedir el enlace cierra la sesion', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([_servicioConDocumento]);
					}
					return http.Response('{"message":"Unauthorized"}', 401);
				}),
			);
			final authBloc = await _authBlocAutenticado(entorno);
			final listado = await _cargarListado(entorno);

			final deslogueado = authBloc.stream.firstWhere(
				(estado) => estado is AuthUnauthenticated,
			);
			entorno.servicioBloc.add(
				ServicioDocumentoEnlacePdfCopiarSolicitado(
					servicio: listado.servicios.single,
				),
			);

			await deslogueado;
			expect(entorno.storage.valores, isEmpty);

			await authBloc.close();
			await entorno.cerrar();
		});
	});

	group('filtro, busqueda y paginacion', () {
		/// Item del listado con documento, para que el bloc no consulte su PDF.
		Map<String, dynamic> servicio(String id, {bool aprobado = false}) => {
					..._servicioConDocumento,
					'id': id,
					'aprobado': aprobado,
				};

		test('lee aprobado del backend sin probar otros nombres', () async {
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						return _respuestaPagina([
							servicio('a', aprobado: true),
							{
								...servicio('b'),
								'aprobado_liquidacion': true,
								'liquidacion': {'aprobado': true},
							},
						]);
					}
					return http.Response('{}', 404);
				}),
			);

			final listado = await _cargarListado(entorno);
			expect(listado.servicios.map((s) => s.aprobado), [true, false]);

			await entorno.cerrar();
		});

		test('manda busqueda y filtro al backend y muestra lo que devuelve', () async {
			final pedidos = <Map<String, String>>[];
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						pedidos.add(request.url.queryParameters);
						// Mezcla aprobados y no: si la app filtrara localmente, se notaria.
						// El total cambia por pedido para saber a cual corresponde el estado.
						return _respuestaPagina(
							[servicio('a', aprobado: true), servicio('b')],
							total: 100 + pedidos.length,
							totalPages: 6,
						);
					}
					return http.Response('{}', 404);
				}),
			);

			final listado = await _cargarListado(entorno);
			expect(pedidos.single, {'page': '1', 'limit': '20'});
			expect(listado.total, 101);
			expect(listado.hayMasPaginas, isTrue);

			final filtrado = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.total == 102,
			);
			entorno.servicioBloc.add(
				const MisServiciosFiltroEstadoCambiado(
					filtro: FiltroEstadoServicio.pendientes,
				),
			);
			final conFiltro = _comoListado(await filtrado);
			expect(pedidos.last, {'aprobado': 'false', 'page': '1', 'limit': '20'});
			expect(conFiltro.servicios, hasLength(2));
			expect(conFiltro.actualizando, isFalse);

			final buscado = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.total == 103,
			);
			entorno.servicioBloc.add(
				const MisServiciosBusquedaCambiada(texto: '  perez '),
			);
			await buscado;
			expect(pedidos.last, {
				'q': 'perez',
				'aprobado': 'false',
				'page': '1',
				'limit': '20',
			});

			// Recargar no le borra al tecnico lo que estaba mirando.
			final recargado = await _cargarListado(entorno);
			expect(recargado.filtroEstado, FiltroEstadoServicio.pendientes);
			expect(recargado.busqueda, '  perez ');
			expect(pedidos.last, {
				'q': 'perez',
				'aprobado': 'false',
				'page': '1',
				'limit': '20',
			});

			await entorno.cerrar();
		});

		test('la busqueda espera a que el tecnico deje de tipear', () async {
			final busquedas = <String?>[];
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						busquedas.add(request.url.queryParameters['q']);
						return _respuestaPagina(
							[servicio('a')],
							total: busquedas.length,
						);
					}
					return http.Response('{}', 404);
				}),
			);
			await _cargarListado(entorno);

			final buscado = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.total == 2,
			);
			entorno.servicioBloc
				..add(const MisServiciosBusquedaCambiada(texto: 'p'))
				..add(const MisServiciosBusquedaCambiada(texto: 'pe'))
				..add(const MisServiciosBusquedaCambiada(texto: 'per'));
			final conBusqueda = _comoListado(await buscado);

			expect(busquedas, [null, 'per']);
			expect(conBusqueda.busqueda, 'per');

			await entorno.cerrar();
		});

		test('la pagina siguiente se agrega sin repetir servicios', () async {
			final paginas = <String?>[];
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						final page = request.url.queryParameters['page'];
						paginas.add(page);
						if (page == '1') {
							return _respuestaPagina(
								[servicio('a'), servicio('b')],
								total: 3,
								totalPages: 2,
							);
						}
						// Entro un servicio nuevo entre pagina y pagina: 'b' se repite.
						return _respuestaPagina(
							[servicio('b'), servicio('c')],
							page: 2,
							total: 4,
							totalPages: 2,
						);
					}
					return http.Response('{}', 404);
				}),
			);
			await _cargarListado(entorno);

			final completo = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.pagina == 2,
			);
			entorno.servicioBloc.add(const MisServiciosSiguientePaginaSolicitada());
			final listado = _comoListado(await completo);

			expect(listado.servicios.map((s) => s.id), ['a', 'b', 'c']);
			expect(listado.total, 4);
			expect(listado.hayMasPaginas, isFalse);
			expect(listado.cargandoMas, isFalse);

			// Sin paginas pendientes no se vuelve a pedir.
			entorno.servicioBloc.add(const MisServiciosSiguientePaginaSolicitada());
			await Future<void>.delayed(const Duration(milliseconds: 50));
			expect(paginas, ['1', '2']);

			await entorno.cerrar();
		});

		test('si falla la pagina siguiente solo se reintenta a pedido', () async {
			var paginasPedidas = 0;
			final entorno = _armarEntorno(
				MockClient((request) async {
					if (request.url.path.endsWith('/servicios/mios')) {
						if (request.url.queryParameters['page'] == '1') {
							return _respuestaPagina([servicio('a')], total: 2, totalPages: 2);
						}
						paginasPedidas++;
						if (paginasPedidas == 1) {
							return http.Response('{"message":"Fallo el backend"}', 500);
						}
						return _respuestaPagina(
							[servicio('b')],
							page: 2,
							total: 2,
							totalPages: 2,
						);
					}
					return http.Response('{}', 404);
				}),
			);
			await _cargarListado(entorno);

			final conError = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.errorPaginacion != null,
			);
			entorno.servicioBloc.add(const MisServiciosSiguientePaginaSolicitada());
			final fallido = _comoListado(await conError);
			expect(fallido.errorPaginacion, 'Fallo el backend');
			expect(fallido.servicios.map((s) => s.id), ['a']);

			// El scroll no reintenta solo.
			entorno.servicioBloc.add(const MisServiciosSiguientePaginaSolicitada());
			await Future<void>.delayed(const Duration(milliseconds: 50));
			expect(paginasPedidas, 1);

			final recuperado = entorno.servicioBloc.stream.firstWhere(
				(estado) => estado is MisServiciosLoaded && estado.pagina == 2,
			);
			entorno.servicioBloc.add(
				const MisServiciosSiguientePaginaSolicitada(reintento: true),
			);
			final listado = _comoListado(await recuperado);
			expect(listado.servicios.map((s) => s.id), ['a', 'b']);
			expect(listado.errorPaginacion, isNull);

			await entorno.cerrar();
		});
	});

	test('los tres pedidos de PDF viajan con el Bearer que pone ApiClient', () async {
		final autorizaciones = <String, String?>{};
		final entorno = _armarEntorno(
			MockClient((request) async {
				autorizaciones[request.url.path] = request.headers['Authorization'];

				if (request.url.path.endsWith('/servicios/mios')) {
					return _respuestaPagina([_servicioSinDocumento]);
				}
				if (request.url.path.endsWith('/documento/pdf')) {
					return http.Response.bytes([37, 80, 68, 70], 200);
				}
				return http.Response(
					jsonEncode({
						'documento': {'pdfUrl': 'https://cdn.ejemplo/orden.pdf'},
					}),
					200,
				);
			}),
		);

		final token = jwtConExpiracion(
			DateTime.now().toUtc().add(const Duration(hours: 8)),
		);
		entorno.storage.valores['jwt_token'] = token;

		// El listado dispara solo la verificacion del documento de cada orden.
		final confirmado = entorno.servicioBloc.stream.firstWhere(
			(estado) =>
				estado is MisServiciosLoaded &&
				estado.serviciosConPdfConfirmado.contains(_servicioId),
		);
		entorno.servicioBloc.add(const MisServiciosSolicitados());
		final listado = _comoListado(await confirmado);

		final conPdf = entorno.servicioBloc.stream.firstWhere(
			(estado) => estado is MisServiciosLoaded && estado.pdfParaAbrir != null,
		);
		entorno.servicioBloc.add(
			ServicioDocumentoPdfVerSolicitado(servicio: listado.servicios.single),
		);
		await conPdf;

		final conEnlace = entorno.servicioBloc.stream.firstWhere(
			(estado) =>
				estado is MisServiciosLoaded && estado.enlacePdfParaCopiar != null,
		);
		entorno.servicioBloc.add(
			ServicioDocumentoEnlacePdfCopiarSolicitado(
				servicio: listado.servicios.single,
			),
		);
		await conEnlace;

		expect(
			autorizaciones['/api/v1/servicios/$_servicioId/documento'],
			'Bearer $token',
		);
		expect(
			autorizaciones['/api/v1/servicios/$_servicioId/documento/pdf'],
			'Bearer $token',
		);

		await entorno.cerrar();
	});
}
