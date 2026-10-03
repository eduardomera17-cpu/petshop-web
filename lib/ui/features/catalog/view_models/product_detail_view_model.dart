// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/view_models/product_detail_view_model.dart
// Propósito: ViewModel del detalle individual de producto, cálculo impositivo
//            y emisión de solicitud de reserva con clave de idempotencia temporal.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/limits.dart' as limits;
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/domain/models/product.dart';

/// Gestor de estado para la pantalla de detalle de un producto específico.
///
/// Permite al cliente inspeccionar la información de un producto, modificar la cantidad
/// deseada dentro de los límites del negocio, visualizar el desglose impositivo en tiempo
/// real y emitir la solicitud de reserva con clave de idempotencia generada mediante [BusinessClock].
class ProductDetailViewModel extends ChangeNotifier {
  /// Cantidad mínima de compra por solicitud.
  static const int minRequestQuantity = 1;

  /// Cantidad máxima de compra por solicitud permitida por el sistema.
  static const int maxRequestQuantity = limits.maxRequestQuantity;

  /// Información del producto a detallar.
  final Product product;

  /// Repositorio para la creación y gestión de solicitudes de productos.
  final ProductRequestsRepository requestsRepository;

  /// Parámetros impositivos vigentes aplicables al producto.
  final PublicPricingConfig pricingConfig;

  int _quantity = 1;
  bool _isSubmitting = false;
  String? _errorMessage;
  Failure? _errorFailure;
  String? _successRequestId;

  /// Construye una instancia del ViewModel con el producto seleccionado y dependencias.
  ProductDetailViewModel({
    required this.product,
    required this.requestsRepository,
    required this.pricingConfig,
  });

  /// Cantidad de unidades seleccionada actualmente.
  int get quantity => _quantity;

  /// Indica si la solicitud de reserva está siendo procesada en el backend.
  bool get isSubmitting => _isSubmitting;

  /// Mensaje o código de error en caso de fallo durante el envío.
  String? get errorMessage => _errorMessage;

  /// Objeto de falla detallado reportado por el repositorio.
  Failure? get errorFailure => _errorFailure;

  /// Identificador asignado por el backend tras registrar la solicitud con éxito.
  String? get successRequestId => _successRequestId;

  /// Determina si el producto cuenta con existencias disponibles para reserva.
  bool get isAvailable => product.stock > 0;

  /// Determina si el producto grava Impuesto a los Consumos Especiales (ICE).
  bool get hasIce => product.iceBp > 0;

  /// Establece un valor arbitrario de cantidad respetando los rangos permitidos.
  void setQuantity(int value) {
    if (value < minRequestQuantity || value > maxRequestQuantity) return;
    if (_quantity == value) return;
    _quantity = value;
    notifyListeners();
  }

  /// Incrementa en uno la cantidad de unidades seleccionadas.
  void incrementQuantity() {
    if (_quantity < maxRequestQuantity) {
      _quantity++;
      notifyListeners();
    }
  }

  /// Decrementa en uno la cantidad de unidades seleccionadas.
  void decrementQuantity() {
    if (_quantity > minRequestQuantity) {
      _quantity--;
      notifyListeners();
    }
  }

  /// Retorna el desglose financiero e impositivo unitario para el producto.
  LinePricingResult get pricingBreakdown {
    return calculateLinePricing(
      basePriceCents: product.basePriceCents,
      iceBp: product.iceBp,
      ivaBp: pricingConfig.ivaBp,
      iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
    );
  }

  /// Calcula el precio final total en centavos multiplicando el precio final unitario por la cantidad.
  int get totalFinalPriceCents => pricingBreakdown.finalPriceCents * _quantity;

  /// Envía la solicitud de producto con clave de idempotencia generada bajo BusinessClock.
  Future<bool> requestProduct({required String uid}) async {
    if (!isAvailable || _isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    _errorFailure = null;
    notifyListeners();

    final timestamp = BusinessClock.now().millisecondsSinceEpoch;
    final requestId = 'req_${uid}_${product.id}_$timestamp';

    final result = await requestsRepository.createProductRequest(
      items: [
        {
          'productId': product.id,
          'quantity': _quantity,
        },
      ],
      requestId: requestId,
    );

    _isSubmitting = false;

    if (result.isErr) {
      _errorFailure = result.failureOrNull;
      _errorMessage = result.failureOrNull?.code ?? 'ERROR_GENERIC';
      notifyListeners();
      return false;
    }

    _successRequestId = result.dataOrNull;
    notifyListeners();
    return true;
  }
}
