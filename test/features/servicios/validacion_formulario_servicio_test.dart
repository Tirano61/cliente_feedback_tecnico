import 'dart:convert';

import 'package:cliente_feedback_tecnico/core/api/api_client.dart';
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
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/infrastructure/repositories/servicio_repository_impl.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/campos_formulario_servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_bloc.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/secure_storage_en_memoria.dart';

const String _clienteId = '22222222-2222-4222-8222-222222222222';
const String _zonaId = '33333333-3333-4333-8333-333333333333';

/// Backend simulado: solo cotizacion y tarifa; el alta no se llega a pedir
/// (cada caso falla en la validacion del BLoC). Guarda lo que llega.
class _Escenario {
	final List<http.Request> requests = [];
	late final ApiClient _apiClient;
	late final ServicioBloc bloc;

	_Escenario() {
		final storage = SecureStorageEnMemoria();
		_apiClient = ApiClient(
			MockClient((request) async {
				requests.add(request);
				final path = request.url.path;
				if (path.endsWith('/cotizacion')) {
					return http.Response(jsonEncode({'valor': 1550}), 200);
				}
				if (path.endsWith('/tarifa-km')) {
					return http.Response(jsonEncode({'valorKmUsd': 1.25}), 200);
				}
				return http.Response('{}', 404);
			}),
			storage,
		);
		final repositorio = ServicioRepositoryImpl(_apiClient, storage);
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
		);
	}

	ServicioFormularioState get estado => bloc.state as ServicioFormularioState;

	Future<void> cambiar(ServicioFormularioCambiado evento) async {
		bloc.add(evento);
		await Future<void>.delayed(Duration.zero);
	}

	/// Toca "Guardar" y devuelve el aviso de validacion.
	Future<ServicioFormularioState> guardar() async {
		final resultado = bloc.stream.firstWhere(
			(s) => s is ServicioFormularioState && s.avisoValidacion != null,
		);
		bloc.add(const ServicioGuardarPressed());
		return await resultado as ServicioFormularioState;
	}

	Future<void> cerrar() async {
		await bloc.close();
		await _apiClient.dispose();
	}
}

/// Una orden de fabrica con los datos del paso 2 completos salvo lo que se
/// pise.
ServicioFormularioCambiado _datosFabrica({String equipoUbicacion = 'Taller', String equipoAnio = '2020'}) {
	return ServicioFormularioCambiado(
		canal: Canal.fabrica,
		clienteId: _clienteId,
		equipoNroSerie: 'IND-1001',
		equipoModelo: 'ST455',
		equipoUbicacion: equipoUbicacion,
		equipoAnio: equipoAnio,
	);
}

