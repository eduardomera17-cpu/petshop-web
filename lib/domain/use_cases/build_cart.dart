// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/domain/use_cases/build_cart.dart
// Propósito: Caso de uso puro de dominio para la consolidación en memoria del carrito del cliente y la partición dual de cifras ("exigible hoy" vs "acumulado proyectado").
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/domain/use_cases/build_payment_summary.dart';

/// {@template cart_product_line}
/// Representación inmutable de una fila individual de producto dentro de una solicitud agrupada en el carrito.
/// {@endtemplate}
@immutable
class CartProductLine {
  /// Identificador del producto en el catálogo.
  final String productId;

  /// Denominación descriptiva del producto.
  final String productName;

  /// Cantidad de unidades solicitadas.
  final int quantity;

  /// Precio unitario pactado al momento de la orden en centavos de dólar.
  final int agreedUnitPriceCents;

  /// Subtotal de la línea antes de impuestos en centavos de dólar.
  final int lineSubtotalCents;

  /// Tarifa de Impuesto a los Consumos Especiales en puntos básicos (1% = 100 bp).
  final int iceBp;

  /// Tarifa de Impuesto al Valor Agregado en puntos básicos (1% = 100 bp).
  final int ivaBp;

  /// Monto calculado de ICE en centavos de dólar.
  final int iceAmountCents;

  /// Monto calculado de IVA en centavos de dólar.
  final int ivaAmountCents;

  /// Total final de la línea con todos los impuestos incluidos en centavos.
  final int totalWithTaxCents;

  const CartProductLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.agreedUnitPriceCents,
    required this.lineSubtotalCents,
    required this.iceBp,
    required this.ivaBp,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.totalWithTaxCents,
  });
}

/// {@template cart_product_request_group}
/// Agrupador inmutable que reúne las líneas de una solicitud de producto bajo su identificador y estado.
/// {@endtemplate}
@immutable
class CartProductRequestGroup {
  /// Identificador único de la solicitud de pedido.
  final String requestId;

  /// Estado actual del flujo de despacho (e.g. PENDING_DISPATCH, READY_FOR_PICKUP).
  final String status;

  /// Fecha programada o de acción en formato legible de texto.
  final String actionDateString;

  /// Lista de líneas de producto pertenecientes a este grupo.
  final List<CartProductLine> lines;

  /// Total consolidado del grupo de productos en centavos de dólar.
  final int groupTotalCents;

  /// Indica si los productos de esta orden ya están listos para retiro y por ende son exigibles de pago hoy.
  final bool isPayableToday;

  const CartProductRequestGroup({
    required this.requestId,
    required this.status,
    required this.actionDateString,
    required this.lines,
    required this.groupTotalCents,
    required this.isPayableToday,
  });
}

/// {@template cart_appointment_line}
/// Representa una fila individual de cita médica o servicio estético dentro del carrito del cliente.
/// {@endtemplate}
@immutable
class CartAppointmentLine {
  /// Identificador único de la cita.
  final String appointmentId;

  /// Nombre del servicio contratado.
  final String serviceName;

  /// Nombre de la mascota beneficiaria.
  final String petName;

  /// Fecha programada de la cita.
  final String dateString;

  /// Franja horaria reservada.
  final String timeSlot;

  /// Estado de la cita (PENDING, CONFIRMED, COMPLETED).
  final String status;

  /// Precio base sin tributos en centavos de dólar.
  final int basePriceCents;

  /// Puntos básicos de ICE aplicables al servicio.
  final int iceBp;

  /// Puntos básicos de IVA aplicables al servicio.
  final int ivaBp;

  /// Monto de ICE en centavos de dólar.
  final int iceAmountCents;

  /// Monto de IVA en centavos de dólar.
  final int ivaAmountCents;

  /// Precio final con tributos incluidos en centavos.
  final int finalPriceCents;

  /// Determina si la cita está en estado COMPLETED y por ende es exigible de cobro hoy.
  final bool isPayableToday;

  const CartAppointmentLine({
    required this.appointmentId,
    required this.serviceName,
    required this.petName,
    required this.dateString,
    required this.timeSlot,
    required this.status,
    required this.basePriceCents,
    required this.iceBp,
    required this.ivaBp,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.finalPriceCents,
    required this.isPayableToday,
  });
}

/// {@template cart_result}
/// Resultado consolidado e inmutable del cálculo y partición dual del carrito de compras.
///
/// Contiene el desglose separado de los ítems de pago inmediato ("exigible hoy") y del
/// total proyectado acumulado que incluye servicios y solicitudes en curso.
/// {@endtemplate}
@immutable
class CartResult {
  /// Grupos de solicitudes de productos activas del cliente.
  final List<CartProductRequestGroup> requestGroups;

