import { prisma } from '../../db/prisma.js';

// Criterion codes are stored as strings like 'C1', 'C10', 'C11', 'C2' — a
// plain lexicographic sort would give C1, C10, C11, C2, C3... instead of
// numeric order. Same fix already used elsewhere in the portfolio module.
function byCriterionCodeNumber<T extends { code: string }>(a: T, b: T): number {
  const numA = Number(a.code.replace(/\D/g, ''));
  const numB = Number(b.code.replace(/\D/g, ''));
  return numA - numB;
}

const DAYS_SINCE_UPLOAD_THRESHOLD = 14;
const SEMESTER_END_WARNING_DAYS = 30;

export async function computeReminders(userId: string) {
  // 1) Criteria with zero covered indicators — a real gap, not just "low
  // percentage": these are criteria the teacher hasn't touched at all yet.
  const criteria = await prisma.criterion.findMany({
    include: {
      indicators: {
        include: {
          links: {
            where: { evidence: { userId, status: 'APPROVED' } },
            take: 1,
          },
        },
      },
    },
  });

  const emptyCriteria = criteria
    .filter((criterion) => criterion.indicators.every((indicator) => indicator.links.length === 0))
    .sort(byCriterionCodeNumber)
    .map((criterion) => ({ code: criterion.code, name: criterion.name }));

  // 2) Days since the last approved evidence was uploaded — flags if the
  // teacher has gone quiet for a while.
  const lastEvidence = await prisma.evidence.findFirst({
    where: { userId, status: 'APPROVED' },
    orderBy: { createdAt: 'desc' },
    select: { createdAt: true },
  });

  const daysSinceLastUpload = lastEvidence
    ? Math.floor((Date.now() - lastEvidence.createdAt.getTime()) / (1000 * 60 * 60 * 24))
    : null;

  // 3) Approaching semester end — only shown if the school/teacher has
  // actually set an active academic year with an end date. No fabricated
  // dates: if this isn't configured, the reminder simply doesn't appear.
  const activeYear = await prisma.academicYear.findFirst({
    where: { isActive: true, endDate: { not: null } },
    select: { name: true, endDate: true },
  });

  let daysUntilSemesterEnd: number | null = null;
  if (activeYear?.endDate) {
    daysUntilSemesterEnd = Math.ceil((activeYear.endDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  }

  return {
    emptyCriteria,
    daysSinceLastUpload,
    showUploadReminder: daysSinceLastUpload === null || daysSinceLastUpload >= DAYS_SINCE_UPLOAD_THRESHOLD,
    semesterName: activeYear?.name ?? null,
    daysUntilSemesterEnd,
    showSemesterReminder:
      daysUntilSemesterEnd !== null && daysUntilSemesterEnd >= 0 && daysUntilSemesterEnd <= SEMESTER_END_WARNING_DAYS,
  };
}
