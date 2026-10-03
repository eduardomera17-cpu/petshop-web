// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/views/catalog_view.dart
// Propósito: Vista principal del catálogo comercial de productos con búsqueda por prefijo, filtrado por categorías, cálculo impositivo en vivo y barra flotante de selección múltiple.
// =========================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mipetshop/ui/features/catalog/view_models/product_detail_view_model.dart';
import 'package:mipetshop/ui/features/catalog/views/product_detail_view.dart';
import 'package:provider/provider.dart';

/// Pantalla principal para la navegación, búsqueda y selección del catálogo de productos.
///
/// Ofrece una experiencia de compra asistida con las siguientes características:
/// - Búsqueda reactiva optimizada por prefijos de texto (`searchPrefixes`).
/// - Filtrado interactivo mediante chips categorizados (Alimentos, Medicinas, Accesorios, Higiene).
/// - Cuadrícula adaptable responsiva (1 a 3 columnas según resolución de pantalla).
/// - Desglose tributario en tiempo real con cálculo de base imponible, ICE e IVA proyectados.
/// - Verificación instantánea de niveles de inventario activo.
/// - Barra de compras inferior para pedidos de múltiples líneas con resumen flotante.
class CatalogView extends StatefulWidget {
  /// Modelo de vista reactivo gestor del catálogo, búsquedas y carrito temporal.
  final CatalogViewModel viewModel;

  /// Identificador único del usuario cliente autenticado en sesión.
  final String currentUid;

  /// Callback de navegación hacia el historial de solicitudes de productos del cliente.
  final VoidCallback? onNavigateToRequests;

