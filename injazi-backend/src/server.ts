import express from 'express';
import cors from 'cors';
import { env } from './config/env.js';
import { prisma } from './db/prisma.js';
import { authRouter } from './modules/auth/routes.js';
import { profileRouter } from './modules/profile/routes.js';
import { sourcesRouter } from './modules/sources/routes.js';
import { evidenceRouter } from './modules/evidence/routes.js';
import { coverageRouter } from './modules/coverage/routes.js';
import { portfolioRouter } from './modules/portfolio/routes.js';

const app = express();
app.use(cors({ origin: env.CORS_ORIGIN }));
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'injazi-backend' }));
app.use('/auth', authRouter);
app.use('/me/profile', profileRouter);
app.use('/sources', sourcesRouter);
app.use('/evidence', evidenceRouter);
app.use('/me/coverage', coverageRouter);
app.use('/me/portfolio', portfolioRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(400).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
});

const server = app.listen(env.PORT, () => {
  console.log(`إنجازي backend listening on http://localhost:${env.PORT}`);
});

const shutdown = async () => {
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
