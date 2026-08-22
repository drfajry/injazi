import { Router } from 'express';
import { EvidenceStatus, EvidenceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { createEvidenceCandidate } from './evidence-engine.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';

export const evidenceRouter = Router();

evidenceRouter.get('/', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const status = req.query.status ? z.nativeEnum(EvidenceStatus).parse(String(req.query.status)) : undefined;
    const evidence = await prisma.evidence.findMany({
      where: { userId, ...(status ? { status } : {}) },
      include: { links: true, files: true, sourceItem: true },
      orderBy: { updatedAt: 'desc' },
    });
    res.json({ data: evidence });
  } catch (error) {
    next(error);
  }
});

evidenceRouter.post('/manual', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const body = z.object({
      academicYearId: z.string().cuid().optional(),
      title: z.string().min(2),
      description: z.string().optional(),
      type: z.nativeEnum(EvidenceType).default(EvidenceType.DOCUMENT),
      confidence: z.number().min(0).max(1).default(0.95),
    }).parse(req.body);

    const evidence = await createEvidenceCandidate({ ...body, userId });
    res.status(201).json({ data: evidence });
  } catch (error) {
    next(error);
  }
});

evidenceRouter.post('/:id/approve', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const evidence = await prisma.evidence.findUnique({ where: { id } });

    if (!evidence || evidence.userId !== userId) {
      return res.status(404).json({ error: 'Evidence not found' });
    }

    const updated = await prisma.evidence.update({
      where: { id },
      data: { status: EvidenceStatus.APPROVED },
    });
    res.json({ data: updated });
  } catch (error) {
    next(error);
  }
});

evidenceRouter.post('/:id/reject', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const evidence = await prisma.evidence.findUnique({ where: { id } });

    if (!evidence || evidence.userId !== userId) {
      return res.status(404).json({ error: 'Evidence not found' });
    }

    const updated = await prisma.evidence.update({
      where: { id },
      data: { status: EvidenceStatus.REJECTED },
    });
    res.json({ data: updated });
  } catch (error) {
    next(error);
  }
});
