// functions/src/domain/validators.js
// Validadores unificados de identidad y contacto para registro y perfil (TRD §5.1, §2.2, N-17, N-18, A-01, CA-17, CA-37, CA-38)

import { MAX_REQUEST_LINES, MAX_REQUEST_QUANTITY } from '../config/constants.js';

export const DOCUMENT_TYPES = Object.freeze({
  CEDULA: 'CEDULA',
  PASSPORT: 'PASSPORT',
  RUC: 'RUC',
});

// N-17, CA-37: Prefijo +593 seguido de exactamente 9 dígitos numéricos
export const PHONE_REGEX = /^\+593[0-9]{9}$/;

// N-18, CA-38: Expresiones regulares estrictas por tipo de documento
export const CEDULA_REGEX = /^[0-9]{10}$/;
export const RUC_REGEX = /^[0-9]{13}$/;
export const PASSPORT_REGEX = /^[A-Za-z0-9]{5,20}$/;

/**
 * Valida el nombre completo (1 a 100 caracteres) (CA-17, A-01)
 * @param {any} fullName
 * @returns {boolean}
 */
export function isValidFullName(fullName) {
  if (typeof fullName !== 'string') return false;
  const trimmed = fullName.trim();
  return trimmed.length >= 1 && trimmed.length <= 100;
}

/**
 * Valida el formato ecuatoriano de teléfono (N-17, CA-37)
 * +593 seguido de exactamente 9 dígitos
 * @param {any} phone
 * @returns {boolean}
 */
export function isValidPhone(phone) {
  if (typeof phone !== 'string') return false;
  return PHONE_REGEX.test(phone.trim());
}

/**
 * Valida el tipo de documento permitido (N-18)
 * @param {any} documentType
 * @returns {boolean}
 */
export function isValidDocumentType(documentType) {
  if (typeof documentType !== 'string') return false;
  return Object.values(DOCUMENT_TYPES).includes(documentType.trim());
}

/**
 * Valida el número de documento según su tipo específico (N-18, CA-38)
 * - CEDULA: exactamente 10 dígitos numéricos
 * - RUC: exactamente 13 dígitos numéricos
 * - PASSPORT: entre 5 y 20 caracteres alfanuméricos
 * @param {any} documentType
 * @param {any} documentNumber
 * @returns {boolean}
 */
export function isValidDocumentNumber(documentType, documentNumber) {
  if (typeof documentType !== 'string' || typeof documentNumber !== 'string') return false;
  const type = documentType.trim();
  const number = documentNumber.trim();

  switch (type) {
    case DOCUMENT_TYPES.CEDULA:
      return CEDULA_REGEX.test(number);
    case DOCUMENT_TYPES.RUC:
      return RUC_REGEX.test(number);
    case DOCUMENT_TYPES.PASSPORT:
      return PASSPORT_REGEX.test(number);
    default:
      return false;
  }
}

/**
 * Valida la dirección (1 a 200 caracteres) (N-18)
 * @param {any} address
 * @returns {boolean}
 */
export function isValidAddress(address) {
  if (typeof address !== 'string') return false;
  const trimmed = address.trim();
  return trimmed.length >= 1 && trimmed.length <= 200;
}

/**
 * Normaliza una cadena para búsqueda (searchName):
 * Minúsculas, sin tildes/diacríticos Unicode (NFD), sin espacios sobrantes (ADR-012, TRD §2.2, CL-01)
 * @param {any} source
 * @returns {string}
 */
