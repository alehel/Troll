"""Render all icons from scripts/data/icons.gd into a contact sheet PNG."""
import re, sys
from PIL import Image, ImageDraw
src = open("scripts/data/icons.gd").read()
pal = dict(re.findall(r'"(\w)": "([0-9a-f]{6})"', src.split("const JAM_COLORS")[0]))
jam = {"blueberry_jam": {"J": "b", "j": "n", "L": "r"}, "lingonberry_jam": {"J": "r", "j": "d", "L": "g"}}
art_src = src.split("const ART := {")[1].split("\nstatic var")[0]
arts = {}
for m in re.finditer(r'"(\w+)": \[(.*?)\]', art_src, re.S):
    rows = re.findall(r'"([^"]*)"', m.group(2))
    arts[m.group(1)] = rows
for k, v in jam.items():
    arts[k] = [''.join(v.get(c, c) for c in r) for r in arts["jar"]]
bad = [k for k, r in arts.items() if len(r) != 16 or any(len(x) != 16 for x in r)]
print("bad sizes:", bad)
names = list(arts)
cols = 8
S = 6
sheet = Image.new("RGBA", (cols * 20 * S, ((len(names) + cols - 1) // cols) * 26 * S), (230, 220, 200, 255))
d = ImageDraw.Draw(sheet)
for idx, n in enumerate(names):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    rows = arts[n]
    for y, r in enumerate(rows[:16]):
        for x, c in enumerate(r[:16]):
            if c in pal:
                img.putpixel((x, y), tuple(int(pal[c][i:i+2], 16) for i in (0, 2, 4)) + (255,))
    out = img.copy()
    for y in range(16):
        for x in range(16):
            if img.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                X, Y = x+dx, y+dy
                if 0 <= X < 16 and 0 <= Y < 16 and img.getpixel((X, Y))[3]:
                    out.putpixel((x, y), (42, 30, 26, 255)); break
    cx, cy = (idx % cols) * 20 * S, (idx // cols) * 26 * S
    sheet.paste(out.resize((16*S, 16*S), Image.NEAREST), (cx + 2*S, cy + 2*S), out.resize((16*S, 16*S), Image.NEAREST))
    d.text((cx + 2*S, cy + 19*S), n, fill=(0, 0, 0))
sheet.save(sys.argv[1])
