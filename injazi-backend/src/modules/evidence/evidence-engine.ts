import { EvidenceStatus, EvidenceType, Prisma } from '@prisma/client';
import { prisma } from '../../db/prisma.js';

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
};

export async function createEvidenceCandidate(candidate: Candidate) {
return prisma.evidence.create({
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
}

export function shouldAutoApprove(confidence: number): boolean {
return confidence >= 0.90;
}
