import { Router } from 'express';
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

const emailSchema = z
.string()
.trim()
.email()
.transform((value) => value.toLowerCase());

const passwordSchema = z
.string()
.min(8, 'Password must be at least 8 characters long')
.max(128);

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
    error: 'ظ‡ط°ط§ ط§ظ„ط¨ط±ظٹط¯ ظ…ط³طھط®ط¯ظ… ط¨ط§ظ„ظپط¹ظ„',
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
    error: 'ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ ط£ظˆ ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط± ط؛ظٹط± طµط­ظٹط­ط©',
  });
}

const validPassword = verifyPassword(
  body.password,
  user.passwordHash,
);

if (!validPassword) {
  return res.status(401).json({
    error: 'ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ ط£ظˆ ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط± ط؛ظٹط± طµط­ظٹط­ط©',
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

authRouter.post('/google', async (_req, res) => {
return res.status(501).json({
error: 'Google OAuth will be implemented in the next authentication phase.',
});
});
