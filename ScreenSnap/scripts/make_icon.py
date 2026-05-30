#!/usr/bin/env python3
"""ScreenSnap 앱 아이콘(1024x1024 PNG) 생성기.

외부 의존성 없이 순수 표준 라이브러리(zlib)만으로 RGBA PNG 를 직접 인코딩한다.
디자인: 파랑→네이비 그라데이션 둥근 사각형 위에 흰색 뷰파인더(코너 브래킷).

사용법:
    python3 make_icon.py [출력경로]
기본 출력: ../Resources/AppIcon.png
"""
import os
import sys
import struct
import zlib

SIZE = 1024

# 색상 (R, G, B)
TOP = (0x4A, 0x90, 0xE2)      # 밝은 파랑
BOTTOM = (0x1F, 0x3A, 0x68)   # 네이비
WHITE = (0xFF, 0xFF, 0xFF)


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def rounded_rect_coverage(x, y, x0, y0, x1, y1, radius):
    """둥근 사각형 내부 커버리지(0~1). 경계에서 1px 안티앨리어싱."""
    # 사각형 중심 기준 거리장(SDF)
    hw = (x1 - x0) / 2.0
    hh = (y1 - y0) / 2.0
    cx = (x0 + x1) / 2.0
    cy = (y0 + y1) / 2.0
    dx = abs(x - cx) - (hw - radius)
    dy = abs(y - cy) - (hh - radius)
    dx = max(dx, 0.0)
    dy = max(dy, 0.0)
    dist = (dx * dx + dy * dy) ** 0.5 - radius
    # dist < 0 이면 내부. 0 근처에서 부드럽게.
    return clamp(0.5 - dist)


def in_brackets(x, y, v0, v1, arm, thick):
    """뷰파인더 코너 브래킷 위에 있으면 True."""
    corners = [
        (v0, v0, 1, 1),    # 좌상 (방향: +x, +y)
        (v1, v0, -1, 1),   # 우상
        (v0, v1, 1, -1),   # 좌하
        (v1, v1, -1, -1),  # 우하
    ]
    for (cxp, cyp, sx, sy) in corners:
        # 가로 팔
        hx0, hx1 = sorted([cxp, cxp + sx * arm])
        hy0, hy1 = sorted([cyp, cyp + sy * thick])
        if hx0 <= x <= hx1 and hy0 <= y <= hy1:
            return True
        # 세로 팔
        vx0, vx1 = sorted([cxp, cxp + sx * thick])
        vy0, vy1 = sorted([cyp, cyp + sy * arm])
        if vx0 <= x <= vx1 and vy0 <= y <= vy1:
            return True
    return False


def build_pixels():
    # 둥근 사각형 영역 (캔버스에 약간의 여백)
    margin = 96
    r0, r1 = margin, SIZE - margin
    radius = 200

    # 뷰파인더 좌표
    v0, v1 = 312, SIZE - 312
    arm = 150
    thick = 50

    rows = bytearray()
    for y in range(SIZE):
        rows.append(0)  # 각 행 앞 필터 바이트(None)
        # 그라데이션(세로)
        t = y / (SIZE - 1)
        gr = int(TOP[0] + (BOTTOM[0] - TOP[0]) * t)
        gg = int(TOP[1] + (BOTTOM[1] - TOP[1]) * t)
        gb = int(TOP[2] + (BOTTOM[2] - TOP[2]) * t)
        for x in range(SIZE):
            cov = rounded_rect_coverage(x + 0.5, y + 0.5, r0, r0, r1, r1, radius)
            if cov <= 0.0:
                rows.extend((0, 0, 0, 0))
                continue
            if in_brackets(x, y, v0, v1, arm, thick):
                r, g, b = WHITE
            else:
                r, g, b = gr, gg, gb
            a = int(round(255 * cov))
            rows.extend((r, g, b, a))
    return bytes(rows)


def write_png(path, raw_rgba_with_filters):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        c += struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        return c

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)  # 8bit, RGBA
    idat = zlib.compress(raw_rgba_with_filters, 9)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else \
        os.path.join(os.path.dirname(__file__), "..", "Resources", "AppIcon.png")
    out = os.path.abspath(out)
    print("아이콘 생성 중...", out)
    write_png(out, build_pixels())
    print("완료:", out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    main()
