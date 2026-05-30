#!/usr/bin/env python3
"""DMG 설치 창 배경 이미지(660x400 PNG) 생성기.

외부 의존성 없이 zlib 만으로 RGBA PNG 를 인코딩한다.
가운데에 오른쪽 화살표를 그려, 왼쪽 앱 아이콘 → 오른쪽 Applications 폴더로
드래그하는 것을 안내한다 (아이콘 자체는 Finder 가 배치).

사용법:
    python3 make_dmg_background.py [출력경로]
기본 출력: dmg-background.png (스크립트와 같은 폴더)
"""
import os
import sys
import struct
import zlib

W, H = 660, 400
SS = 2  # 슈퍼샘플링 배율 (안티앨리어싱)

BG = (0xF0, 0xED, 0xE6)     # 크림색 배경
ARROW = (0x3A, 0x3A, 0x38)  # 짙은 회색 화살표

# 화살표 좌표 (캔버스 중앙)
SHAFT_X0, SHAFT_X1 = 280, 360
SHAFT_HALF = 13            # 샤프트 두께/2
HEAD_X0, HEAD_X1 = 355, 400
HEAD_HALF = 34             # 화살촉 밑변 절반
CY = 200                   # 세로 중심


def in_arrow(x, y):
    # 샤프트(가로 막대)
    if SHAFT_X0 <= x <= SHAFT_X1 and abs(y - CY) <= SHAFT_HALF:
        return True
    # 화살촉(삼각형: 오른쪽으로 갈수록 좁아짐)
    if HEAD_X0 <= x <= HEAD_X1:
        t = (HEAD_X1 - x) / (HEAD_X1 - HEAD_X0)
        if abs(y - CY) <= HEAD_HALF * t:
            return True
    return False


def build_pixels():
    rows = bytearray()
    for y in range(H):
        rows.append(0)  # 필터 바이트
        for x in range(W):
            # 슈퍼샘플링으로 화살표 커버리지 계산
            hit = 0
            for sy in range(SS):
                for sx in range(SS):
                    px = x + (sx + 0.5) / SS
                    py = y + (sy + 0.5) / SS
                    if in_arrow(px, py):
                        hit += 1
            cov = hit / (SS * SS)
            if cov <= 0.0:
                rows.extend((BG[0], BG[1], BG[2], 255))
            else:
                r = int(BG[0] + (ARROW[0] - BG[0]) * cov)
                g = int(BG[1] + (ARROW[1] - BG[1]) * cov)
                b = int(BG[2] + (ARROW[2] - BG[2]) * cov)
                rows.extend((r, g, b, 255))
    return bytes(rows)


def write_png(path, raw):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else \
        os.path.join(os.path.dirname(__file__), "dmg-background.png")
    out = os.path.abspath(out)
    print("DMG 배경 생성 중...", out)
    write_png(out, build_pixels())
    print("완료:", out, os.path.getsize(out), "bytes")


if __name__ == "__main__":
    main()
