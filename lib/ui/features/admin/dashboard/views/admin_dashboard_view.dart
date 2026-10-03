// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/dashboard/views/admin_dashboard_view.dart
// Propósito: Panel de control administrativo con métricas operativas clave, atajos de teclado globales y modo de tolerancia a degradación.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/core/shortcuts/admin_shortcuts.dart';
import 'package:mipetshop/ui/features/admin/dashboard/view_models/admin_dashboard_view_model.dart';

/// Panel principal de control gerencial y monitoreo operativo para administradores.
///
/// Características y capacidades:
/// - Tarjetas de métricas agregadas en tiempo real: citas del día, solicitudes pendientes,
///   conceptos por facturar, productos con stock bajo, conversaciones no leídas y clientes activos.
/// - Detección de latencia y estado degradado (ADR-020): alerta visual informativa en caso de timeout
///   o indisponibilidad temporal del backend sin bloquear la interfaz.
/// - Sistema de atajos de teclado accesibles [AdminShortcuts] para navegación rápida.
/// - Cuadrícula interactiva responsiva que adapta el número de columnas al ancho del dispositivo.
class AdminDashboardView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de las métricas agregadas y su refresco.
  final AdminDashboardViewModel viewModel;

  /// Constructor de la vista de dashboard administrativo.
  const AdminDashboardView({
    super.key,
    required this.viewModel,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminShortcuts(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n?.navAdmin ?? ''),
          actions: [
            TappableArea(
              key: const Key('dashboard_shortcuts_help_btn'),
              tooltip: l10n?.dashboardShortcutsTooltip ?? '',
              semanticLabel: l10n?.dashboardShortcutsSemantic ?? '',
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: () => AdminShortcuts.showHelpModal(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(Icons.help_outline),
              ),
            ),
            TappableArea(
              key: const Key('dashboard_refresh_btn'),
              tooltip: l10n?.dashboardRefreshTooltip ?? '',
              semanticLabel: l10n?.dashboardRefreshSemantic ?? '',
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: viewModel.loadMetrics,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(Icons.refresh),
              ),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            if (viewModel.isLoading && viewModel.metrics.todayAppointmentsCount == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            return ResponsiveLayout(
              builder: (context, breakpoint) {
                final crossAxisCount = breakpoint.isCompact
                    ? 1
                    : breakpoint.isMedium
                        ? 2
                        : 3;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner de Estado Degradado o DEADLINE_EXCEEDED (ADR-020, AD-02)
                      if (viewModel.isDegraded) ...[
                        Container(
                          key: const Key('dashboard_degraded_banner'),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  viewModel.degradationMessage ??
                                      'Tiempo de respuesta excedido (DEADLINE_EXCEEDED). Datos presentados en estado degradado.',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (viewModel.errorMessage != null && !viewModel.isDegraded) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade700),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade900),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  viewModel.failure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
                                      viewModel.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Grid con las 6 Tarjetas Métricas
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: breakpoint.isCompact ? 2.2 : 1.8,
                        children: [
                          _MetricCard(
                            key: const Key('metric_card_today_appointments'),
                            title: 'Citas de hoy',
                            value: viewModel.metrics.todayAppointmentsCount.toString(),
                            icon: Icons.calendar_today,
                            color: Colors.blue.shade700,
                            onTap: () => context.go('/admin/agenda'),
                          ),
                          _MetricCard(
                            key: const Key('metric_card_pending_appointments'),
                            title: 'Citas pendientes',
                            value: viewModel.metrics.pendingAppointmentsCount.toString(),
                            icon: Icons.pending_actions,
                            color: Colors.indigo.shade700,
                            onTap: () => context.go('/admin/agenda'),
                          ),
                          _MetricCard(
                            key: const Key('metric_card_pending_requests'),
                            title: 'Solicitudes pendientes',
                            value: viewModel.metrics.pendingRequestsCount.toString(),
                            icon: Icons.assignment_late_outlined,
                            color: Colors.teal.shade700,
                            onTap: () => context.go('/admin/requests'),
                          ),
                          _MetricCard(
                            key: const Key('metric_card_monthly_clients'),
                            title: 'Clientes del mes',
                            value: viewModel.metrics.monthlyClientsCount.toString(),
                            icon: Icons.person_add_alt_1,
                            color: Colors.purple.shade700,
                            onTap: () => context.go('/admin/clients'),
                          ),
                          _MetricCard(
                            key: const Key('metric_card_low_stock'),
                            title: 'Stock bajo',
                            value: viewModel.metrics.lowStockProductsCount.toString(),
                            icon: Icons.inventory_2_outlined,
                            color: Colors.orange.shade800,
                            onTap: () => context.go('/admin/inventory'),
                          ),
                          _MetricCard(
                            key: const Key('metric_card_conflicts'),
                            title: 'Citas en conflicto',
                            value: viewModel.metrics.conflictedAppointmentsCount.toString(),
                            icon: Icons.event_busy,
                            color: Colors.red.shade700,
                            onTap: () => context.go('/admin/agenda'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Tarjeta interactiva de presentación de métrica estadística en el panel administrativo.
class _MetricCard extends StatelessWidget {
  /// Título o etiqueta descriptiva de la métrica operativa.
  final String title;

  /// Valor numérico formateado de la métrica (ej. recuento o porcentaje).
  final String value;

  /// Ícono representativo de la dimensión analítica.
  final IconData icon;

  /// Color temático de acento visual para el valor y el ícono.
  final Color color;

  /// Retrollamada ejecutada al presionar la tarjeta para navegar al submódulo correspondiente.
  final VoidCallback onTap;

  /// Constructor de la tarjeta de métrica de dashboard.
  const _MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: TappableArea(
        tooltip: l10n?.dashboardMetricDetailTooltip(title) ?? '',
        semanticLabel: l10n?.dashboardMetricSemantic(title, value) ?? '',
        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color, size: 28.0),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
