"""Top-down preview of the procedural terrain.

This mirrors scripts/world/terrain_data.gd so the world layout can be iterated
on quickly without launching Godot. Run:  python3 tools/terrain_preview.py out.png
Requires numpy + pillow.
"""
import math
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from layout import *  # noqa: E402,F401,F403


def hash2(ix, iz, seed):
    h = (ix * 374761393 + iz * 668265263 + seed * 144665) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h = h ^ (h >> 16)
    return (h & 0xFFFF) / 65535.0


def vnoise(x, z, seed):
    ix = math.floor(x)
    iz = math.floor(z)
    fx = x - ix
    fz = z - iz
    u = fx * fx * (3.0 - 2.0 * fx)
    v = fz * fz * (3.0 - 2.0 * fz)
    a = hash2(ix, iz, seed)
    b = hash2(ix + 1, iz, seed)
    c = hash2(ix, iz + 1, seed)
    d = hash2(ix + 1, iz + 1, seed)
    top = a + (b - a) * u
    bot = c + (d - c) * u
    return top + (bot - top) * v


def fbm(x, z, seed, octaves=4):
    s = 0.0
    amp = 0.5
    f = 1.0
    tot = 0.0
    for i in range(octaves):
        s += amp * vnoise(x * f, z * f, seed + i * 17)
        tot += amp
        amp *= 0.5
        f *= 2.03
    return s / tot


