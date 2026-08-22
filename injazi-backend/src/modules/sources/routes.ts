import { Router } from 'express';
import multer from 'multer';
import { EvidenceType, SourceStatus, SourceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { extractText } from './text-extraction.js';
import { ingestUrl, UrlIngestionError } from './url-ingestion.js';

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

// Basic SSRF guard: blocks obviously-private/internal hostnames before we
// let the server fetch a user-supplied URL. Not exhaustive (doesn't resolve
// DNS to check for rebinding), but stops the common cases.
const BLOCKED_HOSTNAME_PATTERNS = [
  /^localhost$/i,
  /^127\./,
  /^0\.0\.0\.0$/,
  /^10\./,
  /^172\.(1[6-9]|2\d|3[01])\./,
  /^192\.168\./,
  /^169\.254\./,
  /^\[?::1\]?$/,
  /\.local$/i,
];

function isSafeUrl(rawUrl: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    return false;
  }

  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return false;

  return !BLOCKED_HOSTNAME_PATTERNS.some((pattern) => pattern.test(parsed.hostname));
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

    // Best-effort text extraction — never blocks the upload if it fails or
    // the file type isn't supported yet (e.g. images require OCR, not built yet).
    const extractedText = await extractText(file.buffer, file.mimetype);

    const evidence = await prisma.evidence.create({
      data: {
        userId,
        title,
        description: extractedText,
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

    res.status(201).json({
      data: {
        evidence,
        file: evidenceFile,
        textExtracted: extractedText !== null,
      },
    });
  } catch (error) {
    next(error);
  }
});

sourcesRouter.post('/url', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const body = z.object({ url: z.string().url() }).parse(req.body);

    if (!isSafeUrl(body.url)) {
      return res.status(400).json({ error: 'هذا الرابط غير مسموح به.' });
    }

    let page;
    try {
      page = await ingestUrl(body.url);
    } catch (error) {
      if (error instanceof UrlIngestionError) {
        return res.status(422).json({ error: error.message });
      }
      throw error;
    }

    const source = await getOrCreateManualSource(userId);

    const sourceItem = await prisma.sourceItem.create({
      data: {
        sourceId: source.id,
        externalId: `url-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        itemType: 'text/html',
        title: page.title,
        url: body.url,
      },
    });

    const evidence = await prisma.evidence.create({
      data: {
        userId,
        title: page.title,
        description: page.text,
        type: EvidenceType.LINK,
        confidence: 0.9, // fetched successfully but content wasn't reviewed — slightly below auto-approve threshold
        status: page.text ? 'APPROVED' : 'SUGGESTED',
        sourceItemId: sourceItem.id,
      },
    });

    res.status(201).json({
      data: {
        evidence,
        textExtracted: page.text !== null,
      },
    });
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

sourcesRouter.get('/', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const sources = await prisma.connectedSource.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
    res.json({ data: sources });
  } catch (error) {
    next(error);
  }
});

sourcesRouter.post('/google/connect', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const body = z.object({ externalAccountId: z.string().min(1).optional() }).parse(req.body);
    const source = await prisma.connectedSource.create({
      data: {
        userId,
        type: SourceType.GOOGLE_DRIVE,
        status: SourceStatus.PENDING,
        externalAccountId: body.externalAccountId,
      },
    });
    res.status(201).json({ data: source, next: 'Implement Google OAuth callback and token vault.' });
  } catch (error) { next(error); }
});

sourcesRouter.post('/madrasati/connect', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const source = await prisma.connectedSource.create({
      data: { userId, type: SourceType.MADRASATI, status: SourceStatus.PENDING },
    });
    res.status(201).json({ data: source, next: 'Attach the approved Madrasati connector flow.' });
  } catch (error) { next(error); }
});

sourcesRouter.post('/:id/sync', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const source = await prisma.connectedSource.findUnique({ where: { id } });

    if (!source || source.userId !== userId) {
      return res.status(404).json({ error: 'Source not found' });
    }

    const updated = await prisma.connectedSource.update({ where: { id }, data: { lastSyncAt: new Date(), status: SourceStatus.CONNECTED } });
    res.status(202).json({ data: updated, queued: true });
  } catch (error) { next(error); }
});
