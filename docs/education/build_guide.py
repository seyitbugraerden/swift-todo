"""Build the Turkish Odak source walkthrough; documentation only."""
from pathlib import Path
import re
import html
import hashlib
import json
import textwrap
from datetime import date

from reportlab.pdfgen import canvas
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, PageBreak,
    KeepTogether, Table, TableStyle, Image,
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PDF = ROOT / 'docs/odak-gelistirici-rehberi.pdf'
MD = ROOT / 'docs/odak-gelistirici-rehberi.md'
FONT_DIR = Path('/System/Library/Fonts/Supplemental')
for name, filename in [
    ('Body', 'Arial.ttf'), ('BodyBold', 'Arial Bold.ttf'),
    ('BodyItalic', 'Arial Italic.ttf'), ('Code', 'Courier New.ttf'),
    ('Unicode', 'Arial Unicode.ttf'),
]:
    pdfmetrics.registerFont(TTFont(name, str(FONT_DIR / filename)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='BodyItalic', boldItalic='BodyBold')
NAVY = colors.HexColor('#17233B')
PURPLE = colors.HexColor('#5C5CD6')
MUTED = colors.HexColor('#5A6474')
PALE = colors.HexColor('#F3F4FA')
BORDER = colors.HexColor('#DADEEA')
WIDTH, HEIGHT = A4
CONTENT_WIDTH = WIDTH - 96
styles = {
    'body': ParagraphStyle('BodyText', fontName='Body', fontSize=10, leading=15, textColor=NAVY, spaceAfter=9),
    'small': ParagraphStyle('Small', fontName='Body', fontSize=8.5, leading=12, textColor=MUTED, spaceAfter=6),
    'h1': ParagraphStyle('Chapter', fontName='BodyBold', fontSize=23, leading=29, textColor=NAVY, spaceAfter=19, keepWithNext=True),
    'h2': ParagraphStyle('Section', fontName='BodyBold', fontSize=14, leading=19, textColor=PURPLE, spaceBefore=16, spaceAfter=9, keepWithNext=True),
    'code': ParagraphStyle('SourceCode', fontName='Code', fontSize=8, leading=10.5, textColor=NAVY, spaceAfter=3),
    'note': ParagraphStyle('SourceNote', fontName='Body', fontSize=9.2, leading=13, textColor=NAVY, spaceAfter=0),
    'struct': ParagraphStyle('Structural', fontName='Body', fontSize=8, leading=10.5, textColor=MUTED, spaceAfter=0),
    'cell': ParagraphStyle('TableCell', fontName='Body', fontSize=8.3, leading=11.5, textColor=NAVY),
    'cellhead': ParagraphStyle('TableHead', fontName='BodyBold', fontSize=8.3, leading=11.5, textColor=colors.white),
    'cover': ParagraphStyle('Cover', fontName='BodyBold', fontSize=39, leading=46, textColor=NAVY, spaceAfter=14),
    'subtitle': ParagraphStyle('Subtitle', fontName='Body', fontSize=20, leading=28, textColor=PURPLE, spaceAfter=20),
}


def esc(s):
    return html.escape(s, quote=False)


def rich(s):
    """Escape text, preserve supported glyphs, and make official URLs clickable."""
    s = esc(s)
    s = re.sub(r'(https://[^\s<]+)', r'<link href="\1" color="#5C5CD6">\1</link>', s)
    return s


def code_text(s):
    parts = []
    cmap = pdfmetrics.getFont('Code').face.charToGlyph
    for char in s:
        if ord(char) not in cmap and char != '\n':
            parts.append(f'<font name="Unicode">{esc(char)}</font>')
        else:
            parts.append('&nbsp;' if char == ' ' else esc(char))
    return ''.join(parts)


class Guide(BaseDocTemplate):
    def __init__(self, filename):
        super().__init__(str(filename), pagesize=A4, leftMargin=48, rightMargin=48,
                         topMargin=53, bottomMargin=48, title='Odak — Satır Satır Geliştirici Rehberi',
                         author='Odak Projesi', subject='SwiftUI, Swift, macOS ve yerel JSON depolama eğitimi')
        frame = Frame(48, 48, CONTENT_WIDTH, HEIGHT - 101, leftPadding=0, rightPadding=0,
                      topPadding=0, bottomPadding=0)
        self.addPageTemplates(PageTemplate(id='guide', frames=frame, onPage=self.decorate))

    def decorate(self, c, doc):
        c.saveState()
        if doc.page > 1:
            c.setStrokeColor(BORDER)
            c.setLineWidth(.5)
            c.line(48, HEIGHT - 36, WIDTH - 48, HEIGHT - 36)
            c.setFont('BodyBold', 8)
            c.setFillColor(PURPLE)
            c.drawString(48, HEIGHT - 28, 'ODAK  /  GELİŞTİRİCİ REHBERİ')
            c.setFont('Body', 8)
            c.setFillColor(MUTED)
            c.drawRightString(WIDTH - 48, HEIGHT - 28, 'SwiftUI • macOS • Türkçe')
        c.setFont('Body', 8)
        c.setFillColor(MUTED)
        c.drawString(48, 28, 'Kaynak kod incelemesi  •  25 Eylül 2026')
        c.drawRightString(WIDTH - 48, 28, str(doc.page))
        c.restoreState()

    def afterFlowable(self, flowable):
        if getattr(flowable, 'toc_entry', None):
            level, text, key = flowable.toc_entry
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(text, key, level=level, closed=False)
            self.notify('TOCEntry', (level, text, self.page, key))


story = []
markdown = []
heading_count = 0

def heading(text, level=0, pagebreak=False):
    global heading_count
    if pagebreak:
        story.append(PageBreak())
    heading_count += 1
    p = Paragraph(rich(text), styles['h1' if level == 0 else 'h2'])
    p.toc_entry = (level, text, f'h{heading_count}')
    story.append(p)


def code_block(lines):
    rendered = []
    for line in lines:
        wrapped = textwrap.wrap(line, width=94, expand_tabs=False, replace_whitespace=False,
                                drop_whitespace=False, break_long_words=True, break_on_hyphens=False) or [' ']
        rendered.extend(code_text(x) for x in wrapped)
    p = Paragraph('<br/>'.join(rendered), styles['code'])
    t = Table([[p]], colWidths=[CONTENT_WIDTH])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), PALE),
        ('BOX', (0, 0), (-1, -1), .5, BORDER),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 9),
    ]))
    story.extend([t, Spacer(1, 10)])


