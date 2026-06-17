# tools/

빌드·점검용 보조 스크립트. **앱 자체는 무빌드**(브라우저가 `index.html`을 직접 실행)이며, 여기 도구는 선택적 최적화/검증용입니다.

## build-precompiled.js — 사전 컴파일 + 엄격 CSP 빌드

`index.html`(JSX, Babel Standalone)에서 **브라우저 컴파일이 필요 없는** 버전을 만들어 `precompiled-test.html`로 출력합니다.

- **무엇이 달라지나**
  - `<script type="text/babel">` → 미리 컴파일한 평범한 `<script>`
  - Babel Standalone 로더(`@babel/standalone`) 제거 → **초기 로딩 가속**(약 3MB 다운로드 + 즉석 컴파일 제거)
  - **엄격 CSP** 삽입: `'unsafe-eval'` 없음. 인라인 스크립트(헤드 GA, 앱 코드)는 `sha256` 해시로만 허용.
- **index.html은 건드리지 않습니다.** (원본·편집 대상 유지)

### 실행
```bash
npm i @babel/standalone@7.26.4   # 1회 (index.html이 쓰는 CDN 버전과 동일)
node tools/build-precompiled.js
```
출력: `precompiled-test.html` (+ 콘솔에 CSP용 sha256 해시 표시)

### 검증 순서 (중요)
`precompiled-test.html`은 **라이브로 전환하기 전 브라우저 검증용**입니다. GitHub Pages 배포 후:
1. `https://www.redmir.net/precompiled-test.html` 접속 → 정상 렌더 확인
2. 구글 드라이브 **연결/로그인/저장**이 동작하는지
3. 브라우저 콘솔에 **CSP 위반(빨간 오류)** 이 없는지
4. 초기 로딩이 더 빠른지

검증이 끝나면 같은 빌드 산출물을 `index.html`로 전환(또는 GitHub Actions로 자동화)하면 됩니다.

### 주의
- `index.html`의 babel 블록 경계(`<script type="text/babel" data-presets="env,react">`)와 charset 메타(`<meta charset="UTF-8" />`)에 의존합니다. 이 마커가 바뀌면 스크립트도 함께 수정하세요.
- 외부 의존성(구글 로그인/드라이브/폰트/애널리틱스)이 늘면 CSP의 `script-src`/`connect-src` 등을 함께 갱신해야 합니다.
