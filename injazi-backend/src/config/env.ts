import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
DATABASE_URL: z.string().min(1),
PORT: z.coerce.number().int().positive().default(4000),
CORS_ORIGIN: z.string().default('http://localhost:3000'),
JWT_SECRET: z.string().min(32),
JWT_EXPIRES_IN: z.coerce.number().int().positive().default(604800),
});

export const env = schema.parse(process.env);