def table(rows):
    count = len(rows[0])
    widths = ([.24, .32, .44] if count == 3 else [1 / count] * count)
    data = [[Paragraph(rich(c), styles['cellhead' if i == 0 else 'cell']) for c in row]
            for i, row in enumerate(rows)]
    t = Table(data, colWidths=[CONTENT_WIDTH * x for x in widths], repeatRows=1, hAlign='LEFT')
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PURPLE),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, PALE]),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LINEBELOW', (0, -1), (-1, -1), .4, BORDER),
    ]))
    story.extend([t, Spacer(1, 12)])


def render_markdown(path):
    source = path.read_text()
    markdown.append(source)
    lines = source.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if line.startswith('```'):
            body = []
            i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                body.append(lines[i])
                i += 1
            code_block(body)
        elif line.startswith('# '):
            heading(line[2:], 0, pagebreak=True)
        elif line.startswith('## '):
            heading(line[3:], 1)
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                row = [x.strip() for x in lines[i].strip('|').split('|')]
                if not all(re.fullmatch(r'[:\- ]+', c or '-') for c in row):
                    rows.append(row)
                i += 1
            table(rows)
            continue
        elif line.startswith('!['):
            match = re.match(r'!\[(.*?)\]\((.*?)\)', line)
            image_path = (path.parent / match[2]).resolve()
            im = Image(str(image_path))
            ratio = CONTENT_WIDTH / im.imageWidth
            im.drawWidth, im.drawHeight = CONTENT_WIDTH, im.imageHeight * ratio
            story.extend([im, Spacer(1, 6), Paragraph(rich(match[1]), styles['small'])])
        elif line.startswith('- ') or re.match(r'^\d+\. ', line):
            bullet = '•' if line.startswith('- ') else line.split('.')[0] + '.'
            body = line[2:] if line.startswith('- ') else line.split('. ', 1)[1]
            p = Paragraph(rich(body), ParagraphStyle('List', parent=styles['body'], leftIndent=14, bulletIndent=0), bulletText=bullet)
            story.append(p)
        else:
            story.append(Paragraph(rich(line), styles['body']))
        i += 1