  /// Citas veterinarias o estéticas pendientes de facturación.
  final List<CartAppointmentLine> appointments;

  /// Ítems elegibles para pago inmediato convertidos a modelo de proforma.
  final List<ProformaItem> payableTodayItems;

  /// Resumen tributario normativo de los conceptos exigibles de pago hoy.
  final DocumentPricingResult? payableTodaySummary;

  /// Monto total exigible hoy en centavos de dólar.
  final int payableTodayCents;

  /// Subtotal base de los conceptos exigibles hoy en centavos de dólar.
  final int payableTodaySubtotalCents;

  /// Total acumulado de ICE exigible hoy en centavos de dólar.
  final int payableTodayIceCents;

  /// Total acumulado de IVA exigible hoy en centavos de dólar.
  final int payableTodayIvaCents;

  /// Monto total acumulado (exigible + futuro en curso) en centavos de dólar.
  final int accumulatedTotalCents;

  /// Subtotal acumulado de todos los conceptos en centavos de dólar.
  final int accumulatedSubtotalCents;

  /// Total de ICE acumulado en centavos de dólar.
  final int accumulatedIceCents;

  /// Total de IVA acumulado en centavos de dólar.
  final int accumulatedIvaCents;

  /// Cantidad total de filas de conceptos contenidas en el carrito.
  final int totalRowsCount;

  const CartResult({
    required this.requestGroups,
    required this.appointments,
    this.payableTodayItems = const [],
    this.payableTodaySummary,
    required this.payableTodayCents,
    required this.payableTodaySubtotalCents,
    required this.payableTodayIceCents,
    required this.payableTodayIvaCents,
    required this.accumulatedTotalCents,
    required this.accumulatedSubtotalCents,
    required this.accumulatedIceCents,
    required this.accumulatedIvaCents,
    required this.totalRowsCount,
  });

  /// Indica si el carrito se encuentra vacío (cero filas de conceptos).
  bool get isEmpty => totalRowsCount == 0;
}

/// {@template build_cart_use_case}
/// Caso de uso que procesa, filtra y consolida el carrito del cliente en memoria.
///
/// Ejecuta las reglas de negocio de elegibilidad de conceptos (órdenes listas para retiro
/// y citas completadas como exigibles hoy) y realiza el cálculo impositivo dual sin
/// generar efectos secundarios en base de datos.
/// {@endtemplate}
class BuildCartUseCase {
  /// Caso de uso auxiliar de liquidación tributaria.
  final BuildPaymentSummaryUseCase paymentSummaryUseCase;

  const BuildCartUseCase({
    this.paymentSummaryUseCase = const BuildPaymentSummaryUseCase(),
  });

