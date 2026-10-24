import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/estados_fabrica.dart';
import 'package:cliente_feedback_tecnico/features/fabrica/domain/entities/referencias_fabrica.dart';
import 'package:equatable/equatable.dart';

/// Pieza con numero de serie: indicador, placa o celda.
///
/// `piezasInstaladas` solo viene cuando la unidad es un indicador
/// (`GET /fabrica/unidades/:id`); en el resto de las respuestas queda vacia.
class Unidad extends Equatable {
	final String id;
	final TipoUnidad tipo;
	final String nroSerie;
	final EstadoUnidad estado;
	final ProductoFabrica? producto;
	final String? indicadorActualId;
	final List<Unidad> piezasInstaladas;

	const Unidad({
		required this.id,
		required this.tipo,
		required this.nroSerie,
		required this.estado,
		this.producto,
		this.indicadorActualId,
		this.piezasInstaladas = const [],
	});

	@override
	List<Object?> get props => [
				id,
				tipo,
				nroSerie,
				estado,
				producto,
				indicadorActualId,
				piezasInstaladas,
			];
}
