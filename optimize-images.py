"""Rebuild optimized assets from untouched originals. Requires Pillow 12+."""
from pathlib import Path
from PIL import Image, ImageOps
from urllib.parse import unquote, quote
import re, json, hashlib

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'optimized'
OUT.mkdir(exist_ok=True)
scripts = list(ROOT.glob('app*.js'))
refs = sorted(set(unquote(s) for p in scripts for s in re.findall(r"image:'([^']+)'", p.read_text(encoding='utf-8')) if not s.startswith(('optimized/', 'http'))))
manifest_path = OUT / 'manifest.json'
if not refs and manifest_path.exists():
    refs = [r['original'] for r in json.loads(manifest_path.read_text(encoding='utf-8')) if r['kind'] == 'product']
rows = []
for source in refs + ['logo-acnatural-web.png', 'maquina.jpeg']:
    p = ROOT / source
    im = ImageOps.exif_transpose(Image.open(p))
    kind = 'product' if source in refs else 'logo' if 'logo' in source else 'hero'
    stem = re.sub(r'[^a-z0-9]+', '-', __import__('unicodedata').normalize('NFKD', p.stem).encode('ascii', 'ignore').decode().lower()).strip('-')
    variants = []
    widths = [480, 960, im.width] if kind == 'product' else [570] if kind == 'logo' else [im.width]
    for width in sorted(set(widths)):
        resized = im.resize((width, round(im.height * width / im.width)), Image.Resampling.LANCZOS) if width != im.width else im
        target = OUT / f'{stem}-{width}.webp'
        resized.save(target, 'WEBP', quality=92, method=6, lossless=kind == 'logo', exact=True)
        if kind == 'hero' and target.stat().st_size >= p.stat().st_size:
            target.unlink()  # Only the newly generated, larger candidate.
            target = p
        variants.append({'path': target.relative_to(ROOT).as_posix(), 'width': width, 'height': resized.height, 'bytes': target.stat().st_size})
    rows.append({'original': source, 'original_bytes': p.stat().st_size, 'original_dimensions': list(im.size), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'kind': kind, 'variants': variants})
manifest_path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Generated {sum(len(r["variants"]) for r in rows)} assets from {len(rows)} originals.')
