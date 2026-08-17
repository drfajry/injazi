import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../../db/prisma.js';
import {
  getAuthenticatedUserId,
  requireAuth,
} from '../auth/middleware.js';

export const profileRouter = Router();

const profileSchema = z.object({
  name: z.string().trim().min(2).max(120),
  schoolName: z.string().trim().max(200).optional().nullable(),
  stage: z.string().trim().max(100).optional().nullable(),
  subject: z.string().trim().max(100).optional().nullable(),
  photoUrl: z.string().url().optional().nullable(),
});

profileRouter.use(requireAuth);

profileRouter.get('/', async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);

    const profile = await prisma.teacherProfile.findUnique({
      where: { userId },
      include: {
        school: true,
      },
    });

    res.json({
      data: profile,
    });
  } catch (error) {
    next(error);
  }
});

profileRouter.put('/', async (req, res, next) => {
  try {
    const userId = getAuthenticatedUserId(req);
    const body = profileSchema.parse(req.body);

    let schoolId: string | null = null;

    if (body.schoolName) {
      const normalizedSchoolName = body.schoolName.trim();

      let school = await prisma.school.findFirst({
        where: {
          name: normalizedSchoolName,
        },
      });

      if (!school) {
        school = await prisma.school.create({
          data: {
            name: normalizedSchoolName,
          },
        });
      }

      schoolId = school.id;
    }

    const profile = await prisma.teacherProfile.upsert({
      where: { userId },
      create: {
        userId,
        name: body.name,
        schoolId,
        stage: body.stage ?? null,
        subject: body.subject ?? null,
        photoUrl: body.photoUrl ?? null,
      },
      update: {
        name: body.name,
        schoolId,
        stage: body.stage ?? null,
        subject: body.subject ?? null,
        photoUrl: body.photoUrl ?? null,
      },
      include: {
        school: true,
      },
    });

    res.status(200).json({
      data: profile,
    });
  } catch (error) {
    next(error);
  }
});
