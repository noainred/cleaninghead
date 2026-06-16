# 보안 정책 · 점검 (Security)

BrainBloom은 **백엔드 없는 단일 HTML, 클라이언트 전용** 앱입니다. 이 문서는 보안 위협 모델, 적용된 방어, 알려진 한계, 성능 메모를 정리합니다.

- 대상: `index.html` (React 18 + Babel Standalone)
- 최종 점검: 2026-06-16 (v3.82.2)
- 제보: redmirnet@naver.com

---

## 위협 모델

- **서버·DB 없음** → 서버측 공격면이 존재하지 않음.
- 데이터는 **사용자 브라우저(IndexedDB)** 와 — 선택 시 — **본인 구글 드라이브**에만 저장. 서버로 전송되지 않음.
- **협업·공유 기능 없음** → 타인이 내 마인드맵을 볼 수 없음.
- 따라서 현실적 위협은: ① CDN 공급망 변조, ② 노드 라벨·불러온 데이터를 통한 XSS, ③ 액세스 토큰 탈취, ④ 위험한 링크(`javascript:` 등) 실행.

---

## 적용된 방어

### 공급망(Supply chain)
- 버전 고정 + **SRI(sha384)** 적용: `react`, `react-dom`, `@babel/standalone`, `jspdf`(동적 주입 시에도 `integrity`+`crossOrigin` 설정). CDN이 변조돼도 해시 불일치로 로드 거부.
- Google 스크립트(GIS 로그인·GA)는 Google이 버전을 고정하지 않아 SRI 불가 → 신뢰 도메인(`accounts.google.com`, `googletagmanager.com`)으로 한정.

### XSS / 주입
- 앱 코드에 `dangerouslySetInnerHTML` · `eval` · `new Function` **없음**.
- 유일한 `innerHTML` 사용처는 공식 도메인 외 접속 시 보여주는 **정적 안내 문자열**(사용자 데이터 미포함).
- 링크 출력 시 `safeLinkUrl()`로 **스킴 화이트리스트(http/https/mailto)** 검증 + 제어문자 제거(개행 삽입을 통한 스킴 스머글링 차단) — 입력 정규식과 별개로 **출력 시점에도 막는 심층 방어**.
- 불러오기·복원 데이터는 `sanitizeTree()` / `sanitizeNode()`로 알려진 필드·타입만 보존(모르는 필드 폐기).
- About(외부 안내) 페이지는 **sandbox iframe**으로 격리.

### 링크 / 네비게이션
- 모든 `target="_blank"` 및 `window.open(...)`에 `rel="noopener noreferrer"`(또는 `'noopener,noreferrer'`) — 탭 탈취(reverse tabnabbing)·리퍼러 유출 차단.

### 인증 / 토큰
- 구글 액세스 토큰은 **메모리 + sessionStorage**(탭을 닫으면 자동 삭제)에만 보관 — `localStorage` 미사용.
- OAuth 범위 **`drive.file`** — 앱이 만든 파일만 접근. 사용자의 다른 드라이브 파일은 읽지 못함.

### 탭 간 통신
- 중복 탭 감지는 **`BroadcastChannel`**(브라우저 동일 출처 전용)만 사용 — 교차 출처 메시지 수신/검증 위험 없음.

---

## 알려진 한계 · 트레이드오프

- **CSP(Content-Security-Policy) 미적용.** 의도된 한계다. Babel Standalone로 브라우저에서 JSX를 즉석 컴파일하는 **무빌드 구조**라, 의미 있는 CSP를 적용하려면 `script-src`에 `'unsafe-eval'`(Babel)과 인라인 스크립트·React 인라인 스타일을 위한 `'unsafe-inline'`이 필요해 **CSP의 XSS 방어 가치가 크게 줄어든다.** 동시에 Google 로그인(GIS)·드라이브 연동을 깨뜨릴 위험이 있다.
  - **권장 경로**: JSX **사전 컴파일(빌드 단계 도입)** → Babel Standalone 제거 → 그때 `'unsafe-eval'` 없이 엄격 CSP 적용 가능. (저장소의 `precompiled-test.html`이 사전 컴파일 프로토타입.) 이는 "단일 HTML·무빌드" 철학(TechDoc의 의도적 트레이드오프)과 상충하므로 별도 결정 사안.
- **호스트 게이트**(공식 도메인 외 실행 억제)는 클라이언트 측 억제로, 소스를 수정하면 우회 가능 — 단일 공개 소스의 구조적 한계(데이터 보안이 아닌 재호스팅 억제 목적).

---

## 성능 메모 (최적화 현황)

이미 적용된 의도적 최적화로, **함부로 바꾸면 회귀**가 나는 지점들:

- `layoutTree(tree)`는 **매 렌더 호출**한다(의도적). useMemo에 두면 동시성 렌더의 드문 타이밍에 좌표(`_x/_y`) mutate가 누락돼 모든 노드가 (0,0)에 겹치는 버그가 났다. 결정적·O(n)이고 노드는 `React.memo`로 `_x`가 같으면 리렌더를 건너뛰어 실비용은 거의 없다.
- 로컬 자동저장은 **1.5초 디바운스 + 직렬화 스냅샷 비교**로 무변경 쓰기를 건너뛴다(좌표 등 휘발성 필드는 비교 전 제거).
- 활성 문서 미러(`writeActiveDoc`)는 자동저장 핫패스에서 **`setState` 없이 `ref`+IndexedDB만** 갱신해 타이핑 중 추가 렌더 비용이 없다.
- 파생값은 `useMemo`/`useCallback`(약 26곳)으로 캐시, 아웃라인 이동도 내부 계산을 캐시한다.

**초기 로딩 비용**의 가장 큰 항목은 브라우저에서 ~1.3만 줄 JSX를 Babel로 즉석 컴파일하는 것이다 → 위 CSP 항목과 동일하게 **사전 컴파일** 도입이 로딩 성능·보안을 동시에 개선하는 단일 최적화다.

---

## 점검 체크리스트 (요약)

| 항목 | 상태 |
|---|---|
| CDN SRI(버전 고정) | ✅ react·react-dom·babel·jspdf |
| `dangerouslySetInnerHTML`/`eval` | ✅ 없음 |
| 링크 스킴 화이트리스트 | ✅ `safeLinkUrl` |
| `rel=noopener`(외부 링크) | ✅ 전부 |
| 토큰 보관(메모리/세션) | ✅ localStorage 미사용 |
| OAuth 최소 범위 | ✅ `drive.file` |
| 불러온 데이터 검증 | ✅ `sanitizeTree` |
| iframe sandbox(About) | ✅ |
| CSP | ⚠️ 미적용(무빌드 구조 한계 — 사전 컴파일과 함께 권장) |
