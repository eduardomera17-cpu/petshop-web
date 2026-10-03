// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/products/views/admin_products_screen.dart
// Propósito: Pantalla adaptadora e inyectora de dependencias para el catálogo maestro de productos comerciales.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/products/view_models/admin_products_view_model.dart';
import 'package:mipetshop/ui/features/admin/products/views/admin_products_list_view.dart';

/// Pantalla adaptadora que inicializa [AdminProductsViewModel] resolviendo los repositorios
/// [ProductsRepository] y [AuthRepository] y presenta la vista de listado [AdminProductsListView].
class AdminProductsScreen extends StatefulWidget {
  /// Constructor del adaptador de pantalla de productos administrativos.
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

/// Estado interactivo de [AdminProductsScreen] a cargo de gestionar el ciclo de vida del ViewModel.
class _AdminProductsScreenState extends State<AdminProductsScreen> {
  /// Instancia activa del modelo de vista gestor de productos.
  AdminProductsViewModel? _viewModel;

  /// Identificador único del usuario autenticado en la sesión.
  String? _uid;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final productsRepo = Provider.of<ProductsRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        if (productsRepo != null) {
          _viewModel = AdminProductsViewModel(productsRepository: productsRepo);
          _uid = authRepo?.currentUser?.uid;
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
    final authRepo = Provider.of<AuthRepository?>(context, listen: false);
    final currentUid = _uid ?? authRepo?.currentUser?.uid;

    if (_viewModel == null || currentUid == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminProductsTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminProductsListView(
      viewModel: _viewModel!,
      currentUid: currentUid,
      onNavigateToInventory: () => context.go('/admin/inventory'),
    );
  }
}