  /// Constructor de la vista principal del catálogo comercial.
  const CatalogView({
    super.key,
    required this.viewModel,
    required this.currentUid,
    this.onNavigateToRequests,
  });

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

/// Estado mutable de [CatalogView].
///
/// Controla el ciclo de vida del [CatalogViewModel] y el controlador de entrada para búsquedas.
class _CatalogViewState extends State<CatalogView> {
  /// Controlador de edición del campo de búsqueda reactiva por prefijo.
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.catalogTitle ?? ''),
            actions: [
              if (widget.onNavigateToRequests != null)
                TappableArea(
                  semanticLabel: l10n?.myRequestsTitle ?? '',
                  onTap: widget.onNavigateToRequests,
                  child: TextButton.icon(
                    key: const ValueKey('navigate_to_my_requests_button'),
                    onPressed: widget.onNavigateToRequests,
                    icon: const Icon(Icons.receipt_long),
                    label: Text(l10n?.myRequestsTitle ?? ''),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: widget.viewModel.totalSelectedLines > 0
              ? _CatalogSelectionBar(
                  viewModel: widget.viewModel,
                  currentUid: widget.currentUid,
                  onViewDetails: () => _showSelectionModal(context),
                )
              : null,
          body: Builder(
            builder: (context) {
              if (widget.viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.viewModel.loadFailure != null &&
                  widget.viewModel.pricingConfig == null) {
                return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    widget.viewModel.loadFailure!.toLocalizedMessage(l10n!),
                    key: const ValueKey('catalog_load_error_message'),
                  ),
                  const SizedBox(height: 16),
                  TappableArea(
                    semanticLabel: l10n.retry,
                    onTap: () => widget.viewModel.init(),
                    child: ElevatedButton(
                      onPressed: () => widget.viewModel.init(),
                      child: Text(l10n.retry),
                    ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1024
                  ? 3
                  : (width >= 600 ? 2 : 1);

              return Column(
                children: [
                  // Barra de búsqueda y categorías
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: const ValueKey('catalog_search_field'),
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: l10n?.searchProductHint ?? '',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? TappableArea(
                                    semanticLabel:
                                        l10n?.catalogClearSearch ?? '',
                                    onTap: () {
                                      _searchCtrl.clear();
                                      widget.viewModel.search('');
                                    },
                                    child: IconButton(
                                      key: const ValueKey(
                                          'catalog_search_clear_button'),
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        widget.viewModel.search('');
                                      },
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            widget.viewModel.search(val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _CategoryChips(
                          selectedCategory: widget.viewModel.selectedCategory,
                          onSelect: (cat) => widget.viewModel.setCategory(cat),
                        ),
                      ],
                    ),
                  ),

                  // Banner de error de solicitud múltiple
                  if (widget.viewModel.submissionError != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (widget.viewModel.submissionFailure ??
                                      DomainFailure(
                                        code: widget.viewModel.submissionError!,
                                      ))
                                  .toLocalizedMessage(
                                l10n!,
                                productNameOf:
                                    widget.viewModel.productNameOf,
                              ),
                              key: const ValueKey('catalog_error_message'),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          TappableArea(
                            semanticLabel: l10n.close,
                            onTap: () =>
                                widget.viewModel.clearSubmissionState(),
                            child: IconButton(
                              key: const ValueKey(
                                  'catalog_error_dismiss_button'),
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  widget.viewModel.clearSubmissionState(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Banner de éxito de solicitud múltiple
                  if (widget.viewModel.submissionSuccessId != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
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
                              l10n?.catalogRequestSuccess ?? '',
                              key: const ValueKey('catalog_success_message'),
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TappableArea(
                            semanticLabel: l10n?.close ?? '',
                            onTap: () =>
                                widget.viewModel.clearSubmissionState(),
                            child: IconButton(
                              key: const ValueKey(
                                  'catalog_success_dismiss_button'),
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  widget.viewModel.clearSubmissionState(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Lista o cuadrícula de productos
                  Expanded(
                    child: widget.viewModel.products.isEmpty
                        ? Center(
                            child: Text(
                              l10n?.emptyCatalogMessage ?? '',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: crossAxisCount == 1 ? 290 : 300,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: widget.viewModel.products.length,
                            itemBuilder: (context, index) {
                              final product = widget.viewModel.products[index];
                              final pricing = widget.viewModel
                                  .calculatePricingForProduct(product);

                              return _ProductCard(
                                product: product,
                                pricing: pricing,
                                viewModel: widget.viewModel,
                                onTap: () =>
                                    _openProductDetail(context, product),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  },
);
}

  void _showSelectionModal(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (ctx, _) {
            final items = widget.viewModel.selectedList;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.catalogSelectionTitle ?? '',
                          style:
                              Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TappableArea(
                          semanticLabel: l10n?.close ?? '',
                          onTap: () => Navigator.of(ctx).pop(),
                          child: IconButton(
                            key: const ValueKey(
                                'catalog_selection_close_button'),
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            l10n?.catalogSelectionEmpty ?? '',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final item = items[index];
                            final pricing = widget.viewModel
                                .calculatePricingForProduct(item.product);
                            final finalUnitPrice = pricing?.finalPriceCents ??
                                item.product.basePriceCents;
                            return ListTile(
                              key:
                                  ValueKey('selection_item_${item.product.id}'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                l10n?.catalogSelectionLinePrices(
                                      formatCents(finalUnitPrice),
                                      formatCents(
                                          finalUnitPrice * item.quantity),
                                    ) ??
                                    '',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TappableArea(
                                    semanticLabel:
                                        l10n?.catalogDecreaseQuantity ?? '',
                                    onTap: widget.viewModel.isSubmitting
                                        ? null
                                        : () => widget.viewModel
                                            .decrementQuantity(
                                                item.product.id),
                                    child: IconButton(
                                      key: ValueKey(
                                          'selection_decrement_${item.product.id}'),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: widget.viewModel.isSubmitting
                                          ? null
                                          : () => widget.viewModel
                                              .decrementQuantity(
                                                  item.product.id),
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    key: ValueKey(
                                        'selection_quantity_${item.product.id}'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TappableArea(
                                    semanticLabel:
                                        l10n?.catalogIncreaseQuantity ?? '',
                                    onTap: widget.viewModel.isSubmitting ||
                                            item.quantity >=
                                                CatalogViewModel
                                                    .maxRequestQuantity
                                        ? null
                                        : () => widget.viewModel
                                            .incrementQuantity(
                                                item.product.id),
                                    child: IconButton(
                                      key: ValueKey(
                                          'selection_increment_${item.product.id}'),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: widget.viewModel.isSubmitting ||
                                              item.quantity >=
                                                  CatalogViewModel
                                                      .maxRequestQuantity
                                          ? null
                                          : () => widget.viewModel
                                              .incrementQuantity(
                                                  item.product.id),
                                    ),
                                  ),
                                  TappableArea(
                                    semanticLabel:
                                        l10n?.catalogRemoveFromSelection ?? '',
                                    onTap: widget.viewModel.isSubmitting
                                        ? null
                                        : () => widget.viewModel
                                            .removeProduct(item.product.id),
                                    child: IconButton(
                                      key: ValueKey(
                                          'selection_remove_${item.product.id}'),
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: widget.viewModel.isSubmitting
                                          ? null
                                          : () => widget.viewModel
                                              .removeProduct(item.product.id),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openProductDetail(BuildContext context, Product product) {
    final requestsRepo =
        Provider.of<ProductRequestsRepository?>(context, listen: false);
    final pricingConfig = widget.viewModel.pricingConfig;

    if (requestsRepo != null && pricingConfig != null) {
      final detailVm = ProductDetailViewModel(
        product: product,
        requestsRepository: requestsRepo,
        pricingConfig: pricingConfig,
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => ProductDetailView(
            viewModel: detailVm,
            currentUid: widget.currentUid,
          ),
        ),
      );
    }
  }
}

/// Fila horizontal deslizable de chips para filtrado por categoría taxonómica de producto.
class _CategoryChips extends StatelessWidget {
  /// Categoría actualmente seleccionada (null representa todas las categorías).
  final String? selectedCategory;

  /// Callback emitido al presionar sobre un chip de categoría.
  final ValueChanged<String?> onSelect;

  /// Constructor de la barra de chips de categorías.
  const _CategoryChips({
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final categories = <String?, String>{
      null: l10n?.categoryAll ?? '',
      'FOOD': l10n?.categoryFood ?? '',
      'MEDICINE': l10n?.categoryMedicine ?? '',
      'ACCESSORIES': l10n?.categoryAccessories ?? '',
      'HYGIENE': l10n?.categoryHygiene ?? '',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.entries.map((entry) {
          final isSelected = selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TappableArea(
              semanticLabel: entry.value,
              onTap: () => onSelect(entry.key),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => onSelect(entry.key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tarjeta visual representativa de un producto comercial en el catálogo.
///
/// Incorpora imagen del producto con descarga en memoria desde Cloud Storage,
/// indicadores de disponibilidad de inventario, desglose de impuestos y selector
/// interactivo de cantidad para la orden multi-línea.
class _ProductCard extends StatelessWidget {
  /// Entidad de datos del producto comercial.
  final Product product;

  /// Resultado precalculado de la proyección de precios e impuestos.
  final LinePricingResult? pricing;

  /// Modelo de vista gestor de la selección y el inventario.
  final CatalogViewModel viewModel;

  /// Callback invocado al pulsar la tarjeta para abrir la vista detallada del producto.
  final VoidCallback onTap;

  /// Constructor de la tarjeta de producto del catálogo.
  const _ProductCard({
    required this.product,
    required this.pricing,
    required this.viewModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = Provider.of<StorageService?>(context, listen: false);
    final isAvailable = product.stock > 0;
    final hasIce = product.iceBp > 0;
    final isSelected = viewModel.isSelected(product.id);
    final selectedQty = viewModel.getSelectedQuantity(product.id);

    final availableText = isAvailable
        ? (l10n?.stockAvailable ?? '')
        : (l10n?.stockOutOfStock ?? '');

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: TappableArea(
        semanticLabel: product.name,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          key: ValueKey('product_card_${product.id}'),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con imagen e info básica
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imagePath != null && storage != null)
                      FutureBuilder<Uint8List?>(
                        future: storage.getData(product.imagePath!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                snapshot.data!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2),
                          );
                        },
                      )
                    else
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              isAvailable
                                  ? StatusBadge.success(text: availableText)
                                  : StatusBadge.danger(text: availableText),
                              if (isSelected)
                                Container(
                                  key: ValueKey('selected_badge_${product.id}'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n?.catalogInSelectionBadge(
                                          selectedQty,
                                        ) ??
                                        '',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Desglose de precios en la tarjeta
              if (pricing != null) ...[
                Text(
                  l10n?.priceBaseFormatted(
                        formatCents(pricing!.basePriceCents),
                      ) ??
                      '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (hasIce)
                  Text(
                    l10n?.taxIceFormatted(
                          (pricing!.iceBp / 100).toStringAsFixed(0),
                          formatCents(pricing!.iceAmountCents),
                        ) ??
                        '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  l10n?.priceWithTaxesFormatted(
                        formatCents(pricing!.finalPriceCents),
                      ) ??
                      '',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
              const SizedBox(height: 8),

              // Botón de agregar a selección
              SizedBox(
                width: double.infinity,
                height: 48,
                child: isAvailable
                    ? TappableArea(
                        semanticLabel: l10n?.catalogAddToSelection ?? '',
                        onTap: viewModel.isSubmitting
                            ? null
                            : () => viewModel.addProduct(product),
                        child: OutlinedButton.icon(
                          key: ValueKey('add_to_selection_${product.id}'),
                          onPressed: viewModel.isSubmitting
                              ? null
                              : () => viewModel.addProduct(product),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: Text(
                            l10n?.catalogAddToSelection ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra flotante inferior de resumen para la orden multi-línea de productos.
///
/// Informa al cliente el total acumulado de ítems y el costo proyectado,
/// ofreciendo accesos directos para revisar el detalle de la selección o proceder al envío del pedido.
class _CatalogSelectionBar extends StatelessWidget {
  /// Modelo de vista gestor de los ítems seleccionados y el envío transaccional.
  final CatalogViewModel viewModel;

  /// Identificador único del cliente autenticado.
  final String currentUid;

  /// Acción ejecutada al pulsar el resumen para desplegar el modal de detalle de la orden.
  final VoidCallback onViewDetails;

  /// Constructor de la barra flotante de selección del catálogo.
  const _CatalogSelectionBar({
    required this.viewModel,
    required this.currentUid,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsRepo =
        Provider.of<ProductRequestsRepository?>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final summaryContent = TappableArea(
          semanticLabel: l10n?.catalogSelectionTitle ?? '',
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            key: const ValueKey('catalog_selection_summary'),
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              l10n?.catalogSelectionTitle ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_less, size: 18),
                        ],
                      ),
                      Text(
                        l10n?.catalogSelectionSummary(
                              viewModel.totalSelectedUnits,
                              viewModel.totalSelectedLines,
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        final clearButton = TappableArea(
          semanticLabel: l10n?.catalogClearSelection ?? '',
          onTap: viewModel.isSubmitting
              ? null
              : () => viewModel.clearSelection(),
          child: TextButton.icon(
            key: const ValueKey('catalog_clear_selection_button'),
            onPressed: viewModel.isSubmitting
                ? null
                : () => viewModel.clearSelection(),
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: Text(l10n?.catalogClearSelection ?? ''),
          ),
        );

        final submitButton = TappableArea(
          semanticLabel: l10n?.catalogSubmitRequestWithCount(
                viewModel.totalSelectedLines,
              ) ??
              '',
          onTap: viewModel.isSubmitting
              ? null
              : () => viewModel.submitSelectedRequest(
                    uid: currentUid,
                    repository: requestsRepo,
                  ),
          child: ElevatedButton(
            key: const ValueKey('catalog_submit_selection_button'),
            onPressed: viewModel.isSubmitting
                ? null
                : () => viewModel.submitSelectedRequest(
                      uid: currentUid,
                      repository: requestsRepo,
                    ),
            child: viewModel.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n?.catalogSubmitRequestWithCount(
                          viewModel.totalSelectedLines,
                        ) ??
                        '',
                  ),
          ),
        );

        return Container(
          key: const ValueKey('catalog_selection_panel'),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: isCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(child: summaryContent),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: clearButton),
                          const SizedBox(width: 8),
                          Expanded(child: submitButton),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: summaryContent),
                      clearButton,
                      const SizedBox(width: 8),
                      submitButton,
                    ],
                  ),
          ),
        );
      },
    );
  }
}

