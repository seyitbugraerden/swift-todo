"""Verify the generated PDF's source coverage, text, fonts and page bounds."""
from pathlib import Path
import hashlib
import json
import re
import pymupdf
from pypdf import PdfReader

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
pdf_path = ROOT / 'docs/odak-gelistirici-rehberi.pdf'
manifest = json.loads((HERE / 'coverage.json').read_text())
doc = pymupdf.open(pdf_path)
reader = PdfReader(pdf_path)
text = '\n'.join(page.get_text() for page in doc)
expected = []
for entry in manifest['files']:
    source = ROOT / entry['path']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == entry['sha256'], source
    expected.extend(f'{n:03d}' for n in range(1, entry['lines'] + 1))
actual = re.findall(r'(?m)^(\d{3})(?=\s|})', text)
assert actual == expected, 'Source line sequence missing, duplicated or out of order.'
assert len(actual) == 514
assert '\ufffd' not in text and '\u25a0' not in text, 'Possible replacement glyph.'
for term in ['Önemli', 'değişiklik', 'HStack', 'VStack', 'ZStack', '@StateObject', '514']:
    assert term in text, term
# Every nonempty source line must survive text extraction (ignoring visual wrapping/indentation).
flat = ''.join(text.split())
for entry in manifest['files']:
    for n, line in enumerate((ROOT / entry['path']).read_text().splitlines(), 1):
        if line.strip():
            assert ''.join(line.split()) in flat, f'Code missing from PDF: {entry["path"]}:{n}'
for page_index, page in enumerate(doc, 1):
    assert len(page.get_text().strip()) > 100, f'Unexpected blank page {page_index}'
    for block in page.get_text('dict')['blocks']:
        if block['type'] != 0:
            continue
        for line in block['lines']:
            x0, y0, x1, y1 = line['bbox']
            assert x0 >= 40 and x1 <= page.rect.width - 40, (page_index, 'horizontal overflow', line['bbox'])
            assert y0 >= 14 and y1 <= page.rect.height - 15, (page_index, 'vertical overflow', line['bbox'])
embedded = set()
for page in reader.pages:
    for font in page['/Resources'].get('/Font', {}).get_object().values():
        font = font.get_object()
        if font.get('/Subtype') == '/TrueType':
            descriptor = font['/FontDescriptor'].get_object()
            assert '/FontFile2' in descriptor, 'TrueType font is not embedded.'
            embedded.add(str(font['/BaseFont']))
assert embedded, 'No embedded TrueType fonts.'
links = sum(len(page.get_links()) for page in doc)
assert links >= 8 and reader.outline, 'Navigation links or outline missing.'
print(json.dumps({'pages': len(doc), 'source_files': len(manifest['files']),
                  'source_lines_verified': len(actual), 'embedded_fonts': len(embedded),
                  'links': links, 'pdf_bytes': pdf_path.stat().st_size,
                  'status': 'passed'}, ensure_ascii=False, indent=2))
