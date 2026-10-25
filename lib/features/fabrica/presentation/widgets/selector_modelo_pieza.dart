import 'package:cliente_feedback_tecnico/features/catalogos/domain/entities/producto.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_bloc.dart';
import 'package:cliente_feedback_tecnico/features/catalogos/presentation/bloc/catalogo_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Modelo de una placa o celda, del catalogo de productos (ingreso y poner
/// pieza). La pagina pide `CargarCatalogosProductos` al entrar.
class SelectorModeloPieza extends StatelessWidget {
	/// "placa" o "celda"; null: todavia no se eligio el tipo.
	final String? palabra;
	final String? productoId;
	final bool habilitado;

	/// null: "Sin especificar".
	final ValueChanged<String?> onChanged;

	const SelectorModeloPieza({
		required this.palabra,
		required this.productoId,
		required this.onChanged,
		this.habilitado = true,
		super.key,
	});

	@override
	Widget build(BuildContext context) {
		return BlocBuilder<CatalogoBloc, CatalogoState>(
			builder: (context, catalogoState) {
				final palabra = this.palabra;
				final modelos = catalogoState is CatalogoLoaded && palabra != null
						? catalogoState.modelosActivosDe(palabra)
						: const <Producto>[];
				final cargando = catalogoState is CatalogoLoaded && catalogoState.cargandoProductos;
				final seleccionado = modelos.any((p) => p.id == productoId) ? productoId : null;

				return DropdownButtonFormField<String?>(
					// Al llegar el catalogo o cambiar el tipo se reconstruye con el valor vigente.
					key: ValueKey('modelo-$palabra-${modelos.length}-$seleccionado'),
					initialValue: seleccionado,
					isExpanded: true,
					decoration: InputDecoration(
						labelText: palabra == null
								? 'Modelo (elegí primero el tipo)'
								: cargando
										? 'Modelo (cargando...)'
										: 'Modelo (opcional)',
					),
					items: [
						const DropdownMenuItem<String?>(value: null, child: Text('Sin especificar')),
						for (final producto in modelos)
							DropdownMenuItem<String?>(
								value: producto.id,
								child: Text(producto.nombre, overflow: TextOverflow.ellipsis),
							),
					],
					onChanged: palabra == null || !habilitado ? null : onChanged,
				);
			},
		);
	}
}
