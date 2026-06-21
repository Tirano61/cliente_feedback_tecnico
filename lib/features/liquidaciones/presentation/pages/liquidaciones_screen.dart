import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cliente_feedback_tecnico/features/auth/presentation/bloc/auth_event.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/domain/entities/liquidacion.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_event.dart';
import 'package:cliente_feedback_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LiquidacionesScreen extends StatefulWidget {
  const LiquidacionesScreen({super.key});

  @override
  State<LiquidacionesScreen> createState() => _LiquidacionesScreenState();
}

class _LiquidacionesScreenState extends State<LiquidacionesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LiquidacionesBloc>().add(const LiquidacionesSolicitadas());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Liquidaciones')),
        body: BlocConsumer<LiquidacionesBloc, LiquidacionesState>(
          listener: (context, state) {
            if (state is LiquidacionesSesionExpirada) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.mensaje)),
              );
              context.read<AuthBloc>().add(const LogoutRequested());
            }
            if (state is LiquidacionesLoaded) {
              final mensaje = (state.mensajeAviso ?? '').trim();
              if (mensaje.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mensaje)),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is LiquidacionesLoading || state is LiquidacionesInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LiquidacionesError) {
              return _ErrorState(
                mensaje: state.mensaje,
                onRetry: () {
                  context.read<LiquidacionesBloc>().add(
                        const LiquidacionesSolicitadas(),
                      );
                },
              );
            }

            if (state is LiquidacionesLoaded) {
              final pendientes = _filtrarPorEstado(
                state.liquidaciones,
                EstadoLiquidacion.pendiente,
              );
              final aprobadas = _filtrarPorEstado(
                state.liquidaciones,
                EstadoLiquidacion.aprobada,
              );
              final reabiertas = _filtrarPorEstado(
                state.liquidaciones,
                EstadoLiquidacion.reabierta,
              );
              final totalAprobadas = aprobadas.fold<double>(
                0,
                (acum, item) => acum + item.resumen.totalLiquidacionUsd,
              );

              return Column(
                children: [
                  _HeaderTotales(
                    totalAprobadas: totalAprobadas,
                    pendientes: pendientes.length,
                    aprobadas: aprobadas.length,
                    reabiertas: reabiertas.length,
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Pendientes'),
                      Tab(text: 'Aprobadas'),
                      Tab(text: 'Reabiertas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListaLiquidacionesTab(
                          estado: EstadoLiquidacion.pendiente,
                          liquidaciones: pendientes,
                          detallesItemsPorLiquidacion:
                              state.detallesItemsPorLiquidacion,
                          detallesCargandoIds: state.detallesCargandoIds,
                          onRefresh: () async {
                            context.read<LiquidacionesBloc>().add(
                                  const LiquidacionesRefrescadas(),
                                );
                          },
                          onAbrirDetalle: _abrirDetalleLiquidacion,
                        ),
                        _ListaLiquidacionesTab(
                          estado: EstadoLiquidacion.aprobada,
                          liquidaciones: aprobadas,
                          detallesItemsPorLiquidacion:
                              state.detallesItemsPorLiquidacion,
                          detallesCargandoIds: state.detallesCargandoIds,
                          onRefresh: () async {
                            context.read<LiquidacionesBloc>().add(
                                  const LiquidacionesRefrescadas(),
                                );
                          },
                          onAbrirDetalle: _abrirDetalleLiquidacion,
                        ),
                        _ListaLiquidacionesTab(
                          estado: EstadoLiquidacion.reabierta,
                          liquidaciones: reabiertas,
                          detallesItemsPorLiquidacion:
                              state.detallesItemsPorLiquidacion,
                          detallesCargandoIds: state.detallesCargandoIds,
                          onRefresh: () async {
                            context.read<LiquidacionesBloc>().add(
                                  const LiquidacionesRefrescadas(),
                                );
                          },
                          onAbrirDetalle: _abrirDetalleLiquidacion,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  List<Liquidacion> _filtrarPorEstado(
    List<Liquidacion> liquidaciones,
    EstadoLiquidacion estado,
  ) {
    return liquidaciones.where((item) => item.estado == estado).toList();
  }

  void _abrirDetalleLiquidacion(Liquidacion liquidacion) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
          builder: (context, state) {
            Map<String, List<ItemLiquidacion>> itemsPorLiquidacion = const {};
            Set<String> idsCargando = const {};

            if (state is LiquidacionesLoaded) {
              itemsPorLiquidacion = state.detallesItemsPorLiquidacion;
              idsCargando = state.detallesCargandoIds;
            }

            final itemsActualizados =
                itemsPorLiquidacion[liquidacion.id] ?? liquidacion.items;
            final cargandoItems = idsCargando.contains(liquidacion.id);

            return _DetalleLiquidacionSheet(
              liquidacion: liquidacion,
              items: itemsActualizados,
              cargandoItems: cargandoItems,
              onActualizarItems: () {
                context.read<LiquidacionesBloc>().add(
                      LiquidacionDetalleSolicitado(liquidacionId: liquidacion.id),
                    );
              },
            );
          },
        );
      },
    );
  }
}

