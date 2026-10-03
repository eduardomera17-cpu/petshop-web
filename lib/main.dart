// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/main.dart
// Propósito: Punto de entrada oficial de la aplicación Web PetShop, inicialización
//            de enlaces del framework y orquestación asíncrona de arranque con Bootstrap.
// =========================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mipetshop/app/app.dart';
import 'package:mipetshop/app/bootstrap.dart';
import 'package:mipetshop/data/services/recaptcha_service.dart';

/// Punto de entrada oficial de la aplicación Web PetShop (TRD §1.3.6, N-15).
///
/// Inicializa los enlaces del framework Flutter y ejecuta la configuración
/// perimetral de servicios dentro de un entorno protegido por [runZonedGuarded].
/// Este mecanismo captura cualquier excepción asíncrona no controlada a nivel global,
/// evitando la interrupción del servicio web y resguardando la estabilidad del sistema.
void main() {
  runZonedGuarded(() async {
    // Asegura la correcta inicialización de los servicios de la plataforma web antes de renderizar widgets.
    WidgetsFlutterBinding.ensureInitialized();

    // Carga el SDK de reCAPTCHA Enterprise con la clave de AppConfig (no está fijo en web/index.html).
    // Si no carga (sin red), la aplicación arranca igualmente y reCAPTCHA falla de forma controlada al usarse.
    try {
      await RecaptchaService.loadScript();
    } catch (e) {
      debugPrint('No se pudo cargar el SDK de reCAPTCHA Enterprise: $e');
    }

    // Inicializa la configuración de Firebase, inyección de dependencias y servicios base.
    final bootstrapResult = await bootstrapApp();

    // Lanza la jerarquía principal de widgets de la aplicación web pasando el resultado de inicialización.
    runApp(PetShopApp(bootstrapResult: bootstrapResult));
  }, (Object error, StackTrace stackTrace) {
    // Captura y registro controlado de excepciones críticas no manejadas en tiempo de ejecución (N-15).
    // Previene la exposición de trazas de pila sensibles a los usuarios finales.
    debugPrint('Excepción no controlada capturada en zona de ejecución: $error');
  });
}
