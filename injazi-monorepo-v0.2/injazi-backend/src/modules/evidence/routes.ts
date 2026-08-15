import { Router } from 'express';
import { EvidenceStatus, EvidenceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { createEvidenceCandidate } from './evidence-engine.js';

export const evidenceRouter = Router();

// Development-only auth placeholder: replace with real session/JWT middleware.
const userIdQuery = z.string().cuid();

evidenceRouter.get('/', async (req, res, next) => {
  try {
    const userId = userIdQuery.parse(String(req.query.userId ?? ''));
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

evidenceRouter.post('/manual', async (req, res, next) => {
  try {
    const body = z.object({
      userId: z.string().cuid(),
      academicYearId: z.string().cuid().optional(),
      title: z.string().min(2),
      description: z.string().optional(),
      type: z.nativeEnum(EvidenceType).default(EvidenceType.DOCUMENT),
      confidence: z.number().min(0).max(1).default(0.95),
    }).parse(req.body);

    const evidence = await createEvidenceCandidate(body);
    res.status(201).json({ data: evidence });
  } catch (error) {
    next(error);
  }
});

evidenceRouter.post('/:id/approve', async (req, res, next) => {
  try {
    const id = z.string().cuid().parse(req.params.id);
    const evidence = await prisma.evidence.update({
      where: { id },
      data: { status: EvidenceStatus.APPROVED },
    });
    res.json({ data: evidence });
  } catch (error) {
    next(error);
  }
});

evidenceRouter.post('/:id/reject', async (req, res, next) => {
  try {
    const id = z.string().cuid().parse(req.params.id);
    const evidence = await prisma.evidence.update({
      where: { id },
      data: { status: EvidenceStatus.REJECTED },
    });
    res.json({ data: evidence });
  } catch (error) {
    next(error);
  }
});
