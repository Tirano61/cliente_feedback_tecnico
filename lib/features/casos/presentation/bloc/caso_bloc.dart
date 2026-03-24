import 'package:cliente_feedback_tecnico/features/casos/application/cargar_caso_use_case.dart';
import 'package:cliente_feedback_tecnico/features/casos/application/obtener_mis_casos_use_case.dart';
import 'package:cliente_feedback_tecnico/features/casos/domain/entities/caso.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_event.dart';
import 'package:cliente_feedback_tecnico/features/casos/presentation/bloc/caso_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CasoBloc extends Bloc<CasoEvent, CasoState> {
	final CargarCasoUseCase _cargarCasoUseCase;
	final ObtenerMisCasosUseCase _obtenerMisCasosUseCase;

	Canal? _canal;
	String? _zonaId;
	String? _productoId;
	String? _sintoma;
	String? _diagnosticoCatId;
	String? _diagnosticoDetalle;
	String? _resolucionId;
	String? _observaciones;

	CasoBloc(this._cargarCasoUseCase, this._obtenerMisCasosUseCase)
			: super(const CasoInitial()) {
		on<CasoFormularioCambiado>(_onCasoFormularioCambiado);
		on<CasoGuardarPressed>(_onCasoGuardarPressed);
		on<MisCasosSolicitados>(_onMisCasosSolicitados);
		on<CasoFormularioReiniciado>(_onCasoFormularioReiniciado);
	}

	void _onCasoFormularioCambiado(
		CasoFormularioCambiado event,
		Emitter<CasoState> emit,
	) {
		_canal = event.canal ?? _canal;
		_zonaId = event.zonaId ?? _zonaId;
		_productoId = event.productoId ?? _productoId;
		_sintoma = event.sintoma ?? _sintoma;
		_diagnosticoCatId = event.diagnosticoCatId ?? _diagnosticoCatId;
		_diagnosticoDetalle = event.diagnosticoDetalle ?? _diagnosticoDetalle;
		_resolucionId = event.resolucionId ?? _resolucionId;
		_observaciones = event.observaciones ?? _observaciones;
	}

	Future<void> _onCasoGuardarPressed(
		CasoGuardarPressed event,
		Emitter<CasoState> emit,
	) async {
		final faltanCampos = _canal == null ||
				(_zonaId?.isEmpty ?? true) ||
				(_productoId?.isEmpty ?? true) ||
				(_sintoma?.isEmpty ?? true) ||
				(_diagnosticoCatId?.isEmpty ?? true) ||
				(_diagnosticoDetalle?.isEmpty ?? true) ||
				(_resolucionId?.isEmpty ?? true);

		if (faltanCampos) {
			emit(const CasoError(mensaje: 'Completa todos los campos obligatorios.'));
			return;
		}

		emit(const CasoGuardando());
		try {
			final caso = Caso(
				id: '',
				tecnicoId: '',
				productoId: _productoId!,
				zonaId: _zonaId!,
				canal: _canal!,
				fecha: DateTime.now(),
				sintoma: _sintoma!,
				diagnosticoCatId: _diagnosticoCatId!,
				diagnosticoDetalle: _diagnosticoDetalle!,
				resolucionId: _resolucionId!,
				resuelto: true,
				aprobado: false,
				observaciones: _observaciones,
			);
			await _cargarCasoUseCase.ejecutar(caso);
			emit(const CasoGuardadoExito());
		} catch (_) {
			emit(const CasoError(mensaje: 'No se pudo guardar la orden de servicio.'));
		}
	}

	Future<void> _onMisCasosSolicitados(
		MisCasosSolicitados event,
		Emitter<CasoState> emit,
	) async {
		emit(const MisCasosLoading());
		try {
			final casos = await _obtenerMisCasosUseCase.ejecutar();
			emit(MisCasosLoaded(casos: casos));
		} catch (_) {
			emit(const CasoError(mensaje: 'No se pudieron cargar los servicios.'));
		}
	}

	void _onCasoFormularioReiniciado(
		CasoFormularioReiniciado event,
		Emitter<CasoState> emit,
	) {
		_canal = null;
		_zonaId = null;
		_productoId = null;
		_sintoma = null;
		_diagnosticoCatId = null;
		_diagnosticoDetalle = null;
		_resolucionId = null;
		_observaciones = null;
		emit(const CasoInitial());
	}
}
