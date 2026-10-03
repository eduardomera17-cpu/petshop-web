// functions/src/lib/proforma_pdf.js
// Generador del documento PDF de proforma en memoria con pdfkit (TRD §3.3.E, §4.5.3, §8.2, FA-05, Plan General v2.4 §3.8)

import PDFDocument from 'pdfkit';

/**
 * Formatea céntimos a representación monetaria en dólares (ej. 3500 -> "$35.00").
 * @param {number} cents
 * @returns {string}
 */
function formatMoney(cents) {
  const value = (cents || 0) / 100;
  return `$${value.toFixed(2)}`;
}

/**
 * Formatea puntos básicos a porcentaje (ej. 1500 -> "15.00%").
 * @param {number} bp
 * @returns {string}
 */
function formatPercent(bp) {
  const value = (bp || 0) / 100;
  return `${value.toFixed(2)}%`;
}

/**
 * Compone el documento PDF oficial de la proforma en memoria y retorna su Buffer.
 * Cumple con el diseño normativo: snapshots, numeración correlativa, desglose impositivo y soporte de logotipo.
 *
 * @param {Object} params
 * @param {string} params.series - Serie de la proforma (ej. '001-001')
 * @param {number} params.number - Número correlativo entero N
 * @param {string} [params.formattedNumber] - Número formateado (ej. '001-001-000001')
 * @param {string} params.proformaId - Identificador único de la proforma
 * @param {Array<Object>} params.items - Arreglo de líneas calculadas
 * @param {Array<Object>} [params.adjustments=[]] - Arreglo de ajustes calculados
 * @param {Object} params.totals - Totales normativos de document pricing
 * @param {Object} [params.clientSnapshot] - Snapshot del cliente
 * @param {Object} [params.businessSnapshot] - Snapshot del negocio
 * @param {Buffer|null} [params.logoBuffer=null] - Buffer de la imagen de logotipo (opcional)
 * @returns {Promise<Buffer>} Buffer binario del archivo PDF
 */
