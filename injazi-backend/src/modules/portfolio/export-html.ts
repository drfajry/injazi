import { getMinistryLogoBase64 } from './assets.js';

type ExportEvidence = {
  title: string;
  type: string;
  description: string | null;
  imageDataUrl: string | null;
  tableHtml: string | null;
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
  generalInfo: ExportEvidence[];
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
    <div class="footer">هذا ملخص عام لملف الإنجاز — لا يعرض تفاصيل الشواهد المرفقة.</div>
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

  const generalInfoHtml = data.generalInfo.length
    ? `
      <section class="criterion-section general-info-section">
        <div class="criterion-pill">بيانات عامة</div>
        <div class="criterion-meta">الجدول الدراسي وبيانات الفصول — لإفادة الإدارة والمشرفين</div>
        ${data.generalInfo
          .map((e) => {
            const image = e.imageDataUrl
              ? `<img class="evidence-image" src="${e.imageDataUrl}" alt="${escapeHtml(e.title)}" />`
              : '';
            const table = !image && e.tableHtml ? `<div class="evidence-table-wrap">${e.tableHtml}</div>` : '';
            const excerpt = !image && !table && e.description
              ? `<blockquote class="evidence-excerpt">${escapeHtml(e.description.slice(0, 600))}${e.description.length > 600 ? '…' : ''}</blockquote>`
              : '';

            return `
              <div class="evidence-item">
                <div class="evidence-title">📎 ${escapeHtml(e.title)}</div>
                ${image}
                ${table}
                ${excerpt}
              </div>
            `;
          })
          .join('')}
      </section>
    `
    : '';

  const sectionsHtml = data.sections
    .map((section) => {
      const sectionPercent = section.totalIndicators
        ? Math.round((section.coveredIndicators / section.totalIndicators) * 100)
        : 0;

      const indicatorsHtml = section.indicators
        .map((indicator) => {
          const covered = indicator.evidence.length > 0;
          const evidenceHtml = covered
            ? `<div class="evidence-badge">الشواهد</div>` + indicator.evidence
                .map((e) => {
                  const image = e.imageDataUrl
                    ? `<img class="evidence-image" src="${e.imageDataUrl}" alt="${escapeHtml(e.title)}" />`
                    : '';
                  const table = !image && e.tableHtml
                    ? `<div class="evidence-table-wrap">${e.tableHtml}</div>`
                    : '';
                  // Only show the extracted-text excerpt when there's no
                  // rendered image or table — once the real content is
                  // visible, repeating it as plain text underneath is
                  // redundant clutter.
                  const excerpt = !image && !table && e.description
                    ? `<blockquote class="evidence-excerpt">${escapeHtml(e.description.slice(0, 600))}${e.description.length > 600 ? '…' : ''}</blockquote>`
                    : '';
                  const noContent = !excerpt && !image && !table
                    ? `<p class="no-content-note">(لم يتم استخراج محتوى نصي قابل للعرض من هذا الملف)</p>`
                    : '';

                  return `
                    <div class="evidence-item">
                      <div class="evidence-title">📎 ${escapeHtml(e.title)}</div>
                      ${image}
                      ${table}
                      ${excerpt}
                      ${noContent}
                    </div>
                  `;
                })
                .join('')
            : `<p class="no-evidence">لا يوجد شاهد مرتبط بعد</p>`;

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
          <div class="criterion-pill">${escapeHtml(section.name)}</div>
          <div class="criterion-meta">${section.coveredIndicators} من ${section.totalIndicators} مؤشر مغطى — ${sectionPercent}%</div>
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
  @page { size: A4; margin: 0; }
  * { box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
    color: #1E293B;
    line-height: 1.6;
    margin: 0;
    background: #FFFFFF;
  }
  .page-padding { padding: 16mm 15mm 24mm; }

  /* Decorative corner graphic — repeats on every printed page via
     position:fixed, matching the brand motif used in the reference deck
     (two overlapping triangles + a rotated square "diamond"). */
  .corner-motif {
    position: fixed;
    bottom: 0;
    left: 0;
    width: 130px;
    height: 130px;
    pointer-events: none;
    z-index: 0;
  }
  @media print {
    .corner-motif { position: fixed; }
  }

  .letterhead {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 18px;
    position: relative;
    z-index: 1;
  }
  .letterhead .ministry-logo { height: 46px; width: auto; object-fit: contain; }
  .letterhead .logo-placeholder {
    width: 46px; height: 46px;
    border: 1px dashed #CBD5E1;
    border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    font-size: 8px; color: #94A3B8; text-align: center;
  }
  .letterhead .gov-text { text-align: center; }
  .letterhead .gov-text div:first-child { font-size: 11px; color: #64748B; }
  .letterhead .gov-text div:last-child { font-size: 12px; color: #093B64; font-weight: 700; }

  /* Cover page */
  .cover {
    min-height: 240mm;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    position: relative;
    z-index: 1;
  }
  .cover-pill {
    background: linear-gradient(135deg, #359B77, #093B64);
    color: white;
    border-radius: 999px;
    padding: 18px 44px;
    font-size: 22px;
    font-weight: 800;
    margin-bottom: 14px;
    box-shadow: 0 8px 20px rgba(9, 59, 100, 0.25);
  }
  .cover-subtitle { color: #64748B; font-size: 13px; margin-bottom: 40px; }
  .cover-field { font-size: 15px; color: #093B64; font-weight: 700; margin-top: 30px; }
  .cover-stat {
    margin-top: 30px;
    display: inline-block;
    padding: 14px 28px;
    background: #F0FDFA;
    border-radius: 12px;
    border: 1px solid #99F6E4;
  }
  .cover-stat .percent { font-size: 30px; font-weight: 800; color: #359B77; }
  .cover-stat .label { font-size: 12px; color: #475569; }
  .cover-date { color: #94A3B8; font-size: 11px; margin-top: 16px; }

  /* Criterion sections */
  .criterion-section { margin-bottom: 30px; page-break-inside: avoid; position: relative; z-index: 1; }
  .criterion-pill {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    background: linear-gradient(90deg, #359B77, #093B64);
    color: white;
    border-radius: 999px;
    padding: 10px 22px;
    font-size: 14px;
    font-weight: 800;
    margin-bottom: 4px;
  }
  .criterion-meta { font-size: 11px; color: #64748B; margin: 6px 4px 12px; }

  .indicator { padding: 10px 6px; border-bottom: 1px solid #EEF2F6; page-break-inside: avoid; }
  .indicator-header { display: flex; align-items: baseline; gap: 8px; }
  .indicator.covered .status-dot { color: #359B77; }
  .indicator.missing .status-dot { color: #CBD5E1; }
  .indicator-name { font-size: 12.5px; font-weight: 600; }

  .evidence-badge {
    display: inline-block;
    background: #359B77;
    color: white;
    border-radius: 999px;
    padding: 3px 14px;
    font-size: 10.5px;
    font-weight: 700;
    margin: 6px 0 8px 26px;
  }
  .evidence-item { margin: 6px 0 10px 26px; page-break-inside: avoid; }
  .evidence-title { font-size: 12px; font-weight: 700; color: #334155; margin-bottom: 4px; }
  .evidence-excerpt {
    font-size: 11px;
    color: #475569;
    background: #F8FAFC;
    border-right: 3px solid #359B77;
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
  .evidence-table-wrap {
    margin: 6px 0;
    overflow-x: auto;
    border: 1px solid #E2E8F0;
    border-radius: 6px;
  }
  .evidence-table-wrap table { border-collapse: collapse; font-size: 10px; width: 100%; }
  .evidence-table-wrap td, .evidence-table-wrap th {
    border: 1px solid #E2E8F0;
    padding: 3px 6px;
    text-align: right;
    white-space: nowrap;
  }
  .evidence-table-wrap tr:nth-child(even) { background: #F8FAFC; }
  .table-truncated-note { font-size: 10px; color: #94A3B8; padding: 4px 6px; margin: 0; }
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
    position: relative;
    z-index: 1;
  }
  @media print { .print-hint { display: none; } }
</style>
</head>
<body>
  <svg class="corner-motif" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
    <rect x="70" y="18" width="46" height="46" rx="6" fill="#E2E8F0" transform="rotate(45 93 41)" />
    <polygon points="0,130 65,130 0,55" fill="#093B64" />
    <polygon points="0,130 130,130 65,55" fill="#359B77" opacity="0.85" />
  </svg>

  <div class="page-padding">
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
      <div class="cover-pill">ملف الإنجاز للمعلم للعام الدراسي</div>
      <div class="cover-subtitle">وفق نموذج تقييم أداء الوظائف التعليمية — الدليل المهني الجديد</div>
      <div class="cover-field">اسم المعلم: ${escapeHtml(data.teacherName)}</div>
      ${data.subject ? `<div class="cover-field">المادة: ${escapeHtml(data.subject)}</div>` : ''}
      <div class="cover-stat">
        <div class="percent">${overallPercent}%</div>
        <div class="label">${data.coveredIndicators} من ${data.totalIndicators} مؤشر مغطى</div>
      </div>
      <div class="cover-date">تاريخ الإصدار: ${date}</div>
    </div>

    ${generalInfoHtml}
    ${sectionsHtml}
  </div>
</body>
</html>`;
}
