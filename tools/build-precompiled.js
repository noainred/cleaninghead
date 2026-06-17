#!/usr/bin/env node
/*
 * build-precompiled.js — index.html(JSX, Babel Standalone)에서
 *   "사전 컴파일 + 엄격 CSP" 버전을 생성한다 → precompiled-test.html
 *
 * 목적:
 *   1) 초기 로딩 가속: 브라우저에서 ~1.3만 줄 JSX를 즉석 컴파일하던 Babel Standalone 제거
 *   2) 보안 강화: 'unsafe-eval' 없는 엄격 CSP 적용 (인라인 스크립트는 sha256 해시로 허용)
 *
 * index.html(원본·편집 대상)은 건드리지 않는다. 결과물만 새로 쓴다.
 *
 * 사용:
 *   npm i @babel/standalone@7.26.4   # 1회
 *   node tools/build-precompiled.js
 *
 * 주의: @babel/standalone 버전은 index.html이 CDN으로 쓰는 버전과 맞출 것(7.26.4).
 */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const Babel = require('@babel/standalone');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'index.html');
const OUT = path.join(ROOT, 'precompiled-test.html');

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
const { code } = Babel.transform(jsx, { presets: ['env', 'react'], compact: false });
const appInner = '\n' + code + '\n';

// 3) babel 블록을 평범한 <script>로 교체 + Babel Standalone 로더 <script> 제거
html = html.slice(0, oi) + '<script>' + appInner + '</script>' + html.slice(ci + '</script>'.length);
html = html.replace(/[ \t]*<script crossorigin src="https:\/\/unpkg\.com\/@babel\/standalone@[^"]+"[^>]*><\/script>\n?/, '');

// 4) 인라인 스크립트 해시 (GA 헤드 스니펫 + 방금 넣은 앱 코드)
const gaOpen = html.indexOf('<script>');                 // 첫 bare <script> = GA(헤드)
const gaClose = html.indexOf('</script>', gaOpen);
const gaInner = html.slice(gaOpen + '<script>'.length, gaClose);
const hashes = [sha256(gaInner), sha256(appInner)];

// 5) 엄격 CSP (unsafe-eval 없음). 인라인 스크립트는 해시로만 허용.
const csp = [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  `script-src 'self' ${hashes.join(' ')} https://unpkg.com https://accounts.google.com https://www.googletagmanager.com`,
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com", // React 인라인 스타일 + <style> + 구글폰트 CSS
  "font-src 'self' https://fonts.gstatic.com",
  "img-src 'self' data: https:",
  "connect-src 'self' https://www.googleapis.com https://accounts.google.com https://oauth2.googleapis.com https://www.googletagmanager.com https://www.google-analytics.com https://*.google-analytics.com https://*.analytics.google.com",
  "frame-src 'self' https://accounts.google.com",
].join('; ');
const cspMeta = `<meta http-equiv="Content-Security-Policy" content="${csp}" />`;

if (html.indexOf('<meta charset="UTF-8" />') < 0) throw new Error('charset 메타를 찾지 못했습니다(삽입 위치).');
html = html.replace('<meta charset="UTF-8" />', '<meta charset="UTF-8" />\n' + cspMeta);

// 6) 자동 생성물 표식 주석
html = html.replace('<head>', '<head>\n<!-- ⚙ 자동 생성물: tools/build-precompiled.js (index.html 원본 → 사전컴파일+CSP). 직접 편집하지 마세요. -->');

fs.writeFileSync(OUT, html);
console.log('✅ 생성:', path.basename(OUT), '(' + html.length + ' bytes)');
console.log('   GA  hash:', hashes[0]);
console.log('   APP hash:', hashes[1]);
