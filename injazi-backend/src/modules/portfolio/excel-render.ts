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

    // Cap huge sheets so the export page doesn't balloon — a truncated
    // table with a note is more useful than a 5,000-row wall.
    const range = XLSX.utils.decode_range(sheet['!ref'] ?? 'A1');
    const wasTruncated = range.e.r - range.s.r + 1 > MAX_ROWS_PER_SHEET;
    if (wasTruncated) {
      range.e.r = range.s.r + MAX_ROWS_PER_SHEET - 1;
    }

    const html = XLSX.utils.sheet_to_html(sheet, { header: '', footer: '', range });

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