def load_annotations():
    result = {}
    current = None
    for line in (HERE / 'annotations.txt').read_text().splitlines():
        if line.startswith('@@ '):
            current = line[3:]
            result[current] = {}
        elif line.strip():
            number, explanation = line.split('|', 1)
            number = int(number)
            if number in result[current]:
                raise ValueError(f'Duplicate annotation: {current}:{number}')
            result[current][number] = explanation
    return result


def lexical_code(s):
    # Ignore braces in quoted strings and comments when tracking closing scopes.
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', s).split('//', 1)[0]


def annotate_file(path, supplied):
    lines = path.read_text().splitlines()
    stack, annotated = [], []
    for number, line in enumerate(lines, 1):
        plain = line.strip()
        opening = stack[-1] if stack else None
        if number in supplied:
            note, kind = supplied[number], 'semantic'
        elif not plain:
            note, kind = 'Boş satır: komşu kod bölümlerini görsel olarak ayırır; çalıştırılan bir ifade değildir.', 'blank'
        elif plain.startswith('//'):
            note, kind = 'Yorum satırı: derlenip çalıştırılmaz; geliştiriciye bağlam veya şablon yönergesi verir.', 'comment'
            if 'Created by' in plain:
                note = 'Dosyanın oluşturulma bilgisini taşıyan Xcode şablon yorumudur; çalışma zamanı davranışını etkilemez.'
            elif 'Refresh' in plain or 'retained' in plain:
                note = 'Yorum, önceki geliştirme derlemesinden kalmış Dock simgesini yenileme gerekçesini açıklar.'
            elif 'XCTAssert' in plain:
                note = 'Şablon, işlevsel assertion eklemeyi önerir; yorumun kendisi doğrulama yapmaz ve bu metotta ek bir assertion yoktur.'
            elif 'Insert steps' in plain or 'such as logging' in plain:
                note = 'Şablon, görüntü almadan önce uygulama içi hazırlık eklenebileceğini söyler. Mevcut test burada ek adım uygulamaz.'
        elif re.fullmatch(r'[}\s]+', plain):
            assert opening is not None, (path, number, 'unmatched close')
            start_number, start_text = opening
            note = f'{start_number}. satırda açılan kapsamı kapatır: {start_text.strip()}'
            kind = 'close'
        else:
            raise ValueError(f'Missing explanation: {path.name}:{number}: {plain}')
        annotated.append({'line': number, 'code': line, 'explanation': note, 'kind': kind})
        for token in re.findall(r'[{}]', lexical_code(line)):
            if token == '{':
                stack.append((number, line))
            elif stack:
                stack.pop()
            else:
                raise ValueError(f'Unmatched brace {path}:{number}')
    if stack:
        raise ValueError(f'Unclosed scope in {path}: {stack}')
    extra = set(supplied) - set(range(1, len(lines) + 1))
    assert not extra, extra
    return annotated


snapshot = json.loads((HERE / 'source_snapshot.json').read_text())
for entry in snapshot['files']:
    actual = hashlib.sha256((ROOT / entry['path']).read_bytes()).hexdigest()
    if actual != entry['sha256']:
        raise ValueError(f"Source changed: {entry['path']}. Review annotations and update source_snapshot.json first.")
