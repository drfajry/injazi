import { Router } from 'express';
import multer from 'multer';
import { EvidenceType, SourceStatus, SourceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';

export const sourcesRouter = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
});

function guessEvidenceType(mimeType: string): EvidenceType {
  if (mimeType.startsWith('image/')) return EvidenceType.IMAGE;
  if (mimeType.startsWith('video/')) return EvidenceType.VIDEO;
  return EvidenceType.DOCUMENT;
}

async function getOrCreateManualSource(userId: string) {
  const existing = await prisma.connectedSource.findFirst({
    where: { userId, type: SourceType.MANUAL },
  });

  if (existing) return existing;

  return prisma.connectedSource.create({
    data: { userId, type: SourceType.MANUAL, status: SourceStatus.CONNECTED },
  });
}

sourcesRouter.post('/upload', requireAuth, upload.single('file'), async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: 'No file provided. Send multipart/form-data with a "file" field.' });
    }

    const title = typeof req.body?.title === 'string' && req.body.title.trim().length > 0
      ? req.body.title.trim()
      : file.originalname;

    const source = await getOrCreateManualSource(userId);

    const sourceItem = await prisma.sourceItem.create({
      data: {
        sourceId: source.id,
        externalId: `manual-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        itemType: file.mimetype,
        title,
      },
    });

    const evidence = await prisma.evidence.create({
      data: {
        userId,
        title,
        type: guessEvidenceType(file.mimetype),
        confidence: 0.95, // manual, user-provided upload — high confidence
        status: 'APPROVED',
        sourceItemId: sourceItem.id,
      },
    });

    const evidenceFile = await prisma.evidenceFile.create({
      data: {
        evidenceId: evidence.id,
        storageKey: `db://evidence-file/${evidence.id}`,
        mimeType: file.mimetype,
        size: file.size,
        originalName: file.originalname,
        data: Uint8Array.from(file.buffer),
      },
      select: { id: true, mimeType: true, size: true, originalName: true, createdAt: true },
    });

    res.status(201).json({ data: { evidence, file: evidenceFile } });
  } catch (error) {
    next(error);
  }
});

sourcesRouter.get('/files/:fileId', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const fileId = z.string().cuid().parse(req.params.fileId);

    const file = await prisma.evidenceFile.findUnique({
      where: { id: fileId },
      include: { evidence: { select: { userId: true } } },
    });

    if (!file || file.evidence.userId !== userId || !file.data) {
      return res.status(404).json({ error: 'File not found' });
    }

    res.setHeader('Content-Type', file.mimeType);
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(file.originalName ?? 'file')}"`);
    res.send(Buffer.from(file.data));
  } catch (error) {
    next(error);
  }
});

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
