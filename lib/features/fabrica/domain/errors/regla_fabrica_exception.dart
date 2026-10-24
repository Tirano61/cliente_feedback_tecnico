import 'package:cliente_feedback_tecnico/core/error/failures.dart';

/// Codigos con los que el backend rechaza una operacion de fabrica por una
/// regla de negocio. Ver la tabla "Errores con `codigo`" en endpoints.md.
class CodigoReglaFabrica {
	const CodigoReglaFabrica._();

	static const String recepcionAbierta = 'RECEPCION_ABIERTA';
	static const String recepcionCerrada = 'RECEPCION_CERRADA';
	static const String recepcionDeOtroIndicador = 'RECEPCION_DE_OTRO_INDICADOR';
	static const String transicionInvalida = 'TRANSICION_INVALIDA';
	static const String servicioRequerido = 'SERVICIO_REQUERIDO';
	static const String servicioNoEsDeFabrica = 'SERVICIO_NO_ES_DE_FABRICA';
	static const String servicioYaVinculado = 'SERVICIO_YA_VINCULADO';
	static const String ingresoAbierto = 'INGRESO_ABIERTO';
	static const String unidadNoDisponible = 'UNIDAD_NO_DISPONIBLE';
	static const String unidadYaInstalada = 'UNIDAD_YA_INSTALADA';
	static const String unidadEnOtroIndicador = 'UNIDAD_EN_OTRO_INDICADOR';
	static const String retiradaNoInstalada = 'RETIRADA_NO_INSTALADA';
	static const String celdaNoSeDeriva = 'CELDA_NO_SE_DERIVA';
	static const String fallaRequerida = 'FALLA_REQUERIDA';
	static const String reparacionYaRegistrada = 'REPARACION_YA_REGISTRADA';
	static const String componenteDeOtroModelo = 'COMPONENTE_DE_OTRO_MODELO';
	static const String clienteOrigenRequerido = 'CLIENTE_ORIGEN_REQUERIDO';
	static const String rolNoHabilitado = 'ROL_NO_HABILITADO';
}

/// El backend rechazo una operacion de fabrica con `{ codigo, mensaje }`.
///
/// `mensaje` esta pensado para mostrarlo tal cual. Es un `ServerException`,
/// asi que un BLoC que solo muestra el error no necesita distinguirla; el que
/// quiera reaccionar a un caso puntual mira `codigo` y `extra` (por ejemplo
/// `recepcionId` y `numero` en `RECEPCION_ABIERTA`).
class ReglaFabricaException extends ServerException {
	final String codigo;

	/// Campos adicionales del body, sin `statusCode`, `error`, `codigo`,
	/// `mensaje` ni `message`.
	final Map<String, dynamic> extra;

	const ReglaFabricaException({
		required this.codigo,
		required String mensaje,
		int? statusCode,
		this.extra = const {},
	}) : super(mensaje, statusCode: statusCode);

	@override
	String toString() => 'ReglaFabricaException($codigo): $mensaje';
}
