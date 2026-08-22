import { prisma } from '../../db/prisma.js';

// How many top-matching indicators to link per evidence item.
const MAX_LINKS_PER_EVIDENCE = 3;

// Below this similarity score, a match is too weak to be useful — skip it
// rather than create noisy, low-confidence links. Tuned empirically: real
// evidence/indicator text pairs on the same topic typically score 0.06–0.15
// with this method (short indicator texts naturally cap Jaccard overlap).
const MIN_MATCH_SCORE = 0.06;

// Common Arabic connector/filler words that carry no topical meaning and
// would otherwise dilute keyword overlap scoring.
const ARABIC_STOPWORDS = new Set([
  'في', 'من', 'إلى', 'على', 'عن', 'مع', 'أو', 'و', 'ثم', 'أن', 'إن', 'كان',
  'هذا', 'هذه', 'ذلك', 'التي', 'الذي', 'الذين', 'كل', 'بعض', 'كما', 'قد',
  'لا', 'ما', 'لم', 'لن', 'إذا', 'حتى', 'بين', 'عند', 'بعد', 'قبل', 'خلال',
  'التعلم', 'المعلم', 'الطالب', 'المتعلم', 'يتم', 'يجب', 'يمكن', 'الذي', 'التي',
]);

function normalizeArabic(text: string): string {
  return text
    // strip Arabic diacritics (tashkeel)
    .replace(/[\u064B-\u065F\u0670]/g, '')
    // normalize alef variants to bare alef
    .replace(/[إأآا]/g, 'ا')
    // normalize ta marbuta to ha
    .replace(/ة/g, 'ه')
    // normalize alef maksura to ya
    .replace(/ى/g, 'ي')
    .toLowerCase();
}

function tokenize(text: string): Set<string> {
  const normalized = normalizeArabic(text);
  const words = normalized
    .split(/[^\p{L}\p{N}]+/u)
    .filter((word) => word.length >= 2 && !ARABIC_STOPWORDS.has(word));

  return new Set(words);
}

/**
 * Jaccard similarity between two token sets: size of intersection over size
 * of union. Simple, explainable, and free — no external API calls. This is
 * intentionally a stepping stone; a future version can swap this function
 * for an LLM-based classifier without changing anything that calls it.
 */
function jaccardSimilarity(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 || b.size === 0) return 0;

  let intersectionSize = 0;
  for (const word of a) {
    if (b.has(word)) intersectionSize += 1;
  }

  const unionSize = a.size + b.size - intersectionSize;
  return unionSize === 0 ? 0 : intersectionSize / unionSize;
}

/**
 * Matches a single evidence item against every indicator and creates
 * EvidenceIndicatorLink rows for the strongest matches. Safe to re-run: it
 * clears previous links for this evidence first, so re-matching after an
 * edit never leaves stale links behind.
 */
export async function matchEvidenceToIndicators(evidenceId: string): Promise<number> {
  const evidence = await prisma.evidence.findUnique({ where: { id: evidenceId } });
  if (!evidence) return 0;

  const evidenceText = [evidence.title, evidence.description].filter(Boolean).join(' ');
  const evidenceTokens = tokenize(evidenceText);

  if (evidenceTokens.size === 0) return 0;

  const indicators = await prisma.indicator.findMany();

  const scored = indicators
    .map((indicator) => {
      const indicatorText = [indicator.name, indicator.description].filter(Boolean).join(' ');
      const indicatorTokens = tokenize(indicatorText);
      const score = jaccardSimilarity(evidenceTokens, indicatorTokens);
      return { indicatorId: indicator.id, score };
    })
    .filter((match) => match.score >= MIN_MATCH_SCORE)
    .sort((a, b) => b.score - a.score)
    .slice(0, MAX_LINKS_PER_EVIDENCE);

  await prisma.evidenceIndicatorLink.deleteMany({ where: { evidenceId } });

  if (scored.length === 0) return 0;

  await prisma.evidenceIndicatorLink.createMany({
    data: scored.map((match) => ({
      evidenceId,
      indicatorId: match.indicatorId,
      matchScore: Number(match.score.toFixed(3)),
      modelVersion: 'keyword-jaccard-v1',
    })),
  });

  return scored.length;
}
