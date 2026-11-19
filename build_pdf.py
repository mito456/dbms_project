import re
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Preformatted, PageBreak, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            super().showPage()
        super().save()

    def draw_page_number(self, page_count):
        if self._pageNumber > 1:
            self.setFont("Times-Roman", 9)
            text = f"Page {self._pageNumber} of {page_count}"
            self.drawRightString(A4[0] - 40, 30, text)
            self.drawString(40, 30, "PES University - Dept. of CSE (AI & ML) | DBMS Project Report | UE23CS351A")
            self.setStrokeColor(colors.HexColor("#cbd5e1"))
            self.setLineWidth(0.5)
            self.line(40, 42, A4[0] - 40, 42)

def build_pdf(md_path, pdf_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        content = f.read()

    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=40,
        rightMargin=40,
        topMargin=45,
        bottomMargin=55
    )

    styles = getSampleStyleSheet()

    style_normal = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=11,
        leading=15,
        alignment=4, # Justified
        spaceAfter=6,
        textColor=colors.HexColor("#1a1a1a")
    )

    style_title = ParagraphStyle(
        'CustomTitle',
        fontName='Times-Bold',
        fontSize=17,
        leading=21,
        alignment=1, # Centered
        spaceAfter=8,
        textColor=colors.HexColor("#0f2942")
    )

    style_h1 = ParagraphStyle(
        'CustomH1',
        fontName='Times-Bold',
        fontSize=13.5,
        leading=17,
        spaceBefore=14,
        spaceAfter=6,
        textColor=colors.HexColor("#0f2942"),
        keepWithNext=True
    )

    style_h2 = ParagraphStyle(
        'CustomH2',
        fontName='Times-Bold',
        fontSize=12,
        leading=15,
        spaceBefore=10,
        spaceAfter=4,
        textColor=colors.HexColor("#1b4965"),
        keepWithNext=True
    )

    style_h3 = ParagraphStyle(
        'CustomH3',
        fontName='Times-Bold',
        fontSize=11,
        leading=14,
        spaceBefore=8,
        spaceAfter=4,
        textColor=colors.HexColor("#2b2b2b"),
        keepWithNext=True
    )

    style_bullet = ParagraphStyle(
        'CustomBullet',
        parent=style_normal,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=3
    )

    style_code = ParagraphStyle(
        'CustomCode',
        fontName='Courier',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#1e1e1e"),
        backColor=colors.HexColor("#f8f9fa")
    )

    style_table_header = ParagraphStyle(
        'TableHeader',
        fontName='Times-Bold',
        fontSize=9,
        leading=11.5,
        textColor=colors.HexColor("#0f2942")
    )

    style_table_cell = ParagraphStyle(
        'TableCell',
        fontName='Times-Roman',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#1a1a1a")
    )

    story = []
    lines = content.split('\n')
    i = 0
    n = len(lines)

    in_code_block = False
    code_lines = []

    def format_inline(text):
        text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
        text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
        text = re.sub(r'`(.+?)`', r'<font face="Courier" color="#800020"><b>\1</b></font>', text)
        return text

    available_width = A4[0] - 80

    while i < n:
        line = lines[i]

        # Code block handling
        if line.strip().startswith('```'):
            if in_code_block:
                in_code_block = False
                # Chunk code lines into maximum 40 lines per Preformatted flowable
                chunk_size = 40
                for start_idx in range(0, max(1, len(code_lines)), chunk_size):
                    chunk = code_lines[start_idx:start_idx + chunk_size]
                    code_text = '\n'.join(chunk)
                    
                    wrapped_lines = []
                    for cl in code_text.split('\n'):
                        while len(cl) > 85:
                            wrapped_lines.append(cl[:85])
                            cl = "  " + cl[85:]
                        wrapped_lines.append(cl)
                    final_code = '\n'.join(wrapped_lines)

                    t = Table([[Preformatted(final_code, style_code)]], colWidths=[available_width])
                    t.setStyle(TableStyle([
                        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#f8f9fa')),
                        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#cbd5e1')),
                        ('LEFTPADDING', (0,0), (-1,-1), 7),
                        ('RIGHTPADDING', (0,0), (-1,-1), 7),
                        ('TOPPADDING', (0,0), (-1,-1), 5),
                        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
                    ]))
                    story.append(t)
                    story.append(Spacer(1, 3))
                code_lines = []
                story.append(Spacer(1, 6))
            else:
                in_code_block = True
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Horizontal Rule
        if re.match(r'^\s*[-*_]{3,}\s*$', line):
            story.append(HRFlowable(width="100%", thickness=0.75, color=colors.HexColor('#cbd5e1'), spaceBefore=6, spaceAfter=6))
            i += 1
            continue

        # Markdown Table Detection
        if '|' in line and line.strip().startswith('|') and line.strip().endswith('|'):
            table_raw = []
            while i < n and '|' in lines[i] and lines[i].strip().startswith('|') and lines[i].strip().endswith('|'):
                table_raw.append(lines[i].strip())
                i += 1
            
            if len(table_raw) >= 2:
                rows_data = []
                for row_idx, r_str in enumerate(table_raw):
                    if re.match(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$', r_str):
                        continue
                    cells = [c.strip() for c in r_str.strip('|').split('|')]
                    formatted_cells = []
                    for c_idx, c in enumerate(cells):
                        fmt = format_inline(c)
                        if row_idx == 0:
                            p = Paragraph(fmt, style_table_header)
                        else:
                            p = Paragraph(fmt, style_table_cell)
                        formatted_cells.append(p)
                    rows_data.append(formatted_cells)

                if rows_data:
                    num_cols = max(len(r) for r in rows_data)
                    for r in rows_data:
                        while len(r) < num_cols:
                            r.append(Paragraph("", style_table_cell))
                    
                    if num_cols == 2:
                        col_widths = [150, available_width - 150]
                    elif num_cols == 3:
                        col_widths = [130, 240, available_width - 370]
                    elif num_cols == 4:
                        col_widths = [35, 120, 110, available_width - 265]
                    elif num_cols == 5:
                        col_widths = [25, 110, 130, 65, available_width - 330]
                    else:
                        col_widths = [available_width / num_cols] * num_cols

                    table_obj = Table(rows_data, colWidths=col_widths, repeatRows=1)
                    table_obj.setStyle(TableStyle([
                        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#f1f5f9')),
                        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#cbd5e1')),
                        ('TOPPADDING', (0,0), (-1,-1), 4),
                        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
                        ('LEFTPADDING', (0,0), (-1,-1), 4),
                        ('RIGHTPADDING', (0,0), (-1,-1), 4),
                        ('VALIGN', (0,0), (-1,-1), 'TOP'),
                    ]))
                    story.append(table_obj)
                    story.append(Spacer(1, 6))
            continue

        # Headings
        if line.startswith('# '):
            text = format_inline(line[2:].strip())
            story.append(Paragraph(text, style_title))
            story.append(Spacer(1, 3))
            i += 1
            continue

        if line.startswith('## '):
            text = format_inline(line[3:].strip())
            story.append(Paragraph(text, style_h1))
            story.append(Spacer(1, 3))
            i += 1
            continue

        if line.startswith('### '):
            text = format_inline(line[4:].strip())
            story.append(Paragraph(text, style_h2))
            story.append(Spacer(1, 2))
            i += 1
            continue

        if line.startswith('#### '):
            text = format_inline(line[5:].strip())
            story.append(Paragraph(text, style_h3))
            story.append(Spacer(1, 2))
            i += 1
            continue

        # Bullet lists
        if re.match(r'^\s*[-*]\s+', line):
            text = re.sub(r'^\s*[-*]\s+', '', line).strip()
            bullet_text = f"&bull;&nbsp;&nbsp;{format_inline(text)}"
            story.append(Paragraph(bullet_text, style_bullet))
            i += 1
            continue

        # Numbered lists
        if re.match(r'^\s*\d+\.\s+', line):
            text = re.sub(r'^\s*\d+\.\s+', '', line).strip()
            num_match = re.match(r'^\s*(\d+)\.\s+', line).group(1)
            item_text = f"{num_match}.&nbsp;&nbsp;{format_inline(text)}"
            story.append(Paragraph(item_text, style_bullet))
            i += 1
            continue

        # Regular Paragraph
        if line.strip():
            text = format_inline(line.strip())
            story.append(Paragraph(text, style_normal))
        else:
            story.append(Spacer(1, 3))

        i += 1

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF built successfully at: {pdf_path}")

if __name__ == '__main__':
    build_pdf("C:/DBMS_Project/DBMS_PROJECT_REPORT.md", "C:/DBMS_Project/DBMS_PROJECT_REPORT.pdf")