export function normalizeSearchName(source) {
  if (!source || typeof source !== 'string') return '';
  return source
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

/**
 * Valida de forma exhaustiva los 5 campos del formulario de registro (A-01, TRD §5.1)
 * @param {Object} data
 * @returns {{ isValid: boolean, errors: Object }}
 */
export function validateRegistrationData(data) {
  const { fullName, phone, documentType, documentNumber, address } = data || {};
  const errors = {};

  if (!isValidFullName(fullName)) {
    errors.fullName = 'El nombre completo es obligatorio y debe tener entre 1 y 100 caracteres.';
  }

  if (!isValidPhone(phone)) {
    errors.phone = 'El teléfono de contacto debe tener formato ecuatoriano (+593 seguido de 9 dígitos).';
  }

  if (!isValidDocumentType(documentType)) {
    errors.documentType = 'El tipo de documento debe ser CEDULA, PASSPORT o RUC.';
  } else if (!isValidDocumentNumber(documentType, documentNumber)) {
    if (documentType.trim() === DOCUMENT_TYPES.CEDULA) {
      errors.documentNumber = 'La cédula debe contener exactamente 10 dígitos numéricos.';
    } else if (documentType.trim() === DOCUMENT_TYPES.RUC) {
      errors.documentNumber = 'El RUC debe contener exactamente 13 dígitos numéricos.';
    } else if (documentType.trim() === DOCUMENT_TYPES.PASSPORT) {
      errors.documentNumber = 'El pasaporte debe contener entre 5 y 20 caracteres alfanuméricos.';
    }
  }

  if (!isValidAddress(address)) {
    errors.address = 'La dirección es obligatoria y debe tener entre 1 y 200 caracteres.';
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

/**
 * Valida las líneas de una solicitud de productos (fase 1 de createProductRequest, TRD v1.21 §3.2.D)
 * @param {any} items Arreglo de líneas de solicitud
 * @returns {{ isValid: true, lines: Array<{ productId: string, quantity: number }> } | { isValid: false, errorCode: string, details: Object }}
 */
export function validateRequestItems(items) {
  // 1. items es un arreglo con al menos una línea
  if (!Array.isArray(items) || items.length === 0) {
    return {
      isValid: false,
      errorCode: 'EMPTY_REQUEST',
      details: { errorCode: 'EMPTY_REQUEST' },
    };
  }

  // 2. items.length <= MAX_REQUEST_LINES
  if (items.length > MAX_REQUEST_LINES) {
    return {
      isValid: false,
      errorCode: 'TOO_MANY_REQUEST_LINES',
      details: {
        errorCode: 'TOO_MANY_REQUEST_LINES',
        maxLines: MAX_REQUEST_LINES,
      },
    };
  }

  // 3. Cada línea es un objeto no nulo, y su productId es una cadena no vacía tras recortar espacios
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const isObject = typeof item === 'object' && item !== null && !Array.isArray(item);
    if (!isObject || typeof item.productId !== 'string' || item.productId.trim().length === 0) {
      return {
        isValid: false,
        errorCode: 'INVALID_ARGUMENT',
        details: {
          errorCode: 'INVALID_ARGUMENT',
          lineIndex: i,
        },
      };
    }
  }

  // 4. Ningún productId, ya recortado, se repite
  const seenProductIds = new Set();
  for (let i = 0; i < items.length; i++) {
    const trimmedId = items[i].productId.trim();
    if (seenProductIds.has(trimmedId)) {
      return {
        isValid: false,
        errorCode: 'DUPLICATE_PRODUCT_LINE',
        details: {
          errorCode: 'DUPLICATE_PRODUCT_LINE',
          lineIndex: i,
        },
      };
    }
    seenProductIds.add(trimmedId);
  }

  // 5. Cada quantity es un entero, >= 1 y <= MAX_REQUEST_QUANTITY
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const isInt = typeof item.quantity === 'number' && Number.isInteger(item.quantity);
    if (!isInt || item.quantity < 1 || item.quantity > MAX_REQUEST_QUANTITY) {
      return {
        isValid: false,
        errorCode: 'INVALID_QUANTITY',
        details: {
          errorCode: 'INVALID_QUANTITY',
          lineIndex: i,
          maxQuantity: MAX_REQUEST_QUANTITY,
        },
      };
    }
  }

  return {
    isValid: true,
    lines: items.map((item) => ({
      productId: item.productId.trim(),
      quantity: item.quantity,
    })),
  };
}
