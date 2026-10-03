// functions/src/domain/product_request.js
// Módulo de dominio para lectura y normalización de líneas de solicitudes de producto.
//
// La transición a items[] terminó: las solicitudes ya no se guardan en forma plana, así que los lectores
// no toleran esa forma: una solicitud sin items[] no vacío se rechaza y no se deriva ninguna línea.

/**
 * Extrae las líneas de una solicitud guardada que mueven stock.
 * items[] no vacío es la única forma válida: la forma plana se retiró.
 * Función pura: no interactúa con Firestore ni con dependencias externas.
 *
 * @param {any} requestData Datos del documento de la solicitud guardada
 * @returns {Array<{ productId: string, quantity: number }>}
 * @throws {TypeError} Si la estructura o los tipos son inválidos, o si la solicitud no tiene items[]
 */
export function requestStockLines(requestData) {
  if (typeof requestData !== 'object' || requestData === null || Array.isArray(requestData)) {
    throw new TypeError('requestData debe ser un objeto no nulo');
  }
  if (!Array.isArray(requestData.items) || requestData.items.length === 0) {
    throw new TypeError('La solicitud no tiene items[]: la forma plana se retiró (WP-6.11-B)');
  }

  const lines = [];
  const seenProductIds = new Set();

  for (const item of requestData.items) {
    if (typeof item !== 'object' || item === null || Array.isArray(item)) {
      throw new TypeError('Cada elemento de items debe ser un objeto no nulo');
    }
    if (typeof item.productId !== 'string' || item.productId.trim().length === 0) {
      throw new TypeError('Cada elemento de items debe tener un productId no vacío tras recortar');
    }
    if (typeof item.quantity !== 'number' || !Number.isInteger(item.quantity) || item.quantity < 1) {
      throw new TypeError('Cada elemento de items debe tener una quantity entera >= 1');
    }
    const trimmed = item.productId.trim();
    if (seenProductIds.has(trimmed)) {
      throw new TypeError('No se permiten productId repetidos en items[]');
    }
    seenProductIds.add(trimmed);

    lines.push({
      productId: item.productId,
      quantity: item.quantity,
    });
  }

  return lines;
}

/**
 * Enumera las líneas de una solicitud guardada para la previsualización de la desactivación de cuenta
 * (TRD v1.21 §3.4.G: cada solicitud con sus líneas —producto y cantidad—, leídas con la regla de §2.8).
 * Valida primero con requestStockLines: lo que esa función rechaza, esta también, con el mismo TypeError.
 * productName se devuelve tal como está guardado si es una cadena, y null en cualquier otro caso.
 * Función pura: no interactúa con Firestore ni con dependencias externas.
 *
 * @param {any} requestData Datos del documento de la solicitud guardada
 * @returns {Array<{ productId: string, productName: string|null, quantity: number }>}
 * @throws {TypeError} Si la estructura o los tipos son inválidos, o si la solicitud no tiene items[]
 */
export function requestPreviewLines(requestData) {
  const stockLines = requestStockLines(requestData);
  const nameOf = (value) => (typeof value === 'string' ? value : null);

  return stockLines.map((line, index) => ({
    productId: line.productId,
    productName: nameOf(requestData.items[index].productName),
    quantity: line.quantity,
  }));
}

/**
 * Extrae las líneas de una solicitud guardada para la facturación en proformas (TRD v1.22 §2.8 regla 3, §3.3.C).
 * Valida primero con requestStockLines: lo que esa función rechaza, esta también, con el mismo TypeError.
 * Cada línea toma sus propios importes e impuestos de items[]; no hay valores por omisión.
 * Función pura: no interactúa con Firestore ni con dependencias externas, y no lanza HttpsError.
 *
 * @param {any} requestData Datos del documento de la solicitud guardada
 * @returns {Array<{ productId: string, productName: string|null, quantity: number, agreedUnitPriceCents: any, iceBp: any, ivaBp: any }>}
 * @throws {TypeError} Si la estructura o los tipos son inválidos, o si la solicitud no tiene items[]
 */
export function requestBillingLines(requestData) {
  const stockLines = requestStockLines(requestData);
  const nameOf = (value) => (typeof value === 'string' ? value : null);

  return stockLines.map((line, index) => {
    const item = requestData.items[index];
    return {
      productId: line.productId,
      productName: nameOf(item.productName),
      quantity: line.quantity,
      agreedUnitPriceCents: item.agreedUnitPriceCents,
      iceBp: item.iceBp,
      ivaBp: item.ivaBp,
    };
  });
}
