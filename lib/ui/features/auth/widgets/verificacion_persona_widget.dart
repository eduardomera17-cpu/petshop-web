// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/auth/widgets/verificacion_persona_widget.dart
// Propósito: Widget interactivo de casilla de verificación reCAPTCHA Enterprise Checkbox (renderizado DOM en Web).
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mipetshop/data/services/recaptcha_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Widget oficial que materializa la casilla interactiva de reCAPTCHA Enterprise.
///
/// En la Web (entorno de producción), renderiza el contenedor DOM y delega en
/// [RecaptchaService.renderCheckbox] la renderización del widget oficial de Google reCAPTCHA Enterprise.
///
/// Estados y eventos:
/// - [onTokenChanged]: Emitido cuando la casilla es marcada y superada, entregando el token emitido.
/// - [onExpired]: Emitido cuando el token expira (2 minutos), deshabilitando el botón.
/// - [onError]: Emitido cuando la red o el servicio fallan.
class VerificacionPersonaWidget extends StatefulWidget {
  /// Callback notificado cuando se genera un token de verificación exitoso o se limpia el estado.
  final ValueChanged<String?> onTokenChanged;

  /// Callback invocado cuando el token de verificación expira tras su ventana de validez.
  final VoidCallback onExpired;

  /// Callback notificado ante errores de comunicación o fallos en el servicio de reCAPTCHA.
  final VoidCallback onError;

  /// Servicio de reCAPTCHA Enterprise (por defecto, el servicio oficial).
  final RecaptchaService? recaptchaService;

  /// Determina si la casilla de verificación se encuentra habilitada para interacción.
  final bool isEnabled;

  /// Constructor del widget de verificación de persona.
  const VerificacionPersonaWidget({
    super.key,
    required this.onTokenChanged,
    required this.onExpired,
    required this.onError,
    this.recaptchaService,
    this.isEnabled = true,
  });

  @override
  State<VerificacionPersonaWidget> createState() => _VerificacionPersonaWidgetState();
}

class _VerificacionPersonaWidgetState extends State<VerificacionPersonaWidget> {
  /// Contador estático global para generar identificadores DOM únicos por instancia.
  static int _instanceCounter = 0;

  /// Identificador único del nodo HTML contenedor de reCAPTCHA Enterprise en el DOM.
  late final String _containerId;

  /// Nombre del tipo de vista registrado en la factoría de elementos de Flutter Web.
  late final String _viewType;

  /// Bandera que previene reinvocaciones duplicadas de renderizado del script reCAPTCHA.
  bool _isRendered = false;

  /// Estado booleano que indica si la verificación humana fue completada exitosamente.
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    final id = ++_instanceCounter;
    _containerId = 'recaptcha-enterprise-checkbox-$id';
    _viewType = 'recaptcha-view-$id';

    if (kIsWeb) {
      RecaptchaService.registerViewFactory(_viewType, _containerId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _renderOfficialCheckbox();
      });
    }
  }

  void _renderOfficialCheckbox() {
    if (_isRendered || !mounted) return;
    _isRendered = true;
    final service = widget.recaptchaService ?? RecaptchaService();
    service.renderCheckbox(
      containerId: _containerId,
      onVerified: (token) {
        if (!mounted) return;
        setState(() {
          _isVerified = true;
        });
        widget.onTokenChanged(token);
      },
      onExpired: () {
        if (!mounted) return;
        setState(() {
          _isVerified = false;
        });
        widget.onExpired();
      },
      onError: () {
        if (!mounted) return;
        setState(() {
          _isVerified = false;
        });
        widget.onError();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checkboxLabel = l10n?.verificationCheckboxLabel ?? '';

    // La casilla oficial de reCAPTCHA solo existe en Flutter Web.
    if (!kIsWeb) return const SizedBox.shrink();

    return Semantics(
      label: checkboxLabel,
      checked: _isVerified,
      child: SizedBox(
        height: 78.0,
        width: 304.0,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }

  /// Método para reiniciar la casilla externamente (ej. expiración o reintento).
  void reset() {
    if (!mounted) return;
    setState(() {
      _isVerified = false;
    });
    final service = widget.recaptchaService ?? RecaptchaService();
    service.resetCheckbox();
    widget.onTokenChanged(null);
  }
}
