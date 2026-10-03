// functions/src/domain/clock.js
// Reloj y fechas de negocio en zona horaria oficial America/Guayaquil (TRD §1.3.5, N-12, ADR-010)
// Implementación pura sin dependencias externas usando Intl nativo de Node.js.

export const BUSINESS_TIMEZONE = 'America/Guayaquil';

const businessDateFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: BUSINESS_TIMEZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/**
 * Retorna la fecha actual como objeto Date.
 * @returns {Date}
 */
export function getNow() {
  return new Date();
}

/**
 * Retorna la fecha actual del negocio en formato canónico 'YYYY-MM-DD' (TRD §1.3.5, N-12).
 * @returns {string}
 */
export function todayBusinessDate() {
  return toBusinessDate(getNow());
}

/**
 * Convierte un objeto Date o instante a la fecha calendario del negocio en 'YYYY-MM-DD'.
 * @param {Date|number|string} date
 * @returns {string}
 */
export function toBusinessDate(date) {
  const d = date instanceof Date ? date : new Date(date);
  if (isNaN(d.getTime())) {
    throw new TypeError('Fecha inválida para toBusinessDate.');
  }
  return businessDateFormatter.format(d);
}

/**
 * Evalúa si una fecha 'YYYY-MM-DD' es estrictamente posterior a la fecha actual del negocio.
 * @param {string} dateString
 * @returns {boolean}
 */
export function isFutureBusinessDate(dateString) {
  if (typeof dateString !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
    throw new TypeError('dateString debe ser una cadena con formato YYYY-MM-DD.');
  }
  return dateString.localeCompare(todayBusinessDate()) > 0;
}

/**
 * Evalúa si una fecha 'YYYY-MM-DD' es anterior a la fecha actual del negocio.
 * @param {string} dateString
 * @returns {boolean}
 */
export function isPastBusinessDate(dateString) {
  if (typeof dateString !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
    throw new TypeError('dateString debe ser una cadena con formato YYYY-MM-DD.');
  }
  return dateString.localeCompare(todayBusinessDate()) < 0;
}
