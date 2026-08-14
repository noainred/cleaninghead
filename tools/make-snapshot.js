#!/usr/bin/env node
/* 스냅샷 생성기 — index.html의 외부 데이터 <script src="data/*.js">를 파일 내용 인라인으로
 * 치환해 '자족(self-contained) 복사본'을 만든다. (seahyun/brainstorm_v<버전>.html)
 * 데이터 분리(v3.110.1~) 이후에도 스냅샷은 단일 파일로 열리도록 유지하기 위함.
 * 사용: node tools/make-snapshot.js <출력경로>
 */
'use strict';
const fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..');
const out = process.argv[2];
if (!out) { console.error('사용: node tools/make-snapshot.js <출력경로>'); process.exit(1); }
let html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
// <script src="data/xxx.js"></script> → 인라인 (경로는 data/ 하위만 허용)
html = html.replace(/<script src="(data\/[^"]+\.js)"><\/script>/g, (m, rel) => {
  const code = fs.readFileSync(path.join(ROOT, rel), 'utf8');
  return '<script>\n/* [스냅샷 인라인] ' + rel + ' */\n' + code + '\n</script>';
});
if (/<script src="data\//.test(html)) throw new Error('인라인화되지 않은 data 스크립트가 남았습니다');
fs.writeFileSync(out, html);
console.log('스냅샷 생성:', out, fs.statSync(out).size, 'bytes');
