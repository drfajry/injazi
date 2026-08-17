import { createHash, randomBytes } from 'node:crypto';

import { Router } from 'express';
import { Resend } from 'resend';
import { z } from 'zod';
import { AuthProvider } from '@prisma/client';

import { prisma } from '../../db/prisma.js';
import { env } from '../../config/env.js';
import {
  createAccessToken,
  hashPassword,
  verifyPassword,
} from './auth-utils.js';

export const authRouter = Router();

const resend = new Resend(env.RESEND_API_KEY);

const emailSchema = z
  .string()
  .trim()
  .email()
  .transform((value) => value.toLowerCase());

const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters long')
  .max(128);

function hashResetToken(token: string): string {
  return createHash('sha256')
    .update(token)
    .digest('hex');
}

async function sendPasswordResetEmail(
  email: string,
  token: string,
): Promise<void> {
  const resetUrl =
    `${env.APP_URL}/#/reset-password?token=` +
    encodeURIComponent(token);

  const { error } = await resend.emails.send({
    from: env.RESEND_FROM,
    to: email,
    subject: 'إعادة تعيين كلمة المرور - إنجازي',
    html: `
      <div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8;max-width:600px;margin:auto">
        <h2 style="color:#0F766E">إعادة تعيين كلمة المرور</h2>
        <p>تلقينا طلبًا لإعادة تعيين كلمة المرور لحسابك في إنجازي.</p>
        <p>
          <a
            href="${resetUrl}"
            style="display:inline-block;padding:12px 22px;background:#0F766E;color:#fff;text-decoration:none;border-radius:8px"
          >
            إعادة تعيين كلمة المرور
          </a>
        </p>
        <p>صلاحية الرابط 15 دقيقة.</p>
        <p>إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذه الرسالة.</p>
      </div>
    `,
  });

  if (error) {
    throw new Error(error.message);
  }
}

authRouter.post('/register', async (req, res, next) => {
  try {
    const body = z
      .object({
        email: emailSchema,
        password: passwordSchema,
      })
      .parse(req.body);

    const existingUser = await prisma.user.findUnique({
      where: { email: body.email },
    });

    if (existingUser?.passwordHash) {
      return res.status(409).json({
        error: 'البريد الإلكتروني مستخدم بالفعل',
      });
    }

    const passwordHash = hashPassword(body.password);

    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            passwordHash,
            authProvider: AuthProvider.EMAIL,
          },
        })
      : await prisma.user.create({
          data: {
            email: body.email,
            passwordHash,
            authProvider: AuthProvider.EMAIL,
          },
        });

    const accessToken = createAccessToken(
      user.id,
      user.email,
      env.JWT_SECRET,
      env.JWT_EXPIRES_IN,
    );

    return res.status(201).json({
      data: {
        accessToken,
        user: {
          id: user.id,
          email: user.email,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post('/login', async (req, res, next) => {
  try {
    const body = z
      .object({
        email: emailSchema,
        password: passwordSchema,
      })
      .parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
    });

    if (!user?.passwordHash) {
      return res.status(401).json({
        error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }

    const validPassword = verifyPassword(
      body.password,
      user.passwordHash,
    );

    if (!validPassword) {
      return res.status(401).json({
        error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }

    const accessToken = createAccessToken(
      user.id,
      user.email,
      env.JWT_SECRET,
      env.JWT_EXPIRES_IN,
    );

    return res.status(200).json({
      data: {
        accessToken,
        user: {
          id: user.id,
          email: user.email,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post('/forgot-password', async (req, res, next) => {
  try {
    const body = z
      .object({
        email: emailSchema,
      })
      .parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
    });

    if (user) {
      await prisma.passwordResetToken.deleteMany({
        where: {
          userId: user.id,
          usedAt: null,
        },
      });

      const token = randomBytes(32).toString('hex');
      const tokenHash = hashResetToken(token);

      await prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash,
          expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        },
      });

      try {
        await sendPasswordResetEmail(
          user.email,
          token,
        );
      } catch (emailError) {
        console.error('Password reset email failed:', emailError);

        await prisma.passwordResetToken.updateMany({
          where: {
            tokenHash,
            usedAt: null,
          },
          data: {
            usedAt: new Date(),
          },
        });
      }
    }

    return res.status(200).json({
      message:
        'إذا كان البريد مسجلًا لدينا، فسيتم إرسال رابط إعادة التعيين.',
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post('/reset-password', async (req, res, next) => {
  try {
    const body = z
      .object({
        token: z.string().min(32),
        password: passwordSchema,
      })
      .parse(req.body);

    const tokenHash = hashResetToken(body.token);

    const resetToken =
      await prisma.passwordResetToken.findUnique({
        where: { tokenHash },
      });

    if (
      !resetToken ||
      resetToken.usedAt ||
      resetToken.expiresAt.getTime() < Date.now()
    ) {
      return res.status(400).json({
        error: 'رابط إعادة التعيين غير صالح أو منتهي الصلاحية',
      });
    }

    const passwordHash = hashPassword(body.password);

    const user = await prisma.user.update({
      where: { id: resetToken.userId },
      data: {
        passwordHash,
        authProvider: AuthProvider.EMAIL,
      },
    });

    await prisma.passwordResetToken.update({
      where: { id: resetToken.id },
      data: {
        usedAt: new Date(),
      },
    });

    const accessToken = createAccessToken(
      user.id,
      user.email,
      env.JWT_SECRET,
      env.JWT_EXPIRES_IN,
    );

    return res.status(200).json({
      data: {
        accessToken,
        user: {
          id: user.id,
          email: user.email,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post('/google', async (_req, res) => {
  return res.status(501).json({
    error:
      'Google OAuth will be implemented in the next authentication phase.',
  });
});
