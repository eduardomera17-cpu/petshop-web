// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/services/views/service_form_view.dart
// Propósito: Formulario administrativo para la creación y edición de servicios del catálogo, con validación de reglas de negocio y cálculo tributario en tiempo real.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/services/view_models/service_form_view_model.dart';

/// {@template service_form_view}
/// Formulario reactivo para la creación y modificación de servicios ofertados en el catálogo.
///
/// Ofrece validación de campos requeridos (nombre, descripción, duración estimada, base imponible
/// e ICE), cálculo reactivo del precio final al consumidor y alternancia de indicadores de estado
/// (servicio clínico veterinario y disponibilidad activa).
/// {@endtemplate}
class ServiceFormView extends StatefulWidget {
  /// ViewModel encargado de gestionar el estado del formulario y persistencia del servicio.
  final ServiceFormViewModel viewModel;

  /// Identificador único del usuario administrativo que ejecuta la creación o edición.
  final String currentUid;

  /// Constructor inmutable para la vista del formulario de servicio.
  const ServiceFormView({
    super.key,
    required this.viewModel,
    required this.currentUid,
  });

  @override
  State<ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<ServiceFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _iceController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _nameController = TextEditingController(text: vm.name);
    _descriptionController = TextEditingController(text: vm.description);
    _basePriceController = TextEditingController(
      text: vm.basePriceCents > 0 ? formatCents(vm.basePriceCents) : '',
    );
    _iceController = TextEditingController(text: vm.iceBp.toString());
    _durationController = TextEditingController(
      text: vm.estimatedDurationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _iceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onBasePriceChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '.'));
    if (parsed != null && parsed >= 0) {
      widget.viewModel.setBasePriceCents(toCents(parsed));
    } else if (val.isEmpty) {
      widget.viewModel.setBasePriceCents(0);
    }
  }

  void _onIceChanged(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed >= 0) {
      widget.viewModel.setIceBp(parsed);
    } else if (val.isEmpty) {
      widget.viewModel.setIceBp(0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.viewModel.save(widget.currentUid);
    if (!mounted) return;

    if (success) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.serviceSaveSuccess ?? ''),
          backgroundColor: Colors.green.shade800,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.viewModel.isEdit;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (l10n?.editServiceAction ?? '')
              : (l10n?.addServiceAction ?? ''),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final pricing = widget.viewModel.pricingPreview;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                if (widget.viewModel.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            widget.viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
                TextFormField(
                  key: const Key('service_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.serviceNameLabel ?? '',
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 80,
                  onChanged: widget.viewModel.setName,
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) return 'El nombre es obligatorio.';
                    if (trimmed.length > 80) return 'Máximo 80 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  key: const Key('service_description_field'),
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n?.serviceDescriptionLabel ?? '',
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: widget.viewModel.setDescription,
                  validator: (val) {
                    if ((val?.length ?? 0) > 500) return 'Máximo 500 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('service_base_price_field'),
                        controller: _basePriceController,
                        decoration: InputDecoration(
                          labelText: l10n?.serviceBasePriceLabel ?? '',
                          prefixText: r'$ ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onBasePriceChanged,
                        validator: (val) {
                          final parsed = double.tryParse(val?.replaceAll(',', '.') ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Ingresa un valor válido mayor o igual a cero.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: TextFormField(
                        key: const Key('service_ice_field'),
                        controller: _iceController,
                        decoration: InputDecoration(
                          labelText: l10n?.serviceIceLabel ?? '',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onIceChanged,
                        validator: (val) {
                          final parsed = int.tryParse(val ?? '');
                          if (parsed == null || parsed < 0 || parsed > 10000) {
                            return 'Valor entre 0 y 10000.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  key: const Key('service_duration_field'),
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: l10n?.serviceDurationLabel ?? '',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      widget.viewModel.setEstimatedDurationMinutes(parsed);
                    }
                  },
                  validator: (val) {
                    final parsed = int.tryParse(val ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Debe ser mayor a 0 minutos.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Card(
                  color: Colors.blueGrey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.serviceFinalPriceLabel ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          l10n?.servicePriceSummary(
                                formatCents(pricing.basePriceCents),
                                formatCents(pricing.finalPriceCents),
                              ) ??
                              '',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SwitchListTile(
                  title: Text(l10n?.serviceIsClinicalLabel ?? ''),
                  value: widget.viewModel.isClinical,
                  onChanged: widget.viewModel.setIsClinical,
                ),
                SwitchListTile(
                  title: Text(l10n?.serviceIsActiveLabel ?? ''),
                  value: widget.viewModel.isActive,
                  onChanged: widget.viewModel.setIsActive,
                ),
                const SizedBox(height: 24.0),
                TappableArea(
                  onTap: widget.viewModel.isSaving ? () {} : _submit,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton(
                      onPressed: widget.viewModel.isSaving ? null : _submit,
                      child: widget.viewModel.isSaving
                          ? Text(l10n?.savingService ?? '')
                          : Text(l10n?.saveChangesAction ?? ''),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
