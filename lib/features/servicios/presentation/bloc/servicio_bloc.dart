import 'package:cliente_feedback_tecnico/features/servicios/application/cargar_servicio_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/application/obtener_mis_servicios_use_case.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/servicio.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_event.dart';
import 'package:cliente_feedback_tecnico/features/servicios/presentation/bloc/servicio_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServicioBloc extends Bloc<ServicioEvent, ServicioState> {
	final CargarServicioUseCase _cargarServicioUseCase;
	final ObtenerMisServiciosUseCase _obtenerMisServiciosUseCase;

	Canal? _canal;
	String? _zonaId;
	String? _productoId;
	String? _sintoma;
	String? _diagnosticoCatId;
	String? _diagnosticoDetalle;
	String? _resolucionId;
	String? _observaciones;

	ServicioBloc(this._cargarServicioUseCase, this._obtenerMisServiciosUseCase)
			: super(const ServicioInitial()) {
		on<ServicioFormularioCambiado>(_onServicioFormularioCambiado);
		on<ServicioGuardarPressed>(_onServicioGuardarPressed);
		on<MisServiciosSolicitados>(_onMisServiciosSolicitados);
		on<ServicioFormularioReiniciado>(_onServicioFormularioReiniciado);
	}

	void _onServicioFormularioCambiado(
		ServicioFormularioCambiado event,
		Emitter<ServicioState> emit,
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

	Future<void> _onServicioGuardarPressed(
		ServicioGuardarPressed event,
		Emitter<ServicioState> emit,
	) async {
		final faltanCampos = _canal == null ||
				(_zonaId?.isEmpty ?? true) ||
				(_productoId?.isEmpty ?? true) ||
				(_sintoma?.isEmpty ?? true) ||
				(_diagnosticoCatId?.isEmpty ?? true) ||
				(_diagnosticoDetalle?.isEmpty ?? true) ||
				(_resolucionId?.isEmpty ?? true);

		if (faltanCampos) {
			emit(const ServicioError(mensaje: 'Completa todos los campos obligatorios.'));
			return;
		}

		emit(const ServicioGuardando());
		try {
			final servicio = Servicio(
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
			await _cargarServicioUseCase.ejecutar(servicio);
			emit(const ServicioGuardadoExito());
		} catch (_) {
			emit(const ServicioError(mensaje: 'No se pudo guardar la orden de servicio.'));
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
		} catch (_) {
			emit(const ServicioError(mensaje: 'No se pudieron cargar los servicios.'));
		}
	}

	void _onServicioFormularioReiniciado(
		ServicioFormularioReiniciado event,
		Emitter<ServicioState> emit,
	) {
		_canal = null;
		_zonaId = null;
		_productoId = null;
		_sintoma = null;
		_diagnosticoCatId = null;
		_diagnosticoDetalle = null;
		_resolucionId = null;
		_observaciones = null;
		emit(const ServicioInitial());
	}
}


