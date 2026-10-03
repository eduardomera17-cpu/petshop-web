// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/inventory/views/admin_inventory_view.dart
// Propósito: Vista de supervisión de inventario físico, filtrado de stock crítico y ajustes manuales de existencias.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/inventory/view_models/admin_inventory_view_model.dart';
import 'package:mipetshop/ui/features/admin/inventory/views/stock_adjustment_dialog.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';

/// Vista interactiva para el control administrativo de inventario y monitoreo de existencias.
///
/// Capacidades del módulo:
/// - Filtrado predictivo por nombre de producto y conmutador para ver exclusivamente artículos con stock bajo.
/// - Identificación de productos por debajo del umbral mínimo con insignias visuales de advertencia en rojo.
/// - Despliegue del diálogo modal [StockAdjustmentDialog] para aplicar entradas, salidas o correcciones de inventario.
class AdminInventoryView extends StatelessWidget {
  /// Modelo de vista reactivo gestor del inventario y los filtros de alerta.
  final AdminInventoryViewModel viewModel;

  /// Constructor de la vista de inventario.
  const AdminInventoryView({
    super.key,
    required this.viewModel,
  });


  void _openAdjustmentDialog(BuildContext context, Product product) {
    StockAdjustmentDialog.show(
      context,
      product: product,
      viewModel: viewModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n.adminInventoryTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 32.0 : 16.0;

          return Column(
            children: [
              // Barra de filtros y búsqueda
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16.0,
                  horizontalPadding,
                  8.0,
                ),
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey('inventory_search_bar'),
                      decoration: InputDecoration(
                        labelText: l10n.searchPlaceholder,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: viewModel.search,
                    ),
                    const SizedBox(height: 8.0),
                    ListenableBuilder(
                      listenable: viewModel,
                      builder: (context, _) {
                        return SwitchListTile(
                          key: const ValueKey('filter_low_stock_switch'),
                          title: Text(l10n.lowStockAlert),
                          subtitle: Text(
                            '${l10n.lowStockAlert} (≤ ${viewModel.lowStockThreshold})',
                          ),
                          value: viewModel.onlyLowStock,
                          onChanged: viewModel.toggleOnlyLowStock,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Lista de productos e inventario
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.errorMessage != null) {
                      return Center(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }

                    if (viewModel.products.isEmpty) {
                      return Center(
                        child: Text(l10n.noProductsFoundAdmin),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16.0,
                      ),
                      itemCount: viewModel.products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final product = viewModel.products[index];
                        final isLow = viewModel.isLowStock(product);

                        return _InventoryProductCard(
                          product: product,
                          isLowStock: isLow,
                          onAdjust: () => _openAdjustmentDialog(context, product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta de presentación individual de un producto comercial en la lista de inventario.
class _InventoryProductCard extends StatelessWidget {
  /// Entidad del producto cuyo stock y atributos son presentados.
  final Product product;

  /// Indica si el producto se encuentra en condición crítica por debajo del umbral mínimo configurado.
  final bool isLowStock;

  /// Retrollamada ejecutada al solicitar el ajuste manual de existencias.
  final VoidCallback onAdjust;

  /// Constructor de la tarjeta de inventario de producto.
  const _InventoryProductCard({
    required this.product,
    required this.isLowStock,
    required this.onAdjust,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isLowStock ? Colors.red.shade300 : Colors.grey.shade300,
          width: isLowStock ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          key: ValueKey('low_stock_badge_${product.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: Colors.red.shade400),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Colors.red.shade900),
                              const SizedBox(width: 4.0),
                              Text(
                                l10n.lowStockAlert,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    product.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${l10n.currentStockLabel}: ${product.stock}',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red.shade800 : Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48.0,
              child: ElevatedButton.icon(
                key: ValueKey('adjust_stock_button_${product.id}'),
                onPressed: onAdjust,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l10n.adjustStockAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
