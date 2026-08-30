import { Router } from 'express';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { computeCoverageSummary } from './coverage-engine.js';
import { computeProgressTimeline, computeCriterionComparison } from './reports-engine.js';
import { computeReminders } from './reminders-engine.js';

export const coverageRouter = Router();

coverageRouter.get('/', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const summary = await computeCoverageSummary(userId);
    res.json(summary);
  } catch (error) {
    next(error);
  }
});

coverageRouter.get('/reports/progress', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const [timeline, criteria] = await Promise.all([
      computeProgressTimeline(userId),
      computeCriterionComparison(userId),
    ]);
    res.json({ data: { ...timeline, criteria } });
  } catch (error) {
    next(error);
  }
});

coverageRouter.get('/reminders', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const reminders = await computeReminders(userId);
    res.json({ data: reminders });
  } catch (error) {
    next(error);
  }
});
