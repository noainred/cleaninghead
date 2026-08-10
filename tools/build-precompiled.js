#!/usr/bin/env node
/*
 * build-precompiled.js — index.html(JSX, Babel Standalone)에서
 *   "사전 컴파일 + 엄격 CSP" 배포본을 생성한다.
 *
 * 목적:
 *   1) 초기 로딩 가속: 브라우저에서 ~1.2만 줄 JSX를 즉석 컴파일하던 Babel Standalone 제거
 *      (컴파일 실측 ~3.1초 + babel.min.js 631KB gzip 다운로드가 사라짐)
 *   2) 보안 강화: 'unsafe-eval' 없는 엄격 CSP 적용 (인라인 스크립트는 sha256 해시로만 허용)
 *
 * index.html(원본·편집 대상)은 건드리지 않는다. 결과물만 새로 쓴다.
 *
 * 사용:
 *   npm i @babel/standalone@7.26.4       # 1회 (index.html이 쓰는 CDN 버전과 동일해야 함)
 *   node tools/build-precompiled.js                     # → precompiled-test.html (검증용)
 *   node tools/build-precompiled.js --out dist/index.html   # CI 배포용 경로 지정
 *   node tools/build-precompiled.js --readable          # compact 끄기(디버깅용, gzip +16KB)
 *
 * 2026-08-10 결함 수정 (성능 감사 검증 반영):
 *   - 인라인 스크립트를 2개만 해시하던 버그 → bare <script> 블록 '전부' 해시
 *     (미해시 시 랜딩/모바일 리다이렉트·GA가 엄격 CSP에 조용히 차단되던 문제)
 *   - img-src에 blob: 추가 (svgToRaster가 blob: 이미지를 로드 — 없으면 PNG/JPG/PDF
 *     내보내기와 노드 이미지 복사가 전부 실패)
 *   - 원본의 부분 CSP 메타 제거(엄격 CSP와 중복) + compact:true 기본화(gzip 16KB 절감)
 */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const Babel = require('@babel/standalone');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'index.html');
const args = process.argv.slice(2);
const outArg = args.indexOf('--out');
const OUT = outArg >= 0 && args[outArg + 1] ? path.resolve(args[outArg + 1]) : path.join(ROOT, 'precompiled-test.html');
const COMPACT = !args.includes('--readable');

const sha256 = (s) => "'sha256-" + crypto.createHash('sha256').update(s, 'utf8').digest('base64') + "'";

let html = fs.readFileSync(SRC, 'utf8');

// 1) <script type="text/babel"> 블록의 JSX 추출
const BABEL_OPEN = '<script type="text/babel" data-presets="env,react">';
const oi = html.indexOf(BABEL_OPEN);
if (oi < 0) throw new Error('text/babel 스크립트 블록을 찾지 못했습니다.');
const innerStart = oi + BABEL_OPEN.length;
const ci = html.indexOf('</script>', innerStart);
if (ci < 0) throw new Error('text/babel 블록의 </script>를 찾지 못했습니다.');
const jsx = html.slice(innerStart, ci);

// 2) JSX → 평범한 JS (index.html과 동일한 presets)
const t0 = Date.now();
const { code } = Babel.transform(jsx, { presets: ['env', 'react'], compact: COMPACT });
const buildMs = Date.now() - t0;
const appInner = '\n' + code + '\n';

// 3) babel 블록을 평범한 <script>로 교체 + Babel Standalone 로더 <script> 제거
html = html.slice(0, oi) + '<script>' + appInner + '</script>' + html.slice(ci + '</script>'.length);
html = html.replace(/[ \t]*<script crossorigin src="https:\/\/unpkg\.com\/@babel\/standalone@[^"]+"[^>]*><\/script>\n?/, '');

// 4) 인라인 스크립트 '전부' 해시 — bare <script> 블록만 대상(외부 스크립트는 속성이 있어 제외됨)
//    현재 원본 기준 4개: 클릭재킹 방어 / 랜딩·모바일 리다이렉트 / GA 로더 / 앱 코드(방금 삽입)
const inlineBlocks = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
if (inlineBlocks.length < 2) throw new Error('인라인 스크립트가 예상보다 적습니다: ' + inlineBlocks.length);
const hashes = inlineBlocks.map(sha256);

// 5) 엄격 CSP (unsafe-eval 없음). 인라인 스크립트는 해시로만 허용.
//    img-src의 blob: — svgToRaster(내보내기·노드 이미지 복사)가 blob: URL 이미지를 로드하므로 필수.
const csp = [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  `script-src 'self' ${hashes.join(' ')} https://unpkg.com https://accounts.google.com https://www.googletagmanager.com`,
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com", // React 인라인 스타일 + <style> + 구글폰트 CSS
  "font-src 'self' https://fonts.gstatic.com",
  "img-src 'self' data: blob: https:",
  // www.google.com/g/collect — GA4(Google Signals)가 비콘을 보내는 경로 (v3.104.1: 미허용 시 매 방문 콘솔에 CSP 위반 오류)
  "connect-src 'self' https://www.googleapis.com https://accounts.google.com https://oauth2.googleapis.com https://www.googletagmanager.com https://www.google-analytics.com https://*.google-analytics.com https://*.analytics.google.com https://www.google.com/g/collect https://unpkg.com https://fonts.googleapis.com https://fonts.gstatic.com",
  "frame-src 'self' https://accounts.google.com",
].join('; ');
const cspMeta = `<meta http-equiv="Content-Security-Policy" content="${csp}" />`;

// 원본의 부분 CSP 메타(object-src/base-uri)는 엄격 CSP에 포함되므로 제거(중복 방지)
html = html.replace(/[ \t]*<meta http-equiv="Content-Security-Policy" content="object-src[^"]*" \/>\n?/, '');

if (html.indexOf('<meta charset="UTF-8" />') < 0) throw new Error('charset 메타를 찾지 못했습니다(삽입 위치).');
html = html.replace('<meta charset="UTF-8" />', '<meta charset="UTF-8" />\n' + cspMeta);

// 6) 자동 생성물 표식 주석
html = html.replace('<head>', '<head>\n<!-- ⚙ 자동 생성물: tools/build-precompiled.js (index.html 원본 → 사전컴파일+CSP). 직접 편집하지 마세요. -->');

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, html);
console.log('✅ 생성:', OUT, '(' + html.length + ' bytes, 컴파일 ' + buildMs + 'ms, compact=' + COMPACT + ')');
console.log('   인라인 스크립트 해시 ' + hashes.length + '개:');
hashes.forEach((h, i) => console.log('   #' + (i + 1) + ' (' + inlineBlocks[i].length + '자): ' + h));
