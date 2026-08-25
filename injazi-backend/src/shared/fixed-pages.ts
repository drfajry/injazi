// Fixed, well-known prefatory page types the teacher can attach to their
// portfolio (CV, schedule, etc.) — kept as a small closed list so the
// export can order and label them consistently, whether the content came
// in as an uploaded file or typed directly.
export const FIXED_PAGE_LABELS: Record<string, string> = {
  CV: 'السيرة الذاتية',
  VISION_MISSION: 'الرؤية والرسالة والأهداف',
  SCHEDULE: 'الجدول الدراسي',
  STUDENTS: 'بيانات الطلاب',
  OTHER: 'أخرى',
};

export function isValidFixedPageType(value: unknown): value is keyof typeof FIXED_PAGE_LABELS {
  return typeof value === 'string' && value in FIXED_PAGE_LABELS;
}
