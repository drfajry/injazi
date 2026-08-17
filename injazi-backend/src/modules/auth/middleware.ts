import type { NextFunction, Request, Response } from 'express';

import { prisma } from '../../db/prisma.js';
import { env } from '../../config/env.js';
import { verifyAccessToken } from './auth-utils.js';

type AuthenticatedRequest = Request & {
  userId?: string;
  userEmail?: string;
};

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const authorization = req.header('Authorization');

    if (!authorization) {
      return res.status(401).json({
        error: 'Authentication required',
      });
    }

    const parts = authorization.trim().split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return res.status(401).json({
        error: 'Invalid authorization header',
      });
    }

    const payload = verifyAccessToken(
      parts[1],
      env.JWT_SECRET,
      );

    const user = await prisma.user.findUnique({
      where: {
        id: payload.sub,
      },
      select: {
        id: true,
        email: true,
      },
    });

    if (!user) {
      return res.status(401).json({
        error: 'Session expired',
      });
    }

    const authenticatedRequest =
      req as AuthenticatedRequest;

    authenticatedRequest.userId = user.id;
    authenticatedRequest.userEmail = user.email;

    return next();
  } catch {
    return res.status(401).json({
      error: 'Invalid or expired access token',
    });
  }
}

export function getAuthenticatedUserId(
  req: Request,
): string {
  const userId = (req as AuthenticatedRequest).userId;

  if (!userId) {
    throw new Error('Authenticated user ID is missing');
  }

  return userId;
}
