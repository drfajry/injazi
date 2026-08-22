import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { buildPortfolioExportHtml } from './export-html.js';

export const portfolioRouter = Router();

// Criterion codes are stored as strings like 'C1', 'C10', 'C11', 'C2' — a
// plain lexicographic sort (what Prisma's orderBy does) compares them
// character by character, producing C1, C10, C11, C2, C3... instead of
// numeric order. This extracts the number and sorts on that instead.
function byCriterionCodeNumber<T extends { code: string }>(a: T, b: T): number {
  const numA = Number(a.code.replace(/\D/g, ''));
  const numB = Number(b.code.replace(/\D/g, ''));
  return numA - numB;
}

async function buildPortfolioData(userId: string) {
  const criteria = await prisma.criterion.findMany({
    include: {
      indicators: {
        include: {
          links: {
            where: { evidence: { userId, status: 'APPROVED' } },
            include: { evidence: { include: { files: true } } },
            orderBy: { matchScore: 'desc' },
          },
        },
      },
    },
  });

  criteria.sort(byCriterionCodeNumber);

  const sections = criteria.map((criterion) => {
    const indicators = criterion.indicators.map((indicator) => ({
      id: indicator.id,
      code: indicator.code,
      name: indicator.name,
      evidence: indicator.links.map((link) => ({
        id: link.evidence.id,
        title: link.evidence.title,
        type: link.evidence.type,
        matchScore: link.matchScore,
        fileId: link.evidence.files[0]?.id ?? null,
      })),
    }));

    const coveredCount = indicators.filter((indicator) => indicator.evidence.length > 0).length;

    return {
      criterionId: criterion.id,
      code: criterion.code,
      name: criterion.name,
      totalIndicators: indicators.length,
      coveredIndicators: coveredCount,
      indicators,
    };
  });

  const totalIndicators = sections.reduce((sum, section) => sum + section.totalIndicators, 0);
  const coveredIndicators = sections.reduce((sum, section) => sum + section.coveredIndicators, 0);

  return {
    sections,
    totalIndicators,
    coveredIndicators,
    overallCoverage: totalIndicators ? Number((coveredIndicators / totalIndicators).toFixed(3)) : 0,
  };
}

async function buildPortfolioExportData(userId: string) {
  const criteria = await prisma.criterion.findMany({
    include: {
      indicators: {
        include: {
          links: {
            where: { evidence: { userId, status: 'APPROVED' } },
            include: { evidence: { include: { files: true } } },
            orderBy: { matchScore: 'desc' },
          },
        },
      },
    },
  });

  criteria.sort(byCriterionCodeNumber);

  const sections = criteria.map((criterion) => {
    const indicators = criterion.indicators.map((indicator) => ({
      id: indicator.id,
      code: indicator.code,
      name: indicator.name,
      evidence: indicator.links.map((link) => {
        const file = link.evidence.files[0];
        const isImage = file?.mimeType?.startsWith('image/') ?? false;

        return {
          id: link.evidence.id,
          title: link.evidence.title,
          type: link.evidence.type,
          // The extracted text itself (already stored from upload time) —
          // shown as a quoted excerpt so the evidence is actually verifiable
          // in the printed document, not just a filename label.
          description: link.evidence.description,
          // Only images are embedded as actual visual content (base64 data
          // URI). PDFs/Word/Excel would need a rasterization step (heavy,
          // same memory concerns as server-side PDF generation) — those show
          // their extracted text excerpt instead, which is honest and doesn't
          // require new heavy dependencies.
          imageDataUrl: isImage && file?.data
            ? `data:${file.mimeType};base64,${Buffer.from(file.data).toString('base64')}`
            : null,
        };
      }),
    }));

    const coveredCount = indicators.filter((indicator) => indicator.evidence.length > 0).length;

    return {
      criterionId: criterion.id,
      code: criterion.code,
      name: criterion.name,
      totalIndicators: indicators.length,
      coveredIndicators: coveredCount,
      indicators,
    };
  });

  const totalIndicators = sections.reduce((sum, section) => sum + section.totalIndicators, 0);
  const coveredIndicators = sections.reduce((sum, section) => sum + section.coveredIndicators, 0);

  return {
    sections,
    totalIndicators,
    coveredIndicators,
    overallCoverage: totalIndicators ? Number((coveredIndicators / totalIndicators).toFixed(3)) : 0,
  };
}

/**
 * Live, computed view of the portfolio: every official criterion, its
 * indicators, and which of the user's APPROVED evidence is linked to each
 * one. This is always up to date — nothing is stored, it's assembled fresh
 * from Criterion/Indicator/EvidenceIndicatorLink on every request.
 */
portfolioRouter.get('/preview', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const data = await buildPortfolioData(userId);
    res.json({ data });
  } catch (error) { next(error); }
});

/**
 * Returns a full, print-ready HTML document of the whole portfolio. Opened
 * directly by the browser (not downloaded as JSON) — the person uses the
 * browser's own Print → Save as PDF, which renders Arabic RTL correctly
 * without needing a heavy PDF-generation dependency on the server.
 */
portfolioRouter.get('/export', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const [data, profile] = await Promise.all([
      buildPortfolioExportData(userId),
      prisma.teacherProfile.findUnique({ where: { userId }, include: { school: true } }),
    ]);

    const html = buildPortfolioExportHtml({
      teacherName: profile?.name ?? 'المعلم',
      schoolName: profile?.school?.name ?? null,
      subject: profile?.subject ?? null,
      ...data,
    });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  } catch (error) { next(error); }
});

portfolioRouter.get('/versions', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const versions = await prisma.portfolioVersion.findMany({
      where: { userId },
      orderBy: { versionNo: 'desc' },
    });
    res.json({ data: versions });
  } catch (error) { next(error); }
});

portfolioRouter.post('/generate', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const body = z.object({ academicYearId: z.string().cuid().optional() }).parse(req.body ?? {});

    // Keep PortfolioSection rows in sync with the official criteria, so the
    // ordering/visibility metadata exists even though the section CONTENT
    // (evidence per indicator) is always computed live via /preview.
    const criteria = (await prisma.criterion.findMany()).sort(byCriterionCodeNumber);

    for (const [index, criterion] of criteria.entries()) {
      const existing = await prisma.portfolioSection.findFirst({
        where: { userId, sectionKey: criterion.code },
        select: { id: true },
      });

      if (existing) {
        await prisma.portfolioSection.update({
          where: { id: existing.id },
          data: { title: criterion.name, sortOrder: index },
        });
      } else {
        await prisma.portfolioSection.create({
          data: {
            userId,
            academicYearId: body.academicYearId,
            sectionKey: criterion.code,
            title: criterion.name,
            sortOrder: index,
          },
        });
      }
    }

    const count = await prisma.portfolioVersion.count({ where: { userId } });
    const version = await prisma.portfolioVersion.create({
      data: {
        userId,
        academicYearId: body.academicYearId,
        versionNo: count + 1,
        visibility: 'PRIVATE',
      },
    });

    res.status(201).json({ data: version });
  } catch (error) { next(error); }
});