export async function generateProformaPdf({
  series,
  number,
  formattedNumber,
  proformaId,
  items = [],
  adjustments = [],
  totals = {},
  clientSnapshot = {},
  businessSnapshot = {},
  logoBuffer = null,
}) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({
        size: 'A4',
        margin: 40,
        info: {
          Title: `Proforma ${formattedNumber || `${series}-${number}`}`,
          Author: businessSnapshot?.businessName || 'PetShop',
          Subject: 'Proforma de Servicios y Productos',
        },
      });

      const chunks = [];
      doc.on('data', (chunk) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', (err) => reject(err));

      const displayFormattedNumber = formattedNumber || `${series}-${String(number).padStart(6, '0')}`;

      // 1. Encabezado con Logotipo (si está disponible) y Datos del Negocio
      const headerTop = 40;
      let textLeft = 40;

      if (logoBuffer && Buffer.isBuffer(logoBuffer)) {
        try {
          doc.image(logoBuffer, 40, headerTop, { width: 75, height: 75, fit: [75, 75] });
          textLeft = 125;
        } catch (logoErr) {
          console.warn('[PDF] Error al renderizar logoBuffer, continuando sin logo:', logoErr.message);
          textLeft = 40;
        }
      }

      // Datos del Negocio
      doc
        .fontSize(16)
        .font('Helvetica-Bold')
        .text(businessSnapshot?.businessName || 'PetShop', textLeft, headerTop);

      doc
        .fontSize(9)
        .font('Helvetica')
        .text(`RUC: ${businessSnapshot?.taxId || 'N/D'}`, textLeft, headerTop + 20)
        .text(`Dirección: ${businessSnapshot?.address || 'N/D'}`, textLeft, headerTop + 32)
        .text(`Teléfono: ${businessSnapshot?.phone || 'N/D'}`, textLeft, headerTop + 44);

      // Bloque del Número de Proforma a la derecha
      doc
        .fontSize(12)
        .font('Helvetica-Bold')
        .text('PROFORMA', 380, headerTop, { align: 'right', width: 175 })
        .fontSize(11)
        .font('Helvetica-Bold')
        .fillColor('#003366')
        .text(displayFormattedNumber, 380, headerTop + 16, { align: 'right', width: 175 })
        .fillColor('#000000')
        .fontSize(8)
        .font('Helvetica')
        .text(`ID Ref: ${proformaId}`, 380, headerTop + 32, { align: 'right', width: 175 })
        .text(`Fecha de Emisión: ${new Date().toLocaleDateString('es-EC')}`, 380, headerTop + 44, { align: 'right', width: 175 });

      // Línea divisoria
      doc
        .moveTo(40, headerTop + 85)
        .lineTo(555, headerTop + 85)
        .strokeColor('#CCCCCC')
        .lineWidth(1)
        .stroke();

      // 2. Datos del Cliente (clientSnapshot)
      const clientTop = headerTop + 95;
      doc
        .fontSize(10)
        .font('Helvetica-Bold')
        .fillColor('#003366')
        .text('DATOS DEL CLIENTE', 40, clientTop)
        .fillColor('#000000');

      doc
        .fontSize(9)
        .font('Helvetica')
        .text(`Cliente: ${clientSnapshot?.fullName || 'Consumidor Final'}`, 40, clientTop + 16)
        .text(`Identificación (${clientSnapshot?.documentType || 'DOC'}): ${clientSnapshot?.documentNumber || '9999999999'}`, 40, clientTop + 28)
        .text(`Dirección: ${clientSnapshot?.address || 'N/D'}`, 300, clientTop + 16)
        .text(`Teléfono: ${clientSnapshot?.phone || 'N/D'} | Email: ${clientSnapshot?.email || 'N/D'}`, 300, clientTop + 28);

      // Línea divisoria previa a la tabla
      doc
        .moveTo(40, clientTop + 46)
        .lineTo(555, clientTop + 46)
        .strokeColor('#CCCCCC')
        .stroke();

      // 3. Tabla de Ítems
      let tableY = clientTop + 56;
      doc
        .fontSize(9)
        .font('Helvetica-Bold')
        .fillColor('#003366')
        .text('Cant', 40, tableY, { width: 30 })
        .text('Descripción / Concepto', 75, tableY, { width: 190 })
        .text('P. Unit', 270, tableY, { width: 50, align: 'right' })
        .text('Subtotal', 325, tableY, { width: 50, align: 'right' })
        .text('ICE', 380, tableY, { width: 40, align: 'right' })
        .text('IVA', 425, tableY, { width: 55, align: 'right' })
        .text('Total', 485, tableY, { width: 70, align: 'right' })
        .fillColor('#000000');

      doc
        .moveTo(40, tableY + 14)
        .lineTo(555, tableY + 14)
        .strokeColor('#999999')
        .stroke();

      tableY += 20;

      doc.font('Helvetica').fontSize(8);
      for (const item of items) {
        if (tableY > 720) {
          doc.addPage();
          tableY = 40;
        }

        const qty = item.quantity || 1;
        const concept = item.concept || 'Concepto';
        const unitPrice = formatMoney(item.unitBasePriceCents);
        const subtotal = formatMoney(item.lineSubtotalCents);
        const ice = item.iceAmountCents > 0 ? `${formatMoney(item.iceAmountCents)} (${formatPercent(item.iceBp)})` : '$0.00';
        const iva = `${formatMoney(item.ivaAmountCents)} (${formatPercent(item.ivaBp)})`;
        const total = formatMoney(item.lineTotalCents);

        doc
          .text(String(qty), 40, tableY, { width: 30 })
          .text(concept, 75, tableY, { width: 190 })
          .text(unitPrice, 270, tableY, { width: 50, align: 'right' })
          .text(subtotal, 325, tableY, { width: 50, align: 'right' })
          .text(ice, 380, tableY, { width: 40, align: 'right' })
          .text(iva, 425, tableY, { width: 55, align: 'right' })
          .text(total, 485, tableY, { width: 70, align: 'right' });

        tableY += 16;
      }

      // 4. Ajustes (Descuentos y Recargos)
      if (adjustments && adjustments.length > 0) {
        tableY += 8;
        if (tableY > 700) {
          doc.addPage();
          tableY = 40;
        }

        doc
          .moveTo(40, tableY)
          .lineTo(555, tableY)
          .strokeColor('#EEEEEE')
          .stroke();

        tableY += 6;
        doc.font('Helvetica-Bold').fontSize(8).fillColor('#003366').text('Ajustes y Descuentos aplicados:', 40, tableY);
        doc.fillColor('#000000').font('Helvetica');
        tableY += 12;

        for (const adj of adjustments) {
          const sign = adj.type === 'DISCOUNT' ? '-' : '+';
          const val = adj.percentBp != null
            ? `${sign}${formatMoney(adj.amountCents)} (${formatPercent(adj.percentBp)})`
            : `${sign}${formatMoney(adj.amountCents)}`;

          doc.text(`• ${adj.concept} [${adj.type}]: ${val}`, 50, tableY);
          tableY += 12;
        }
      }

      // 5. Totales y Resumen Impositivo
      tableY += 12;
      if (tableY > 680) {
        doc.addPage();
        tableY = 40;
      }

      doc
        .moveTo(350, tableY)
        .lineTo(555, tableY)
        .strokeColor('#003366')
        .lineWidth(1)
        .stroke();

      tableY += 8;
      const totalColLabel = 350;
      const totalColValue = 475;
      const colWidth = 80;

      doc.font('Helvetica').fontSize(9);

      doc.text('Subtotal:', totalColLabel, tableY).text(formatMoney(totals.subtotalCents), totalColValue, tableY, { align: 'right', width: colWidth });
      tableY += 14;

      if ((totals.totalDiscountCents || 0) > 0) {
        doc.text('Descuentos:', totalColLabel, tableY).text(`-${formatMoney(totals.totalDiscountCents)}`, totalColValue, tableY, { align: 'right', width: colWidth });
        tableY += 14;
      }

      if ((totals.totalSurchargeCents || 0) > 0) {
        doc.text('Recargos:', totalColLabel, tableY).text(`+${formatMoney(totals.totalSurchargeCents)}`, totalColValue, tableY, { align: 'right', width: colWidth });
        tableY += 14;
      }

      doc.text('Base Imponible:', totalColLabel, tableY).text(formatMoney(totals.taxableBaseCents), totalColValue, tableY, { align: 'right', width: colWidth });
      tableY += 14;

      if ((totals.totalIceCents || 0) > 0) {
        doc.text('ICE Total:', totalColLabel, tableY).text(formatMoney(totals.totalIceCents), totalColValue, tableY, { align: 'right', width: colWidth });
        tableY += 14;
      }

      doc.text('IVA Total:', totalColLabel, tableY).text(formatMoney(totals.totalIvaCents), totalColValue, tableY, { align: 'right', width: colWidth });
      tableY += 16;

      doc
        .moveTo(350, tableY - 2)
        .lineTo(555, tableY - 2)
        .strokeColor('#003366')
        .stroke();

      doc
        .font('Helvetica-Bold')
        .fontSize(11)
        .fillColor('#003366')
        .text('TOTAL A PAGAR:', totalColLabel, tableY)
        .text(formatMoney(totals.totalCents), totalColValue, tableY, { align: 'right', width: colWidth })
        .fillColor('#000000');

      // 6. Pie de Página y Términos
      const footerY = 780;
      doc
        .fontSize(7)
        .font('Helvetica')
        .fillColor('#666666')
        .text('Este documento es una proforma informativa emitida para fines de control interno y detalle de pago presencial en mostrador.', 40, footerY, { align: 'center', width: 515 })
        .text('No constituye comprobante de venta fiscal electrónico oficial bajo la normativa del SRI.', 40, footerY + 10, { align: 'center', width: 515 });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}
