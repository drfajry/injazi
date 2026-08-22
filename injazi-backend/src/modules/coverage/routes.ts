import { Router } from 'express';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';

export const coverageRouter = Router();

coverageRouter.get('/', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const totalIndicators = await prisma.indicator.count();

    const links = await prisma.evidenceIndicatorLink.findMany({
      where: {
        evidence: { userId },
      },
      include: { indicator: { include: { criterion: true } }, evidence: true },
    });

    const byIndicator = new Map<string, { code: string; name: string; criterion: string; scores: number[] }>();
    for (const link of links) {
      const key = link.indicatorId;
      const current = byIndicator.get(key) ?? {
        code: link.indicator.code,
        name: link.indicator.name,
        criterion: link.indicator.criterion.name,
        scores: [],
      };
      if (link.evidence.status === 'APPROVED') current.scores.push(link.matchScore);
      byIndicator.set(key, current);
    }

    const indicators = [...byIndicator.entries()].map(([id, item]) => ({
      indicatorId: id,
      ...item,
      coverage: Math.min(1, Math.max(0, item.scores.reduce((a, b) => Math.max(a, b), 0))),
    }));

    const complete = indicators.filter((item) => item.coverage >= 0.7).length;
    const needsSupport = indicators.filter((item) => item.coverage > 0 && item.coverage < 0.7).length;
    const missing = Math.max(0, totalIndicators - complete - needsSupport);

    const overall = totalIndicators
      ? indicators.reduce((sum, item) => sum + Math.min(1, item.coverage), 0) / totalIndicators
      : 0;

    res.json({
      overallCoverage: Number(overall.toFixed(3)),
      totalIndicators,
      complete,
      needsSupport,
      missing,
      indicators,
    });
  } catch (error) {
    next(error);
  }
});
