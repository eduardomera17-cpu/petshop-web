// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/core/widgets/status_badge.dart
// Propósito: Componente visual para la presentación de estados mediante distintivos coloreados (chips/badges) del sistema de diseño SaaS.
// =========================================================================

import 'package:flutter/material.dart';

/// Tipología semántica del distintivo de estado conforme a la guía de estilos de Interfaz.pdf.
enum StatusBadgeType {
  /// Verde: Activo, Confirmada, Retirada, Entregada.
  success,

  /// Naranja/Ámbar: Pendiente, Borrador, Pendiente de despacho.
  warning,

  /// Rojo: Cancelada, Desactivado, Bloqueado.
  danger,

  /// Azul/Cian: Disponible, Finalizada, Clínico.
  info,

  /// Gris neutro: No clínico, Cerrada, Genérico.
  neutral,
}

/// Distintivo visual reutilizable para estados de entidades (citas, pedidos, cuentas, servicios, etc.).
class StatusBadge extends StatelessWidget {
  /// Texto descriptivo localizado a mostrar.
  final String text;

  /// Tipo semántico de color del distintivo.
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
  });

  const StatusBadge.success({super.key, required this.text})
      : type = StatusBadgeType.success;

  const StatusBadge.warning({super.key, required this.text})
      : type = StatusBadgeType.warning;

  const StatusBadge.danger({super.key, required this.text})
      : type = StatusBadgeType.danger;

  const StatusBadge.info({super.key, required this.text})
      : type = StatusBadgeType.info;

  const StatusBadge.neutral({super.key, required this.text})
      : type = StatusBadgeType.neutral;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    switch (type) {
      case StatusBadgeType.success:
        bgColor = const Color(0xFFDEF7EC);
        textColor = const Color(0xFF03543F);
        borderColor = const Color(0xFFBCF0DA);
        break;
      case StatusBadgeType.warning:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        borderColor = const Color(0xFFFDE68A);
        break;
      case StatusBadgeType.danger:
        bgColor = const Color(0xFFFDE8E8);
        textColor = const Color(0xFF9B1C1C);
        borderColor = const Color(0xFFFBD5D5);
        break;
      case StatusBadgeType.info:
        bgColor = const Color(0xFFE1EFFE);
        textColor = const Color(0xFF1E429F);
        borderColor = const Color(0xFFC3DDFD);
        break;
      case StatusBadgeType.neutral:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF374151);
        borderColor = const Color(0xFFE5E7EB);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
