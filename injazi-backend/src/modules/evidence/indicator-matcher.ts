import { prisma } from '../../db/prisma.js';

// How many top-matching indicators to link per evidence item.
const MAX_LINKS_PER_EVIDENCE = 3;

// Below this similarity score, a match is too weak to be useful — skip it
// rather than create noisy, low-confidence links.
const MIN_MATCH_SCORE = 0.25;

// Common Arabic connector/filler words that carry no topical meaning and
// would otherwise dilute keyword overlap scoring.
const ARABIC_STOPWORDS = new Set([
  'في', 'من', 'إلى', 'على', 'عن', 'مع', 'أو', 'و', 'ثم', 'أن', 'إن', 'كان',
  'هذا', 'هذه', 'ذلك', 'التي', 'الذي', 'الذين', 'كل', 'بعض', 'كما', 'قد',
  'لا', 'ما', 'لم', 'لن', 'إذا', 'حتى', 'بين', 'عند', 'بعد', 'قبل', 'خلال',
  'التعلم', 'المعلم', 'الطالب', 'المتعلم', 'يتم', 'يجب', 'يمكن', 'الذي', 'التي',
  // Generic administrative/pedagogical vocabulary that appears across MANY
  // indicator descriptions regardless of topic. Without excluding these,
  // a handful of incidental hits (e.g. any document mentioning "معلومات"
  // or "بيانات") can inflate the overlap score against short indicator
  // text, producing spurious matches unrelated to the actual content.
  'معلومات', 'المعلومات', 'بيانات', 'البيانات', 'العمل', 'الأداء', 'الأنشطة',
  'نشاط', 'المهنية', 'المهني', 'العملية', 'التعليمية', 'المدرسة', 'الفصل',
  'الطلاب', 'الطالبات', 'المتعلمين', 'المتعلمات', 'يستخدم', 'استخدام',
  'وفق', 'وفقًا', 'ذات', 'صلة', 'مناسب', 'مناسبة', 'مختلف', 'مختلفة',
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
 * Overlap coefficient between two token sets: size of intersection over the
 * size of the SMALLER set. Unlike Jaccard, this isn't diluted when one
 * document (typically the evidence — an exam, report, or plan) is much
 * longer than the other (the indicator's short description sentence). It
 * effectively measures "what fraction of the indicator's vocabulary shows
 * up in this evidence?", which is what actually matters here.
 */
function overlapCoefficient(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 || b.size === 0) return 0;

  let intersectionSize = 0;
  for (const word of a) {
    if (b.has(word)) intersectionSize += 1;
  }

  return intersectionSize / Math.min(a.size, b.size);
}

/**
 * Matches a single evidence item against every indicator and creates
 * EvidenceIndicatorLink rows for the strongest matches. Safe to re-run: it
 * clears previous links for this evidence first, so re-matching after an
 * edit never leaves stale links behind.
 */
export async function matchEvidenceToIndicators(evidenceId: string): Promise<number> {
  const evidence = await prisma.evidence.findUnique({ where: { id: evidenceId } });
  if (!evidence) {
    console.warn(`[indicator-matcher] Evidence ${evidenceId} not found, skipping.`);
    return 0;
  }

  const evidenceText = [evidence.title, evidence.description].filter(Boolean).join(' ');
  const evidenceTokens = tokenize(evidenceText);

  if (evidenceTokens.size === 0) {
    console.warn(
      `[indicator-matcher] Evidence "${evidence.title}" (${evidenceId}) has no usable text ` +
      `(description is ${evidence.description ? 'present but produced 0 tokens' : 'empty/null'}). ` +
      `No indicators can be matched without text content.`,
    );
    return 0;
  }

  const indicators = await prisma.indicator.findMany();

  const scored = indicators
    .map((indicator) => {
      // Compare against the indicator's own name+description AND each
      // concrete example separately, taking the best match — rather than
      // merging everything into one big blob of text. A real uploaded
      // document (e.g. an exam) matches a specific concrete example (e.g.
      // "نموذج اختبار تحريري يتضمن أسئلة متنوعة") far better than it
      // matches the indicator's short, abstract policy description, and
      // merging them would just dilute that concrete signal.
      const referenceTexts = [
        [indicator.name, indicator.description].filter(Boolean).join(' '),
        ...(indicator.examples ?? []),
      ];

      const bestScore = referenceTexts.reduce((best, text) => {
        const score = overlapCoefficient(evidenceTokens, tokenize(text));
        return Math.max(best, score);
      }, 0);

      return { indicatorId: indicator.id, indicatorCode: indicator.code, score: bestScore };
    })
    .sort((a, b) => b.score - a.score);

  const topMatches = scored.slice(0, MAX_LINKS_PER_EVIDENCE).filter((match) => match.score >= MIN_MATCH_SCORE);

  console.log(
    `[indicator-matcher] Evidence "${evidence.title}" (${evidenceTokens.size} tokens): ` +
    `best score ${scored[0]?.score.toFixed(3) ?? 'n/a'} (${scored[0]?.indicatorCode ?? 'none'}), ` +
    `${topMatches.length} link(s) created above threshold ${MIN_MATCH_SCORE}.`,
  );

  await prisma.evidenceIndicatorLink.deleteMany({ where: { evidenceId } });

  if (topMatches.length === 0) return 0;

  await prisma.evidenceIndicatorLink.createMany({
    data: topMatches.map((match) => ({
      evidenceId,
      indicatorId: match.indicatorId,
      matchScore: Number(match.score.toFixed(3)),
      modelVersion: 'keyword-overlap-v2',
    })),
  });

  return topMatches.length;
}
