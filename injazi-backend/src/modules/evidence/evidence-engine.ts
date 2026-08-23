import { EvidenceStatus, EvidenceType, Prisma } from '@prisma/client';
import { prisma } from '../../db/prisma.js';
import { matchEvidenceToIndicators } from './indicator-matcher.js';

type Candidate = {
userId: string;
academicYearId?: string;
title: string;
description?: string;
type: EvidenceType;
eventDate?: Date;
confidence: number;
sourceItemId?: string;
metadata?: Prisma.InputJsonValue;
// When true, the automatic keyword-matching step is skipped entirely —
// used when the caller already knows the correct indicator (or knows
// there isn't one, e.g. general prefatory info) so a guess never
// overrides a known-correct answer.
skipAutoMatch?: boolean;
};

export async function createEvidenceCandidate(candidate: Candidate) {
const evidence = await prisma.evidence.create({
data: {
userId: candidate.userId,
academicYearId: candidate.academicYearId,
title: candidate.title,
description: candidate.description,
type: candidate.type,
eventDate: candidate.eventDate,
confidence: candidate.confidence,
status:
candidate.confidence >= 0.90
? EvidenceStatus.APPROVED
: EvidenceStatus.SUGGESTED,
sourceItemId: candidate.sourceItemId,
metadata: candidate.metadata,
},
});

if (!candidate.skipAutoMatch) {
// Matches the new evidence against the 53 official indicators in the
// background. Never blocks or fails evidence creation — a matching
// failure just means no links get created, which is safe.
matchEvidenceToIndicators(evidence.id).catch((error) => {
console.error(`Indicator matching failed for evidence ${evidence.id}:`, error);
});
}

return evidence;
}

export function shouldAutoApprove(confidence: number): boolean {
return confidence >= 0.90;
}
