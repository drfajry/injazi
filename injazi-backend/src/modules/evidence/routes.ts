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

// Deletes an evidence item entirely — used when something was uploaded by
// mistake. Cascades to its file and all its indicator links (schema already
// defines onDelete: Cascade on both relations), so nothing is left orphaned.
evidenceRouter.delete('/:id', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const evidence = await prisma.evidence.findUnique({ where: { id } });

    if (!evidence || evidence.userId !== userId) {
      return res.status(404).json({ error: 'Evidence not found' });
    }

    await prisma.evidence.delete({ where: { id } });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// Removes just one indicator link from an evidence item — used when the
// evidence itself is correct but the automatic matcher linked it to the
// wrong indicator. The evidence and its other links are untouched.
evidenceRouter.delete('/:id/indicators/:indicatorId', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const indicatorId = z.string().cuid().parse(req.params.indicatorId);

    const evidence = await prisma.evidence.findUnique({ where: { id } });
    if (!evidence || evidence.userId !== userId) {
      return res.status(404).json({ error: 'Evidence not found' });
    }

    await prisma.evidenceIndicatorLink.deleteMany({
      where: { evidenceId: id, indicatorId },
    });

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// Manually links an evidence item to a chosen indicator — used to fix a
// missed or wrong automatic match. matchScore is set to 1 and modelVersion
// to 'manual' so it's clearly distinguishable from algorithm-created links.
evidenceRouter.post('/:id/indicators', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const body = z.object({ indicatorId: z.string().cuid() }).parse(req.body);

    const evidence = await prisma.evidence.findUnique({ where: { id } });
    if (!evidence || evidence.userId !== userId) {
      return res.status(404).json({ error: 'Evidence not found' });
    }

    const indicator = await prisma.indicator.findUnique({ where: { id: body.indicatorId } });
    if (!indicator) {
      return res.status(404).json({ error: 'Indicator not found' });
    }

    const link = await prisma.evidenceIndicatorLink.upsert({
      where: { evidenceId_indicatorId: { evidenceId: id, indicatorId: body.indicatorId } },
      update: { matchScore: 1, modelVersion: 'manual' },
      create: { evidenceId: id, indicatorId: body.indicatorId, matchScore: 1, modelVersion: 'manual' },
    });

    res.status(201).json({ data: link });
  } catch (error) {
    next(error);
  }
});
