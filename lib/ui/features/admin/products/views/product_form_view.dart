// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/products/views/product_form_view.dart
// Propósito: Formulario administrativo para el alta y modificación de productos comerciales con desglose impositivo y control de stock inicial.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/products/view_models/admin_products_view_model.dart';

/// Formulario interactivo para la creación y edición de productos comerciales en el catálogo.
///
/// Características y reglas de integridad:
/// - Normalización de categorías canónicas: `FOOD`, `MEDICINE`, `ACCESSORIES`, `HYGIENE`.
/// - Configuración del precio base en dólares con conversión interna a centavos enteros para evitar errores de redondeo IEEE 754.
/// - Entrada de tarifa de ICE (Impuesto a los Consumos Especiales) en puntos básicos (basis points).
/// - Regla de inmutabilidad de stock en edición: el stock inicial solo se define en la creación; las modificaciones posteriores deben registrarse en el módulo de inventario.
class ProductFormView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de las operaciones sobre productos.
  final AdminProductsViewModel viewModel;

  /// Instancia del producto en caso de edición; si es nulo, el formulario opera en modo de creación.
  final Product? product;

  /// Identificador del usuario administrativo que ejecuta la operación.
  final String currentUid;

  /// Retrollamada ejecutada al completar y guardar los cambios exitosamente.
  final VoidCallback onSaved;

  /// Constructor del formulario de producto comercial.
  const ProductFormView({
    super.key,
    required this.viewModel,
    this.product,
    required this.currentUid,
    required this.onSaved,
  });

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}


class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late String _selectedCategory;
  late TextEditingController _basePriceCtrl;
  late TextEditingController _iceBpCtrl;
  late TextEditingController _stockCtrl;
  bool _isActive = true;

  static const List<String> _canonicalCategories = [
    'FOOD',
    'MEDICINE',
    'ACCESSORIES',
    'HYGIENE',
  ];

  static String _normalizeCategory(String? cat) {
    if (cat == null || cat.trim().isEmpty) return 'FOOD';
    final upper = cat.trim().toUpperCase();
    if (_canonicalCategories.contains(upper)) return upper;
    if (upper.startsWith('ALIM')) return 'FOOD';
    if (upper.startsWith('MEDIC')) return 'MEDICINE';
    if (upper.startsWith('ACCES')) return 'ACCESSORIES';
    if (upper.startsWith('HIGI')) return 'HYGIENE';
    return 'FOOD';
  }

  String _categoryLabel(String cat, AppLocalizations l10n) {
    switch (cat) {
      case 'FOOD':
        return l10n.categoryFood;
      case 'MEDICINE':
        return l10n.categoryMedicine;
      case 'ACCESSORIES':
        return l10n.categoryAccessories;
      case 'HYGIENE':
        return l10n.categoryHygiene;
      default:
        return cat;
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _selectedCategory = _normalizeCategory(p?.category);
    _basePriceCtrl = TextEditingController(
        text: p != null ? (p.basePriceCents / 100.0).toStringAsFixed(2) : '');
    _iceBpCtrl = TextEditingController(text: p?.iceBp.toString() ?? '0');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _basePriceCtrl.dispose();
    _iceBpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final category = _selectedCategory;
    final basePriceDouble = double.tryParse(_basePriceCtrl.text.trim()) ?? 0.0;
    final basePriceCents = (basePriceDouble * 100).round();
    final iceBp = int.tryParse(_iceBpCtrl.text.trim()) ?? 0;
    final initialStock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    final success = await widget.viewModel.saveProduct(
      productId: widget.product?.id,
      name: name,
      description: desc,
      category: category,
      basePriceCents: basePriceCents,
      iceBp: iceBp,
      initialStock: initialStock,
      isActive: _isActive,
      uid: widget.currentUid,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.productSavedSuccess),
          backgroundColor: Colors.teal,
        ),
      );
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editProductAction : l10n.addProductAction),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 48.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mensaje de error
                  ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      if (widget.viewModel.errorMessage != null) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            widget.viewModel.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Nombre del Producto
                  TextFormField(
                    key: const ValueKey('product_name_input'),
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.productNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.productNameLabel;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Descripción
                  TextFormField(
                    key: const ValueKey('product_description_input'),
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.productDescriptionLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.productDescriptionLabel;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Selector de categoría canónica de producto
                  DropdownButtonFormField<String>(
                    key: const ValueKey('product_category_input'),
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.productCategoryPrompt,
                      border: const OutlineInputBorder(),
                    ),
                    items: _canonicalCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(_categoryLabel(cat, l10n)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      }
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return l10n.productCategoryPrompt;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Precio Base y ICE
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('product_base_price_input'),
                          controller: _basePriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.productBasePriceLabel,
                            prefixText: r'$ ',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.productBasePriceLabel;
                            }
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed <= 0) {
                              return l10n.productBasePriceLabel;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('product_ice_bp_input'),
                          controller: _iceBpCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.productIceBpLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return null;
                            final parsed = int.tryParse(val.trim());
                            if (parsed == null || parsed < 0) {
                              return l10n.productIceBpLabel;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Stock: Solo editable en creación
                  if (!isEditing)
                    TextFormField(
                      key: const ValueKey('product_initial_stock_input'),
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.productInitialStockLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.productInitialStockLabel;
                        }
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return l10n.productInitialStockLabel;
                        }
                        return null;
                      },
                    )
                  else
                    Container(
                      key: const ValueKey('product_stock_locked_notice'),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.amber.shade900),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              l10n.productStockLockedNotice,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16.0),

                  // Switch Activo/Inactivo
                  SwitchListTile(
                    key: const ValueKey('product_active_switch'),
                    title: Text(l10n.productActiveStatusLabel),
                    value: _isActive,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Botón Guardar
                  ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      return SizedBox(
                        height: 48.0,
                        child: ElevatedButton(
                          key: const ValueKey('save_product_button'),
                          onPressed: widget.viewModel.isSaving ? null : _submit,
                          child: widget.viewModel.isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(l10n.savingAction),
                                  ],
                                )
                              : Text(l10n.saveAction),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
