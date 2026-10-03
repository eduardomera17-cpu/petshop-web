// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/billing/views/cart_view.dart
// Propósito: Vista reactiva y consultiva del carrito unificado de compras (citas y pedidos), con desglose normativo bidimensional («A pagar hoy» vs «Total acumulado»).
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/use_cases/build_cart.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/billing/view_models/cart_view_model.dart';

/// Vista reactiva del carrito unificado de compras del cliente.
///
/// Consolida en un panel unificado los consumos pendientes de liquidación y los servicios
/// programados del usuario cliente:
/// 1. Solicitudes de productos aprobadas/en preparación y listas para retiro en tienda.
/// 2. Citas agendadas (activas) y citas atendidas/completadas pendientes de pago.
///
/// Principios de diseño fiscal y arquitectural (ADR-026, PR-08, D-05, CA-66, CA-69):
/// - Disciplina de solo lectura: el cliente no modifica precios ni genera escrituras en base de datos.
/// - Cero agregaciones en frontend: los subtotales e impuestos provienen precalculados del use case [BuildCart].
/// - Aviso normativo mandatorio visible informando que los precios definitivos se fijan al emitir la proforma/factura.
/// - Visualización de dos magnitudes financieras claramente rotuladas:
///   * «A pagar hoy»: Importe inmediato correspondiente a productos listos y servicios completados.
///   * «Total acumulado»: Compromiso global que abarca servicios agendados a futuro.
class CartView extends StatefulWidget {
  /// Modelo de vista reactivo que suministra el resultado consolidado del carrito [CartResult].
  final CartViewModel viewModel;

  /// Constructor de la vista de carrito de compras.
  const CartView({
    super.key,
    required this.viewModel,
  });

  @override
  State<CartView> createState() => _CartViewState();
}