def smoothstep(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def shore_z(x):
    return SHORE_Z + 5.0 * math.sin(x * 0.045) + (fbm(x * 0.05, 3.7, 11) - 0.5) * 8.0


def base_height(x, z):
    # North/south profile.
    sz = shore_z(x)
    if z > sz:
        h = VILLAGE_Y - (z - sz) * 0.55
        h = max(h, -9.0)
    elif z > 18.0:
        h = lerp(VILLAGE_Y + 0.6, VILLAGE_Y, smoothstep(18.0, sz, z))
    elif z > -10.0:
        h = lerp(9.0, VILLAGE_Y + 0.6, smoothstep(-10.0, 18.0, z))
    elif z > -44.0:
        h = lerp(16.0, 9.0, smoothstep(-44.0, -10.0, z))
    elif z > -54.0:
        h = lerp(PLATEAU_Y, 16.0, smoothstep(-54.0, -44.0, z))
    else:
        h = PLATEAU_Y
    # zone-dependent roughness
    if z < -54.0:
        amp = 3.0
    elif z < -8.0:
        amp = 2.6
    elif z < sz - 8.0:
        amp = 0.9
    else:
        amp = 0.5
    h += (fbm(x * 0.035, z * 0.035, 3) - 0.5) * 2.0 * amp
    # Northern wall
    wz = -112.0 - (fbm(x * 0.02, 1.3, 13) - 0.5) * 22.0
    if z < wz:
        d = wz - z
        h += d * (0.7 + fbm(x * 0.03, z * 0.03, 5) * 1.1) + (fbm(x * 0.08, z * 0.08, 6) - 0.5) * d * 0.5
    # Side walls
    ax = abs(x)
    wall_start = 86.0 + (fbm(z * 0.02, 7.7, 14) - 0.5) * 16.0
    if x > 0.0:
        # the east road along the fjord stays open
        opening = smoothstep(10.0, 26.0, z) * (1.0 - smoothstep(64.0, 80.0, z))
        wall_start = lerp(wall_start, 150.0, opening)
    if ax > wall_start:
        d = ax - wall_start
        h += d * (0.7 + fbm(x * 0.03, z * 0.03, 8) * 1.1) + (fbm(x * 0.06, z * 0.06, 7) - 0.5) * d * 0.5
    return min(h, 140.0)


def seg_dist(px, pz, ax, az, bx, bz):
    dx = bx - ax
    dz = bz - az
    l2 = dx * dx + dz * dz
    if l2 < 1e-6:
        return math.hypot(px - ax, pz - az), 0.0
    t = ((px - ax) * dx + (pz - az) * dz) / l2
    t = min(max(t, 0.0), 1.0)
    cx = ax + dx * t
    cz = az + dz * t
    return math.hypot(px - cx, pz - cz), t


def polyline_query(px, pz, pts):
    """Returns (dist, y_at_closest)."""
    best = 1e9
    by = 0.0
    for i in range(len(pts) - 1):
        a = pts[i]
        b = pts[i + 1]
        d, t = seg_dist(px, pz, a[0], a[1], b[0], b[1])
        if d < best:
            best = d
            by = lerp(a[2], b[2], t)
    return best, by


def resolve_path_heights(pts):
    out = []
    for p in pts:
        if len(p) >= 3 and p[2] is not None:
            out.append((p[0], p[1], p[2]))
        else:
            out.append((p[0], p[1], base_height(p[0], p[1])))
    return out


PATHS_R = [(resolve_path_heights(p["pts"]), p["width"]) for p in PATHS]


def height(x, z):
    h = base_height(x, z)
    # Flat zones
    for (cx, cz, r, fall, ty) in FLATS:
        d = math.hypot(x - cx, z - cz)
        if d < r + fall:
            w = 1.0 - smoothstep(r, r + fall, d)
            t = ty if ty is not None else base_height(cx, cz)
            h = lerp(h, t, w)
    # Paths
    for pts, width in PATHS_R:
        d, py = polyline_query(x, z, pts)
        half = width * 0.5
        if d < half + 4.0:
            w = 1.0 - smoothstep(half, half + 4.0, d)
            h = lerp(h, py - 0.05, w)
    # River
    d, by = polyline_query(x, z, RIVER)
    if d < RIVER_HALF + 5.0:
        w = 1.0 - smoothstep(RIVER_HALF, RIVER_HALF + 5.0, d)
        h = min(h, lerp(h, by, w))
    # Lake
    lx, lz, lr, ly = LAKE
    d = math.hypot(x - lx, z - lz)
    if d < lr + 6.0:
        bed = ly - 2.5 * (1.0 - (d / lr) ** 2) if d < lr else ly + 0.4
        w = 1.0 - smoothstep(lr - 1.0, lr + 6.0, d)
        h = min(h, lerp(h, bed, w))
    return h


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "terrain.png"
    nx = int((X1 - X0) / STEP) + 1
    nz = int((Z1 - Z0) / STEP) + 1
    H = np.zeros((nz, nx))
    for j in range(nz):
        z = Z0 + j * STEP
        for i in range(nx):
            x = X0 + i * STEP
            H[j, i] = height(x, z)
    print("h range", H.min(), H.max())
    # hillshade
    gy, gx = np.gradient(H, STEP)
    slope = np.sqrt(gx * gx + gy * gy)
    shade = np.clip(0.6 + (-gx * 0.5 - gy * 0.7) * 0.35, 0.25, 1.2)
    img = np.zeros((nz, nx, 3))
    for j in range(nz):
        for i in range(nx):
            h = H[j, i]
            if h < SEA_Y - 0.2:
                c = (40, 90, 150)
            elif h < SEA_Y + 1.0:
                c = (210, 200, 150)
            elif slope[j, i] > 1.0:
                c = (120, 115, 110)
            elif h > 50:
                c = (240, 240, 245)
            elif h > PLATEAU_Y - 3:
                c = (140, 160, 80)
            elif h > 8:
                c = (60, 110, 60)
            else:
                c = (100, 160, 70)
            img[j, i] = np.array(c) * shade[j, i]
    # water surfaces for lake/river
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).resize((nx * 4, nz * 4), Image.NEAREST)
    dr = ImageDraw.Draw(im)

    def P(x, z):
        return ((x - X0) / STEP * 4, (z - Z0) / STEP * 4)

    for i in range(len(RIVER) - 1):
        dr.line([P(*RIVER[i][:2]), P(*RIVER[i + 1][:2])], fill=(60, 120, 220), width=10)
    lx, lz, lr, ly = LAKE
    a = P(lx - lr, lz - lr)
    b = P(lx + lr, lz + lr)
    dr.ellipse([a, b], outline=(60, 120, 220), width=3)
    for pts, width in PATHS_R:
        for i in range(len(pts) - 1):
            dr.line([P(*pts[i][:2]), P(*pts[i + 1][:2])], fill=(170, 130, 80), width=3)
    for name, (x, z) in LANDMARKS.items():
        px, pz = P(x, z)
        dr.rectangle([px - 4, pz - 4, px + 4, pz + 4], fill=(255, 0, 0))
        dr.text((px + 6, pz - 6), name, fill=(255, 255, 255))
    im.save(out)
    for name, (x, z) in LANDMARKS.items():
        print("%-12s base %.2f final %.2f" % (name, base_height(x, z), height(x, z)))
    # Report path slopes
    for idx, (pts, width) in enumerate(PATHS_R):
        worst = 0
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            worst = max(worst, abs(b[2] - a[2]) / max(L, 0.01))
        print("path", idx, PATHS[idx].get("name"), "max grade %.2f" % worst)


if __name__ == "__main__":
    main()
