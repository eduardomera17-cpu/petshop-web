// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/inventory/views/admin_inventory_screen.dart
// Propósito: Pantalla adaptadora e inyectora de dependencias para el módulo de control de inventario y existencias físicas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/inventory/view_models/admin_inventory_view_model.dart';
import 'package:mipetshop/ui/features/admin/inventory/views/admin_inventory_view.dart';

/// Pantalla adaptadora que resuelve el [ProductsRepository] e inicializa el [AdminInventoryViewModel]
/// para desplegar la vista principal de inventario [AdminInventoryView].
class AdminInventoryScreen extends StatefulWidget {
  /// Constructor del adaptador de pantalla de inventario.
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

/// Estado interactivo de [AdminInventoryScreen] a cargo de administrar el ciclo de vida de [AdminInventoryViewModel].
class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  /// Instancia activa del modelo de vista gestor de inventario y ajustes de stock.
  AdminInventoryViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final productsRepo = Provider.of<ProductsRepository?>(context, listen: false);
        if (productsRepo != null) {
          _viewModel = AdminInventoryViewModel(productsRepository: productsRepo);
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminInventoryTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminInventoryView(viewModel: _viewModel!);
  }
}