annotations = load_annotations()
manifest = {'title': 'Odak — Satır Satır Geliştirici Rehberi', 'snapshot_date': '2026-09-25', 'files': []}
all_rows = {}
for filename, notes in annotations.items():
    path = ROOT / filename
    rows = annotate_file(path, notes)
    all_rows[filename] = rows
    manifest['files'].append({'path': filename, 'lines': len(rows),
                              'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                              'semantic_lines': sum(r['kind'] == 'semantic' for r in rows)})
manifest['total_lines'] = sum(x['lines'] for x in manifest['files'])
assert manifest['total_lines'] == 514, 'Update the stated scope if source line counts change.'
(HERE / 'coverage.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

# Cover.
story.append(Spacer(1, 24))
story.append(Paragraph('ODAK', styles['cover']))
story.append(Paragraph('Satır Satır<br/>Geliştirici Rehberi', styles['subtitle']))
story.append(Paragraph('SwiftUI ile bir macOS uygulamasını anlamak', styles['h2']))
story.append(Paragraph('Ne yapıyor? Neden böyle yazılmış? Hangi araç hangi sorunu çözüyor?', styles['body']))
story.append(Spacer(1, 15))
cover_image = Image(str(ROOT / 'docs/screenshots/odak-light.png'), width=CONTENT_WIDTH, height=CONTENT_WIDTH * .74)
story.append(cover_image)
story.append(Spacer(1, 20))
story.append(Paragraph('6 Swift dosyası • 514 kaynak satırı • Yerleşim, veri akışı, kayıt ve testler', styles['body']))
story.append(Paragraph('Türkçe eğitim belgesi · Kaynak anlık görüntüsü: 25 Eylül 2026', styles['small']))
markdown.append('# Odak — Satır Satır Geliştirici Rehberi\n\nKaynak anlık görüntüsü: 25 Eylül 2026.\n')

story.append(PageBreak())
story.append(Paragraph('İçindekiler', styles['h1']))
toc = TableOfContents()
toc.levelStyles = [
    ParagraphStyle('TOC0', fontName='BodyBold', fontSize=10, leading=15, leftIndent=0, spaceBefore=8, textColor=NAVY),
    ParagraphStyle('TOC1', fontName='Body', fontSize=9, leading=12, leftIndent=15, spaceBefore=3, textColor=MUTED),
]
story.append(toc)
render_markdown(HERE / 'handbook.md')

summaries = {
    'ios_test/ios_testApp.swift': 'Giriş noktası, macOS delege köprüsü, ortak veri deposu ve pencere yapılandırması.',
    'ios_test/TaskStore.swift': 'Değer modeli, güvenli değişiklik akışı ve atomik JSON kaydı. Önce bu dosyayı anlamak, arayüzün veri çağrılarını okumayı kolaylaştırır.',
    'ios_test/ContentView.swift': 'Filtre enum’u, yerel durum, yerleşim bileşenleri, etkileşimler ve Canvas önizlemesi. En uzun dosya olduğu için alt bloklar kaynak satırlarıyla ayrılmıştır.',
    'ios_testTests/ios_testTests.swift': 'Geçici dosyalar üzerinde model davranışı ve bozuk veri korumasını sınayan Swift Testing testleri.',
    'ios_testUITests/ios_testUITests.swift': 'XCTest hazırlık kancaları, temel açılış ve açılış performansı ölçümü.',
    'ios_testUITests/ios_testUITestsLaunchTests.swift': 'UI yapılandırmaları için uygulamayı başlatıp test raporuna ekran görüntüsü ekleyen test.',
}
content_blocks = {1: 'Filtre türü ve görünüm durumu', 39: 'Ana yerleşim ve düzenleme sayfası', 80: 'Kenar çubuğu', 137: 'Başlık alanı', 155: 'İlerleme kartı', 178: 'Yeni görev alanı', 199: 'Liste ve arama', 234: 'Görev satırı', 262: 'Alt bilgi ve eylem yardımcıları', 294: 'Xcode önizlemesi'}
for idx, (filename, rows) in enumerate(all_rows.items(), 1):
    title = f'7.{idx}. {Path(filename).name}'
    story.append(PageBreak())
    heading(title, 1)
    story.append(Paragraph(rich(filename), styles['small']))
    story.append(Paragraph(rich(summaries[filename]), styles['body']))
    markdown.extend([f'\n## {title}\n\n`{filename}`\n\n{summaries[filename]}\n'])
    for row in rows:
        number, code, note, kind = row['line'], row['code'], row['explanation'], row['kind']
        if filename.endswith('/ContentView.swift') and number in content_blocks:
            story.append(Paragraph(rich(content_blocks[number]), styles['h2']))
        label = f'{number:03d}'
        if kind == 'blank':
            p = Paragraph(f'<font name="Code" color="#5C5CD6">{label}</font>  Boş satır — kod bölümlerini ayırır.', styles['struct'])
            story.extend([p, Spacer(1, 4)])
        elif kind == 'close':
            p = Paragraph(f'<font name="Code" color="#5C5CD6">{label} {esc(code.strip())}</font> — ' + rich(note), styles['struct'])
            story.extend([p, Spacer(1, 5)])
        else:
            code = code.rstrip()
            # Strip only common visual indentation for fit; exact source remains in Markdown.
            view_code = code.lstrip()
            chunks = textwrap.wrap(view_code, width=95, expand_tabs=False, replace_whitespace=False,
                                   drop_whitespace=False, break_long_words=True, break_on_hyphens=False) or ['']
            code_p = Paragraph(f'<font color="#5C5CD6">{label}</font>  ' + '<br/>     '.join(code_text(s) for s in chunks), styles['code'])
            note_p = Paragraph(rich(note), styles['struct' if kind in ('close', 'comment') else 'note'])
            panel = Table([[code_p], [note_p]], colWidths=[CONTENT_WIDTH])
            panel.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), PALE),
                ('LEFTPADDING', (0, 0), (-1, -1), 8),
                ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                ('TOPPADDING', (0, 0), (-1, 0), 5),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 4),
                ('TOPPADDING', (0, 1), (-1, 1), 4),
                ('BOTTOMPADDING', (0, 1), (-1, 1), 5),
            ]))
            story.append(KeepTogether([panel, Spacer(1, 4)]))
        markdown.append(f'### Satır {number}\n\n```swift\n{row["code"]}\n```\n\n{note}\n')

render_markdown(HERE / 'appendix.md')
heading('11.2. Kaynak anlık görüntüsü ve kapsam kontrolü', 1)
story.append(Paragraph('Aşağıda kaynak dosyaların satır sayıları ve SHA-256 özetlerinin ilk 16 karakteri yer alır. Tam özetler docs/education/source_snapshot.json dosyasındadır. Kod değişirse açıklamalar gözden geçirilmelidir.', styles['body']))
for item in manifest['files']:
    story.append(Paragraph(rich(f'{Path(item["path"]).name} · {item["lines"]} satır · {item["sha256"][:16]}'), styles['small']))
markdown.append('\n## Kaynak özeti\n\n```json\n' + json.dumps(manifest, ensure_ascii=False, indent=2) + '\n```\n')
# Resolve handbook-relative image links in the generated Markdown, located in docs/.
MD.write_text('\n'.join(markdown).replace('(../screenshots/', '(screenshots/'))
Guide(PDF).multiBuild(story)
print(json.dumps({'pdf': str(PDF), 'markdown': str(MD), 'source_lines': manifest['total_lines'], 'source_files': len(manifest['files']), 'pdf_bytes': PDF.stat().st_size}, ensure_ascii=False))
