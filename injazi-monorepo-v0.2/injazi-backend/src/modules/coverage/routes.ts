import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';

export const coverageRouter = Router();

coverageRouter.get('/', async (req, res, next) => {
  try {
    const userId = z.string().cuid().parse(String(req.query.userId ?? ''));
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

    const overall = indicators.length
      ? indicators.reduce((sum, item) => sum + item.coverage, 0) / indicators.length
      : 0;

    res.json({ overallCoverage: Number(overall.toFixed(3)), indicators });
  } catch (error) {
    next(error);
  }
});
