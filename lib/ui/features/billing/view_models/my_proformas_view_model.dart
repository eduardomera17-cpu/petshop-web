// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: my_proformas_view_model.dart
// Propósito: ViewModel para la visualización de proformas del cliente y descarga segura de comprobantes PDF en memoria binaria.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/domain/models/proforma.dart';

/// ViewModel para la visualización del listado de proformas del cliente y descarga de PDF.
///
/// Escucha en tiempo real las cotizaciones emitidas a nombre del cliente autenticado
/// excluyendo borradores internos y permite descargar el archivo PDF tributario
/// directamente en memoria mediante almacenamiento autenticado sin links públicos de descarga.
class MyProformasViewModel extends ChangeNotifier {
  /// Repositorio de consulta y descarga de proformas.
  final ProformasRepository repository;

  /// Identificador único del cliente autenticado.
  final String clientId;

  List<Proforma> _proformas = [];
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  Failure? _failure;
  Failure? get failure => _failure;
  Uint8List? _downloadedPdfBytes;
  String? _downloadedProformaId;

  StreamSubscription<List<Proforma>>? _proformasSub;

  /// Constructor con inyección de repositorio y cliente.
  MyProformasViewModel({
    required this.repository,
    required this.clientId,
  });

  /// Lista reactiva de proformas visibles para el cliente.
  List<Proforma> get proformas => _proformas;

  /// Indica si el listado inicial de proformas se encuentra cargando.
  bool get isLoading => _isLoading;

  /// Indica si hay una descarga de documento PDF en ejecución.
  bool get isDownloading => _isDownloading;

  /// Mensaje de error para despliegue en interfaz.
  String? get errorMessage => _errorMessage;

  /// Bytes del comprobante PDF descargado más recientemente en memoria.
  Uint8List? get downloadedPdfBytes => _downloadedPdfBytes;

  /// Identificador de la proforma a la que corresponden los bytes en [_downloadedPdfBytes].
  String? get downloadedProformaId => _downloadedProformaId;

  /// Inicializa la escucha reactiva de proformas del cliente desde Firestore.
  void init() {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    unawaited(_proformasSub?.cancel());
    _proformasSub = repository.streamClientProformas(clientId).listen(
      (items) {
        _proformas = items;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
      },
      onError: (Object err) {
        _isLoading = false;
        _failure = Failure.fromException(err);
        _errorMessage = err is String ? err : _failure?.code;
        notifyListeners();
      },
    );
  }

  /// Descarga el PDF de la proforma en memoria mediante almacenamiento autenticado en Firebase Storage.
  ///
  /// Valida la existencia de [proforma.pdfStoragePath] y utiliza [ProformasRepository.downloadProformaPdf].
  Future<bool> downloadPdf(Proforma proforma) async {
    if (proforma.pdfStoragePath == null || proforma.pdfStoragePath!.isEmpty) {
      _failure = const DomainFailure(code: 'PDF_NOT_AVAILABLE');
      _errorMessage = 'PDF_NOT_AVAILABLE';
      notifyListeners();
      return false;
    }

    _isDownloading = true;
    _errorMessage = null;
    _failure = null;
    _downloadedPdfBytes = null;
    _downloadedProformaId = null;
    notifyListeners();

    final res = await repository.downloadProformaPdf(proforma.pdfStoragePath!);

    _isDownloading = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code ?? 'DOWNLOAD_FAILED';
      notifyListeners();
      return false;
    }

    _downloadedPdfBytes = res.dataOrNull;
    _downloadedProformaId = proforma.id;
    notifyListeners();
    return true;
  }

  /// Cancela la suscripción al flujo de proformas de Firestore al destruirse el ViewModel.
  @override
  void dispose() {
    _proformasSub?.cancel();
    super.dispose();
  }
}
