import { prisma } from '../../db/prisma.js';

/**
 * Single source of truth for how "coverage" is calculated, used by BOTH the
 * dashboard summary (/me/coverage) and the portfolio view (/me/portfolio/preview).
 * Previously each endpoint computed this independently with different
 * formulas (one score-weighted, one binary), which showed the person two
 * different percentages for the same underlying data — confusing and wrong.
 *
 * Definition: an indicator counts as "covered" if it has at least one
 * APPROVED evidence item linked to it (regardless of how strong the match
 * score is). This is intentionally binary and simple: the goal is "do I
 * have at least one solid evidence item for this indicator," not a
 * weighted score. An indicator with 3 evidence items still counts once —
 * having extra evidence for an already-covered indicator doesn't inflate
 * the percentage, since the target is breadth across all 53 indicators,
 * not depth on a few of them.
 */
export async function computeCoverageSummary(userId: string) {
  const totalIndicators = await prisma.indicator.count();

  const links = await prisma.evidenceIndicatorLink.findMany({
    where: { evidence: { userId, status: 'APPROVED' } },
    include: { indicator: { include: { criterion: true } } },
  });

  const coveredIndicatorIds = new Set(links.map((link) => link.indicatorId));

  const byIndicator = new Map<string, { code: string; name: string; criterion: string }>();
  for (const link of links) {
    byIndicator.set(link.indicatorId, {
      code: link.indicator.code,
      name: link.indicator.name,
      criterion: link.indicator.criterion.name,
    });
  }

  const complete = coveredIndicatorIds.size;
  const missing = Math.max(0, totalIndicators - complete);
  const overallCoverage = totalIndicators ? Number((complete / totalIndicators).toFixed(3)) : 0;

  const indicators = [...byIndicator.entries()].map(([id, item]) => ({
    indicatorId: id,
    ...item,
    coverage: 1,
  }));

  return {
    overallCoverage,
    totalIndicators,
    complete,
    // Kept for UI compatibility — always 0 now, since coverage is binary
    // (an indicator either has approved evidence or it doesn't; there's no
    // partial/"needs support" state anymore).
    needsSupport: 0,
    missing,
    indicators,
  };
}
