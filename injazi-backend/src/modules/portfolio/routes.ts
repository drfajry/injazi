import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';

export const portfolioRouter = Router();

portfolioRouter.get('/', async (req, res, next) => {
  try {
    const userId = z.string().cuid().parse(String(req.query.userId ?? ''));
    const sections = await prisma.portfolioSection.findMany({ where: { userId }, orderBy: { sortOrder: 'asc' } });
    res.json({ data: sections });
  } catch (error) { next(error); }
});

portfolioRouter.post('/generate', async (req, res, next) => {
  try {
    const body = z.object({ userId: z.string().cuid(), academicYearId: z.string().cuid().optional() }).parse(req.body);
    const count = await prisma.portfolioVersion.count({ where: { userId: body.userId } });
    const version = await prisma.portfolioVersion.create({
      data: {
        userId: body.userId,
        academicYearId: body.academicYearId,
        versionNo: count + 1,
        visibility: 'PRIVATE',
      },
    });
    res.status(202).json({ data: version, queued: true });
  } catch (error) { next(error); }
});
