type ExportEvidence = {
  title: string;
  type: string;
};

type ExportIndicator = {
  code: string;
  name: string;
  evidence: ExportEvidence[];
};

type ExportSection = {
  code: string;
  name: string;
  totalIndicators: number;
  coveredIndicators: number;
  indicators: ExportIndicator[];
};

type ExportData = {
  teacherName: string;
  sections: ExportSection[];
  totalIndicators: number;
  coveredIndicators: number;
  overallCoverage: number;
};

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Builds a complete, print-ready HTML document for the whole portfolio.
 * Intentionally NOT generated as a binary PDF server-side — real PDF
 * libraries (or a headless-browser approach like Puppeteer) need far more
 * memory than the free hosting tier has, and their Arabic RTL text shaping
 * is often unreliable. Real browsers already render Arabic correctly, so
 * this HTML is opened in a new tab and the person uses the browser's own
 * "Print → Save as PDF" — same visual result, zero server risk.
 */
export function buildPortfolioExportHtml(data: ExportData): string {
  const date = new Intl.DateTimeFormat('ar-SA-u-ca-gregory', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date());

  const overallPercent = (data.overallCoverage * 100).toFixed(1);

  const sectionsHtml = data.sections
    .map((section) => {
      const sectionPercent = section.totalIndicators
        ? Math.round((section.coveredIndicators / section.totalIndicators) * 100)
        : 0;

      const indicatorsHtml = section.indicators
        .map((indicator) => {
          const covered = indicator.evidence.length > 0;
          const evidenceHtml = covered
            ? `<ul class="evidence-list">${indicator.evidence
                .map((e) => `<li>${escapeHtml(e.title)}</li>`)
                .join('')}</ul>`
            : `<p class="no-evidence">لا يوجد دليل مرتبط بعد</p>`;

          return `
            <div class="indicator ${covered ? 'covered' : 'missing'}">
              <div class="indicator-header">
                <span class="status-dot">${covered ? '✓' : '○'}</span>
                <span class="indicator-name">${escapeHtml(indicator.name)}</span>
              </div>
              ${evidenceHtml}
            </div>
          `;
        })
        .join('');

      return `
        <section class="criterion-section">
          <div class="criterion-header">
            <h2>${escapeHtml(section.name)}</h2>
            <span class="criterion-badge">${section.coveredIndicators} / ${section.totalIndicators} (${sectionPercent}%)</span>
          </div>
          ${indicatorsHtml}
        </section>
      `;
    })
    .join('');

  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8" />
<title>ملف الإنجاز — ${escapeHtml(data.teacherName)}</title>
<style>
  @page { size: A4; margin: 18mm 15mm; }
  * { box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
    color: #0F172A;
    line-height: 1.6;
    margin: 0;
    padding: 24px;
  }
  .cover {
    text-align: center;
    padding: 40px 0 30px;
    border-bottom: 3px solid #0F766E;
    margin-bottom: 30px;
  }
  .cover h1 { font-size: 28px; color: #0F766E; margin: 0 0 8px; }
  .cover .teacher-name { font-size: 20px; font-weight: 700; margin: 4px 0; }
  .cover .date { color: #64748B; font-size: 14px; }
  .overall-stat {
    display: inline-block;
    margin-top: 18px;
    padding: 14px 28px;
    background: #F0FDFA;
    border-radius: 12px;
    border: 1px solid #99F6E4;
  }
  .overall-stat .percent { font-size: 32px; font-weight: 800; color: #0F766E; }
  .overall-stat .label { font-size: 13px; color: #475569; }
  .criterion-section { margin-bottom: 26px; page-break-inside: avoid; }
  .criterion-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: #F1F5F9;
    padding: 10px 14px;
    border-radius: 8px;
    margin-bottom: 10px;
  }
  .criterion-header h2 { font-size: 16px; margin: 0; }
  .criterion-badge { font-size: 13px; font-weight: 700; color: #0F766E; }
  .indicator { padding: 8px 14px; border-bottom: 1px solid #E2E8F0; page-break-inside: avoid; }
  .indicator-header { display: flex; align-items: baseline; gap: 8px; }
  .indicator.covered .status-dot { color: #15803D; }
  .indicator.missing .status-dot { color: #CBD5E1; }
  .indicator-name { font-size: 13px; font-weight: 600; }
  .evidence-list { margin: 4px 0 0 0; padding-inline-start: 26px; font-size: 12px; color: #334155; }
  .no-evidence { margin: 4px 0 0 0; font-size: 12px; color: #CBD5E1; }
  .print-hint {
    text-align: center;
    background: #FEF9C3;
    color: #854D0E;
    padding: 10px;
    border-radius: 8px;
    margin-bottom: 20px;
    font-size: 13px;
  }
  @media print { .print-hint { display: none; } }
</style>
</head>
<body>
  <div class="print-hint">استخدم Ctrl+P (أو ⌘+P) ثم اختر "حفظ كـ PDF" لتنزيل هذا الملف.</div>
  <div class="cover">
    <h1>ملف الإنجاز المهني</h1>
    <div class="teacher-name">${escapeHtml(data.teacherName)}</div>
    <div class="date">تاريخ الإصدار: ${date}</div>
    <div class="overall-stat">
      <div class="percent">${overallPercent}%</div>
      <div class="label">${data.coveredIndicators} من ${data.totalIndicators} مؤشر مغطى</div>
    </div>
  </div>
  ${sectionsHtml}
</body>
</html>`;
}