/// Estado mutable de [CartView].
///
/// Administra el ciclo de vida e inicialización asíncrona del [CartViewModel].
class _CartViewState extends State<CartView> {
  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel y suscripción a los flujos reactivos de citas y solicitudes
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.cartTitle ?? ''),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final loadFailure = widget.viewModel.loadFailure;
          if (loadFailure != null && widget.viewModel.cartResult == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    loadFailure.toLocalizedMessage(l10n!),
                    key: const ValueKey('cart_error_message'),
                  ),
                  const SizedBox(height: 16),
                  TappableArea(
                    semanticLabel: l10n.retry,
                    onTap: () => widget.viewModel.init(),
                    child: ElevatedButton(
                      key: const ValueKey('cart_retry_button'),
                      onPressed: () => widget.viewModel.init(),
                      child: Text(l10n.retry),
                    ),
                  ),
                ],
              ),
            );
          }

          final cart = widget.viewModel.cartResult;

          if (cart == null || cart.isEmpty) {
            return Center(
              child: Text(
                key: const ValueKey('cart_empty_state'),
                l10n?.cartEmptyMessage ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 800.0 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    key: const ValueKey('cart_view_scroll'),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aviso Mandatorio Informativo (FA-04, §1.3.7)
                        Container(
                          key: const ValueKey('cart_mandatory_notice'),
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n?.cartNoticeAdjustments ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sección: Solicitudes de Producto
                        if (cart.requestGroups.isNotEmpty) ...[
                          Text(
                            l10n?.cartProductsSection ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...cart.requestGroups.map(
                            (group) => _ProductRequestGroupCard(group: group),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Sección: Citas Agendadas y Completadas
                        if (cart.appointments.isNotEmpty) ...[
                          Text(
                            l10n?.cartAppointmentsSection ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cart.appointments.length,
                                separatorBuilder: (_, _) => const Divider(height: 16),
                                itemBuilder: (context, index) {
                                  final app = cart.appointments[index];
                                  return _AppointmentRow(appointment: app);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(thickness: 1.5, height: 28),

                        // Totales Normativos Rotulados (PR-08, D-05, CA-66, CA-69, ADR-026)
                        _TotalsFooterCard(
                          cartResult: cart,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta contenedora que agrupa los ítems pertenecientes a una solicitud de productos específica.
class _ProductRequestGroupCard extends StatelessWidget {
  /// Grupo de productos con identificador de solicitud, estado de despacho y líneas de ítems.
  final CartProductRequestGroup group;

  /// Constructor del grupo de solicitud de productos.
  const _ProductRequestGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.cartRequestGroupHeader(group.requestId) ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    group.status == 'READY_FOR_PICKUP'
                        ? (l10n?.requestStatusReadyForPickup ?? group.status)
                        : (l10n?.requestStatusPendingDispatch ?? group.status),
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 12),
            ...group.lines.map((line) => _ProductLineRow(line: line)),
          ],
        ),
      ),
    );
  }
}

/// Fila descriptiva para cada producto individual dentro de un grupo de solicitud.
class _ProductLineRow extends StatelessWidget {
  /// Datos de la línea de producto: nombre, cantidad, precio unitario e importes tributarios.
  final CartProductLine line;

  /// Constructor de la fila de producto.
  const _ProductLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                l10n?.moneyAmount(formatCents(line.totalWithTaxCents)) ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l10n?.cartQuantity(line.quantity) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                l10n?.cartUnitPrice(formatCents(line.agreedUnitPriceCents)) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                l10n?.cartSubtotal(formatCents(line.lineSubtotalCents)) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                l10n?.cartPriceWithTaxes(formatCents(line.totalWithTaxCents)) ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila descriptiva para una cita agendada o completada dentro del carrito unificado.
class _AppointmentRow extends StatelessWidget {
  /// Línea de servicio de cita con fecha, franja, mascota e importe congelado.
  final CartAppointmentLine appointment;

  /// Constructor de la fila de cita.
  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n?.cartAppointmentService(appointment.serviceName) ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              l10n?.moneyAmount(formatCents(appointment.finalPriceCents)) ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l10n?.cartAppointmentPet(appointment.petName) ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          l10n?.cartAppointmentDateTime(appointment.dateString, appointment.timeSlot) ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          l10n?.cartAppointmentPrice(formatCents(appointment.finalPriceCents)) ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Panel consolidado de totales normativos rotulados y desgloses impositivos.
///
/// Presenta con absoluta distinción técnica las dos magnitudes financieras requeridas por ley:
/// 1. «A pagar hoy»: Valor líquido inmediatamente exigible en caja.
/// 2. «Total acumulado»: Cifra proyectada global que contempla atenciones agendadas a futuro.
class _TotalsFooterCard extends StatelessWidget {
  /// Objeto inmutable que contiene los totales y desgloses de impuestos ya computados.
  final CartResult cartResult;

  /// Constructor del panel de totales.
  const _TotalsFooterCard({
    required this.cartResult,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Desglose de cifra 1: A pagar hoy
            Container(
              key: const ValueKey('cart_payable_today_breakdown'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.cartBreakdownSubtotal(
                              formatCents(cartResult.payableTodaySubtotalCents),
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (cartResult.payableTodayIceCents > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.cartBreakdownIce(
                                formatCents(cartResult.payableTodayIceCents),
                              ) ??
                              '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.cartBreakdownIva(
                              formatCents(cartResult.payableTodayIvaCents),
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Cifra 1: A pagar hoy (PR-08, D-05, FA-01)
            Row(
              key: const ValueKey('cart_payable_today'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.cartPayableTodayLabel ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.moneyAmount(formatCents(cartResult.payableTodayCents)) ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Desglose de cifra 2: Total acumulado
            Container(
              key: const ValueKey('cart_accumulated_breakdown'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.cartBreakdownSubtotal(
                              formatCents(cartResult.accumulatedSubtotalCents),
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (cartResult.accumulatedIceCents > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.cartBreakdownIce(
                                formatCents(cartResult.accumulatedIceCents),
                              ) ??
                              '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.cartBreakdownIva(
                              formatCents(cartResult.accumulatedIvaCents),
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Cifra 2: Total acumulado (PR-08, D-05)
            Row(
              key: const ValueKey('cart_accumulated_total'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.cartAccumulatedTotalLabel ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.moneyAmount(formatCents(cartResult.accumulatedTotalCents)) ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
