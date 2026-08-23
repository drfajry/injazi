import { getMinistryLogoBase64 } from './assets.js';

type ExportEvidence = {
  title: string;
  type: string;
  description: string | null;
  imageDataUrl: string | null;
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
  schoolName: string | null;
  subject: string | null;
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
export function buildPublicPortfolioHtml(data: {
  teacherName: string;
  overallCoverage: number;
  totalIndicators: number;
  complete: number;
  sections: { name: string; indicators: { name: string; covered: boolean }[] }[];
}): string {
  const percent = (data.overallCoverage * 100).toFixed(1);

  const sectionsHtml = data.sections
    .map((section) => {
      const covered = section.indicators.filter((i) => i.covered).length;
      const total = section.indicators.length;
      return `
        <div class="pub-section">
          <div class="pub-section-header">
            <span>${escapeHtml(section.name)}</span>
            <span class="pub-badge">${covered}/${total}</span>
          </div>
          <div class="pub-dots">
            ${section.indicators.map((i) => `<span class="dot ${i.covered ? 'on' : ''}" title="${escapeHtml(i.name)}"></span>`).join('')}
          </div>
        </div>
      `;
    })
    .join('');

  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>ملف إنجاز — ${escapeHtml(data.teacherName)}</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
    background: #F8FAFC;
    color: #0F172A;
    margin: 0;
    padding: 24px 16px;
  }
  .wrap { max-width: 560px; margin: 0 auto; }
  .header { text-align: center; margin-bottom: 24px; }
  .header h1 { font-size: 20px; margin: 0 0 4px; color: #0F766E; }
  .header .name { font-weight: 700; font-size: 16px; }
  .stat {
    background: linear-gradient(135deg, #0F766E, #115E59);
    color: white;
    border-radius: 16px;
    padding: 20px;
    text-align: center;
    margin-bottom: 20px;
  }
  .stat .percent { font-size: 34px; font-weight: 800; }
  .stat .label { font-size: 13px; opacity: 0.85; }
  .pub-section {
    background: white;
    border-radius: 10px;
    padding: 12px 14px;
    margin-bottom: 8px;
    border: 1px solid #E2E8F0;
  }
  .pub-section-header { display: flex; justify-content: space-between; font-size: 13px; font-weight: 700; margin-bottom: 8px; }
  .pub-badge { color: #0F766E; }
  .pub-dots { display: flex; flex-wrap: wrap; gap: 5px; }
  .dot { width: 10px; height: 10px; border-radius: 50%; background: #E2E8F0; display: inline-block; }
  .dot.on { background: #15803D; }
  .footer { text-align: center; font-size: 11px; color: #94A3B8; margin-top: 20px; }
</style>
</head>
<body>
  <div class="wrap">
    <div class="header">
      <h1>ملف الإنجاز المهني</h1>
      <div class="name">${escapeHtml(data.teacherName)}</div>
    </div>
    <div class="stat">
      <div class="percent">${percent}%</div>
      <div class="label">${data.complete} من ${data.totalIndicators} مؤشر مغطى</div>
    </div>
    ${sectionsHtml}
    <div class="footer">هذا ملخص عام لملف الإنجاز — لا يعرض تفاصيل الأدلة المرفقة.</div>
  </div>
</body>
</html>`;
}

export function buildPublicNotFoundHtml(): string {
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head><meta charset="UTF-8" /><title>الرابط غير متاح</title></head>
<body style="font-family: sans-serif; text-align: center; padding: 60px 20px; color: #64748B;">
  <h2>هذا الرابط غير متاح</h2>
  <p>إما أن الرابط غير صحيح، أو أن صاحب الملف ألغى مشاركته.</p>
</body>
</html>`;
}

export function buildPortfolioExportHtml(data: ExportData): string {
  const date = new Intl.DateTimeFormat('ar-SA-u-ca-gregory', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(new Date());

  const overallPercent = (data.overallCoverage * 100).toFixed(1);
  const ministryLogo = getMinistryLogoBase64();
  const ministryLogoHtml = ministryLogo
    ? `<img class="ministry-logo" src="data:image/png;base64,${ministryLogo}" alt="شعار وزارة التعليم" />`
    : `<div class="logo-placeholder">شعار<br/>الوزارة</div>`;

  const sectionsHtml = data.sections
    .map((section) => {
      const sectionPercent = section.totalIndicators
        ? Math.round((section.coveredIndicators / section.totalIndicators) * 100)
        : 0;

      const indicatorsHtml = section.indicators
        .map((indicator) => {
          const covered = indicator.evidence.length > 0;
          const evidenceHtml = covered
            ? indicator.evidence
                .map((e) => {
                  const image = e.imageDataUrl
                    ? `<img class="evidence-image" src="${e.imageDataUrl}" alt="${escapeHtml(e.title)}" />`
                    : '';
                  // Only show the extracted-text excerpt when there's no
                  // rendered image — once the real page/photo is visible,
                  // repeating its text underneath is redundant clutter.
                  const excerpt = !image && e.description
                    ? `<blockquote class="evidence-excerpt">${escapeHtml(e.description.slice(0, 600))}${e.description.length > 600 ? '…' : ''}</blockquote>`
                    : '';
                  const noContent = !excerpt && !image
                    ? `<p class="no-content-note">(لم يتم استخراج محتوى نصي قابل للعرض من هذا الملف)</p>`
                    : '';

                  return `
                    <div class="evidence-item">
                      <div class="evidence-title">📎 ${escapeHtml(e.title)}</div>
                      ${image}
                      ${excerpt}
                      ${noContent}
                    </div>
                  `;
                })
                .join('')
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
  .letterhead {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    font-size: 12px;
    color: #475569;
    border-bottom: 2px solid #0F766E;
    padding-bottom: 10px;
    margin-bottom: 20px;
  }
  .letterhead .logo-placeholder {
    width: 64px;
    height: 64px;
    border: 1px dashed #CBD5E1;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 9px;
    color: #94A3B8;
    text-align: center;
  }
  .letterhead .ministry-logo {
    height: 56px;
    width: auto;
    object-fit: contain;
  }
  .letterhead .gov-text { text-align: center; font-weight: 700; }
  .letterhead .gov-text div:first-child { font-size: 13px; }
  .letterhead .gov-text div:last-child { font-size: 12px; color: #0F766E; }
  .cover {
    text-align: center;
    padding: 20px 0 30px;
    margin-bottom: 20px;
  }
  .cover h1 { font-size: 26px; color: #0F766E; margin: 0 0 14px; }
  .cover-info {
    display: inline-block;
    text-align: right;
    background: #F8FAFC;
    border-radius: 12px;
    padding: 16px 24px;
    margin-bottom: 6px;
  }
  .cover-info div { font-size: 14px; margin: 4px 0; }
  .cover-info .label { color: #64748B; display: inline-block; min-width: 90px; }
  .cover .date { color: #64748B; font-size: 13px; margin-top: 10px; }
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
  .evidence-item { margin: 8px 0 8px 26px; page-break-inside: avoid; }
  .evidence-title { font-size: 12px; font-weight: 700; color: #334155; margin-bottom: 4px; }
  .evidence-excerpt {
    font-size: 11px;
    color: #475569;
    background: #F8FAFC;
    border-right: 3px solid #0F766E;
    margin: 4px 0;
    padding: 8px 12px;
    border-radius: 4px;
    white-space: pre-wrap;
  }
  .evidence-image {
    max-width: 100%;
    max-height: 320px;
    border-radius: 6px;
    border: 1px solid #E2E8F0;
    margin: 6px 0;
    display: block;
  }
  .no-content-note { font-size: 11px; color: #CBD5E1; margin: 4px 0; }
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
  <div class="letterhead">
    ${ministryLogoHtml}
    <div class="gov-text">
      <div>المملكة العربية السعودية</div>
      <div>وزارة التعليم${data.schoolName ? ` — ${escapeHtml(data.schoolName)}` : ''}</div>
    </div>
    <div class="logo-placeholder">شعار<br/>المدرسة</div>
  </div>
  <div class="cover">
    <h1>ملف الإنجاز المهني</h1>
    <div class="cover-info">
      <div><span class="label">اسم المعلم:</span> ${escapeHtml(data.teacherName)}</div>
      ${data.schoolName ? `<div><span class="label">المدرسة:</span> ${escapeHtml(data.schoolName)}</div>` : ''}
      ${data.subject ? `<div><span class="label">المادة:</span> ${escapeHtml(data.subject)}</div>` : ''}
    </div>
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
