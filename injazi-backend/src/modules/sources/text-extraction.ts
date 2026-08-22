import pdfParse from 'pdf-parse';
import mammoth from 'mammoth';
import * as XLSX from 'xlsx';

// Cap stored extracted text so a huge document doesn't bloat the database.
const MAX_EXTRACTED_CHARS = 8000;

const SUPPORTED_MIME_TYPES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain',
]);

export function isTextExtractionSupported(mimeType: string): boolean {
  return SUPPORTED_MIME_TYPES.has(mimeType);
}

/**
 * Best-effort text extraction from an uploaded file.
 * Returns null when the file type isn't supported yet (e.g. images — OCR is
 * a separate, not-yet-built step) or when extraction fails for any reason.
 * Never throws: a failed extraction should never block the upload itself.
 */
export async function extractText(buffer: Buffer, mimeType: string): Promise<string | null> {
  try {
    if (mimeType === 'application/pdf') {
      const result = await pdfParse(buffer);
      return truncate(result.text);
    }

    if (mimeType === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      const result = await mammoth.extractRawText({ buffer });
      return truncate(result.value);
    }

    if (mimeType === 'text/plain') {
      return truncate(buffer.toString('utf-8'));
    }

    if (
      mimeType === 'application/vnd.ms-excel' ||
      mimeType === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ) {
      const workbook = XLSX.read(buffer, { type: 'buffer' });
      const sheetTexts = workbook.SheetNames.map((sheetName) => {
        const sheet = workbook.Sheets[sheetName];
        // sheet_to_csv gives a compact, readable text dump of every cell —
        // good enough for keyword matching without needing to understand
        // the spreadsheet's structure.
        return XLSX.utils.sheet_to_csv(sheet);
      });
      return truncate(sheetTexts.join(' '));
    }

    // application/msword (legacy .doc binary format) and images are not
    // supported yet. .doc requires a different parser; images need OCR.
    return null;
  } catch (error) {
    console.error('Text extraction failed:', error);
    return null;
  }
}

function truncate(text: string): string | null {
  const cleaned = text.replace(/\s+/g, ' ').trim();

  if (!cleaned) return null;

  return cleaned.length > MAX_EXTRACTED_CHARS
    ? `${cleaned.slice(0, MAX_EXTRACTED_CHARS)}…`
    : cleaned;
}
