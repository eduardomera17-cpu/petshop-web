// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/products/views/admin_products_list_view.dart
// Propósito: Vista de gestión del catálogo maestro de productos comerciales con control de activación y edición.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/products/view_models/admin_products_view_model.dart';
import 'package:mipetshop/ui/features/admin/products/views/product_form_view.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';

/// Vista de administración del catálogo comercial de productos del petshop.
///
/// Permite al personal administrativo:
/// - Buscar y filtrar productos por denominación o categoría comercial.
/// - Conmutar la vigencia del artículo (`isActive`) de forma directa mediante un interruptor interactivo.
/// - Consultar el precio base impositivo y el nivel actual de inventario en existencias.
/// - Acceder al formulario de creación o modificación ([ProductFormView]) y navegar al módulo de inventario.
class AdminProductsListView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de las operaciones sobre el catálogo de productos.
  final AdminProductsViewModel viewModel;

  /// Identificador único del usuario administrativo en sesión.
  final String currentUid;

  /// Retrollamada opcional para navegar hacia el módulo de inventario físico.
  final VoidCallback? onNavigateToInventory;

  /// Constructor de la vista de listado de productos comerciales.
  const AdminProductsListView({
    super.key,
    required this.viewModel,
    required this.currentUid,
    this.onNavigateToInventory,
  });


  void _openForm(BuildContext context, [Product? product]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormView(
          viewModel: viewModel,
          product: product,
          currentUid: currentUid,
          onSaved: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n.adminProductsTitle),
        actions: [
          if (onNavigateToInventory != null)
            IconButton(
              key: const ValueKey('go_to_inventory_button'),
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: l10n.adminInventoryTitle,
              onPressed: onNavigateToInventory,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add_product_button'),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addProductAction),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 32.0 : 16.0;

          return Column(
            children: [
              // Barra de búsqueda y filtros
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16.0,
                  horizontalPadding,
                  8.0,
                ),
                child: TextField(
                  key: const ValueKey('products_admin_search_bar'),
                  decoration: InputDecoration(
                    labelText: l10n.searchPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: viewModel.search,
                ),
              ),

              // Contenido principal
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
                        return _ProductAdminCard(
                          product: product,
                          onEdit: () => _openForm(context, product),
                          onToggleActive: (val) {
                            viewModel.toggleActive(
                              product.id,
                              val,
                              currentUid,
                            );
                          },
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

/// Tarjeta interactiva de presentación de producto comercial para el personal administrativo.
class _ProductAdminCard extends StatelessWidget {
  /// Entidad del producto cuyos atributos son representados.
  final Product product;

  /// Retrollamada ejecutada al solicitar la edición del artículo.
  final VoidCallback onEdit;

  /// Retrollamada ejecutada al alternar el estado de activación del producto.
  final ValueChanged<bool> onToggleActive;

  /// Constructor de la tarjeta de producto para administradores.
  const _ProductAdminCard({
    required this.product,
    required this.onEdit,
    required this.onToggleActive,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: product.isActive ? null : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        product.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: ValueKey('toggle_active_${product.id}'),
                  value: product.isActive,
                  onChanged: onToggleActive,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(height: 24.0),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.proformaSubtotalLabel}: ${l10n.moneyAmount(formatCents(product.basePriceCents))}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${l10n.currentStockLabel}: ${product.stock}',
                      style: TextStyle(
                        color: product.stock > 0 ? Colors.teal.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 48.0,
                  child: OutlinedButton.icon(
                    key: ValueKey('edit_product_button_${product.id}'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.editProductAction),
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
