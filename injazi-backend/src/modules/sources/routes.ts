import { Router } from 'express';
import multer from 'multer';
import { EvidenceType, SourceStatus, SourceType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { extractText } from './text-extraction.js';
import { ingestUrl, UrlIngestionError } from './url-ingestion.js';
import { createEvidenceCandidate } from '../evidence/evidence-engine.js';
import {
  isGoogleDriveConfigured,
  buildAuthUrl,
  verifyState,
  exchangeCodeForTokens,
  getGoogleAccountEmail,
  listDriveFiles,
  downloadDriveFile,
  type GoogleTokens,
} from './google-oauth.js';
import { env } from '../../config/env.js';
import { FIXED_PAGE_LABELS } from '../../shared/fixed-pages.js';

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

// Fixed, well-known prefatory page types the teacher can attach as
// ready-made files (CV, schedule, etc.) — kept as a small closed list so
// the export can order and label them consistently.

sourcesRouter.post('/upload', requireAuth, upload.single('file'), async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: 'No file provided. Send multipart/form-data with a "file" field.' });
    }

    // Optional: mark this upload as a ready-made "fixed page" (CV, schedule,
    // etc.) instead of running it through indicator matching. These appear
    // at the very start of the exported portfolio, before the 11 criteria.
    const fixedPageType = typeof req.body?.fixedPageType === 'string' ? req.body.fixedPageType : undefined;
    const isFixedPage = fixedPageType !== undefined && fixedPageType in FIXED_PAGE_LABELS;
    const fixedPageLabel = isFixedPage ? FIXED_PAGE_LABELS[fixedPageType] : undefined;

    const title = typeof req.body?.title === 'string' && req.body.title.trim().length > 0
      ? req.body.title.trim()
      : (fixedPageLabel ?? file.originalname);

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

    const evidence = await createEvidenceCandidate({
      userId,
      title,
      description: extractedText ?? undefined,
      type: guessEvidenceType(file.mimetype),
      confidence: 0.95, // manual, user-provided upload — high confidence
      sourceItemId: sourceItem.id,
      metadata: isFixedPage ? { category: 'GENERAL_INFO', label: fixedPageLabel, fixedPageType } : undefined,
      skipAutoMatch: isFixedPage,
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

    const evidence = await createEvidenceCandidate({
      userId,
      title: page.title,
      description: page.text ?? undefined,
      type: EvidenceType.LINK,
      // fetched successfully but no readable text found — treat as needing
      // review rather than auto-approving an evidence item with no content.
      confidence: page.text ? 0.9 : 0.5,
      sourceItemId: sourceItem.id,
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

sourcesRouter.get('/google/auth-url', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);

    if (!isGoogleDriveConfigured()) {
      return res.status(503).json({ error: 'Google Drive غير مفعّل على الخادم بعد.' });
    }

    const url = buildAuthUrl(userId);
    res.json({ url });
  } catch (error) {
    next(error);
  }
});

sourcesRouter.get('/google/callback', async (req, res, next) => {
  try {
    const query = z.object({
      code: z.string().min(1).optional(),
      state: z.string().min(1),
      error: z.string().optional(),
    }).parse(req.query);

    const appRedirect = (status: 'connected' | 'error', message?: string) => {
      const url = new URL(env.APP_URL);
      url.hash = `/sources?google=${status}${message ? `&message=${encodeURIComponent(message)}` : ''}`;
      res.redirect(url.toString());
    };

    if (query.error || !query.code) {
      return appRedirect('error', 'تم إلغاء الربط مع Google.');
    }

    let userId: string;
    try {
      userId = verifyState(query.state);
    } catch {
      return appRedirect('error', 'انتهت صلاحية طلب الربط. حاول مرة أخرى.');
    }

    const tokens = await exchangeCodeForTokens(query.code);
    const email = await getGoogleAccountEmail(tokens);

    const existing = await prisma.connectedSource.findFirst({
      where: { userId, type: SourceType.GOOGLE_DRIVE },
    });

    if (existing) {
      await prisma.connectedSource.update({
        where: { id: existing.id },
        data: {
          status: SourceStatus.CONNECTED,
          externalAccountId: email,
          metadata: tokens as unknown as object,
          lastSyncAt: null,
        },
      });
    } else {
      await prisma.connectedSource.create({
        data: {
          userId,
          type: SourceType.GOOGLE_DRIVE,
          status: SourceStatus.CONNECTED,
          externalAccountId: email,
          metadata: tokens as unknown as object,
        },
      });
    }

    return appRedirect('connected');
  } catch (error) {
    next(error);
  }
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

    if (source.type === SourceType.GOOGLE_DRIVE) {
      const tokens = source.metadata as unknown as GoogleTokens | null;

      if (!tokens?.access_token) {
        return res.status(400).json({ error: 'حساب Google Drive غير مربوط بشكل صحيح. أعد الربط.' });
      }

      const files = await listDriveFiles(tokens);

      for (const file of files) {
        await prisma.sourceItem.upsert({
          where: { sourceId_externalId: { sourceId: source.id, externalId: file.id } },
          update: { title: file.name, itemType: file.mimeType, url: file.webViewLink },
          create: {
            sourceId: source.id,
            externalId: file.id,
            itemType: file.mimeType,
            title: file.name,
            url: file.webViewLink,
          },
        });
      }

      const updated = await prisma.connectedSource.update({
        where: { id },
        data: { lastSyncAt: new Date(), status: SourceStatus.CONNECTED },
      });

      const items = await prisma.sourceItem.findMany({
        where: { sourceId: source.id },
        orderBy: { title: 'asc' },
      });

      return res.status(200).json({
        data: updated,
        filesFound: files.length,
        items: items.map((item) => ({
          id: item.id,
          externalId: item.externalId,
          title: item.title,
          itemType: item.itemType,
        })),
      });
    }

    const updated = await prisma.connectedSource.update({ where: { id }, data: { lastSyncAt: new Date(), status: SourceStatus.CONNECTED } });
    res.status(202).json({ data: updated, queued: true });
  } catch (error) { next(error); }
});