  /// Ejecuta la consolidación y cálculo del carrito a partir de las solicitudes, citas y configuración vigentes.
  CartResult execute({
    required List<ProductRequest> requests,
    required List<Appointment> appointments,
    required PublicPricingConfig pricingConfig,
  }) {
    // 1. Filtrado normativo de solicitudes (TRD §1.3.7, Caso crítico 24)
    // Se admiten únicamente PENDING_DISPATCH y READY_FOR_PICKUP.
    // CANCELLED y FINALIZED se excluyen tajantemente.
    final allowedRequestStatuses = {'PENDING_DISPATCH', 'READY_FOR_PICKUP'};
    final validRequests = requests.where((r) => allowedRequestStatuses.contains(r.status)).toList();

    // 2. Filtrado normativo de citas (TRD §1.3.7, Caso crítico 24)
    // Se admiten citas no cobradas (isBilled == false) en PENDING, CONFIRMED o COMPLETED.
    final allowedAppointmentStatuses = {'PENDING', 'CONFIRMED', 'COMPLETED'};
    final validAppointments = appointments.where((a) {
      return !a.isBilled && allowedAppointmentStatuses.contains(a.status);
    }).toList();

    final List<CartProductRequestGroup> requestGroups = [];
    final List<ProformaItem> payableTodayItems = [];
    final List<ProformaItem> accumulatedItems = [];
    int calculatedTotalRows = 0;

    // 3. Procesar solicitudes y sus líneas
    for (final req in validRequests) {
      final isPayable = req.status == 'READY_FOR_PICKUP';
      final List<CartProductLine> groupLines = [];
      int groupTotal = 0;

      if (req.items.isNotEmpty) {
        // Solicitud multilínea (D-04)
        for (final item in req.items) {
          final lineSubtotal = item.agreedUnitPriceCents * item.quantity;
          final pricing = calculateLinePricing(
            basePriceCents: lineSubtotal,
            iceBp: item.iceBp,
            ivaBp: item.ivaBp,
            iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
          );

          final line = CartProductLine(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            agreedUnitPriceCents: item.agreedUnitPriceCents,
            lineSubtotalCents: lineSubtotal,
            iceBp: item.iceBp,
            ivaBp: item.ivaBp,
            iceAmountCents: pricing.iceAmountCents,
            ivaAmountCents: pricing.ivaAmountCents,
            totalWithTaxCents: pricing.finalPriceCents,
          );
          groupLines.add(line);
          groupTotal += pricing.finalPriceCents;
          calculatedTotalRows++;

          final proformaItem = ProformaItem(
            type: 'PRODUCT',
            referenceId: item.productId,
            refLineId: req.id,
            title: item.productName,
            basePriceCents: item.agreedUnitPriceCents,
            iceBp: item.iceBp,
            ivaBp: item.ivaBp,
            quantity: item.quantity,
            subtotalCents: lineSubtotal,
            iceAmountCents: pricing.iceAmountCents,
            ivaAmountCents: pricing.ivaAmountCents,
            totalCents: pricing.finalPriceCents,
          );

          accumulatedItems.add(proformaItem);
          if (isPayable) {
            payableTodayItems.add(proformaItem);
          }
        }
      }
      // La forma plana se retiró (WP-6.11-B, TRD §2.8 «Cuándo termina»): una solicitud sin items[] no aporta
      // ninguna línea; no se deriva nada de su raíz.

      requestGroups.add(CartProductRequestGroup(
        requestId: req.id,
        status: req.status,
        actionDateString: req.actionDateString,
        lines: groupLines,
        groupTotalCents: groupTotal,
        isPayableToday: isPayable,
      ));
    }

    // 4. Procesar citas
    final List<CartAppointmentLine> appointmentLines = [];
    for (final app in validAppointments) {
      final isPayable = app.status == 'COMPLETED';
      calculatedTotalRows++;

      appointmentLines.add(CartAppointmentLine(
        appointmentId: app.id,
        serviceName: app.serviceName,
        petName: app.petName,
        dateString: app.dateString,
        timeSlot: app.timeSlot,
        status: app.status,
        basePriceCents: app.basePriceCents,
        iceBp: app.iceBp,
        ivaBp: app.ivaBp,
        iceAmountCents: app.iceAmountCents,
        ivaAmountCents: app.ivaAmountCents,
        finalPriceCents: app.finalPriceCents,
        isPayableToday: isPayable,
      ));

      final proformaItem = ProformaItem(
        type: 'SERVICE',
        referenceId: app.id,
        title: app.serviceName,
        basePriceCents: app.basePriceCents,
        iceBp: app.iceBp,
        ivaBp: app.ivaBp,
        quantity: 1,
        subtotalCents: app.basePriceCents,
        iceAmountCents: app.iceAmountCents,
        ivaAmountCents: app.ivaAmountCents,
        totalCents: app.finalPriceCents,
      );

      accumulatedItems.add(proformaItem);
      if (isPayable) {
        payableTodayItems.add(proformaItem);
      }
    }

    // 5. Partición en memoria de las dos cifras (ADR-026, TRD §1.3.7)
    // Ambas cifras se calculan a través del caso de uso unificado FA-01
    final payableTodaySummary = paymentSummaryUseCase.execute(
      items: payableTodayItems,
      adjustments: const [],
      pricingConfig: pricingConfig,
    );

    final accumulatedSummary = paymentSummaryUseCase.execute(
      items: accumulatedItems,
      adjustments: const [],
      pricingConfig: pricingConfig,
    );

    return CartResult(
      requestGroups: requestGroups,
      appointments: appointmentLines,
      payableTodayItems: payableTodayItems,
      payableTodaySummary: payableTodaySummary,
      payableTodayCents: payableTodaySummary.totalCents,
      payableTodaySubtotalCents: payableTodaySummary.subtotalCents,
      payableTodayIceCents: payableTodaySummary.totalIceCents,
      payableTodayIvaCents: payableTodaySummary.totalIvaCents,
      accumulatedTotalCents: accumulatedSummary.totalCents,
      accumulatedSubtotalCents: accumulatedSummary.subtotalCents,
      accumulatedIceCents: accumulatedSummary.totalIceCents,
      accumulatedIvaCents: accumulatedSummary.totalIvaCents,
      totalRowsCount: calculatedTotalRows,
    );
  }
}
