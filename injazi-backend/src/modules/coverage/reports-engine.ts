import { prisma } from '../../db/prisma.js';

/**
 * Computes a "coverage over time" timeline WITHOUT needing a scheduled job
 * or a new snapshot table: since every approved evidence item already has
 * a createdAt timestamp, taking the EARLIEST evidence date that covered
 * each indicator gives a real, meaningful growth curve — "how many of the
 * 53 indicators had at least one approved evidence, as of this date."
 */
export async function computeProgressTimeline(userId: string) {
  const links = await prisma.evidenceIndicatorLink.findMany({
    where: { evidence: { userId, status: 'APPROVED' } },
    select: { indicatorId: true, evidence: { select: { createdAt: true } } },
  });

  // First-covered date per indicator (an indicator might have multiple
  // evidence items linked — we only care about when it FIRST became
  // covered for the timeline).
  const firstCoveredDate = new Map<string, Date>();
  for (const link of links) {
    const existing = firstCoveredDate.get(link.indicatorId);
    if (!existing || link.evidence.createdAt < existing) {
      firstCoveredDate.set(link.indicatorId, link.evidence.createdAt);
    }
  }

  const totalIndicators = await prisma.indicator.count();

  const sortedDates = [...firstCoveredDate.values()].sort((a, b) => a.getTime() - b.getTime());

  // Build a running-total timeline: one point per date an indicator was
  // newly covered, showing the cumulative count at that moment.
  const timeline: { date: string; coveredCount: number; percent: number }[] = [];
  let runningCount = 0;

  for (const date of sortedDates) {
    runningCount += 1;
    const dateKey = date.toISOString().slice(0, 10);
    const last = timeline[timeline.length - 1];

    // Collapse multiple indicators covered on the same day into one point
    // (the last one wins, with the updated running count).
    if (last && last.date === dateKey) {
      last.coveredCount = runningCount;
      last.percent = totalIndicators ? Number(((runningCount / totalIndicators) * 100).toFixed(1)) : 0;
    } else {
      timeline.push({
        date: dateKey,
        coveredCount: runningCount,
        percent: totalIndicators ? Number(((runningCount / totalIndicators) * 100).toFixed(1)) : 0,
      });
    }
  }

  return { timeline, totalIndicators };
}

// Criterion codes are stored as strings like 'C1', 'C10', 'C11', 'C2' — a
// plain lexicographic sort would give C1, C10, C11, C2, C3... instead of
// numeric order. Same fix already used elsewhere in the portfolio module.
function byCriterionCodeNumber<T extends { code: string }>(a: T, b: T): number {
  const numA = Number(a.code.replace(/\D/g, ''));
  const numB = Number(b.code.replace(/\D/g, ''));
  return numA - numB;
}

/**
 * Per-criterion coverage comparison — which of the 11 official criteria
 * are furthest along vs. which still need the most work.
 */
export async function computeCriterionComparison(userId: string) {
  const criteria = await prisma.criterion.findMany({
    include: {
      indicators: {
        include: {
          links: {
            where: { evidence: { userId, status: 'APPROVED' } },
            take: 1,
          },
        },
      },
    },
  });

  criteria.sort(byCriterionCodeNumber);

  return criteria.map((criterion) => {
    const total = criterion.indicators.length;
    const covered = criterion.indicators.filter((indicator) => indicator.links.length > 0).length;

    return {
      code: criterion.code,
      name: criterion.name,
      covered,
      total,
      percent: total ? Number(((covered / total) * 100).toFixed(1)) : 0,
    };
  });
}
