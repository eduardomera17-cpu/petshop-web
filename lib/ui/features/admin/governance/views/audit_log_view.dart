// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/views/audit_log_view.dart
// Propósito: Vista de registro cronológico e inmutable de auditoría del sistema con trazabilidad de acciones operativas y administrativas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mipetshop/domain/models/audit_log_entry.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';

/// Pestaña de consulta del registro histórico de auditoría del sistema.
///
/// Principios de seguridad y trazabilidad:
/// - Despliega cronológicamente los eventos sensibles ejecutados en la plataforma (altas de personal, cambios de roles, modificaciones tarifarias, anulaciones).
/// - Filtro dinámico por tipo de acción (`CREATE`, `UPDATE`, `RESET`, `DEACTIVATE`, `DELETE`).
/// - Presentación adaptable: tabla detallada con marcas de tiempo y metadatos en pantallas amplias, y tarjetas compactas en móviles.
/// - Los registros son estrictamente inmutables y de solo lectura.
class AuditLogView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de los registros de auditoría y sus filtros.
  final GovernanceViewModel viewModel;

  /// Constructor de la vista de registro de auditoría.
  const AuditLogView({
    super.key,
    required this.viewModel,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return ResponsiveLayout(
          builder: (context, breakpoint) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(breakpoint.isCompact ? 12.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, viewModel, l10n, breakpoint),
                  const SizedBox(height: 16.0),

                  if (viewModel.isLoadingAudit)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (viewModel.auditError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              viewModel.auditFailure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
                                  viewModel.auditError!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                            const SizedBox(height: 8.0),
                            ElevatedButton(
                              onPressed: viewModel.loadAuditLogs,
                              child: Text(l10n?.govButtonRefresh ?? ''),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (viewModel.filteredAuditLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          l10n?.govAuditLogEmpty ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    )
                  else
                    breakpoint.isCompact
                        ? _buildAuditCards(context, viewModel.filteredAuditLogs, l10n)
                        : _buildAuditTable(context, viewModel.filteredAuditLogs, l10n),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GovernanceViewModel viewModel,
    AppLocalizations? l10n,
    AppBreakpoint breakpoint,
  ) {
    final actions = viewModel.availableAuditActions;

    final filterDropdown = DropdownButtonFormField<String>(
      key: const Key('audit_action_filter'),
      initialValue: viewModel.auditActionFilter,
      decoration: InputDecoration(
        labelText: l10n?.govAuditFilterAction ?? '',
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      ),
      items: [
        DropdownMenuItem(
          value: 'ALL',
          child: Text(l10n?.govAuditAllActions ?? ''),
        ),
        ...actions.map((act) => DropdownMenuItem(value: act, child: Text(act))),
      ],
      onChanged: (val) {
        if (val != null) viewModel.setAuditActionFilter(val);
      },
    );

    final refreshButton = SizedBox(
      height: 48.0,
      child: OutlinedButton.icon(
        key: const Key('refresh_audit_logs_button'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(140.0, 48.0),
        ),
        onPressed: viewModel.isLoadingAudit ? null : viewModel.loadAuditLogs,
        icon: const Icon(Icons.refresh),
        label: Text(l10n?.govButtonRefresh ?? ''),
      ),
    );

    if (breakpoint.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterDropdown,
          const SizedBox(height: 12.0),
          refreshButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: filterDropdown),
        const SizedBox(width: 16.0),
        refreshButton,
      ],
    );
  }

  Widget _buildAuditCards(
    BuildContext context,
    List<AuditLogEntry> logs,
    AppLocalizations? l10n,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Column(
      children: logs.map((log) {
        final formattedDate = log.createdAt != null
            ? dateFormat.format(log.createdAt!)
            : '—';

        return Card(
          key: Key('audit_card_${log.id}'),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionChip(log.action),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${log.actorName} (${log.actorRole})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${log.targetType}: ${log.targetId}',
                  style: TextStyle(
                    fontSize: 13.0,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (log.metadata.isNotEmpty) ...[
                  const Divider(height: 16.0),
                  Text(
                    log.metadata.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAuditTable(
    BuildContext context,
    List<AuditLogEntry> logs,
    AppLocalizations? l10n,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n?.govAuditColumnDate ?? '')),
            DataColumn(label: Text(l10n?.govAuditColumnActor ?? '')),
            DataColumn(label: Text(l10n?.govAuditColumnAction ?? '')),
            DataColumn(label: Text(l10n?.govAuditColumnTarget ?? '')),
            DataColumn(label: Text(l10n?.govAuditColumnMetadata ?? '')),
          ],
          rows: logs.map((log) {
            final formattedDate = log.createdAt != null
                ? dateFormat.format(log.createdAt!)
                : '—';
            final actorLabel = '${log.actorName}\n(${log.actorRole})';
            final targetLabel = '${log.targetType}\n${log.targetId}';

            return DataRow(
              key: ValueKey('audit_row_${log.id}'),
              cells: [
                DataCell(Text(formattedDate)),
                DataCell(Text(actorLabel)),
                DataCell(_buildActionChip(log.action)),
                DataCell(Text(targetLabel)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300.0),
                    child: Text(
                      log.metadata.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.0),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionChip(String action) {
    Color color;
    if (action.contains('CREATE')) {
      color = Colors.teal;
    } else if (action.contains('UPDATE')) {
      color = Colors.blue;
    } else if (action.contains('RESET')) {
      color = Colors.indigo;
    } else if (action.contains('DEACTIVATE')) {
      color = Colors.orange;
    } else if (action.contains('DELETE')) {
      color = Colors.red;
    } else {
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
