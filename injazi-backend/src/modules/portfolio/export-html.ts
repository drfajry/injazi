import { getMinistryLogoBase64 } from './assets.js';

type ExportEvidence = {
  title: string;
  type: string;
  description: string | null;
  imageDataUrl: string | null;
  imageDataUrls?: string[] | null;
  imageIsLandscape?: boolean;
  tableHtml: string | null;
  fileTypeLabel?: string | null;
  addedDate?: string;
  label?: string | null;
  fixedPageType?: string | null;
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
  * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
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

  const generalInfoHtml = data.generalInfo
    .map((e) => {
      // Vision/Mission/Goals is stored as structured JSON (three separate
      // fields) so it can render as three distinct labeled boxes on one
      // page — matching the reference template — instead of one
      // undifferentiated paragraph of text.
      if (e.fixedPageType === 'VISION_MISSION') {
        let parsed: { vision?: string; mission?: string; goals?: string } | null = null;
        try {
          parsed = e.description ? JSON.parse(e.description) : null;
        } catch {
          parsed = null;
        }

        if (parsed) {
          const boxes = [
            { label: 'الرؤية', value: parsed.vision },
            { label: 'الرسالة', value: parsed.mission },
            { label: 'الأهداف', value: parsed.goals },
          ]
            .filter((box) => box.value && box.value.trim().length > 0)
            .map(
              (box) => `
                <div class="vmg-box">
                  <div class="vmg-box-title">${escapeHtml(box.label)}</div>
                  <div class="vmg-box-body">${escapeHtml(box.value!)}</div>
                </div>
              `,
            )
            .join('');

          return `
            <section class="criterion-section general-info-section">
              <div class="criterion-pill">${escapeHtml(e.label ?? e.title)}</div>
              <div class="vmg-wrap">${boxes}</div>
            </section>
          `;
        }
        // Falls through to the generic renderer below if parsing failed
        // (e.g. an older entry saved before this structured format).
      }

      // Multi-page PDFs (e.g. a 2-page CV) render every page at full size,
      // each as its own page — previously only the first page was shown,
      // squeezed into a small thumbnail meant for quick-preview evidence,
      // not a complete standalone document.
      const multiPageImages = e.imageDataUrls?.length
        ? e.imageDataUrls
            .map(
              (url, index) => `
                <div class="fixed-page-image-wrap">
                  <img class="fixed-page-image" src="${url}" alt="${escapeHtml(e.title)} — ${index + 1}" />
                </div>
              `,
            )
            .join('')
        : '';

      const image = !multiPageImages && e.imageDataUrl
        ? `<div class="fixed-page-image-wrap"><img class="fixed-page-image" src="${e.imageDataUrl}" alt="${escapeHtml(e.title)}" /></div>`
        : '';
      const table = !multiPageImages && !image && e.tableHtml ? `<div class="evidence-table-wrap">${e.tableHtml}</div>` : '';
      const excerpt = !multiPageImages && !image && !table && e.description
        ? `<blockquote class="evidence-excerpt">${escapeHtml(e.description.slice(0, 600))}${e.description.length > 600 ? '…' : ''}</blockquote>`
        : '';

      // Each fixed page (CV, schedule, etc.) gets its own labeled section
      // and its own page, rather than being merged under one generic
      // "بيانات عامة" heading — matches how a printed portfolio separates
      // these into distinct pages.
      return `
        <section class="criterion-section general-info-section">
          <div class="criterion-pill">${escapeHtml(e.label ?? e.title)}</div>
          <div class="evidence-item">
            ${multiPageImages}
            ${image}
            ${table}
            ${excerpt}
          </div>
        </section>
      `;
    })
    .join('');

  const sectionsHtml = data.sections
    .map((section) => {
      const sectionPercent = section.totalIndicators
        ? Math.round((section.coveredIndicators / section.totalIndicators) * 100)
        : 0;

      const coveredIndicators = section.indicators.filter((indicator) => indicator.evidence.length > 0);

      // Skip criteria with zero covered indicators entirely — an empty
      // section with nothing but "no evidence yet" lines under every
      // indicator was the main source of large blank pages in the export.
      if (coveredIndicators.length === 0) return '';

      const indicatorsHtml = coveredIndicators
        .map((indicator) => {
          const evidenceHtml = `<div class="evidence-badge">الشواهد</div>` + indicator.evidence
                .map((e) => {
                  // PDFs render as their full set of pages now (not a
                  // single shrunk thumbnail) — same treatment as the fixed
                  // pages section, since a shrunk preview was never
                  // actually useful as a real record of the document.
                  const pdfPages = e.imageDataUrls?.length
                    ? e.imageDataUrls
                        .map(
                          (url, index) => `
                            <div class="fixed-page-image-wrap">
                              <img class="fixed-page-image" src="${url}" alt="${escapeHtml(e.title)} — ${index + 1}" />
                            </div>
                          `,
                        )
                        .join('')
                    : '';

                  const image = !pdfPages && e.imageDataUrl
                    ? `<img class="evidence-image" src="${e.imageDataUrl}" alt="${escapeHtml(e.title)}" />`
                    : '';

                  const table = !pdfPages && !image && e.tableHtml
                    ? `<div class="evidence-table-wrap">${e.tableHtml}</div>`
                    : '';
                  // Only show the extracted-text excerpt when there's no
                  // rendered image or table — once the real content is
                  // visible, repeating it as plain text underneath is
                  // redundant clutter.
                  const excerpt = !pdfPages && !image && !table && e.description
                    ? `<blockquote class="evidence-excerpt">${escapeHtml(e.description.slice(0, 600))}${e.description.length > 600 ? '…' : ''}</blockquote>`
                    : '';
                  const noContent = !excerpt && !pdfPages && !image && !table
                    ? `<p class="no-content-note">(لم يتم استخراج محتوى نصي قابل للعرض من هذا الملف)</p>`
                    : '';

                  const metaBadges = `
                    <div class="evidence-meta-badges">
                      ${e.fileTypeLabel ? `<span class="meta-badge">📄 ${escapeHtml(e.fileTypeLabel)}</span>` : ''}
                      ${e.addedDate ? `<span class="meta-badge">🗓 ${escapeHtml(e.addedDate)}</span>` : ''}
                    </div>
                  `;

                  return `
                    <div class="evidence-item${e.imageIsLandscape ? ' evidence-item-half' : ''}">
                      <div class="evidence-title">📎 ${escapeHtml(e.title)}</div>
                      ${metaBadges}
                      ${pdfPages}
                      ${image}
                      ${table}
                      ${excerpt}
                      ${noContent}
                    </div>
                  `;
                })
                .join('');

          return `
            <div class="indicator covered">
              <div class="indicator-header">
                <span class="status-check">✓</span>
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
          <div class="criterion-meta-badge">${section.coveredIndicators} من ${section.totalIndicators} مؤشر مغطى — ${sectionPercent}%</div>
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
  * {
    box-sizing: border-box;
    /* Without this, Chrome (and most browsers) silently strip background
       colors/gradients when printing to save ink — every teal/navy
       gradient (letterhead, criterion pills, evidence badges, the
       vision/mission boxes) would render correctly on screen but come out
       blank/transparent in the actual printed PDF. This forces them to
       print exactly as shown. */
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
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
  /* Subtle dashed inner frame around the whole cover — an accent border
     echoing a traditional certificate/portfolio look, in our own
     navy/teal identity rather than a solid box. */
  .cover-frame {
    position: absolute;
    inset: 6mm;
    border: 1.5px dashed #99C9BB;
    border-radius: 4px;
    pointer-events: none;
    z-index: -1;
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
  .criterion-section { margin-bottom: 30px; page-break-before: always; page-break-inside: avoid; position: relative; z-index: 1; }
  .criterion-section:first-of-type { page-break-before: auto; }
  .criterion-pill {
    display: block;
    width: 100%;
    background: linear-gradient(90deg, #359B77, #093B64);
    color: white;
    border-radius: 12px;
    padding: 16px 22px;
    font-size: 19px;
    font-weight: 800;
    margin-bottom: 4px;
    box-shadow: 0 4px 14px rgba(9, 59, 100, 0.25);
  }
  .criterion-meta-badge {
    display: inline-block;
    font-size: 11.5px;
    color: #0F766E;
    background: #F0FDFA;
    border: 1px solid #99F6E4;
    border-radius: 999px;
    padding: 4px 14px;
    margin: 8px 0 16px;
    font-weight: 700;
  }

  .indicator { padding: 10px 6px; border-bottom: 1px solid #EEF2F6; page-break-inside: avoid; }
  .indicator-header { display: flex; align-items: center; gap: 9px; }
  .status-check {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 17px;
    height: 17px;
    border-radius: 50%;
    background: #359B77;
    color: white;
    font-size: 10px;
    font-weight: 900;
    flex-shrink: 0;
  }
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
  .evidence-meta-badges { display: flex; gap: 6px; margin-bottom: 6px; }
  .meta-badge {
    font-size: 10px;
    color: #0F766E;
    background: #F0FDFA;
    border: 1px solid #99F6E4;
    border-radius: 999px;
    padding: 2px 9px;
    font-weight: 600;
  }
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
  /* Landscape (wide) photos: the whole evidence block (caption + photo) is
     shown at roughly half the page width, so two land side by side on the
     same row instead of one wide photo wasting an almost-empty page. */
  .evidence-item-half {
    display: inline-block;
    width: 48%;
    vertical-align: top;
    margin-left: 1%;
    margin-right: 1%;
  }
  .evidence-item-half .evidence-image {
    max-height: 220px;
    width: 100%;
    object-fit: contain;
  }
  /* Fixed pages (CV, schedule, etc.) show at full document size, not the
     small evidence-preview thumbnail — each page gets its own printed
     page, matching how the original document actually looks. */
  .fixed-page-image-wrap {
    page-break-before: always;
    padding-top: 10px;
  }
  .fixed-page-image-wrap:first-child { page-break-before: auto; }
  .fixed-page-image {
    width: 100%;
    height: auto;
    display: block;
    border-radius: 6px;
    border: 1px solid #E2E8F0;
  }
  .vmg-wrap { display: flex; flex-direction: column; gap: 14px; margin-top: 6px; }
  .vmg-box { border: 1px solid #E2E8F0; border-radius: 10px; overflow: hidden; }
  .vmg-box-title {
    background: linear-gradient(90deg, #359B77, #093B64);
    color: white;
    font-weight: 800;
    font-size: 13px;
    padding: 8px 16px;
  }
  .vmg-box-body {
    padding: 14px 16px;
    font-size: 12.5px;
    color: #334155;
    line-height: 1.8;
    min-height: 60px;
    white-space: pre-wrap;
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
      <div class="cover-frame"></div>
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
