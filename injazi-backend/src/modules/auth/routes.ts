import { createHash, randomInt } from 'node:crypto';

import { AuthProvider } from '@prisma/client';
import { Router } from 'express';
import { Resend } from 'resend';
import { z } from 'zod';

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
  .min(8)
  .max(128);

function hashValue(value: string): string {
  return createHash('sha256')
    .update(value)
    .digest('hex');
}

function createVerificationCode(): string {
  return String(randomInt(100000, 1000000));
}

async function sendVerificationEmail(
  email: string,
  code: string,
): Promise<void> {
  const { error } = await resend.emails.send({
    from: env.RESEND_FROM,
    to: email,
    subject: '\u062a\u062d\u0642\u064a\u0642 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a - \u0625\u0646\u062c\u0627\u0632\u064a',
    html: `
      <div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8;max-width:600px;margin:auto">
        <h2 style="color:#0F766E">\u062a\u062d\u0642\u064a\u0642 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a</h2>
        <p>\u0627\u0633\u062a\u062e\u062f\u0645 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642 \u0627\u0644\u062a\u0627\u0644\u064a \u0644\u0625\u0643\u0645\u0627\u0644 \u062a\u0633\u062c\u064a\u0644\u0643 \u0641\u064a \u0625\u0646\u062c\u0627\u0632\u064a:</p>
        <div style="font-size:32px;font-weight:800;letter-spacing:8px;text-align:center;margin:24px 0;color:#0F766E">
          ${code}
        </div>
        <p>\u0635\u0644\u0627\u062d\u064a\u0629 \u0627\u0644\u0631\u0645\u0632 10 \u062f\u0642\u0627\u0626\u0642.</p>
        <p>\u0625\u0630\u0627 \u0644\u0645 \u062a\u0642\u0645 \u0628\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062d\u0633\u0627\u0628\u060c \u064a\u0645\u0643\u0646\u0643 \u062a\u062c\u0627\u0647\u0644 \u0627\u0644\u0631\u0633\u0627\u0644\u0629.</p>
      </div>
    `,
  });

  if (error) {
    throw new Error(error.message);
  }
}

async function issueVerificationCode(
  userId: string,
  email: string,
): Promise<void> {
  await prisma.emailVerificationCode.updateMany({
    where: {
      userId,
      usedAt: null,
    },
    data: {
      usedAt: new Date(),
    },
  });

  const code = createVerificationCode();

  await prisma.emailVerificationCode.create({
    data: {
      userId,
      codeHash: hashValue(code),
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    },
  });

  await sendVerificationEmail(email, code);
}

function authError(res: any, status: number, code: string) {
  return res.status(status).json({
    error: code,
  });
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

    if (existingUser?.emailVerifiedAt) {
      return authError(res, 409, 'EMAIL_ALREADY_REGISTERED');
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

    await issueVerificationCode(
      user.id,
      user.email,
    );

    return res.status(201).json({
      data: {
        requiresEmailVerification: true,
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

authRouter.post('/verify-email', async (req, res, next) => {
  try {
    const body = z
      .object({
        email: emailSchema,
        code: z.string().regex(/^\d{6}$/),
      })
      .parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
    });

    if (!user?.passwordHash) {
      return authError(res, 400, 'INVALID_VERIFICATION_CODE');
    }

    if (user.emailVerifiedAt) {
      return authError(res, 409, 'EMAIL_ALREADY_VERIFIED');
    }

    const verification = await prisma.emailVerificationCode.findFirst({
      where: {
        userId: user.id,
        usedAt: null,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    if (!verification) {
      return authError(res, 400, 'VERIFICATION_CODE_NOT_FOUND');
    }

    if (verification.expiresAt.getTime() <= Date.now()) {
      return authError(res, 400, 'VERIFICATION_CODE_EXPIRED');
    }

    if (verification.attempts >= 5) {
      return authError(res, 429, 'VERIFICATION_ATTEMPTS_EXCEEDED');
    }

    const valid = hashValue(body.code) === verification.codeHash;

    if (!valid) {
      await prisma.emailVerificationCode.update({
        where: { id: verification.id },
        data: {
          attempts: {
            increment: 1,
          },
        },
      });

      return authError(res, 400, 'INVALID_VERIFICATION_CODE');
    }

    await prisma.$transaction([
      prisma.emailVerificationCode.update({
        where: { id: verification.id },
        data: {
          usedAt: new Date(),
        },
      }),
      prisma.user.update({
        where: { id: user.id },
        data: {
          emailVerifiedAt: new Date(),
        },
      }),
    ]);

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

authRouter.post('/resend-verification', async (req, res, next) => {
  try {
    const body = z
      .object({
        email: emailSchema,
      })
      .parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: body.email },
    });

    if (!user || !user.passwordHash) {
      return res.status(200).json({
        data: {
          sent: true,
        },
      });
    }

    if (user.emailVerifiedAt) {
      return res.status(200).json({
        data: {
          alreadyVerified: true,
        },
      });
    }

    await issueVerificationCode(
      user.id,
      user.email,
    );

    return res.status(200).json({
      data: {
        sent: true,
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
      return authError(res, 401, 'INVALID_CREDENTIALS');
    }

    const validPassword = verifyPassword(
      body.password,
      user.passwordHash,
    );

    if (!validPassword) {
      return authError(res, 401, 'INVALID_CREDENTIALS');
    }

    if (!user.emailVerifiedAt) {
      return authError(res, 403, 'EMAIL_NOT_VERIFIED');
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

      const token = cryptoToken();

      await prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash: hashValue(token),
          expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        },
      });

      const resetUrl =
        `${env.APP_URL}/#/reset-password?token=` +
        encodeURIComponent(token);

      const { error } = await resend.emails.send({
        from: env.RESEND_FROM,
        to: user.email,
        subject: '\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 - \u0625\u0646\u062c\u0627\u0632\u064a',
        html: `
          <div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8">
            <h2>\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631</h2>
            <p>\u062a\u0644\u0642\u064a\u0646\u0627 \u0637\u0644\u0628\u064b\u0627 \u0644\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631\u0643.</p>
            <p><a href="${resetUrl}">\u0625\u0639\u0627\u062f\u0629 \u062a\u0639\u064a\u064a\u0646 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631</a></p>
            <p>\u0635\u0644\u0627\u062d\u064a\u0629 \u0627\u0644\u0631\u0627\u0628\u0637 15 \u062f\u0642\u064a\u0642\u0629.</p>
          </div>
        `,
      });

      if (error) {
        console.error('Password reset email failed:', error.message);
      }
    }

    return res.status(200).json({
      data: {
        sent: true,
      },
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

    const resetToken =
      await prisma.passwordResetToken.findUnique({
        where: {
          tokenHash: hashValue(body.token),
        },
      });

    if (
      !resetToken ||
      resetToken.usedAt ||
      resetToken.expiresAt.getTime() < Date.now()
    ) {
      return authError(res, 400, 'INVALID_RESET_TOKEN');
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

    if (!user.emailVerifiedAt) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          emailVerifiedAt: new Date(),
        },
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

function cryptoToken(): string {
  return hashValue(
    `${Date.now()}-${Math.random()}-${process.pid}-${randomInt(1, 1000000)}`,
  );
}

authRouter.post('/google', async (_req, res) => {
  return res.status(501).json({
    error: 'GOOGLE_OAUTH_NOT_IMPLEMENTED',
  });
});
