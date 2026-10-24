import 'package:flutter/material.dart';

/// Lo que cargo el tecnico en el alta rapida, sin espacios en los extremos.
class AltaRapidaClienteDatos {
	final String cuit;
	final String nombre;
	final String contacto;
	final String telefono;
	final String localidad;

	const AltaRapidaClienteDatos({
		required this.cuit,
		required this.nombre,
		required this.contacto,
		required this.telefono,
		required this.localidad,
	});
}

/// Dialogo "Alta rapida de cliente". Lo usan el formulario de servicio y el
/// alta de recepcion: cada pantalla lo envuelve con el `BlocBuilder` de su
/// BLoC y despacha su evento en `onCrear`.
class AltaRapidaClienteDialogo extends StatefulWidget {
	final bool creando;

	/// Resultado del ultimo intento; se muestra despues de tocar "Crear cliente".
	final String? mensaje;
	final bool esError;
	final ValueChanged<AltaRapidaClienteDatos> onCrear;

	const AltaRapidaClienteDialogo({
		required this.creando,
		required this.mensaje,
		required this.esError,
		required this.onCrear,
		super.key,
	});

	@override
	State<AltaRapidaClienteDialogo> createState() => _AltaRapidaClienteDialogoState();
}

class _AltaRapidaClienteDialogoState extends State<AltaRapidaClienteDialogo> {
	final GlobalKey<FormState> _formularioKey = GlobalKey<FormState>();
	var _cuit = '';
	var _nombre = '';
	var _contacto = '';
	var _telefono = '';
	var _localidad = '';
	var _intentoCrear = false;

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		final textTheme = Theme.of(context).textTheme;
		final mensaje = widget.mensaje;

		return AlertDialog(
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
			titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
			contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
			actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
			title: Row(
				children: [
					Container(
						padding: const EdgeInsets.all(8),
						decoration: BoxDecoration(
							color: colorScheme.primary.withValues(alpha: 0.12),
							borderRadius: BorderRadius.circular(10),
						),
						child: Icon(
							Icons.person_add_alt_1_outlined,
							size: 20,
							color: colorScheme.primary,
						),
					),
					const SizedBox(width: 10),
					Expanded(
						child: Text(
							'Alta rapida de cliente',
							style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
						),
					),
				],
			),
			content: SizedBox(
				width: 580,
				child: Form(
					key: _formularioKey,
					autovalidateMode: AutovalidateMode.onUserInteraction,
					child: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Container(
									width: double.infinity,
									padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
									decoration: BoxDecoration(
										color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
										borderRadius: BorderRadius.circular(10),
									),
									child: Text(
										'Completá los datos para crear y seleccionar el cliente.',
										style: textTheme.bodySmall?.copyWith(
											color: colorScheme.onSurfaceVariant,
										),
									),
								),
								const SizedBox(height: 12),
								TextFormField(
									onChanged: (valor) => _cuit = valor,
									keyboardType: TextInputType.number,
									decoration: const InputDecoration(
										labelText: 'CUIT',
										hintText: 'Ej: 20240854124',
										border: OutlineInputBorder(),
									),
									validator: (valor) => _requerido(valor, 'El CUIT es obligatorio.'),
								),
								const SizedBox(height: 10),
								TextFormField(
									onChanged: (valor) => _nombre = valor,
									decoration: const InputDecoration(
										labelText: 'Nombre',
										hintText: 'Razón social o nombre del cliente',
										border: OutlineInputBorder(),
									),
									validator: (valor) => _requerido(valor, 'El nombre es obligatorio.'),
								),
								const SizedBox(height: 10),
								TextFormField(
									onChanged: (valor) => _contacto = valor,
									decoration: const InputDecoration(
										labelText: 'Contacto',
										border: OutlineInputBorder(),
									),
									validator: (valor) => _requerido(valor, 'El contacto es obligatorio.'),
								),
								const SizedBox(height: 10),
								TextFormField(
									onChanged: (valor) => _telefono = valor,
									keyboardType: TextInputType.phone,
									decoration: const InputDecoration(
										labelText: 'Telefono',
										hintText: 'Ej: +54 9 11 3462-552333',
										border: OutlineInputBorder(),
									),
									validator: (valor) => _requerido(valor, 'El telefono es obligatorio.'),
								),
								const SizedBox(height: 10),
								TextFormField(
									onChanged: (valor) => _localidad = valor,
									decoration: const InputDecoration(
										labelText: 'Localidad',
										hintText: 'Ej: Venado Tuerto',
										border: OutlineInputBorder(),
									),
									validator: (valor) => _requerido(valor, 'La localidad es obligatoria.'),
								),
								if (_intentoCrear && mensaje != null && mensaje.isNotEmpty) ...[
									const SizedBox(height: 12),
									Container(
										width: double.infinity,
										padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
										decoration: BoxDecoration(
											color: widget.esError
												? colorScheme.errorContainer.withValues(alpha: 0.65)
												: colorScheme.primaryContainer.withValues(alpha: 0.55),
											borderRadius: BorderRadius.circular(10),
										),
										child: Text(
											mensaje,
											style: textTheme.bodySmall?.copyWith(
												color: widget.esError
													? colorScheme.onErrorContainer
													: colorScheme.onPrimaryContainer,
											),
										),
									),
								],
							],
						),
					),
				),
			),
			actions: [
				TextButton(
					onPressed: widget.creando ? null : () => Navigator.of(context).pop(),
					child: const Text('Cancelar'),
				),
				ElevatedButton(
					style: ElevatedButton.styleFrom(
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(10),
						),
					),
					onPressed: widget.creando ? null : _crear,
					child: widget.creando
						? const SizedBox(
							height: 16,
							width: 16,
							child: CircularProgressIndicator(strokeWidth: 2),
						)
						: const Text('Crear cliente'),
				),
			],
		);
	}

	void _crear() {
		setState(() {
			_intentoCrear = true;
		});
		if (!(_formularioKey.currentState?.validate() ?? false)) {
			return;
		}

		widget.onCrear(
			AltaRapidaClienteDatos(
				cuit: _cuit.trim(),
				nombre: _nombre.trim(),
				contacto: _contacto.trim(),
				telefono: _telefono.trim(),
				localidad: _localidad.trim(),
			),
		);
	}

	static String? _requerido(String? valor, String mensaje) {
		return (valor ?? '').trim().isEmpty ? mensaje : null;
	}
}
