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

const MAX_FIXED_PAGE_PDF_PAGES = 15;

/**
 * Renders EVERY page of a PDF as a PNG image (base64), each. Used only for
 * "fixed pages" (CV, schedule, etc.) — documents meant to be shown in full,
 * unlike regular evidence where a single-page thumbnail is enough as a
 * preview. Capped at a reasonable page count so a huge accidental upload
 * doesn't blow up memory/export size.
 */
export async function renderAllPdfPagesToImages(buffer: Buffer): Promise<string[]> {
  try {
    const document = await pdf(buffer, { scale: 2 });
    const images: string[] = [];

    for await (const page of document) {
      images.push(page.toString('base64'));
      if (images.length >= MAX_FIXED_PAGE_PDF_PAGES) break;
    }

    return images;
  } catch (error) {
    console.error('PDF multi-page render failed:', error);
    return [];
  }
}