const MAX_DRIVE_IMPORT_BYTES = 15 * 1024 * 1024; // 15MB, matches the manual upload limit

/**
 * Actually pulls a specific Drive file's content and turns it into a real
 * evidence item — downloads it, extracts text, stores the file, and runs
 * indicator matching, exactly like a manual upload. Listing (`/sync`) only
 * gives file names; this is the step that makes a Drive file usable the
 * same way as anything uploaded directly.
 */
sourcesRouter.post('/:id/import/:fileId', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const id = z.string().cuid().parse(req.params.id);
    const fileId = z.string().min(1).parse(req.params.fileId);

    const source = await prisma.connectedSource.findUnique({ where: { id } });
    if (!source || source.userId !== userId || source.type !== SourceType.GOOGLE_DRIVE) {
      return res.status(404).json({ error: 'Source not found' });
    }

    const tokens = source.metadata as unknown as GoogleTokens | null;
    if (!tokens?.access_token) {
      return res.status(400).json({ error: 'حساب Google Drive غير مربوط بشكل صحيح. أعد الربط.' });
    }

    const sourceItem = await prisma.sourceItem.findFirst({
      where: { sourceId: source.id, externalId: fileId },
    });
    if (!sourceItem) {
      return res.status(404).json({ error: 'الملف غير موجود ضمن قائمة الملفات المتزامنة. جرّب المزامنة أولًا.' });
    }

    const downloaded = await downloadDriveFile(tokens, fileId, sourceItem.itemType ?? 'application/octet-stream');

    if (downloaded.buffer.byteLength > MAX_DRIVE_IMPORT_BYTES) {
      return res.status(413).json({ error: 'حجم الملف كبير جدًا (الحد الأقصى 15MB).' });
    }

    const extractedText = await extractText(downloaded.buffer, downloaded.mimeType);

    const evidence = await createEvidenceCandidate({
      userId,
      title: sourceItem.title ?? 'ملف من Google Drive',
      description: extractedText ?? undefined,
      type: guessEvidenceType(downloaded.mimeType),
      confidence: 0.95,
      sourceItemId: sourceItem.id,
    });

    const evidenceFile = await prisma.evidenceFile.create({
      data: {
        evidenceId: evidence.id,
        storageKey: `db://evidence-file/${evidence.id}`,
        mimeType: downloaded.mimeType,
        size: downloaded.buffer.byteLength,
        originalName: sourceItem.title,
        data: Uint8Array.from(downloaded.buffer),
      },
      select: { id: true, mimeType: true, size: true, originalName: true, createdAt: true },
    });

    res.status(201).json({
      data: { evidence, file: evidenceFile, textExtracted: extractedText !== null },
    });
  } catch (error) { next(error); }
});
