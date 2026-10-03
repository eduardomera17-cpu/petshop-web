// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/failures.dart
// Propósito: Jerarquía sellada para la representación, tipado y traducción de fallas y errores de dominio a mensajes localizados para el usuario.
// =========================================================================

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mipetshop/core/limits.dart' as limits;
import 'package:mipetshop/l10n/app_localizations.dart';

/// {@template failure}
/// Representación canónica y sellada de fallas en la capa de dominio (TRD §1.2, §3.6).
///
/// Todas las fallas son inmutables y proveen traducción a mensajes comprensibles para el usuario
/// mediante [toLocalizedMessage], garantizando la regla de diseño N-15 (cero trazas o
/// códigos técnicos en pantalla).
/// {@endtemplate}
sealed class Failure {
  /// Código canónico del error o regla de negocio infringida.
  final String code;

  /// Mensaje técnico opcional para depuración en registros y consola.
  final String? debugMessage;

  /// Mapa opcional de metadatos o detalles complementarios del error.
  final Map<String, Object?>? details;

  const Failure({
    required this.code,
    this.debugMessage,
    this.details,
  });

  /// Traduce el código de error al mensaje localizado para el usuario.
  String toLocalizedMessage(
    AppLocalizations l10n, {
    String? Function(String productId)? productNameOf,
  }) {
    String? resolveProductNames(String errorCode) {
      if (details == null) return null;
      final rawProducts = details!['products'];
      if (rawProducts is! Map) return null;
      final list = rawProducts[errorCode];
      if (list is! List) return null;

      final names = <String>{};
      for (final item in list) {
        if (item is Map) {
          final rawName = item['productName'];
          final pName = rawName is String ? rawName.trim() : null;
          if (pName != null && pName.isNotEmpty) {
            names.add(pName);
          } else {
            final pId = item['productId']?.toString();
            if (pId != null && productNameOf != null) {
              final resolved = productNameOf(pId)?.trim();
              if (resolved != null && resolved.isNotEmpty) {
                names.add(resolved);
              }
            }
          }
        }
      }

      if (names.isEmpty) return null;
      return names.join(', ');
    }

    return switch (code) {
      'SLOT_TAKEN' => l10n.errorSlotTaken,
      'PET_ALREADY_BOOKED_THAT_DAY' => l10n.errorPetAlreadyBookedThatDay,
      'SLOT_BLOCKED' => l10n.errorSlotBlocked,
      'APPOINTMENT_NOT_RESCHEDULABLE' => l10n.errorAppointmentNotReschedulable,
      'PROFORMA_EMPTY' => l10n.errorProformaEmpty,
      'TOO_MANY_ITEMS' => l10n.errorTooManyItems,
      'TOO_MANY_ATTACHMENTS' => l10n.errorTooManyAttachments,
      'DAILY_LIMIT_APPOINTMENTS' => l10n.errorDailyLimitAppointments,
      'DAILY_LIMIT_REQUESTS' => l10n.errorDailyLimitRequests,
      'EMPTY_REQUEST' => l10n.errorEmptyRequest,
      'TOO_MANY_REQUEST_LINES' =>
        l10n.errorTooManyRequestLines(limits.maxRequestLines),
      'DUPLICATE_PRODUCT_LINE' => l10n.errorDuplicateProductLine,
      'INVALID_QUANTITY' =>
        l10n.errorInvalidQuantity(limits.maxRequestQuantity),
      'PRODUCT_NOT_AVAILABLE' => () {
          final names = resolveProductNames('PRODUCT_NOT_AVAILABLE');
          return names != null
              ? l10n.errorProductNotAvailableNamed(names)
              : l10n.errorProductNotAvailable;
        }(),
      'OUT_OF_STOCK' => () {
          final names = resolveProductNames('OUT_OF_STOCK');
          return names != null
              ? l10n.errorOutOfStockNamed(names)
              : l10n.errorOutOfStock;
        }(),
      'INSUFFICIENT_STOCK' => () {
          final names = resolveProductNames('INSUFFICIENT_STOCK');
          return names != null
              ? l10n.errorInsufficientStockNamed(names)
              : l10n.errorInsufficientStock;
        }(),
      'APPOINTMENT_NOT_CANCELLABLE' => l10n.errorAppointmentNotCancellable,
      'ALREADY_CANCELLED' => l10n.errorAlreadyCancelled,
      'PET_NOT_AVAILABLE' => l10n.errorPetNotAvailable,
      'SERVICE_NOT_AVAILABLE' => l10n.errorServiceNotAvailable,
      'CONFIG_UNAVAILABLE' => l10n.errorConfigUnavailable,
      'PET_ALREADY_DEACTIVATED' => l10n.errorPetAlreadyDeactivated,
      'NO_CHANGE' => l10n.errorNoChange,
      'INVALID_TRANSITION' => l10n.errorInvalidTransition,
      'CONCEPT_LOCKED_BY_DELIVERED_PROFORMA' => l10n.errorConceptLockedByDeliveredProforma,
      'PROFORMA_NOT_DRAFT' => l10n.errorProformaNotDraft,
      'PROFORMA_NOT_VOIDABLE' => l10n.errorProformaNotVoidable,
      'DELIVERY_IN_PROGRESS' => l10n.errorDeliveryInProgress,
      'DELIVERY_LEASE_LOST' => l10n.errorDeliveryLeaseLost,
      'CONCEPT_NO_LONGER_VALID' => l10n.errorConceptNoLongerValid,
      'ENTRY_ANNULLED_NOT_EDITABLE' => l10n.errorEntryAnnulledNotEditable,
      'ANNULMENT_NOT_ANNULLABLE' => l10n.errorAnnulmentNotAnnullable,
      'SUPERADMIN_IMMUTABLE' => l10n.errorSuperadminImmutable,
      'ROLE_CHANGE_NOT_SUPPORTED' => l10n.errorRoleChangeNotSupported,
      'REAUTH_REQUIRED' => l10n.errorReauthRequired,
      'ACCOUNT_NOT_ACTIVE' => l10n.errorAccountNotActive,
      'PROFILE_ALREADY_COMPLETE' => l10n.errorProfileAlreadyComplete,
      'ACCOUNT_PROVISIONING_FAILED' => l10n.errorAccountProvisioningFailed,
      'STAFF_REACTIVATION_REQUIRES_SUPERADMIN' => l10n.errorStaffReactivationRequiresSuperadmin,
      'VERIFICATION_REQUIRED' => l10n.errorVerificationRequired,
      'VERIFICATION_FAILED' => l10n.errorVerificationFailed,
      'VERIFICATION_ACTION_MISMATCH' => l10n.errorVerificationActionMismatch,
      'VERIFICATION_HIGH_RISK' => l10n.errorVerificationHighRisk,
      'VERIFICATION_UNAVAILABLE' => l10n.errorVerificationUnavailable,
      'INVALID_STOCK_ADJUSTMENT' => l10n.errorInvalidStockAdjustment,
      'REQUEST_LOCKED_BY_DELIVERED_PROFORMA' => l10n.errorRequestLockedByDeliveredProforma,
      'NETWORK_ERROR' => l10n.errorNetwork,
      'INVALID_CREDENTIALS' => l10n.errorInvalidCredentials,
      // Sala de chat del cliente (CA-70, MC-10 condición 3, N-15).
      'CHAT_BLOCKED' => l10n.errorChatBlocked,
      'CHAT_MESSAGE_EMPTY' => l10n.errorChatMessageEmpty,
      'CHAT_MESSAGE_TOO_LONG' => l10n.errorChatMessageTooLong,
      _ => l10n.errorGeneric,
    };
  }

