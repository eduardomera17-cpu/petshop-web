// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/limits.dart
// Propósito: Definición de constantes canónicas de topes y límites numéricos operacionales del sistema.
// =========================================================================

/// Tope máximo de productos o líneas distintas permitidas en una sola solicitud (PRD PR-04).
///
/// Mantiene paridad estricta con las reglas de backend en Firebase Functions.
const int maxRequestLines = 50;

/// Tope máximo de unidades permitidas por cada línea individual de producto (ADR-023).
const int maxRequestQuantity = 99;

