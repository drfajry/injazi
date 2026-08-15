import { Router } from 'express';
import { SourceStatus, SourceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';

export const sourcesRouter = Router();

sourcesRouter.get('/', async (req, res, next) => {
  try {
    const userId = z.string().cuid().parse(String(req.query.userId ?? ''));
    const sources = await prisma.connectedSource.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
    res.json({ data: sources });
  } catch (error) {
    next(error);
  }
});

sourcesRouter.post('/google/connect', async (req, res, next) => {
  try {
    const body = z.object({ userId: z.string().cuid(), externalAccountId: z.string().min(1).optional() }).parse(req.body);
    const source = await prisma.connectedSource.create({
      data: {
        userId: body.userId,
        type: SourceType.GOOGLE_DRIVE,
        status: SourceStatus.PENDING,
        externalAccountId: body.externalAccountId,
      },
    });
    res.status(201).json({ data: source, next: 'Implement Google OAuth callback and token vault.' });
  } catch (error) { next(error); }
});

sourcesRouter.post('/madrasati/connect', async (req, res, next) => {
  try {
    const body = z.object({ userId: z.string().cuid() }).parse(req.body);
    const source = await prisma.connectedSource.create({
      data: { userId: body.userId, type: SourceType.MADRASATI, status: SourceStatus.PENDING },
    });
    res.status(201).json({ data: source, next: 'Attach the approved Madrasati connector flow.' });
  } catch (error) { next(error); }
});

sourcesRouter.post('/:id/sync', async (req, res, next) => {
  try {
    const id = z.string().cuid().parse(req.params.id);
    const source = await prisma.connectedSource.update({ where: { id }, data: { lastSyncAt: new Date(), status: SourceStatus.CONNECTED } });
    res.status(202).json({ data: source, queued: true });
  } catch (error) { next(error); }
});
