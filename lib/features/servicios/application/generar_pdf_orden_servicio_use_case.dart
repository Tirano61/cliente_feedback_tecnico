import 'dart:typed_data';

import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/facturacion_item.dart';
import 'package:cliente_feedback_tecnico/features/servicios/domain/entities/orden_servicio_respuesta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class GenerarPdfOrdenServicioUseCase {
	Future<Uint8List> ejecutar(OrdenServicioRespuesta orden) async {
		final documento = pw.Document();
		final servicio = orden.servicio;
		final fechaOrden = orden.fechaHoraServicio ?? servicio.fechaHoraServicio ?? servicio.fecha;

		documento.addPage(
			pw.MultiPage(
				pageFormat: PdfPageFormat.a4,
				build: (context) {
					final nombreCliente = _textoSeguroOpcional(servicio.clienteNombre);
					final cuitCliente = _textoSeguroOpcional(servicio.clienteCuit);
					final telefonoCliente = _textoSeguroOpcional(servicio.clienteTelefono);
					final localidadCliente = _textoSeguroOpcional(servicio.clienteLocalidad);
					final contactoCliente = _textoSeguroOpcional(servicio.clienteContacto);
					final provinciaServicio = _textoSeguro(
						servicio.lugarProvinciaNombre ?? servicio.lugarProvinciaId,
					);

					return [
						pw.Text(
							'Orden de servicio tecnico',
							style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
						),
						pw.SizedBox(height: 8),
						pw.Text('Servicio ID: ${_textoSeguro(orden.servicioId)}'),
						pw.Text('Estado orden: ${_textoSeguro(orden.estadoOrden)}'),
						pw.Text('Canal: ${servicio.canal.name}'),
						pw.Text('Fecha y hora: ${_formatearFechaHora(fechaOrden)}'),
						pw.SizedBox(height: 10),
						pw.Text(
							'Datos del cliente',
							style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
						),
						pw.SizedBox(height: 4),
						_buildFilaDoble('Nombre', nombreCliente, 'CUIT', cuitCliente),
						pw.SizedBox(height: 4),
						_buildFilaDoble(
							'Localidad',
							localidadCliente,
							'Telefono',
							telefonoCliente,
						),
						pw.SizedBox(height: 4),
						_buildFilaDoble('Provincia', provinciaServicio, 'Contacto', contactoCliente),
						pw.SizedBox(height: 10),
						pw.Text(
							'Datos tecnicos',
							style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
						),
						pw.SizedBox(height: 4),
						pw.Bullet(text: 'Lugar: ${_textoSeguro(servicio.lugarDetalle)}'),
						pw.Bullet(text: 'Modelo: ${_textoSeguro(servicio.equipoModelo)}'),
						pw.Bullet(text: 'Serie: ${_textoSeguro(servicio.equipoNroSerie)}'),
						pw.Bullet(text: 'Ubicacion: ${_textoSeguro(servicio.equipoUbicacion)}'),
						pw.Bullet(text: 'Anio: ${servicio.equipoAnio}'),
						pw.Bullet(text: 'Km: ${servicio.km}'),
						pw.Bullet(text: 'Sintoma: ${_textoSeguro(servicio.sintoma)}'),
						pw.Bullet(text: 'Diagnostico: ${_textoSeguro(servicio.diagnosticoDetalle)}'),
						if (servicio.observaciones != null && servicio.observaciones!.trim().isNotEmpty)
							pw.Bullet(text: 'Observaciones: ${servicio.observaciones!.trim()}'),
						pw.SizedBox(height: 10),
						pw.Text(
							'Facturacion',
							style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
						),
						if (orden.facturacion == null)
							pw.Text('Sin facturacion.')
						else
							pw.Column(
								crossAxisAlignment: pw.CrossAxisAlignment.start,
								children: [
									pw.Bullet(text: 'Cotizacion dolar: ${orden.facturacion!.cotizacionDolarSnapshot.toStringAsFixed(2)}'),
									pw.Bullet(text: 'Valor km USD: ${orden.facturacion!.valorKmUsdSnapshot.toStringAsFixed(2)}'),
									pw.Bullet(text: 'Subtotal general ARS: ${orden.facturacion!.subtotalGeneralArs.toStringAsFixed(2)}'),
									pw.Bullet(text: 'Total final ARS: ${orden.facturacion!.totalFinalArs.toStringAsFixed(2)}'),
								],
							),
						if (orden.facturacionItems.isNotEmpty) ...[
							pw.SizedBox(height: 8),
							_buildTablaItems(orden.facturacionItems),
						],
					];
				},
			),
		);

		return documento.save();
	}

	pw.Widget _buildFilaDoble(
		String etiquetaIzquierda,
		String valorIzquierda,
		String etiquetaDerecha,
		String valorDerecha,
	) {
		return pw.Row(
			crossAxisAlignment: pw.CrossAxisAlignment.start,
			children: [
				pw.Expanded(
					child: pw.Text(
						'$etiquetaIzquierda: $valorIzquierda',
						style: const pw.TextStyle(fontSize: 10),
					),
				),
				pw.SizedBox(width: 12),
				pw.Expanded(
					child: pw.Text(
						'$etiquetaDerecha: $valorDerecha',
						style: const pw.TextStyle(fontSize: 10),
					),
				),
			],
		);
	}

	pw.Widget _buildTablaItems(List<FacturacionItem> items) {
		return pw.TableHelper.fromTextArray(
			headers: const ['Tipo', 'Descripcion', 'Cant', 'USD', 'ARS'],
			data: items
					.map(
						(item) => [
							item.tipoItem,
							item.descripcion,
							item.cantidad.toStringAsFixed(2),
							item.subtotalUsd.toStringAsFixed(2),
							item.subtotalArs.toStringAsFixed(2),
						],
					)
					.toList(),
			cellAlignment: pw.Alignment.centerLeft,
			headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
			headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
			cellStyle: const pw.TextStyle(fontSize: 9),
			cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
		);
	}

	String _textoSeguro(String valor) {
		final limpio = valor.trim();
		if (limpio.isEmpty) {
			return '-';
		}
		return limpio;
	}

	String _textoSeguroOpcional(String? valor) {
		if (valor == null) {
			return '-';
		}
		return _textoSeguro(valor);
	}

	String _formatearFechaHora(DateTime? fecha) {
		if (fecha == null) {
			return '-';
		}
		final local = fecha.toLocal();
		final dia = local.day.toString().padLeft(2, '0');
		final mes = local.month.toString().padLeft(2, '0');
		final anio = local.year.toString();
		final hora = local.hour.toString().padLeft(2, '0');
		final minuto = local.minute.toString().padLeft(2, '0');
		return '$dia/$mes/$anio $hora:$minuto';
	}
}