void main() {
	late _Escenario escenario;

	setUp(() => escenario = _Escenario());
	tearDown(() => escenario.cerrar());

	group('aviso al guardar con algo sin completar', () {
		test('el mismo error dos veces se avisa las dos veces', () async {
			await escenario.cambiar(_datosFabrica(equipoUbicacion: ''));
			final avisos = escenario.bloc.stream
					.where((s) => s is ServicioFormularioState && s.avisoValidacion != null)
					.cast<ServicioFormularioState>()
					.take(2)
					.toList();

			escenario.bloc
				..add(const ServicioGuardarPressed())
				..add(const ServicioGuardarPressed());
			final [primero, segundo] = await avisos;

			expect(primero.errorMensaje, 'Completa la ubicación del equipo.');
			expect(segundo.errorMensaje, primero.errorMensaje);
			expect(segundo.avisoValidacion!.mensaje, primero.avisoValidacion!.mensaje);
			expect(segundo.avisoValidacion!.token, isNot(primero.avisoValidacion!.token));
			expect(segundo, isNot(primero), reason: 'si fueran iguales la vista no volveria a avisar');
			expect(escenario.requests.where((r) => r.method == 'POST'), isEmpty);
		});

		test('el aviso es de un solo uso: el proximo cambio ya no lo trae', () async {
			await escenario.cambiar(_datosFabrica(equipoUbicacion: ''));
			await escenario.guardar();

			await escenario.cambiar(const ServicioFormularioCambiado(equipoUbicacion: 'Taller'));

			expect(escenario.estado.avisoValidacion, isNull);
			expect(escenario.estado.errorMensaje, isNull);
		});

		test('sin canal: va al paso 1', () async {
			final estado = await escenario.guardar();

			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.canal);
			expect(estado.avisoValidacion!.paso, PasoFormularioServicio.tipo);
		});

		test('sin ubicacion ni año del equipo: va al paso de datos', () async {
			await escenario.cambiar(_datosFabrica(equipoUbicacion: '', equipoAnio: ''));
			final sinUbicacion = await escenario.guardar();
			expect(sinUbicacion.avisoValidacion!.campo, CampoFormularioServicio.equipoUbicacion);
			expect(sinUbicacion.avisoValidacion!.paso, PasoFormularioServicio.datos);

			await escenario.cambiar(const ServicioFormularioCambiado(equipoUbicacion: 'Taller'));
			final sinAnio = await escenario.guardar();
			expect(sinAnio.avisoValidacion!.campo, CampoFormularioServicio.equipoAnio);
			expect(sinAnio.avisoValidacion!.paso, PasoFormularioServicio.datos);
			expect(sinAnio.errorMensaje, 'Completa un año de equipo válido.');
		});

		test('sin partes que fallaron: va al paso de falla', () async {
			await escenario.cambiar(_datosFabrica());

			final estado = await escenario.guardar();

			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.partesFallaron);
			expect(estado.avisoValidacion!.paso, PasoFormularioServicio.falla);
		});

		test('campo con 0 km: va al paso de facturacion', () async {
			await escenario.cambiar(
				const ServicioFormularioCambiado(
					canal: Canal.campo,
					clienteId: _clienteId,
					zonaId: _zonaId,
					lugarDetalle: 'Cestari 14',
					equipoNroSerie: 'IND-1001',
					equipoModelo: 'ST455',
					equipoUbicacion: 'Tolva',
					equipoAnio: '2021',
					partesFallaronTexto: 'indicador',
					km: '0',
				),
			);

			final estado = await escenario.guardar();

			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.km);
			expect(estado.avisoValidacion!.paso, PasoFormularioServicio.facturacion);
		});

		test('con cobro y sin cotizacion: va al paso de facturacion', () async {
			await escenario.cambiar(_datosFabrica());
			await escenario.cambiar(
				const ServicioFormularioCambiado(partesFallaronTexto: 'indicador', precioServicioUsd: '50'),
			);

			final estado = await escenario.guardar();

			expect(estado.avisoValidacion!.campo, CampoFormularioServicio.valoresFacturacion);
			expect(estado.avisoValidacion!.paso, PasoFormularioServicio.facturacion);
			expect(estado.errorMensaje, contains('Actualizar valores'));
		});
	});

	group('campos obligatorios que marca la vista', () {
		test('en fabrica: datos del equipo si, zona, lugar y km no', () async {
			await escenario.cambiar(const ServicioFormularioCambiado(canal: Canal.fabrica));
			final estado = escenario.estado;

			for (final campo in [
				CampoFormularioServicio.cliente,
				CampoFormularioServicio.equipoNroSerie,
				CampoFormularioServicio.equipoModelo,
				CampoFormularioServicio.equipoUbicacion,
				CampoFormularioServicio.equipoAnio,
				CampoFormularioServicio.partesFallaron,
				CampoFormularioServicio.sintoma,
				CampoFormularioServicio.diagnosticoCategoria,
				CampoFormularioServicio.diagnosticoDetalle,
				CampoFormularioServicio.resolucion,
			]) {
				expect(estado.esObligatorio(campo), isTrue, reason: '$campo');
			}
			for (final campo in [
				CampoFormularioServicio.zona,
				CampoFormularioServicio.lugarDetalle,
				CampoFormularioServicio.km,
				CampoFormularioServicio.precioServicio,
			]) {
				expect(estado.esObligatorio(campo), isFalse, reason: '$campo');
			}
		});

		test('en campo: tambien zona, lugar y km', () async {
			await escenario.cambiar(const ServicioFormularioCambiado(canal: Canal.campo));
			final estado = escenario.estado;

			expect(estado.esObligatorio(CampoFormularioServicio.zona), isTrue);
			expect(estado.esObligatorio(CampoFormularioServicio.lugarDetalle), isTrue);
			expect(estado.esObligatorio(CampoFormularioServicio.km), isTrue);
			expect(estado.esObligatorio(CampoFormularioServicio.precioServicio), isFalse);
		});
	});
}
