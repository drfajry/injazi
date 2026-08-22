import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';
import { requireAuth, getAuthenticatedUserId } from '../auth/middleware.js';

export const portfolioRouter = Router();

/**
 * Live, computed view of the portfolio: every official criterion, its
 * indicators, and which of the user's APPROVED evidence is linked to each
 * one. This is always up to date — nothing is stored, it's assembled fresh
 * from Criterion/Indicator/EvidenceIndicatorLink on every request.
 */
portfolioRouter.get('/preview', requireAuth, async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);

    const criteria = await prisma.criterion.findMany({
      orderBy: { code: 'asc' },
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

    res.json({
      data: {
        sections,
        totalIndicators,
        coveredIndicators,
        overallCoverage: totalIndicators ? Number((coveredIndicators / totalIndicators).toFixed(3)) : 0,
      },
    });
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
    const criteria = await prisma.criterion.findMany({ orderBy: { code: 'asc' } });

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
