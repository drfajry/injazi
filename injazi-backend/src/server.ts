import express from 'express';
import cors from 'cors';
import { env } from './config/env.js';
import { prisma } from './db/prisma.js';
import { seedIndicators } from './db/seed-indicators.js';
import { authRouter } from './modules/auth/routes.js';
import { profileRouter } from './modules/profile/routes.js';
import { sourcesRouter } from './modules/sources/routes.js';
import { evidenceRouter } from './modules/evidence/routes.js';
import { coverageRouter } from './modules/coverage/routes.js';
import { portfolioRouter, publicPortfolioRouter } from './modules/portfolio/routes.js';

const app = express();
app.use(cors({
  origin: (origin, callback) => {
    // Allow the configured web app origin, plus any Chrome extension
    // (chrome-extension://<id>) — needed for the Madrasati companion
    // extension, which calls this API directly from the browser rather
    // than through a server-side proxy.
    if (!origin || origin === env.CORS_ORIGIN || origin.startsWith('chrome-extension://')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
}));
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'injazi-backend' }));
app.use('/auth', authRouter);
app.use('/me/profile', profileRouter);
app.use('/sources', sourcesRouter);
app.use('/evidence', evidenceRouter);
app.use('/me/coverage', coverageRouter);
app.use('/me/portfolio', portfolioRouter);
app.use('/public/portfolio', publicPortfolioRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(400).json({ error: err instanceof Error ? err.message : 'Unexpected error' });
});

const server = app.listen(env.PORT, () => {
  console.log(`إنجازي backend listening on http://localhost:${env.PORT}`);
});

// Seed reference indicators after boot. Safe to run on every deploy: uses
// upsert, so it never duplicates data. Runs in the background so it never
// delays server startup or blocks incoming requests.
seedIndicators().catch((error) => {
  console.error('Indicator seed failed (server will keep running):', error);
});

const shutdown = async () => {
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
