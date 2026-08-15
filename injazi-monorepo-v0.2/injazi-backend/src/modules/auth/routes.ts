import { Router } from 'express';
import { z } from 'zod';
import { AuthProvider } from '@prisma/client';
import { prisma } from '../../db/prisma.js';

export const authRouter = Router();

authRouter.post('/email', async (req, res, next) => {
  try {
    const body = z.object({ email: z.string().email() }).parse(req.body);
    const user = await prisma.user.upsert({
      where: { email: body.email },
      update: {},
      create: { email: body.email, authProvider: AuthProvider.EMAIL },
    });
    res.status(200).json({ data: { userId: user.id }, note: 'Password/magic-link flow should be added before production.' });
  } catch (error) { next(error); }
});

authRouter.post('/google', async (_req, res) => {
  res.status(501).json({ error: 'Google OAuth callback is intentionally not implemented in the starter.' });
});
