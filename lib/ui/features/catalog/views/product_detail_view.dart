// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/views/product_detail_view.dart
// Propósito: Vista de detalle extendido de producto comercial con visualización de imagen, desglose impositivo completo y pedido monoproducto directo.
// =========================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/catalog/view_models/product_detail_view_model.dart';
import 'package:provider/provider.dart';

/// Pantalla de detalle individual exhaustivo de un producto comercial del petshop.
///
/// Ofrece una inspección completa del artículo con:
/// - Imagen de alta resolución descargada asíncronamente desde Cloud Storage con fallback visual.
/// - Indicadores de disponibilidad física inmediata según el stock registrado.
/// - Desglose impositivo riguroso (precio base, tarifa de ICE si aplica, tarifa de IVA y precio final).
/// - Control interactivo de unidades deseadas con límites mínimo y máximo de compra.
/// - Computación dinámica del total a pagar según las unidades seleccionadas.
/// - Formulación directa de la solicitud de pedido monoproducto hacia el backend.
class ProductDetailView extends StatelessWidget {
  /// Modelo de vista reactivo gestor del detalle del producto y la transacción de pedido.
  final ProductDetailViewModel viewModel;

  /// Identificador único del usuario cliente que efectúa la consulta o solicitud.
  final String currentUid;

  /// Constructor de la vista de detalle de producto.
  const ProductDetailView({
    super.key,
    required this.viewModel,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = Provider.of<StorageService?>(context, listen: false);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final product = viewModel.product;
        final pricing = viewModel.pricingBreakdown;
        final isAvailable = viewModel.isAvailable;
        final hasIce = viewModel.hasIce;

        final availableText = isAvailable
            ? (l10n?.stockAvailable ?? '')
            : (l10n?.stockOutOfStock ?? '');
        final requestBtnText = viewModel.isSubmitting
            ? (l10n?.requestingProduct ?? '')
            : (l10n?.requestProductAction ?? '');

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.productDetailTitle ?? ''),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final content = SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imagePath != null && storage != null)
                      Center(
                        child: FutureBuilder<Uint8List?>(
                          future: storage.getData(product.imagePath!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  snapshot.data!,
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return Container(
                              height: 160,
                              width: 160,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2, size: 64),
                            );
                          },
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory_2, size: 64),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Nombre y Disponibilidad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Text(
                            availableText,
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Categoría
                    Text(
                      '${l10n?.productCategoryLabel ?? ''}: ${product.category}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    Text(
                      l10n?.productDescriptionLabel ?? '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta de Desglose Impositivo
                    Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.taxBreakdownTitle ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Divider(height: 20),
                            _PricingRow(
                              label: l10n?.priceBaseFormatted(
                                    formatCents(pricing.basePriceCents),
                                  ) ??
                                  '',
                              isBold: false,
                            ),
                            if (hasIce) ...[
                              const SizedBox(height: 6),
                              _PricingRow(
                                label: l10n?.taxIceFormatted(
                                      (pricing.iceBp / 100).toStringAsFixed(0),
                                      formatCents(pricing.iceAmountCents),
                                    ) ??
                                    '',
                                isBold: false,
                              ),
                            ],
                            const SizedBox(height: 6),
                            _PricingRow(
                              label: l10n?.taxIvaFormatted(
                                    (pricing.ivaBp / 100).toStringAsFixed(0),
                                    formatCents(pricing.ivaAmountCents),
                                  ) ??
                                  '',
                              isBold: false,
                            ),
                            const Divider(height: 20),
                            _PricingRow(
                              label: l10n?.priceWithTaxesFormatted(
                                    formatCents(pricing.finalPriceCents),
                                  ) ??
                                  '',
                              isBold: true,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Selector de cantidad
                    if (isAvailable) ...[
                      Row(
                        children: [
                          Text(
                            l10n?.productQuantityLabel ?? '',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          TappableArea(
                            semanticLabel: l10n?.catalogDecreaseQuantity ?? '',
                            onTap: (viewModel.quantity > ProductDetailViewModel.minRequestQuantity && !viewModel.isSubmitting)
                                ? () => viewModel.decrementQuantity()
                                : null,
                            child: IconButton(
                              key: const ValueKey('quantity_decrement_button'),
                              icon: const Icon(Icons.remove),
                              onPressed: (viewModel.quantity > ProductDetailViewModel.minRequestQuantity && !viewModel.isSubmitting)
                                  ? () => viewModel.decrementQuantity()
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${viewModel.quantity}',
                              key: const ValueKey('quantity_text'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          TappableArea(
                            semanticLabel: l10n?.catalogIncreaseQuantity ?? '',
                            onTap: (viewModel.quantity < ProductDetailViewModel.maxRequestQuantity && !viewModel.isSubmitting)
                                ? () => viewModel.incrementQuantity()
                                : null,
                            child: IconButton(
                              key: const ValueKey('quantity_increment_button'),
                              icon: const Icon(Icons.add),
                              onPressed: (viewModel.quantity < ProductDetailViewModel.maxRequestQuantity && !viewModel.isSubmitting)
                                  ? () => viewModel.incrementQuantity()
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (viewModel.quantity > 1) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            l10n?.productDetailTotal(
                                  formatCents(
                                    viewModel.totalFinalPriceCents,
                                  ),
                                ) ??
                                '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Errores o Éxito
                    if (viewModel.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (viewModel.errorFailure ??
                                  DomainFailure(
                                    code: viewModel.errorMessage!,
                                  ))
                              .toLocalizedMessage(
                            l10n!,
                            productNameOf: (_) => viewModel.product.name,
                          ),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (viewModel.successRequestId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n?.requestProductSuccess ?? '',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Botón de Solicitar Producto
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TappableArea(
                        semanticLabel: requestBtnText,
                        onTap: (isAvailable && !viewModel.isSubmitting)
                            ? () => viewModel.requestProduct(uid: currentUid)
                            : null,
                        child: ElevatedButton(
                          key: const ValueKey('request_product_submit_button'),
                          onPressed: (isAvailable && !viewModel.isSubmitting)
                              ? () => viewModel.requestProduct(uid: currentUid)
                              : null,
                          child: Text(requestBtnText),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: content,
                  ),
                );
              }
              return content;
            },
          ),
        );
      },
    );
  }
}

/// Fila tipográfica auxiliar para la presentación alineada y estilizada de valores
/// económicos en la sección de desglose impositivo y comercial del producto.
class _PricingRow extends StatelessWidget {
  /// Texto descriptivo o valor formateado a desplegar en la fila.
  final String label;

  /// Determina si el texto debe representarse con peso tipográfico en negrita (`FontWeight.bold`).
  final bool isBold;

  /// Estilo tipográfico opcional personalizado; si es nulo, se hereda `bodyMedium` del tema contextual.
  final TextStyle? textStyle;

  /// Constructor del componente tipográfico auxiliar de desglose de precios.
  const _PricingRow({
    required this.label,
    required this.isBold,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textStyle ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
    );
  }
}

