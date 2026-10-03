// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/billing_parameters_view.dart
// Propósito: Formulario de configuración de parámetros fiscales, tributarios (IVA, ICE) y datos de emisor para proformas del establecimiento.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/billing_config_view_model.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';

/// Formulario interactivo para la configuración de datos fiscales y parámetros tributarios del negocio.
///
/// Modela y persiste las variables oficiales del emisor:
/// - Razón social, RUC / identificación tributaria, dirección matriz y teléfono de contacto.
/// - Serie o secuencial de proformas comerciales.
/// - Alícuota general de IVA expresada en puntos básicos (ej. 1500 para 15.00%).
/// - Inclusión o exclusión de la base imponible del ICE en el cálculo del IVA de acuerdo a la normativa ecuatoriana vigente.
class BillingParametersView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de los parámetros fiscales y su persistencia.
  final BillingConfigViewModel viewModel;

  /// Identificador único del usuario administrativo que ejecuta la parametrización.
  final String currentUid;

  /// Constructor de la vista de parámetros de facturación.
  const BillingParametersView({
    super.key,
    required this.viewModel,
    required this.currentUid,
  });


  @override
  State<BillingParametersView> createState() => _BillingParametersViewState();
}

class _BillingParametersViewState extends State<BillingParametersView> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _ivaBpCtrl = TextEditingController();
  bool _iceIncluded = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.viewModel.config != null) {
      _loadConfig();
      _initialized = true;
    }
  }

  void _loadConfig() {
    final cfg = widget.viewModel.config;
    if (cfg != null) {
      _businessNameCtrl.text = cfg.businessName;
      _taxIdCtrl.text = cfg.taxId;
      _addressCtrl.text = cfg.address;
      _phoneCtrl.text = cfg.phone;
      _seriesCtrl.text = cfg.proformaSeries;
      _ivaBpCtrl.text = cfg.ivaBp.toString();
      _iceIncluded = cfg.iceIncludedInIvaBase;
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _taxIdCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _seriesCtrl.dispose();
    _ivaBpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.viewModel.saveParameters(
      uid: widget.currentUid,
      businessName: _businessNameCtrl.text.trim(),
      taxId: _taxIdCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      proformaSeries: _seriesCtrl.text.trim(),
      ivaBp: int.tryParse(_ivaBpCtrl.text.trim()) ?? 1500,
      iceIncludedInIvaBase: _iceIncluded,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveBillingParamsSuccess),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n.adminBillingParametersTitle),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_initialized && widget.viewModel.config != null) {
            _loadConfig();
            _initialized = true;
          }

          return LayoutBuilder(
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
                      // Aviso mandatorio sobre IVA que rige hacia adelante
                      Container(
                        key: const ValueKey('iva_forward_notice'),
                        padding: const EdgeInsets.all(14.0),
                        margin: const EdgeInsets.only(bottom: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade900),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                l10n.ivaNoticeFutureOnly,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Razón Social
                      TextFormField(
                        key: const ValueKey('billing_business_name_input'),
                        controller: _businessNameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.businessNameLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.businessNameLabel;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // RUC / Identificación Fiscal
                      TextFormField(
                        key: const ValueKey('billing_tax_id_input'),
                        controller: _taxIdCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.taxIdLabel,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.taxIdLabel;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Dirección y Teléfono
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('billing_address_input'),
                              controller: _addressCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.addressLabel,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n.addressLabel;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('billing_phone_input'),
                              controller: _phoneCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.phoneLabel,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n.phoneLabel;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Serie de Proforma y Porcentaje de IVA
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('billing_proforma_series_input'),
                              controller: _seriesCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.proformaSeriesLabel,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n.proformaSeriesLabel;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('billing_iva_bp_input'),
                              controller: _ivaBpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.ivaBpLabel,
                                // Sin la equivalencia a la vista, 15 y 1500 se
                                // escriben igual de fácil y el error no se nota
                                // hasta que ya se congeló en un concepto.
                                helperText: l10n.ivaBpHelper(
                                  ((int.tryParse(_ivaBpCtrl.text.trim()) ?? 0) / 100)
                                      .toStringAsFixed(2),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n.ivaBpLabel;
                                }
                                final parsed = int.tryParse(val.trim());
                                if (parsed == null || parsed < 0 || parsed > 10000) {
                                  return l10n.ivaBpLabel;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Switch ICE incluido en base imponible de IVA
                      SwitchListTile(
                        key: const ValueKey('billing_ice_in_iva_switch'),
                        title: Text(l10n.iceIncludedInIvaBaseLabel),
                        value: _iceIncluded,
                        onChanged: (val) {
                          setState(() {
                            _iceIncluded = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Botón Guardar
                      TappableArea(
                        semanticLabel: widget.viewModel.isSaving
                            ? l10n.savingAction
                            : l10n.saveAction,
                        onTap: widget.viewModel.isSaving ? null : _submit,
                        child: SizedBox(
                          height: 48.0,
                          child: ElevatedButton(
                            key: const ValueKey('save_billing_params_button'),
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
                        ),
                      ),
                    ],
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
