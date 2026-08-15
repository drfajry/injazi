import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../../db/prisma.js';

export const profileRouter = Router();

profileRouter.get('/', async (req, res, next) => {
  try {
    const userId = z.string().cuid().parse(String(req.query.userId ?? ''));
    const profile = await prisma.teacherProfile.findUnique({ where: { userId }, include: { school: true } });
    res.json({ data: profile });
  } catch (error) {
    next(error);
  }
});
