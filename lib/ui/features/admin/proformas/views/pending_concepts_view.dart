// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/pending_concepts_view.dart
// Propósito: Interfaz administrativa para la consulta, selección y consolidación de conceptos pendientes de cobro (citas y solicitudes) para la composición de proformas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/pending_concepts_view_model.dart';

/// {@template pending_concepts_view}
/// Vista interactiva para la selección de conceptos pendientes de facturar asociados a un cliente.
///
/// Permite visualizar las citas finalizadas sin facturación y los pedidos de catálogo
/// en estado listo para retiro, permitiendo marcarlos selectivamente para incorporarlos
/// a un nuevo borrador de proforma o a una proforma existente en curso.
/// {@endtemplate}
class PendingConceptsView extends StatefulWidget {
  /// Instancia del ViewModel gestor de los conceptos pendientes del cliente.
  final PendingConceptsViewModel viewModel;

  /// Nombre completo del cliente cuyos conceptos pendientes se presentan.
  final String clientName;

  /// Función constructora del texto dinámico del botón principal de confirmación.
  final String Function(AppLocalizations l10n, int count) confirmLabel;

  /// Callback asíncrono invocado al confirmar la selección de conceptos.
  ///
  /// Recibe la lista de referencias estructuradas de los ítems seleccionados.
  /// Retorna un valor booleano (`true`) si la operación de confirmación fue exitosa.
  final Future<bool> Function(List<Map<String, dynamic>> items) onConfirm;

  /// Constructor del widget de conceptos pendientes.
  const PendingConceptsView({
    super.key,
    required this.viewModel,
    required this.clientName,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  State<PendingConceptsView> createState() => _PendingConceptsViewState();
}

class _PendingConceptsViewState extends State<PendingConceptsView> {
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  Future<void> _confirm() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    final ok = await widget.onConfirm(widget.viewModel.selectedItemRefs());
    if (!mounted) return;
    setState(() => _isConfirming = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proformaPendingConceptsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.proformaPendingConceptsSubtitle(widget.clientName),
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null && vm.concepts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48.0, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16.0),
                    Text(vm.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16.0),
                    TappableArea(
                      semanticLabel: l10n.retry,
                      onTap: vm.init,
                      child: ElevatedButton(
                        onPressed: vm.init,
                        child: Text(l10n.retry),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.concepts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64.0, color: Colors.grey.shade400),
                    const SizedBox(height: 16.0),
                    Text(
                      l10n.proformaNoPendingConcepts,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: vm.concepts.length,
            itemBuilder: (context, index) {
              final concepto = vm.concepts[index];
              final pricing = vm.pricingOf(concepto);
              final esCita = concepto.itemType == 'APPOINTMENT';

              return Card(
                key: ValueKey('pending_concept_${concepto.refId}'),
                margin: const EdgeInsets.only(bottom: 8.0),
                child: CheckboxListTile(
                  value: vm.isSelected(concepto.refId),
                  onChanged: (_) => vm.toggle(concepto.refId),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    concepto.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      Text(
                        '${esCita ? l10n.proformaConceptAppointment : l10n.proformaConceptProduct}'
                        '${concepto.detail.isEmpty ? '' : ' · ${concepto.detail}'}',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${l10n.quantityLabel(concepto.quantity)} · '
                        '${l10n.proformaSubtotalLabel}: ${l10n.moneyAmount(formatCents(concepto.basePriceCents * concepto.quantity))} · '
                        '${l10n.proformaTotalLabel}: ${l10n.moneyAmount(formatCents(pricing.finalPriceCents))}',
                        style: TextStyle(fontSize: 12.0, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          if (vm.concepts.isEmpty) return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.proformaSelectedTotalLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.moneyAmount(formatCents(vm.selectedTotalCents)),
                        key: const ValueKey('pending_concepts_total'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  TappableArea(
                    semanticLabel: widget.confirmLabel(l10n, vm.selectedRefIds.length),
                    onTap: (!vm.hasSelection || _isConfirming) ? null : _confirm,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48.0,
                      child: ElevatedButton.icon(
                        key: const ValueKey('confirm_pending_concepts_button'),
                        onPressed: (!vm.hasSelection || _isConfirming) ? null : _confirm,
                        icon: _isConfirming
                            ? const SizedBox(
                                width: 18.0,
                                height: 18.0,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          widget.confirmLabel(l10n, vm.selectedRefIds.length),
                        ),
                      ),
                    ),
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

/// {@template proforma_client_picker_dialog}
/// Diálogo modal interactivo para la búsqueda y selección de un cliente destinatario de proforma.
///
/// Presenta un campo de búsqueda en tiempo real conectado a un flujo de datos reactivo
/// ([clientsStream]) que lista los clientes coincidentes con el término ingresado.
/// Al seleccionar un cliente, el diálogo retorna la instancia correspondiente de [ProformaClientOption].
/// {@endtemplate}
class ProformaClientPickerDialog extends StatefulWidget {
  /// Flujo reactivo de clientes elegibles filtrados según el término de búsqueda ([query]).
  final Stream<List<ProformaClientOption>> Function(String query) clientsStream;

  /// Constructor del diálogo modal de selección de cliente.
  const ProformaClientPickerDialog({super.key, required this.clientsStream});

  @override
  State<ProformaClientPickerDialog> createState() =>
      _ProformaClientPickerDialogState();
}

class _ProformaClientPickerDialogState extends State<ProformaClientPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.proformaSelectClientTitle),
      content: SizedBox(
        width: 420.0,
        height: 420.0,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('proforma_client_search_input'),
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminClientsSearchLabel,
                hintText: l10n.adminClientsSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: StreamBuilder<List<ProformaClientOption>>(
                stream: widget.clientsStream(_query),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final clientes = snapshot.data ?? const <ProformaClientOption>[];
                  if (clientes.isEmpty) {
                    return Center(child: Text(l10n.adminClientsEmptyActive));
                  }
                  return ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return ListTile(
                        key: ValueKey('proforma_client_option_${cliente.uid}'),
                        leading: const Icon(Icons.person_outline),
                        title: Text(cliente.fullName),
                        subtitle: Text(cliente.email),
                        onTap: () => Navigator.of(context).pop(cliente),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TappableArea(
          semanticLabel: l10n.cancel,
          onTap: () => Navigator.of(context).pop(),
          child: TextButton(
            key: const ValueKey('proforma_client_picker_cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ),
      ],
    );
  }
}

/// {@template proforma_client_option}
/// Representación liviana (DTO de presentación) de un cliente seleccionable para proformas.
///
/// Evita el acoplamiento directo y la sobrecarga de transportar el modelo completo
/// de perfil de usuario hacia la capa de composición y facturación administrativa.
/// {@endtemplate}
class ProformaClientOption {
  /// Identificador único del usuario / cliente en Firebase Authentication / Firestore.
  final String uid;

  /// Nombre completo del cliente para visualización en pantalla y reportes.
  final String fullName;

  /// Correo electrónico institucional o personal del cliente.
  final String email;

  /// Constructor inmutable para la opción liviana de cliente de proforma.
  const ProformaClientOption({
    required this.uid,
    required this.fullName,
    required this.email,
  });
}
