import { Router } from 'express';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { computeCoverageSummary } from './coverage-engine.js';

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
