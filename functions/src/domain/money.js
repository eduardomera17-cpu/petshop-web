// functions/src/domain/money.js
// Representación monetaria y redondeo medio-arriba normativo (TRD §1.3.5, §2.1, D-T2, FA-09)

/**
 * Redondeo al entero más próximo con medio punto hacia arriba (half-up).
 * En concordancia con TRD §3.3.A: roundHalfUp(x) = floor(x + 0.5),
 * preservando idéntico comportamiento en números positivos y negativos.
 *
 * @param {number|string} x
 * @returns {number}
 */
export function roundHalfUp(x) {
  const num = Number(x);
  if (Number.isNaN(num)) {
    throw new TypeError('El valor a redondear debe ser un número válido.');
  }
  return Math.floor(num + 0.5);
}

/**
 * Convierte un importe decimal en dólares a céntimos enteros con redondeo medio-arriba.
 * Queda prohibido mantener importes como float/double en modelos, DTOs o Firestore (D-T2).
 *
 * @param {number|string} amount
 * @returns {number}
 */
export function toCents(amount) {
  const num = Number(amount);
  if (Number.isNaN(num)) {
    throw new TypeError('El importe a convertir debe ser un número válido.');
  }
  return roundHalfUp(num * 100);
}

/**
 * Formatea una cantidad en céntimos a representación estándar de dos decimales.
 *
 * @param {number} cents
 * @returns {string}
 */
export function formatCents(cents) {
  if (typeof cents !== 'number' || !Number.isInteger(cents)) {
    throw new TypeError('Los céntimos deben ser un número entero.');
  }
  const isNegative = cents < 0;
  const absCents = Math.abs(cents);
  const dollars = Math.floor(absCents / 100);
  const remainder = absCents % 100;
  const formatted = `${dollars}.${remainder.toString().padStart(2, '0')}`;
  return isNegative ? `-${formatted}` : formatted;
}

/**
 * Calcula el importe de impuesto sobre una base en céntimos dado el porcentaje en puntos básicos.
 * (ej. 1500 puntos básicos = 15.00%).
 *
 * @param {number} baseCents
 * @param {number} taxBp
 * @returns {number}
 */
export function calculateTax(baseCents, taxBp) {
  if (typeof baseCents !== 'number' || !Number.isInteger(baseCents)) {
    throw new TypeError('La base imponible debe ser un número entero en céntimos.');
  }
  if (typeof taxBp !== 'number' || !Number.isInteger(taxBp)) {
    throw new TypeError('El porcentaje impositivo debe ser un número entero en puntos básicos.');
  }
  return roundHalfUp((baseCents * taxBp) / 10000);
}
