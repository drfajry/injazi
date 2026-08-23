import * as XLSX from 'xlsx';

const MAX_ROWS_PER_SHEET = 40;

/**
 * Renders an Excel file's first sheet as an actual HTML table — not a
 * flattened CSV text blob — so the exported portfolio shows the
 * spreadsheet the way it actually looks (rows/columns), same spirit as
 * showing a real PDF page image instead of extracted text.
 *
 * Best-effort: any failure (corrupt file, unsupported structure) returns
 * null, and the caller falls back to the plain-text excerpt instead.
 */
export function renderExcelAsHtmlTable(buffer: Buffer): string | null {
  try {
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const firstSheetName = workbook.SheetNames[0];
    if (!firstSheetName) return null;

    const sheet = workbook.Sheets[firstSheetName];

    // sheet_to_html's TypeScript types don't expose a `range` option (even
    // though some xlsx versions accept it at runtime) — so cap row count by
    // temporarily shrinking the sheet's own !ref bounds instead, which every
    // version respects.
    const range = XLSX.utils.decode_range(sheet['!ref'] ?? 'A1');
    const wasTruncated = range.e.r - range.s.r + 1 > MAX_ROWS_PER_SHEET;

    if (wasTruncated) {
      const truncatedRange = { ...range, e: { ...range.e, r: range.s.r + MAX_ROWS_PER_SHEET - 1 } };
      sheet['!ref'] = XLSX.utils.encode_range(truncatedRange);
    }

    const html = XLSX.utils.sheet_to_html(sheet, { header: '', footer: '' });

    // sheet_to_html wraps output in its own <html><body> tags — strip those
    // since we're embedding this inside our own document.
    const tableMatch = html.match(/<table[\s\S]*<\/table>/);
    if (!tableMatch) return null;

    return wasTruncated
      ? `${tableMatch[0]}<p class="table-truncated-note">(تم عرض أول ${MAX_ROWS_PER_SHEET} صفًا فقط)</p>`
      : tableMatch[0];
  } catch (error) {
    console.error('Excel table render failed:', error);
    return null;
  }
}
