import * as cheerio from 'cheerio';

const MAX_EXTRACTED_CHARS = 8000;
const FETCH_TIMEOUT_MS = 10_000;
const MAX_RESPONSE_BYTES = 5 * 1024 * 1024; // 5MB safety cap

export class UrlIngestionError extends Error {}

type IngestedPage = {
  title: string;
  text: string | null;
};

/**
 * Fetches a public web page and extracts its readable title and body text.
 * Throws UrlIngestionError with a user-facing message on any failure
 * (unreachable, not HTML, too large, timed out, etc).
 */
export async function ingestUrl(url: string): Promise<IngestedPage> {
  let response: Response;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

  try {
    response = await fetch(url, {
      signal: controller.signal,
      redirect: 'follow',
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; InjaziBot/1.0; +https://drfajry.github.io/injazi)',
      },
    });
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new UrlIngestionError('انتهت مهلة الاتصال بالرابط. تأكد أن الرابط صحيح ومتاح.');
    }
    throw new UrlIngestionError('تعذّر الوصول إلى الرابط. تأكد من صحته ومحاولة مرة أخرى.');
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    throw new UrlIngestionError(`الرابط أعاد خطأ (${response.status}). تأكد أن الصفحة متاحة للعموم.`);
  }

  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.includes('text/html') && !contentType.includes('application/xhtml')) {
    throw new UrlIngestionError('الرابط لا يشير إلى صفحة ويب (HTML). هذه الميزة تدعم صفحات الويب فقط حاليًا.');
  }

  const contentLength = Number(response.headers.get('content-length') ?? 0);
  if (contentLength > MAX_RESPONSE_BYTES) {
    throw new UrlIngestionError('حجم الصفحة كبير جدًا.');
  }

  const html = await response.text();

  if (html.length > MAX_RESPONSE_BYTES) {
    throw new UrlIngestionError('حجم الصفحة كبير جدًا.');
  }

  const $ = cheerio.load(html);

  $('script, style, nav, footer, header, noscript, iframe').remove();

  const title =
    $('meta[property="og:title"]').attr('content')?.trim() ||
    $('title').first().text().trim() ||
    url;

  const bodyText = $('article').text().trim() || $('main').text().trim() || $('body').text().trim();

  const cleaned = bodyText.replace(/\s+/g, ' ').trim();

  const text = cleaned.length
    ? cleaned.length > MAX_EXTRACTED_CHARS
      ? `${cleaned.slice(0, MAX_EXTRACTED_CHARS)}…`
      : cleaned
    : null;

  return { title, text };
}
