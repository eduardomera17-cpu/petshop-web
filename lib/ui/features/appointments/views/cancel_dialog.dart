// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/cancel_dialog.dart
// Propósito: Diálogo modal de confirmación y ejecución de cancelación de citas por parte del cliente, con control de errores tipados.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Diálogo modal interactivo para la confirmación explícita de cancelación de citas por el cliente.
///
/// Presenta los datos clave de la cita en cuestión (servicio, mascota, fecha y horario)
/// junto con una advertencia sobre la liberación inmediata del cupo en la agenda.
/// Ejecuta la operación transaccional contra la Cloud Function correspondiente vía repositorio
/// o callback inyectado, traduciendo de forma estricta los fallos de dominio (`ALREADY_CANCELLED`,
/// `APPOINTMENT_NOT_CANCELLABLE`, etc.) para una retroalimentación clara sin exponer detalles técnicos.
class CancelDialog extends StatefulWidget {
  /// Entidad de la cita sobre la cual se solicita la cancelación.
  final Appointment appointment;

  /// Repositorio de citas opcional para invocar la operación transaccional directamente.
  final AppointmentsRepository? repository;

  /// Callback delegado opcional para interceptar la confirmación y ejecutar la cancelación.
  final Future<Result<void>> Function(String appointmentId)? onConfirmCancel;

  /// Constructor del diálogo de confirmación de cancelación.
  const CancelDialog({
    super.key,
    required this.appointment,
    this.repository,
    this.onConfirmCancel,
  });

  @override
  State<CancelDialog> createState() => _CancelDialogState();
}

/// Estado mutable de [CancelDialog].
///
/// Gobierna el estado de carga durante la ejecución remota de la cancelación
/// y la captura de errores traducidos para su presentación en banner.
class _CancelDialogState extends State<CancelDialog> {
  /// Bandera que bloquea acciones y muestra el indicador circular durante el procesamiento.
  bool _isCancelling = false;

  /// Mensaje de error traducido para su despliegue en la interfaz si la operación falla.
  String? _errorMessage;

  /// Ejecuta la petición asíncrona de cancelación invocando el callback o el repositorio correspondiente.
  ///
  /// En caso de éxito notifica al usuario con un [SnackBar] y cierra el diálogo retornando `true`.
  /// Ante una falla, traduce el código de error para informar al cliente mediante banner visual.
  Future<void> _executeCancellation() async {
    setState(() {
      _isCancelling = true;
      _errorMessage = null;
    });

    final Result<void> result;
    if (widget.onConfirmCancel != null) {
      result = await widget.onConfirmCancel!(widget.appointment.id);
    } else if (widget.repository != null) {
      result = await widget.repository!.cancelAppointmentByClient(widget.appointment.id);
    } else {
      result = const Err(
        UnexpectedFailure(
          code: 'NO_REPOSITORY',
          debugMessage: 'No repository or callback provided',
        ),
      );
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    if (result.isOk) {
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appointmentCancelledSuccess),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } else {
      final failure = result.failureOrNull;
      final translatedError = (failure != null && l10n != null)
          ? failure.toLocalizedMessage(l10n)
          : (l10n?.errorGeneric ?? '');

      setState(() {
        _isCancelling = false;
        _errorMessage = translatedError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keepText = l10n?.keepAppointmentAction ?? l10n?.cancel ?? '';
    final confirmText = l10n?.confirmCancelAction ?? '';

    return AlertDialog(
      title: Text(l10n?.cancelAppointmentDialogTitle ?? ''),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.appointment.serviceName} - ${widget.appointment.petName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${widget.appointment.dateString} | ${widget.appointment.timeSlot}',
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14.0),
              ),
              const SizedBox(height: 12.0),
              Text(
                l10n?.cancelAppointmentDialogMessage ?? '',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13.0,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16.0),
                Container(
                  key: const Key('cancel_error_banner'),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13.0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TappableArea(
          semanticLabel: keepText,
          tooltip: keepText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: _isCancelling ? null : () => Navigator.of(context).pop(false),
          child: TextButton(
            onPressed: _isCancelling ? null : () => Navigator.of(context).pop(false),
            child: Text(keepText),
          ),
        ),
        TappableArea(
          semanticLabel: confirmText,
          tooltip: confirmText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: _isCancelling ? null : _executeCancellation,
          child: ElevatedButton(
            key: const Key('confirm_cancel_button'),
            onPressed: _isCancelling ? null : _executeCancellation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(120.0, 48.0),
            ),
            child: _isCancelling
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(confirmText),
          ),
        ),
      ],
    );
  }
}
