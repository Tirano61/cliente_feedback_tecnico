import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';

class PoliticaFirmaCanal {
	const PoliticaFirmaCanal._();

	static bool firmaHabilitada(Canal canal) {
		return canal == Canal.campo;
	}

	static bool puedeEnviarFirma({
		required Canal canal,
		required String? firmaClienteNombre,
		required DateTime? firmaFechaHora,
	}) {
		if (!firmaHabilitada(canal)) {
			return false;
		}

		final nombre = (firmaClienteNombre ?? '').trim();
		return nombre.isNotEmpty && firmaFechaHora != null;
	}
}
