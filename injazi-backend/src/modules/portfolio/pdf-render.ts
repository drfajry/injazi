import { pdf } from 'pdf-to-img';

/**
 * Renders the first page of a PDF as a PNG image (base64). Used so the
 * printed portfolio shows the actual document page — not just its
 * extracted text — the same way an uploaded photo is shown as itself.
 *
 * Best-effort: any failure (corrupt PDF, unsupported structure, etc.)
 * returns null rather than throwing, so a rendering problem with one
 * evidence item never breaks the whole export.
 */
export async function renderFirstPdfPageToImage(buffer: Buffer): Promise<string | null> {
  try {
    const document = await pdf(buffer, { scale: 2 });
    const firstPage = await document.getPage(1);
    return firstPage.toString('base64');
  } catch (error) {
    console.error('PDF page render failed:', error);
    return null;
  }
}