  /// Transforma cualquier excepción técnica en una [Failure] tipada.
  factory Failure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    if (error is FirebaseFunctionsException) {
      final details = error.details;
      final detailsMap =
          details is Map ? Map<String, Object?>.from(details) : null;
      if (detailsMap != null) {
        final rawCode = detailsMap['errorCode']?.toString();
        if (rawCode != null && rawCode.isNotEmpty) {
          return DomainFailure(
            code: rawCode,
            debugMessage: error.message,
            details: detailsMap,
          );
        }
      }
      return DomainFailure(
        code: error.code,
        debugMessage: error.message,
        details: detailsMap,
      );
    }

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'requires-recent-login' => const AuthFailure(
            code: 'REAUTH_REQUIRED',
            debugMessage: 'Re-authentication required',
          ),
        'user-disabled' => const AuthFailure(
            code: 'ACCOUNT_NOT_ACTIVE',
            debugMessage: 'Account disabled',
          ),
        'network-request-failed' => const NetworkFailure(
            code: 'NETWORK_ERROR',
            debugMessage: 'Network request failed',
          ),
        _ => AuthFailure(code: error.code, debugMessage: error.message),
      };
    }

    return UnexpectedFailure(
      code: 'UNEXPECTED_ERROR',
      debugMessage: error.toString(),
    );
  }

  @override
  String toString() => '$runtimeType(code: $code, debugMessage: $debugMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure &&
          other.code == code &&
          other.debugMessage == debugMessage);

  @override
  int get hashCode => Object.hash(code, debugMessage);
}

/// {@template domain_failure}
/// Falla originada por la violación de una regla de negocio o contrato de backend (TRD §3.6).
/// {@endtemplate}
final class DomainFailure extends Failure {
  const DomainFailure({
    required super.code,
    super.debugMessage,
    super.details,
  });
}

/// {@template auth_failure}
/// Falla originada en el flujo de autenticación, verificación de credenciales o gestión de sesiones.
/// {@endtemplate}
final class AuthFailure extends Failure {
  const AuthFailure({
    required super.code,
    super.debugMessage,
    super.details,
  });
}

/// {@template network_failure}
/// Falla ocasionada por indisponibilidad de conectividad, caída de enlace o latencia excesiva.
/// {@endtemplate}
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.code = 'NETWORK_ERROR',
    super.debugMessage,
    super.details,
  });
}

/// {@template unexpected_failure}
/// Falla no contemplada o excepción no controlada en tiempo de ejecución.
/// {@endtemplate}
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.code = 'UNEXPECTED_ERROR',
    super.debugMessage,
    super.details,
  });
}
