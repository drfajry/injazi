import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';
import { buildPortfolioExportHtml, buildPublicPortfolioHtml, buildPublicNotFoundHtml } from './export-html.js';
import { renderFirstPdfPageToImage } from './pdf-render.js';
import { renderExcelAsHtmlTable } from './excel-render.js';
import { computeCoverageSummary } from '../coverage/coverage-engine.js';

export const portfolioRouter = Router();
export const publicPortfolioRouter = Router();

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
            include: {
              evidence: {
                include: {
                  // Only the file's id is actually used here (to build a
                  // "view file" link) — never pull the raw binary `data`
                  // column on this frequently-called live view.
                  files: { select: { id: true } },
                },
              },
            },
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

async function renderEvidenceForExport(evidence: {
  id: string;
  title: string;
  type: string;
  description: string | null;
  files: { mimeType: string; data: Uint8Array | null }[];
}) {
  const file = evidence.files[0];
  const isImage = file?.mimeType?.startsWith('image/') ?? false;
  const isPdf = file?.mimeType === 'application/pdf';
  const isExcel =
    file?.mimeType === 'application/vnd.ms-excel' ||
    file?.mimeType === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  let imageDataUrl: string | null = null;
  let tableHtml: string | null = null;

  if (isImage && file?.data) {
    imageDataUrl = `data:${file.mimeType};base64,${Buffer.from(file.data).toString('base64')}`;
  } else if (isPdf && file?.data) {
    const rendered = await renderFirstPdfPageToImage(Buffer.from(file.data));
    if (rendered) imageDataUrl = `data:image/png;base64,${rendered}`;
  } else if (isExcel && file?.data) {
    tableHtml = renderExcelAsHtmlTable(Buffer.from(file.data));
  }

  return {
    id: evidence.id,
    title: evidence.title,
    type: evidence.type,
    description: evidence.description,
    imageDataUrl,
    tableHtml,
  };
}

async function buildPortfolioExportData(userId: string) {
  const generalInfoEvidence = await prisma.evidence.findMany({
    where: {
      userId,
      status: 'APPROVED',
      metadata: { path: ['category'], equals: 'GENERAL_INFO' },
    },
    include: { files: true },
    orderBy: { createdAt: 'asc' },
  });

  const generalInfo = await Promise.all(generalInfoEvidence.map(renderEvidenceForExport));

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

  const sections = await Promise.all(
    criteria.map(async (criterion) => {
      const indicators = await Promise.all(
        criterion.indicators.map(async (indicator) => {
          const evidence = await Promise.all(
            indicator.links.map((link) => renderEvidenceForExport(link.evidence)),
          );

          return {
            id: indicator.id,
            code: indicator.code,
            name: indicator.name,
            evidence,
          };
        }),
      );

      const coveredCount = indicators.filter((indicator) => indicator.evidence.length > 0).length;

      return {
        criterionId: criterion.id,
        code: criterion.code,
        name: criterion.name,
        totalIndicators: indicators.length,
        coveredIndicators: coveredCount,
        indicators,
      };
    }),
  );

  const totalIndicators = sections.reduce((sum, section) => sum + section.totalIndicators, 0);
  const coveredIndicators = sections.reduce((sum, section) => sum + section.coveredIndicators, 0);

  return {
    generalInfo,
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

function generateSlug(): string {
  // 10 random alphanumeric chars — short enough to share, long enough that
  // guessing an existing one is impractical.
  return Array.from({ length: 10 }, () =>
    '0123456789abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 36)],
  ).join('');
}

/**
 * Publishes a public, no-login link to a summary of the portfolio. Reuses
 * the person's existing public slug if they already have one (so sharing
 * doesn't generate a new link every time), otherwise creates one.
 *
 * By design, the public view only shows the completion percentage and
 * which criteria/indicators are covered — never evidence titles or
 * content. Evidence files can contain student names or other sensitive
 * material, and this link requires no authentication to view.
 */
portfolioRouter.post('/publish', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);

    const existing = await prisma.portfolioVersion.findFirst({
      where: { userId, visibility: 'PUBLIC', publicSlug: { not: null } },
    });

    if (existing) {
      return res.json({ data: { slug: existing.publicSlug } });
    }

    const count = await prisma.portfolioVersion.count({ where: { userId } });
    let slug = generateSlug();

    // Extremely unlikely to collide (36^10 possibilities), but guard anyway.
    while (await prisma.portfolioVersion.findUnique({ where: { publicSlug: slug } })) {
      slug = generateSlug();
    }

    const version = await prisma.portfolioVersion.create({
      data: { userId, versionNo: count + 1, visibility: 'PUBLIC', publicSlug: slug },
    });

    res.status(201).json({ data: { slug: version.publicSlug } });
  } catch (error) { next(error); }
});

/** Revokes the public link — future visits to it will get a 404. */
portfolioRouter.post('/unpublish', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    await prisma.portfolioVersion.updateMany({
      where: { userId, visibility: 'PUBLIC' },
      data: { visibility: 'PRIVATE', publicSlug: null },
    });
    res.status(204).send();
  } catch (error) { next(error); }
});

/**
 * Public, unauthenticated view. Deliberately minimal: teacher name +
 * overall completion percentage + a checklist of criteria/indicators
 * covered or not. No evidence titles, descriptions, or files — those stay
 * behind login. This is meant to be shareable as a lightweight proof of
 * progress, not a full portfolio export.
 */
publicPortfolioRouter.get('/:slug', async (req, res, next) => {
  try {
    const slug = z.string().min(1).parse(req.params.slug);

    const version = await prisma.portfolioVersion.findUnique({
      where: { publicSlug: slug },
    });

    if (!version || version.visibility !== 'PUBLIC') {
      res.status(404).setHeader('Content-Type', 'text/html; charset=utf-8');
      return res.send(buildPublicNotFoundHtml());
    }

    const [profile, summary] = await Promise.all([
      prisma.teacherProfile.findUnique({ where: { userId: version.userId } }),
      computeCoverageSummary(version.userId),
    ]);

    const criteria = (await prisma.criterion.findMany({
      include: { indicators: true },
    })).sort(byCriterionCodeNumber);

    const coveredIndicatorIds = new Set(summary.indicators.map((i) => i.indicatorId));

    const html = buildPublicPortfolioHtml({
      teacherName: profile?.name ?? 'المعلم',
      overallCoverage: summary.overallCoverage,
      totalIndicators: summary.totalIndicators,
      complete: summary.complete,
      sections: criteria.map((criterion) => ({
        name: criterion.name,
        indicators: criterion.indicators.map((indicator) => ({
          name: indicator.name,
          covered: coveredIndicatorIds.has(indicator.id),
        })),
      })),
    });

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  } catch (error) { next(error); }
});
