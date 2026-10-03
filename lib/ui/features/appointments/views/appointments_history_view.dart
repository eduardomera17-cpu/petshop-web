// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/appointments_history_view.dart
// Propósito: Vista de consulta histórica y gestión de citas del cliente, estructurada en pestañas activas y pasadas con soporte de cancelación y paginación por cursor.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/appointments/view_models/history_view_model.dart';
import 'package:mipetshop/ui/features/appointments/views/cancel_dialog.dart';

/// Interfaz gráfica para la visualización del historial y estado de citas del usuario cliente.
///
/// Organiza las solicitudes de atención en dos pestañas diferenciadas:
/// 1. «Próximas»: Citas programadas vigentes en estado PENDING o CONFIRMED.
/// 2. «Pasadas»: Historial de servicios en estado COMPLETED o CANCELLED.
///
/// Presenta para cada registro la fecha, franja horaria asignada, servicio veterinario/estético,
/// mascota receptora, estado actual y el desglose financiero del importe base y precio final
/// con impuestos congelados en el momento de la confirmación.
///
/// Reglas de negocio e invariantes del sistema:
/// - Se prohíbe taxativamente la reprogramación directa desde el perfil del cliente.
/// - Ocultamiento estricto de identificadores internos de conflicto de franja.
/// - Operación de cancelación restringida únicamente a citas activas no completadas.
class AppointmentsHistoryView extends StatefulWidget {
  /// Modelo de vista que suministra la lista reactiva de citas y gestiona la paginación.
  final HistoryViewModel viewModel;

  /// Callback opcional invocado al presionar la acción flotante de creación de nueva cita.
  final VoidCallback? onNavigateToBooking;

  /// Constructor principal de la vista de historial de citas.
  const AppointmentsHistoryView({
    super.key,
    required this.viewModel,
    this.onNavigateToBooking,
  });

  @override
  State<AppointmentsHistoryView> createState() => _AppointmentsHistoryViewState();
}

