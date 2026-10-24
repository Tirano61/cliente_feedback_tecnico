import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/cliente.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:equatable/equatable.dart';

/// Datos con los que arranca el formulario cuando se abre desde otra pantalla
/// (por ejemplo el servicio de fabrica de una recepcion). El canal queda fijo;
/// el resto se puede corregir.
class PrecargaFormularioServicio extends Equatable {
	final Canal canal;
	final Cliente? cliente;
	final String equipoNroSerie;
	final String equipoModelo;

	/// Producto del modelo, para que el selector de indicadores lo muestre.
	final String? equipoModeloProductoId;
	final String sintoma;

	const PrecargaFormularioServicio({
		required this.canal,
		this.cliente,
		this.equipoNroSerie = '',
		this.equipoModelo = '',
		this.equipoModeloProductoId,
		this.sintoma = '',
	});

	@override
	List<Object?> get props => [
				canal,
				cliente,
				equipoNroSerie,
				equipoModelo,
				equipoModeloProductoId,
				sintoma,
			];
}