class _HeaderTotales extends StatelessWidget {
  final double totalAprobadas;
  final int pendientes;
  final int aprobadas;
  final int reabiertas;

  const _HeaderTotales({
    required this.totalAprobadas,
    required this.pendientes,
    required this.aprobadas,
    required this.reabiertas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total a cobrar (USD)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _monedaUsd(totalAprobadas),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipCantidad(
                label: 'Pendientes',
                cantidad: pendientes,
                color: const Color(0xFFE65100),
              ),
              _ChipCantidad(
                label: 'Aprobadas',
                cantidad: aprobadas,
                color: const Color(0xFF2E7D32),
              ),
              _ChipCantidad(
                label: 'Reabiertas',
                cantidad: reabiertas,
                color: const Color(0xFF5E35B1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipCantidad extends StatelessWidget {
  final String label;
  final int cantidad;
  final Color color;

  const _ChipCantidad({
    required this.label,
    required this.cantidad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      backgroundColor: color.withValues(alpha: 0.1),
      label: Text('$label: $cantidad'),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ListaLiquidacionesTab extends StatelessWidget {
  final EstadoLiquidacion estado;
  final List<Liquidacion> liquidaciones;
  final Map<String, List<ItemLiquidacion>> detallesItemsPorLiquidacion;
  final Set<String> detallesCargandoIds;
  final Future<void> Function() onRefresh;
  final void Function(Liquidacion liquidacion) onAbrirDetalle;

  const _ListaLiquidacionesTab({
    required this.estado,
    required this.liquidaciones,
    required this.detallesItemsPorLiquidacion,
    required this.detallesCargandoIds,
    required this.onRefresh,
    required this.onAbrirDetalle,
  });

  @override
  Widget build(BuildContext context) {
    if (liquidaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 140),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _mensajeSinDatos(estado),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final liquidacion = liquidaciones[index];

          return _LiquidacionCard(
            liquidacion: liquidacion,
            itemsDetalle: detallesItemsPorLiquidacion[liquidacion.id],
            onTap: () => onAbrirDetalle(liquidacion),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemCount: liquidaciones.length,
      ),
    );
  }

  String _mensajeSinDatos(EstadoLiquidacion estado) {
    switch (estado) {
      case EstadoLiquidacion.pendiente:
        return 'No tenes liquidaciones pendientes por ahora.';
      case EstadoLiquidacion.aprobada:
        return 'Todavia no hay liquidaciones aprobadas para cobro.';
      case EstadoLiquidacion.reabierta:
        return 'No hay liquidaciones reabiertas actualmente.';
      case EstadoLiquidacion.desconocido:
        return 'No hay liquidaciones para este estado.';
    }
  }
}

class _LiquidacionCard extends StatelessWidget {
  final Liquidacion liquidacion;
  final List<ItemLiquidacion>? itemsDetalle;
  final VoidCallback onTap;

  const _LiquidacionCard({
    required this.liquidacion,
    required this.itemsDetalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usa los items del detalle si ya se cargaron, sino los embebidos en el listado.
    final itemsMostrados = itemsDetalle ?? liquidacion.items;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _textoSeguro(liquidacion.servicio.clienteNombre),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _BadgeEstado(estado: liquidacion.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text('Lugar: ${_textoSeguro(_combinarLugar(liquidacion))}'),
              Text(
                'Fecha: ${_formatearFecha(liquidacion.servicio.fechaHoraServicio)}',
              ),
              Text(
                'Tipo salida: ${_textoSeguro(liquidacion.tipoSalida.nombre)} (${_monedaUsd(liquidacion.tipoSalida.precioUsd)})',
              ),
              const SizedBox(height: 8),
              // Items de tipos de servicio
              if (itemsMostrados.isNotEmpty) ...[
                Text(
                  'Tipos de servicio asignados:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 4),
                ...itemsMostrados.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _textoSeguro(item.tipoServicioNombre),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          _monedaUsd(item.precioUsdSnapshot),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Text(
                  'Sin tipos de servicio asignados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              const SizedBox(height: 8),
              Text(
                'Total: ${_monedaUsd(liquidacion.resumen.totalLiquidacionUsd)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _combinarLugar(Liquidacion liquidacion) {
    final provincia = liquidacion.servicio.lugarProvinciaNombre.trim();
    final detalle = liquidacion.servicio.lugarDetalle.trim();

    if (provincia.isEmpty && detalle.isEmpty) {
      return 'Sin dato';
    }
    if (provincia.isNotEmpty && detalle.isNotEmpty) {
      return '$provincia - $detalle';
    }

    return provincia.isNotEmpty ? provincia : detalle;
  }
}

class _BadgeEstado extends StatelessWidget {
  final EstadoLiquidacion estado;

  const _BadgeEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      EstadoLiquidacion.pendiente => const Color(0xFFE65100),
      EstadoLiquidacion.aprobada => const Color(0xFF2E7D32),
      EstadoLiquidacion.reabierta => const Color(0xFF5E35B1),
      EstadoLiquidacion.desconocido => const Color(0xFF455A64),
    };

    final texto = switch (estado) {
      EstadoLiquidacion.pendiente => 'Pendiente',
      EstadoLiquidacion.aprobada => 'Aprobada',
      EstadoLiquidacion.reabierta => 'Reabierta',
      EstadoLiquidacion.desconocido => 'Sin dato',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetalleLiquidacionSheet extends StatelessWidget {
  final Liquidacion liquidacion;
  final List<ItemLiquidacion> items;
  final bool cargandoItems;
  final VoidCallback onActualizarItems;

  const _DetalleLiquidacionSheet({
    required this.liquidacion,
    required this.items,
    required this.cargandoItems,
    required this.onActualizarItems,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalle de liquidacion',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: cargandoItems ? null : onActualizarItems,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar items',
                  ),
                ],
              ),
              if (cargandoItems)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _SeccionTitulo(texto: 'Servicio'),
                    _DetalleFila(
                      label: 'Cliente',
                      value: _textoSeguro(liquidacion.servicio.clienteNombre),
                    ),
                    _DetalleFila(
                      label: 'Lugar',
                      value: _textoSeguro(_armarLugar(liquidacion)),
                    ),
                    _DetalleFila(
                      label: 'Fecha',
                      value: _formatearFecha(liquidacion.servicio.fechaHoraServicio),
                    ),
                    const SizedBox(height: 10),
                    _SeccionTitulo(texto: 'Tipo de salida'),
                    _DetalleFila(
                      label: 'Tipo',
                      value: _textoSeguro(liquidacion.tipoSalida.nombre),
                    ),
                    _DetalleFila(
                      label: 'Precio',
                      value: _monedaUsd(liquidacion.tipoSalida.precioUsd),
                    ),
                    const SizedBox(height: 10),
                    _SeccionTitulo(texto: 'Items'),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Sin items'),
                      )
                    else
                      ...items.map(
                        (item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_textoSeguro(item.tipoServicioNombre)),
                          subtitle: Text(item.aprobado ? 'Aprobado' : 'Pendiente'),
                          trailing: Text(_monedaUsd(item.precioUsdSnapshot)),
                        ),
                      ),
                    const Divider(height: 28),
                    _SeccionTitulo(texto: 'Resumen'),
                    _DetalleFila(
                      label: 'Subtotal salida',
                      value: _monedaUsd(liquidacion.resumen.subtotalSalidaUsd),
                    ),
                    _DetalleFila(
                      label: 'Subtotal items',
                      value: _monedaUsd(liquidacion.resumen.subtotalItemsUsd),
                    ),
                    _DetalleFila(
                      label: 'Total',
                      value: _monedaUsd(liquidacion.resumen.totalLiquidacionUsd),
                      negrita: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _armarLugar(Liquidacion liquidacion) {
    final provincia = liquidacion.servicio.lugarProvinciaNombre.trim();
    final detalle = liquidacion.servicio.lugarDetalle.trim();
    if (provincia.isEmpty && detalle.isEmpty) {
      return 'Sin dato';
    }
    if (provincia.isNotEmpty && detalle.isNotEmpty) {
      return '$provincia - $detalle';
    }
    return provincia.isNotEmpty ? provincia : detalle;
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String texto;

  const _SeccionTitulo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DetalleFila extends StatelessWidget {
  final String label;
  final String value;
  final bool negrita;

  const _DetalleFila({
    required this.label,
    required this.value,
    this.negrita = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: negrita ? FontWeight.w700 : FontWeight.w400,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorState({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _textoSeguro(String? valor) {
  final limpio = (valor ?? '').trim();
  if (limpio.isEmpty) {
    return 'Sin dato';
  }
  return limpio;
}

String _formatearFecha(DateTime? fecha) {
  if (fecha == null) {
    return 'Sin dato';
  }

  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final anio = local.year.toString();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');

  return '$dia/$mes/$anio $hora:$minuto';
}

String _monedaUsd(double valor) {
  return 'USD ${valor.toStringAsFixed(2)}';
}