/// Estado mutable y controlador de pestañas de [AppointmentsHistoryView].
///
/// Implementa [SingleTickerProviderStateMixin] para gobernar las animaciones de transición
/// entre pestañas de citas próximas e históricas.
class _AppointmentsHistoryViewState extends State<AppointmentsHistoryView>
    with SingleTickerProviderStateMixin {
  /// Controlador de navegación por pestañas de la interfaz.
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicialización del controlador con 2 pestañas y suscripción al cambio de índice
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.viewModel.setSelectedTab(
          _tabController.index == 0 ? HistoryTab.upcoming : HistoryTab.past,
        );
      }
    });

    // Carga inicial reactiva de citas si la colección se encuentra vacía
    if (widget.viewModel.allAppointments.isEmpty) {
      widget.viewModel.loadInitialAppointments();
    }
  }

  @override
  void dispose() {
    // Liberación del controlador de pestañas
    _tabController.dispose();
    super.dispose();
  }

  /// Despliega el diálogo modal de confirmación de cancelación para una cita específica.
  void _openCancelDialog(Appointment appointment) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelDialog(
        appointment: appointment,
        repository: widget.viewModel.repository,
        onConfirmCancel: (apptId) => widget.viewModel.cancelAppointment(apptId),
      ),
    );
  }

  /// Retorna la etiqueta textual internacionalizada para el estado de la cita.
  String _getStatusText(String status, AppLocalizations? l10n) {
    return switch (status) {
      'CONFIRMED' => l10n?.appointmentStatusConfirmed ?? '',
      'PENDING' => l10n?.appointmentStatusPending ?? '',
      'COMPLETED' => l10n?.appointmentStatusCompleted ?? '',
      'CANCELLED' => l10n?.appointmentStatusCancelled ?? '',
      _ => status,
    };
  }

  /// Retorna el distintivo visual con el color semántico correspondiente según el sistema de diseño SaaS.
  Widget _buildStatusBadge(String status, AppLocalizations? l10n) {
    final text = _getStatusText(status, l10n);
    return switch (status) {
      'CONFIRMED' => StatusBadge.success(text: text),
      'PENDING' => StatusBadge.warning(text: text),
      'COMPLETED' => StatusBadge.info(text: text),
      'CANCELLED' => StatusBadge.danger(text: text),
      _ => StatusBadge.neutral(text: text),
    };
  }

  /// Construye la lista desplazable de tarjetas de citas para la pestaña activa.
  Widget _buildAppointmentList(
    BuildContext context,
    List<Appointment> appointments, {
    required bool isUpcoming,
    required AppLocalizations? l10n,
  }) {
    if (widget.viewModel.isLoading && widget.viewModel.allAppointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.viewModel.errorMessage != null &&
        widget.viewModel.allAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            widget.viewModel.errorMessage!,
            style: TextStyle(color: Colors.red.shade800),
          ),
        ),
      );
    }

    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            isUpcoming
                ? (l10n?.noUpcomingAppointments ?? '')
                : (l10n?.noPastAppointments ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15.0),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: appointments.length + (widget.viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == appointments.length) {
          // Botón de paginación por cursor
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: widget.viewModel.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TappableArea(
                      semanticLabel: l10n?.loadMoreAppointmentsAction ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => widget.viewModel.loadMoreAppointments(),
                      child: OutlinedButton(
                        onPressed: () => widget.viewModel.loadMoreAppointments(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(160.0, 48.0),
                        ),
                        child: Text(l10n?.loadMoreAppointmentsAction ?? ''),
                      ),
                    ),
            ),
          );
        }

        final appointment = appointments[index];
        final canCancel =
            appointment.status == 'PENDING' || appointment.status == 'CONFIRMED';

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
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
                // Fila 1: Fecha/Hora y Badge de Estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.event, size: 20.0, color: Colors.blue.shade700),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        '${appointment.dateString} - ${appointment.timeSlot}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    _buildStatusBadge(appointment.status, l10n),
                  ],
                ),
                const Divider(height: 20.0),

                // Fila 2: Servicio y Mascota
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 18.0, color: Colors.grey.shade700),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        appointment.serviceName,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Row(
                  children: [
                    Icon(Icons.pets, size: 18.0, color: Colors.grey.shade700),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        '${l10n?.appointmentPetLabel ?? ''}: ${appointment.petName}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Fila 3: Desglose de Precios
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.appointmentBasePrice(
                              formatCents(appointment.basePriceCents),
                            ) ?? '',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        l10n?.appointmentFinalPriceWithTaxes(
                              formatCents(appointment.finalPriceCents),
                            ) ?? '',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fila 4: Acción de Cancelación
                if (canCancel) ...[
                  const SizedBox(height: 12.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TappableArea(
                      semanticLabel: l10n?.cancelAppointmentAction ?? '',
                      minConstraints:
                          const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => _openCancelDialog(appointment),
                      child: OutlinedButton.icon(
                        key: Key('cancel_button_${appointment.id}'),
                        onPressed: () => _openCancelDialog(appointment),
                        icon: const Icon(Icons.cancel_outlined, size: 18.0),
                        label: Text(l10n?.cancelAppointmentAction ?? ''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade400),
                          minimumSize: const Size(130.0, 48.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upcomingTabLabel = l10n?.upcomingAppointmentsTab ?? '';
    final pastTabLabel = l10n?.pastAppointmentsTab ?? '';

    // Estructura visual con barra de navegación superior, pestañas y botón flotante de reserva
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appointmentsHistoryTitle ?? ''),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              key: const Key('tab_upcoming'),
              text: upcomingTabLabel,
            ),
            Tab(
              key: const Key('tab_past'),
              text: pastTabLabel,
            ),
          ],
        ),
      ),
      floatingActionButton: widget.onNavigateToBooking != null
          ? TappableArea(
              semanticLabel: l10n?.bookingTitle ?? '',
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: widget.onNavigateToBooking,
              child: FloatingActionButton.extended(
                key: const Key('book_appointment_fab'),
                onPressed: widget.onNavigateToBooking,
                icon: const Icon(Icons.add),
                label: Text(l10n?.bookingTitle ?? ''),
              ),
            )
          : null,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(
                context,
                widget.viewModel.upcomingAppointments,
                isUpcoming: true,
                l10n: l10n,
              ),
              _buildAppointmentList(
                context,
                widget.viewModel.pastAppointments,
                isUpcoming: false,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}
