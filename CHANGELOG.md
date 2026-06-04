# Changelog

BrainBloom의 모든 변경사항이 이 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)을 따르며,
이 프로젝트는 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 준수합니다.

---

## [Unreleased]

향후 추가 예정인 기능이 여기에 기록됩니다.

---

## [3.51.0] - 2026-06-04

### Improved — 다중 기기(집↔회사) 충돌 방지 3종 (사용자 제보: 양쪽 켜두면 서로 저장해 충돌)
**진단된 구멍 3개**: ①수동 저장(⬆버튼·Ctrl+Shift+S)은 원격 확인 없이 즉시 저장 ②새로고침 직후 세션은 동기화 기준 시각이 없어 `checkRemoteNewer`가 "비교 불가→통과"(옛 트리를 검사 없이 새 버전으로 저장 — 주범) ③항상 보이는 탭(둘째 모니터)은 visibilitychange가 안 와 감지 누락

- **`syncBaselineOnConnect` 신설** — 연결(수동·자동 재연결) 직후 서버 최신 파일을 1회 내려받아 로컬과 **내용 직접 비교**(serializeTreeContent): 같으면 조용히 기준 시각·내용 세팅(새로고침 일상에 무소음), 다르면 즉시 최신본 배너. 설정 파일 제외, 첫 사용(서버 빈 폴더) 통과, 로컬 비어있으면 불러오기 유도. isCheckingRemoteRef로 직렬화
- **`checkRemoteNewer` base-null 봉쇄** — 기준 없음+서버 파일 있음 → "통과" 대신 배너(베이스라인 실패 시의 최후 안전망)
- **수동 저장 관문** — `handleDriveSave`: remotePending이거나 저장 직전 검사에서 발견 시 `'remote'` 반환·보류. Ctrl+Shift+S 토스트 3분기(보류 경고 3초/성공 1초/실패 3초)
- **주기·포커스 감지** — 10분 ping에 최신본 확인 동승, window focus 리스너 추가(+정리)
- 기존 배너의 "무시하고 계속"(기준 시각 인정 후 계속)·"잠시 보류"(다음 저장 때 재확인) 결정 흐름은 그대로 활용
- UserGuide 안전장치 설명 갱신(검사 시점 4가지 + 버전 파일이라 데이터 유실 없음 안내)

### Technical Notes
- 검증: 실제 sanitizeTree·serializeTreeContent 추출 — 기준 동기화 5케이스(동일/다름/설정파일만/빈서버/빈로컬) + 탐지 3케이스(base없음/서버최신/내가최신) + 수동 관문 3분기 = 9/9 통과

---

## [3.50.2] - 2026-06-04

### Changed
- **헤더 JSON 버튼 표기 변경** — "텍스트" 그룹 캡션 제거(빈 캡션 조건부 렌더), 버튼 라벨 `JSON` → `저장`
  - 형식 정보는 툴팁으로 이동: 'JSON 백업으로 저장 — 설정의 "📂 JSON 백업 파일 열기"로 다시 불러올 수 있어요'
  - 설정의 형식 선택 칩(JSON)은 형식 이름 기준이라 유지

---

## [3.50.1] - 2026-06-04

### Changed
- **📂 JSON 열기를 헤더 → 설정으로 이동** — "헤더에 표시할 저장 버튼" 행 바로 아래 "📂 JSON 백업 파일 열기" 행(아이콘 포함)
  - 헤더 텍스트 그룹은 JSON 저장만 남음(`withOpen` 완전 제거) — 그룹 전부 끄면 그룹·구분선도 사라짐
  - 숨김 file input을 **항상 마운트되는 위치**(SettingsModal 렌더 앞)로 이동 — 미니멀 헤더 상태에서 input이 언마운트돼 열기가 죽는 문제 예방
  - 설정에서 파일을 열어 성공하면 모달 자동 닫힘(불러온 지도가 바로 보이도록)
- **드라이브 섹션 재배치** — 혼동 방지: [⬆저장/⬇목록 버튼] → **파일 목록**(새 캡션 "📄 드라이브의 마인드맵 파일 — 클릭하면 미리보기") → **미리보기 카드** → 점선 구분 → **⚙️ 설정 백업** → 자동저장
  - 기존엔 목록이 설정 백업 버튼 '아래'에 떠서 설정 저장/불러오기와 붙어 보였음

### Technical Notes
- 검증: 배치 순서 인덱스 검사(목록<미리보기<설정백업<자동저장), 헤더 그룹 재시뮬 3케이스, withOpen 잔재 0, input 단일 마운트 확인

---

## [3.50.0] - 2026-06-04

### Added
- **드라이브 보관 개수 설정 (`driveKeepCount`, 기본 5, 1~100)** — 드라이브 섹션 "오늘 버전 보관 개수" 숫자 입력
  - `runVersionedSave` 4번째 인자 `keepArg`로 인자화(내부 clamp 1~100·소수 내림·깨진 값 5) → `filesToDeleteToday(..., keep)` 전달. 수동 저장·자동저장 공통 적용
  - 자동저장은 `autoSaveRef.current.keepCount` 경유 + effect deps에 `settings.driveKeepCount` 추가 — **stale closure 방지(prefix와 동일 패턴)**
  - 설정 초기값 + 누락 방어(비숫자/범위 밖 → 5) 추가. 지난 날짜 "마지막 1개만" 규칙은 기존 그대로
- **설정 불러오기 토스트** — 성공 시 "⚙️ 설정을 불러와 적용했어요" 1초 표시(기존 하단 상태 텍스트는 유지)

### Verified — 설정 불러오기 "실제 적용" 경로 점검 (요청 ②)
- `setSettings` 안전 병합 → React 상태 → 모달 UI 즉시 반영
- `[settings]` effect의 `idbSet('settings')`(settingsLoadedRef 가드) → **새로고침 후에도 유지**
- `bgTheme` effect(`data-theme` setAttribute) → 테마 즉시 적용
- `autoSaveRef` 동기화 effect → 자동저장 동작값(접두어·보관 개수) 즉시 갱신
- 자동저장 interval effect deps(`driveAutoSave`/`Minutes`) → 켬·간격 변경 시 재바인딩
→ 전 경로 정상. 코드 수정 불필요 확인

### Technical Notes
- 검증: 실제 `filesToDeleteToday` 추출 keep 변형 4케이스(5/100/1/딱 맞음) + clamp 3케이스 통과

---

## [3.49.1] - 2026-06-04

### Improved
- **설정 버튼 상태 툴팁** — 마우스 오버 시 현재 상태(파랑=자동저장 작동 중 / 빨강=연결 문제로 멈춤 / 기본색=자동저장 꺼짐·알림 꺼짐) + 색 범례를 멀티라인 title로 표시
  - 색을 정하는 inline style 분기와 **정확히 같은 조건**으로 분기 — 색·설명 불일치 원천 차단(driveAutoFailed vs !driveSignedIn류 조건 어긋남 재발 방지)
  - 검증: 색↔툴팁 상태 일치 5케이스(알림OFF/실패/끊김/정상/자동저장OFF) 통과
- UserGuide 글자 색 섹션에 "버튼에 마우스를 올리면 설명이 뜬다" 안내 추가

---

## [3.49.0] - 2026-06-04

### Added
- **드라이브 불러오기 미리보기** — 목록에서 파일 클릭 시 즉시 로드 대신 미리보기 카드 표시
  - 요약: 노드 수(walk 집계)·깊이(재귀)·중심 주제·1단계 가지(최대 5개 + 외 N개)·내용 앞 12줄(treeToText, + 외 N줄)
  - "⬇ 이 파일 불러오기" 확인 후에만 실제 교체 — 미리보기는 화면 데이터를 건드리지 않음(sanitizeTree만 통과시켜 요약 계산)
  - 선택된 행 하이라이트, 목록 새로고침·실제 로드 시 미리보기 자동 닫힘
- **목록에 세부정보** — `files.list` fields에 `size` 추가 → 각 행에 수정 시각 + 크기(KB) 표시
- **기존 결함 수정** — 목록에서 직접 로드할 때 `modifiedTime`을 안 넘겨 동기 기준(lastSyncedTimeRef) 갱신이 누락되던 문제, 미리보기 경유 로드에서 해결

### Technical Notes
- 검증: 요약 계산 4케이스(노드수·깊이/가지 5+N 절단/단일 노드) 통과
- SettingsModal props 3개 추가(drivePreview/onDrivePreviewFile/onDrivePreviewClose)

---

## [3.48.0] - 2026-06-04

### Added
- **설정 드라이브 백업 (수동 전용)** — 드라이브 연동 칸에 "⚙️⬆ 설정 저장 / ⚙️⬇ 설정 불러오기" 버튼
  - 고정 파일명 `BrainBloom_settings.json` 1개 유지 — **새로 저장 후 옛 사본 삭제** 순서(저장 실패 시 기존 백업 보존)
  - 페이로드에 `__type:'brainbloom-settings'` 마커 + 버전·저장시각 — 불러올 때 마인드맵 파일과 혼동 차단
  - **안전 병합**: 현재 설정에 존재하는 키만(화이트리스트), 타입·배열 여부가 일치할 때만 덮어씀 → 손상·조작된 백업이 앱을 망가뜨리지 못함
  - 마인드맵 "불러오기 목록"에서 설정 파일 제외. 날짜 패턴이 아니라 버전 정리 로직도 건드리지 않음(parseDriveFileName null-skip 확인)
  - 자동저장 없음 — 버튼을 누를 때만 동작 (요구사항)
- UserGuide 드라이브 섹션에 설정 백업 팁 추가

### Technical Notes
- 검증: 안전 병합 5케이스(정상/타입불일치 무시/미지 키 차단/배열 교체/빈 파일 무변화) 통과
- SettingsModal props 2개 추가(onDriveSaveSettings/onDriveLoadSettings) — 콜사이트 연결 확인

---

## [3.47.4] - 2026-06-04

### Changed
- **공식 주소 변경: `noainred.github.io/cleaninghead` → `www.redmir.net`** — 9개 링크 일괄 교체
  - 앱: 설정 문서 바로가기 2곳 (UserGuide·TechDoc)
  - README.md: 바로 써보기·만화·가이드·기술문서·빠른 시작 등 6곳
  - 만화(BrainBloom_Comic.html): 아웃트로 주소 1곳
  - GitHub Issues 링크는 저장소 주소라 유지(github.com/noainred/cleaninghead/issues)
  - 드라이브 OAuth 승인 원본도 redmir.net 기준 — 3.47.3 안내와 일치

---

## [3.47.3] - 2026-06-04

### Improved
- **드라이브 접속 주소 안내 추가** — 베타 안내 박스에 통합: 코드가 변경된 사본의 해킹 위험 차단을 위해 드라이브 연결은 `www.redmir.net` 주소에서만 동작(링크 포함, 새 탭). 다른 주소·내려받은 파일에서는 구글 차단 화면이 뜸(앱 고장 아님)
- 드라이브 섹션 하단 각주 "(배포 주소에서만 작동)" → "(www.redmir.net 주소에서만 작동)" 통일
- 배경: OAuth 승인된 JavaScript 원본이 redmir.net으로 설정됨 → 이전 invalid_request 차단 화면의 원인 규명

---

## [3.47.2] - 2026-06-04

### Improved
- **드라이브 저장 완료 토스트 1초로 단축** (기존 3초가 길다는 피드백) — 성공은 짧은 확인용 1,000ms, 실패 안내는 읽고 조치할 시간이 필요해 3,000ms 유지

---

## [3.47.1] - 2026-06-04

### Improved
- **헤더 저장 버튼 그룹화** — 이미지(JPG·SVG) / 문서(PDF·CSV·MD) / 텍스트(JSON + 📂열기) 세 그룹, 그룹 캡션 + 옅은 구분선
  - 📂 열기를 독립 버튼에서 텍스트 그룹 안으로 이동(불러오기 가능한 형식과 한 묶음)
  - `primary` 강조를 "마지막 버튼"에서 **JSON 고정**으로 변경 — 다시 불러올 수 있는 백업 형식임을 시각적으로 강조(툴팁에도 명시)
  - 빈 그룹은 숨김. 텍스트 그룹은 열기 버튼 때문에 항상 표시(저장 버튼을 전부 꺼도 백업 복원은 가능). 미니멀 헤더에선 전체 숨김(기존과 동일)
- **설정 "헤더에 표시할 저장 버튼" 칩도 같은 3그룹으로 정리** (캡션: 이미지/문서/텍스트(불러오기 가능))

### Technical Notes
- 검증: 그룹 표시 분기 5케이스(전부 켬/PDF만/전부 끔/JSON만/미니멀) 통과. 키드 React.Fragment 사용

---

## [3.47.0] - 2026-06-04

### Added
- **📂 JSON 파일 열기** — JSON 내보내기의 짝(지금까지는 내보내기만 있고 되살릴 방법이 없었음). 헤더에 "📂 열기" 버튼(미니멀 헤더에선 숨김)
  - 드라이브 불러오기와 **동일한 정제 흐름** 재사용: `JSON.parse` → `data.tree || data`(래퍼 형식 호환) → `sanitizeTree`(깊이·노드수·라벨 한도) → 메타 보정 → `assignDefaultColors`
  - 교체 전 `maybePushHistory` → **Ctrl+Z로 복구 가능**(확인 다이얼로그 대신 언두 철학, 토스트로 안내)
  - `lastSavedContentRef`는 갱신하지 않음 — 로컬 파일 내용은 드라이브에 없는 것이므로 자동저장이 변경으로 인식해 저장하는 게 올바른 동작
  - 같은 파일 연속 선택 가능(input.value 초기화), 손상 JSON·비정상 형식은 토스트로 안내
- UserGuide 저장 섹션에 "JSON 백업은 다시 열 수 있어요" 팁 추가

### Technical Notes
- 검증: **실제 sanitizeTree 추출** 후 왕복 시뮬 6케이스(내보내기→열기 보존, 래퍼 형식, 배열/문자열 거부, 라벨 한도 잘림, 손상 JSON 예외 경로) 통과

---

## [3.46.1] - 2026-06-04

### Fixed
- **화면 가장자리 노드 편집 시 입력창이 뷰포트 밖으로 잘리던 문제** (사용자 스크린샷 제보 — 하단 노드 편집 시 입력창 절반이 화면 아래로)
  - `ensureNodeVisible(nodeId, margin=28)` 신설 — `centerNode`와 같은 DOM 기반(`getBoundingClientRect`)이지만, 화면을 통째로 옮기지 않고 **부족한 만큼만 최소 스크롤**(편집 흐름 유지). 줌 배율·편집 링 크기 자동 반영
  - `editingId` effect: 편집 시작 시 rAF 후 가시 보장 + **ResizeObserver**로 편집 노드 관찰 — 타이핑으로 노드 폭이 실시간으로 자라 오른쪽으로 삐져나가는 것도 따라감
  - `behavior:'auto'`(즉시) — 빠른 Tab/Enter 연쇄·타이핑 중 측정 오차 방지

### Technical Notes
- 검증: 보정 계산 6케이스(아래/위/오른쪽 잘림, 완전 가시 시 무동작, 초대형 노드 좌상단 정렬, 모서리 양축 동시) 통과

---

## [3.46.0] - 2026-06-04

### Added — 공개(소프트 런칭) 준비
- **드라이브 연결 버튼 베타 안내** — 미연결 상태에서 연결 버튼 아래 안내 박스 표시
  - 구글 검증 진행 중 → 현재는 등록된 테스트 사용자만 연결 가능, 경고 화면이 떠도 앱 고장이 아님, 드라이브 없이도 전 기능 정상 동작(브라우저 자동 보관)
- **설정 맨 아래 "안내" 카드** (개발자 연락 카드 앞)
  - 내 데이터는 내 것: 어느 서버에도 안 올라감 / 브라우저 보관 + 선택 시 드라이브 / 브라우저 데이터 삭제 시 소실 주의 → 백업 권장
  - 권장 브라우저: Chrome·Edge
  - 피드백: GitHub Issues 링크(`target="_blank" rel="noopener noreferrer"`)

### Docs
- **README.md 전면 재작성** (저장소용, 56줄) — 히어로(바로 써보기 링크) + 만화·사용설명서·기술문서 링크 표, "이런 도구입니다" 30초 소개(5가지 핵심), 빠른 시작, 주요 기능(최신 반영), 내 데이터는 내 것, 🧪 베타 안내, 기술 한 줄, 피드백(Issues)

### Notes
- 베타 안내·안내 카드·README는 소프트 런칭 손질 3종 — 본격 공개(2단계)는 구글 OAuth 검증 통과 후

---

## [3.45.3] - 2026-06-04

### Improved
- **선택 노드 가시성 강화 — 이중 링** (이전 단일 3px 코랄 링이 오렌지 계열 노드·축소 화면에서 묻히던 문제)
  - `box-shadow` 4겹: 배경색 띠(`var(--panel)` 2px) → 본 링(`var(--accent)` 4px) → 옅은 헤일로(`var(--accent-soft)` 3px) → 글로우 그림자
  - 배경색 띠가 노드와 링의 경계를 분리 → 어떤 노드 색에서도 또렷. 다크 테마에선 패널색 띠로 자동 전환(테마 변수 기반)
- **편집 중 전용 강조** — `.node.editing` 클래스 신설(선택보다 한층 굵은 링 + 깊은 글로우)
  - memo 비교에 `isEditing`이 이미 포함돼 있어 상태 전환이 정확히 반영됨
- **입력창 윤곽 개선** — 반투명 흰색 outline(밝은 노드에서 묻힘) → `var(--ink-soft)` 1.5px(밝은·다크 테마 모두 대비) + 분리 그림자

### Technical Notes
- `.node-body`의 기존 `transition: box-shadow 0.2s` 덕에 링 전환이 부드럽게 애니메이션됨
- 시각 변경이라 실화면(특히 오렌지 노드·다크 3테마·축소 상태) 확인 필요

---

## [3.45.2] - 2026-06-04

### Improved
- **드라이브 저장 진행 안내 (Ctrl+Shift+S)** — 클라우드 저장이 수 초~10초 걸리는 동안 무반응으로 보이던 문제 개선
  - 시작 즉시: "💾 저장을 시작했어요 — 구글 드라이브(클라우드)라 보통 10초쯤 걸려요" (sticky — 완료까지 유지)
  - 완료: "✅ 구글 드라이브에 저장했어요" (3초) / 실패: 설정 확인 안내
  - 저장 중 재입력 시: "💾 저장 중이에요 — 잠시만 기다려 주세요" (sticky 유지)

### Fixed
- **토스트 타이머 미정리 버그** (코드 리뷰 때 보류했던 항목) — `showToast`가 이전 타이머를 정리하지 않아, 연속 호출 시 앞 메시지의 2.2초 타이머가 뒤 메시지를 일찍 지우던 문제
  - `toastTimerRef`로 타이머 보관, 새 토스트마다 `clearTimeout` 후 표시. `{ sticky, duration }` 옵션 추가(기존 호출 15+곳은 시그니처 호환)

### Technical Notes
- 검증: 가짜 시계 시뮬 6케이스(sticky 유지/완료 교체/자동 닫힘/연속 호출 2종/일반→sticky) 통과

---

## [3.45.1] - 2026-06-04

### Fixed
- **몰입 모드 전환 직후 노드 클릭이 여러 번(3~5회) 눌러야 동작하던 버그 수정**
  - 원인: `NodeView`가 React.memo + 콜백 무시 비교라, 모드 전환 시 리렌더되지 않은 노드들이 **옛 렌더의 `onSelect` 클로저**(viewMode='edit' 캡처)를 계속 보유 → 클릭이 편집 모드 로직을 탐. 클릭으로 선택이 바뀌면 그 노드만 신선해져 "몇 번 누르면 되는" 증상 발생
  - 수정: **최신 참조 ref 패턴(`nodeActionsRef`)** — 매 렌더마다 최신 함수·상태(viewMode, addChild, updateNode, drag 핸들러 등 16개)를 ref에 담고, NodeView 콜백 14곳이 ref를 경유해 호출. 콜백 객체가 낡아도 항상 최신 로직 실행
- **같은 뿌리의 잠재 데이터 손실 차단** — 오래 리렌더되지 않은 노드의 ➕/드래그 콜백이 옛 `tree`를 `cloneTree`해 최근 편집을 덮어쓸 수 있던 구조적 위험을 동일 패턴으로 제거 (보고 전 선제 수정)

### Technical Notes
- 검증: stale 화살표 시뮬 3케이스(전환 전 편집 로직 / 전환 후 첫 클릭부터 몰입 / 옛 ➕가 최신 tree 사용) 통과
- 교훈: memo 비교에서 콜백을 제외하면, 콜백이 캡처하는 가변 상태는 반드시 ref 경유로 — "새 시각 prop은 비교 함수에, 새 행동 상태는 ref에"

---

## [3.45.0] - 2026-06-04

### Added
- **Ctrl+Shift+S — 구글 드라이브 저장 단축키** (+ 토스트 결과 안내)
  - 수동 저장 버튼과 동일 규칙(`runVersionedSave`: 접두어+날짜.버전, 5개 유지)
  - 가드: 트리 없음/미연결/저장 진행 중 → 각각 토스트 안내 후 중단. `handleDriveSave`가 성공 시 saved 객체, 실패 시 null을 반환하도록 수정해 토스트 분기
  - 성공: "💾 구글 드라이브에 저장했어요" / 실패: 설정 확인 안내
- **Ctrl+Shift+C — 구글 캘린더 추가 단축키** (`addToGoogleCalendar` 호출, 새 탭)

### Technical Notes
- `e.code`(물리 키 KeyS/KeyC)로 판별 — 한글 IME 상태와 무관하게 동작
- 입력 가드(input/textarea/편집 중/IME 조합) 뒤에 배치 → 라벨 편집 중에는 미발동(미커밋 라벨이 저장되는 혼란 방지)
- 단축키 effect deps에 `driveSignedIn` 추가(연결 직후 stale closure 방지)
- Ctrl+Shift+C는 크롬 개발자도구 단축키지만 페이지 preventDefault가 우선(구글 문서와 동일 패턴)
- UserGuide 단축키 표에 2개 항목 추가
- 검증: 가드 분기 4케이스 시뮬레이션 통과

---

## [3.44.0] - 2026-06-04

### Added
- **설정 상단 문서 바로가기** — 설정 모달 본문 맨 위에 📖 사용 설명서 / 🛠️ 기술 문서 링크 카드 2개
  - GitHub Pages 배포 문서로 연결: `BrainBloom_UserGuide.html`, `BrainBloom_TechDoc.html`
  - `target="_blank" rel="noopener noreferrer"`(새 탭 + 보안), 테마 변수(`--bg-2/--line/--ink`) 기반 스타일이라 다크 테마에서도 자연스러움
  - hover 시 테두리 강조

### Notes
- 이 버전부터 배포 zip은 5파일 구성: 앱 2(brainstorm/index) + CHANGELOG + **TechDoc + UserGuide**
- 문서 링크가 동작하려면 GitHub 저장소에 두 문서 파일을 함께 업로드해야 함

---

## [3.43.0] - 2026-06-03

### Added
- **빈 공간 우클릭 메뉴 + 몰입 모드** — `viewMode`('edit'|'immerse', 상태로만 관리·저장 안 함 → 새로고침 시 항상 edit)
  - 빈 공간(노드 밖) 우클릭 → 편집/몰입 선택 메뉴(현재 모드 ✓). `onContextMenu`에서 `e.target.closest('.node')`로 노드 위 우클릭은 제외(브라우저 기본 메뉴 유지)
  - **몰입 모드**: 편집·추가·삭제·순서변경 전부 차단(노드 `onSelect`는 강조로 전환, `onStartEdit` 무시, 키보드 핸들러에서 편집성 키 차단). 노드 클릭 시 `immerseFocusId` 설정 → `computeFocusIds`로 경로+직속자식 강조, 나머지 흐림(기존 `.node.dimmed` 재활용)
  - 다른 노드 클릭 → 강조 이동 / 빈 공간 클릭·Esc → 강조 해제. 화살표 이동·검색·줌·빈 공간 더블클릭(루트 중앙)은 몰입에서도 동작
  - `focusIds` useMemo를 (a)몰입 모드 우선 (b)편집 중 집중 모드 순으로 분기. 단축키 effect 의존성에 `viewMode` 추가
  - **🎯 몰입 모드 배지**(하단 중앙 고정) — 클릭 시 편집 모드 복귀
  - 기존 "편집 중 집중 모드" 옵션과는 별개 기능

### Technical Notes
- 검증: `focusIds` 모드 분기 6케이스(편집모드 3 + 몰입모드 3, 몰입은 editingId 무시하고 클릭노드 우선) 통과
- 배타적 모드(한 번에 하나). 몰입→편집 전환 시 `immerseFocusId` 해제

---

## [3.42.1] - 2026-06-03

### Changed
- **배경 테마 6색을 색조 구분이 뚜렷한 조합으로 교체** — 기존 6색이 모두 회색 기반이라 서로 비슷했던 문제 개선
  - 밝은: ivory→샌드(`#f0e6d2`, 노랑) / mint→세이지(`#e4ece0`, 초록) / gray→스카이(`#e2ebf5`, 파랑)
  - 어두운: charcoal→차콜(`#1c1c1e`, 무채색) / navy→미드나잇(`#15213a`, 파랑) / softdark→포레스트(`#1a2a22`, 초록)
  - 키 이름(ivory/mint/gray/charcoal/navy/softdark)은 유지 → 기존 사용자 저장값 호환. 라벨·스와치만 갱신
  - 다크 3종은 글자·선·입력창 연동 값도 색조에 맞게 재조정

---

## [3.42.0] - 2026-06-03

### Added
- **배경 테마 선택 (`bgTheme`, 기본 default) + 점 패턴 토글 (`bgDots`, 기본 true)** — 눈 피로 완화, 설정 → 화면 표시
  - 밝은 계열 3종: ivory(웜 아이보리) / mint(세이지 민트) / gray(쿨 그레이) — `--bg/--bg-2/--panel/--line/--dot-color`만 변경, 글자색 유지
  - 다크 계열 3종: charcoal / navy / softdark — 배경에 더해 `--ink/--ink-soft/--node-input-bg/--accent-soft`까지 연동(진짜 다크 모드)
  - CSS `[data-theme="..."]` / `[data-dots="off"]` 속성 기반. `<html>`에 effect로 속성 부여
  - 설정 UI: 7개 색상 스와치 팔레트(선택 시 체크 표시) + 점 패턴 토글
  - 하드코딩 흰색 일부를 변수화(`--dot-color`, `--node-input-bg`). 누락 방어 추가

### Technical Notes
- 검증: 테마 적용 로직 5케이스(기본/밝음/다크/점on·off 조합) 통과
- 주의: 다크 3종은 실제 화면에서 노드 글자·연결선·헤더·패널 가독성 확인 필요(밝은 배경 기준으로 만들어진 일부 하드코딩 요소가 남아 있을 수 있음)

---

## [3.41.2] - 2026-06-03

### Security
- **외부 CDN 스크립트에 SRI(Subresource Integrity) 적용** — 공급망 공격 방어 (공개 서비스 대비)
  - React 18.3.1 / ReactDOM 18.3.1 / @babel/standalone 7.26.4 / jspdf 2.5.1 → 버전 고정 + `integrity="sha384-..."` 추가. CDN 변조 시 해시 불일치로 로드 거부
  - 구글 GSI는 구글이 버전 미고정이라 SRI 적용 불가 → CSP로 다룰 항목(별도)
- **입력 안전 한도 추가 (DoS 방어)** — `sanitizeNode`에 깊이·개수·라벨 제한
  - `SANITIZE_MAX_DEPTH=100`(깊이), `SANITIZE_MAX_NODES=20000`(노드 수), `SANITIZE_MAX_LABEL=5000`(라벨 글자) — 초과분은 잘라냄
  - 악의적/거대 입력으로 인한 스택 오버플로우·메모리 고갈 방지. 정상 사용 규모(깊이 10 미만, 노드 수백)엔 영향 없음

### Technical Notes
- SRI 해시는 npm 정식 배포본(unpkg 서빙 파일과 동일)에서 sha384로 계산
- 검증: 깊이 200→100 절단 / 라벨 10000→5000 절단 / 노드 30000→20000 중단 시뮬레이션 통과

---

## [3.41.1] - 2026-06-03

### Fixed
- **빈 공간 더블클릭 → 루트 중앙 정렬이 노드 사이에서 동작 안 하던 문제 수정**
  - 원인: 판별이 `e.target === e.currentTarget`(정확히 `.canvas-inner`)이라, 노드 사이의 연결선(SVG)·`.map-wrapper` 영역을 더블클릭하면 target이 달라 동작 안 함. 노드에서 멀리 떨어진 순수 패딩 영역에서만 작동했음
  - 수정: `!e.target.closest('.node')`로 변경 → 노드(및 그 내부 요소) 위가 아니면 어디서든(연결선·빈 공간·여백) 동작. 노드 내부 더블클릭은 편집이므로 정상 제외

---

## [3.41.0] - 2026-06-03

### Added
- **같은 브라우저 중복 탭 감지·경고** (`duplicateTabAlert`, 기본 true) — 설정 → 화면 표시
  - `BroadcastChannel('brainbloom_tabs')`로 같은 출처(도메인) 탭 간 통신. 다른 브라우저·기기와는 무관
  - 프로토콜: 새 탭이 `who` 방송 → 기존 탭이 `here` 응답. `here`를 받은 탭(=나중에 열린 탭)만 상단 배너 표시
  - **버그 수정 포함**: `here`는 브로드캐스트라 전체에 퍼지므로, 먼저 열린 탭에도 배너가 뜰 수 있던 문제를 `isExistingTab`(누군가의 who에 응답한 적 있으면 기존 탭) 플래그로 차단 → 남의 here 무시
  - 배너는 알림만(강제 차단 없음), "확인"으로 닫힘. `typeof BroadcastChannel === 'undefined'` 미지원 방어
  - 누락 방어 추가

### Technical Notes
- 검증: 탭 순서/추가/동시 열림 9케이스 시뮬레이션 통과(먼저 연 탭 무배너, 나중 탭만 배너)
- 로컬(IndexedDB `lastWork`)은 같은 브라우저 탭 간 공유되어 last-write-wins이므로, 이 경고로 사용자가 인지하도록 보완(드라이브는 기존 modifiedTime 충돌 감지가 별도로 처리)

---

## [3.40.0] - 2026-06-03

### Added
- **빈 공간 더블클릭 → 루트 노드 화면 중앙 정렬**
  - `.canvas-inner`에 `onDoubleClick` 추가, `e.target === e.currentTarget`로 빈 패딩 영역(맵 바깥)에서만 실행 → 노드 위 더블클릭(편집)과 정확히 구분
  - 기존 `centerNode(tree.id)` 재활용(초기 로드·접기/펼치기 센터링에서 검증된 함수). DOM 위치를 `getBoundingClientRect`로 읽어 뷰포트 중심과의 차이만큼 스크롤
  - 줌(zoom)은 변경하지 않고 스크롤 위치만 조정

### Technical Notes
- `.canvas-inner`는 사방 800px 패딩 + flex 중앙 정렬 구조라, 맵 바깥 빈 영역 클릭 시 target이 `.canvas-inner` 자신이 되어 판별이 정확히 동작
- 별도 옵션 없이 항상 활성(단순 내비게이션 보조 기능)

---

## [3.39.0] - 2026-06-03

### Added
- **편집 중 집중 모드의 흐림 정도 조절** (`focusDimLevel`: `'soft'|'medium'|'strong'`, 기본 medium)
  - 설정 → 화면 표시에서 집중 모드를 켜면 "흐림 정도" 3단계 버튼(약하게/보통/강하게) 노출
  - 단계별 CSS: soft `grayscale(0.6) opacity(0.55)` / medium `grayscale(0.85) opacity(0.35)`(기존 값) / strong `grayscale(1) opacity(0.2)`. hover 시 각 단계별로 살짝 살아남
  - 노드 className에 `dimmed dim-{level}` 부여, CSS 클래스로 적용
  - React.memo 비교 함수에 `focusDimLevel` 추가(단계 변경 시 흐려진 노드 리렌더 보장)
  - 누락 방어 추가. 기존 사용자는 medium으로 적용돼 체감 변화 없음

### Technical Notes
- 검증: className 단계 생성 5케이스(soft/medium/strong/기본/비흐림) 통과
- 흐림은 CSS filter만 — 데이터·저장 색 불변(3.38.0과 동일 원칙)

---

## [3.38.0] - 2026-06-03

### Added
- **편집 중 집중 모드 (`focusModeOnEdit`, 기본 false)** — 설정 → 화면 표시
  - 편집/추가 중(`editingId` 활성)일 때, 편집 노드의 루트까지 경로 + 직속 자식만 컬러 유지, 그 외 노드는 흐리게(`.node.dimmed`: `filter: grayscale(0.85) opacity(0.35)`)
  - 순수 함수 `computeFocusIds(root, targetId)`: DFS로 루트→target 경로 수집 + target 직속 자식 합집합 → 컬러 유지 id Set. target 미발견/null이면 빈 Set
  - `focusIds` useMemo(`[focusModeOnEdit, tree, editingId]`): 옵션 OFF거나 비편집 시 null → 흐리기 비활성
  - 노드 렌더 시 `isDimmed = focusIds!==null && !focusIds.has(id)` → NodeView className에 반영
  - 흐리기는 CSS filter만 적용 — 데이터·저장 색 불변(안전)
  - React.memo 비교 함수에 `isDimmed` 추가(상태 변화 반영 보장)
  - 설정 토글 + 누락 방어 추가

### Technical Notes
- 검증: `computeFocusIds` 10케이스(경로+직속자식 정확성, 손자/타가지 제외, 미발견/null) + 비교 함수 통과
- "편집/추가 중"의 트리거는 `editingId`(F2 편집·새 노드 추가 모두 설정됨). 단순 선택(`selectedId`)으로는 켜지지 않음 — 잦은 깜빡임 방지

---

## [3.37.1] - 2026-06-01

### Performance (외부 코드 리뷰 후속 — 가성비 높은 2건 적용)
- **NodeView를 React.memo로 감쌈** — 노드 선택/줌/검색 시 전체 노드가 리렌더되던 것을, 변경된 노드만 갱신
  - 콜백 props는 부모의 인라인 화살표라 매 렌더 새 함수 → 일반 memo는 무력. **커스텀 비교 함수 `nodeViewPropsEqual`**로 콜백은 무시하고 시각 관련 값만 비교
  - 비교 대상: `isRoot/isRootChild/isSelected/isDropTarget/isEditing/isSearchMatch/isSearchFocus/color`, settings의 라벨 줄수·폰트, node의 `_x/_y/_w/_side/label/pinnedSide/collapsed/_autoLabel/children.length/icons[]/meta{date,effort,cost}`
  - 빠진 값으로 인한 "stale 렌더" 방지 위해 NodeViewBase가 렌더에 쓰는 값을 전수 포함, 14케이스 시뮬레이션 검증
- **로컬 자동백업(lastWork) 변경 감지** — 디바운스(1.5s) IndexedDB 쓰기 전 직전 저장 스냅샷과 비교, 동일하면 직렬화·쓰기 skip
  - `lastLocalSaveRef`에 `JSON.stringify({tree: serializeTree(tree), inputText})` 보관 후 비교 (드라이브 자동저장의 변경 감지 패턴 재활용)
  - 닫기/숨김 시 저장·다운로드 시 저장은 빈도가 낮고 "최종 안전 저장"이라 변경 감지 미적용(의도)

### Technical Notes
- 미적용(리뷰 항목 중): 서브트리 부분 재레이아웃(작업 큼), 가상화·SVG 단일 렌더(대공사), 빌드 도입(무빌드 철학과 상충) — 현재 사용 규모(수백 노드)에선 체감 적어 보류
- 화면 동작/출력 변화 없음(내부 효율만 개선)

---

## [3.37.0] - 2026-06-01

### Improved
- **새로고침 후 드라이브 자동 재연결** — 새로고침 시 토큰(메모리)이 초기화돼 매번 수동 재연결해야 하던 불편 해소
  - `localStorage` 플래그 `bb_drive_linked`(boolean만, **토큰 등 민감정보 저장 안 함**)로 연결 이력 기록
  - 로그인 성공 시 플래그 set / 명시적 로그아웃 시 clear
  - 앱 마운트 시 effect: 플래그 있으면 GIS 로드 대기(최대 9초) 후 `requestDriveToken(false)`(prompt:'', 팝업 없음)로 조용히 재발급 → 성공 시 로그인 복원
  - 조용한 재발급 실패(세션 만료 등) → 조용히 로그아웃 상태 유지 + 플래그 정리(다음 새로고침 불필요 재시도 방지) → 수동 연결로 폴백
  - localStorage 접근은 try/catch로 감싸 시크릿 모드/차단 환경에서도 앱이 깨지지 않음

### Technical Notes
- 보안: 액세스 토큰을 저장하지 않고 GIS 조용한 재인증을 사용(구글 권장 방식). 토큰은 여전히 메모리에만 존재
- 한계: 테스트 모드 7일 만료/구글 세션 만료 시 조용한 재발급이 실패할 수 있으며, 이 경우 수동 재연결 필요

---

## [3.36.0] - 2026-06-01

### Added
- **다중 기기 최신본 감지 (덮어쓰기 방지)** — "회사 방치 → 집에서 작업·저장 → 회사 복귀" 시 모르고 덮어쓰는 것 방지
  - 기준 시각 `lastSyncedTimeRef`(ISO): 저장/불러오기 시 그 파일의 `modifiedTime`을 기록
  - `checkRemoteNewer()`: `driveListFiles`(최신순) 첫 파일의 modifiedTime이 기준보다 새로우면 `remoteNewer` 설정. 기준 없음(이번 세션 미저장/미불러옴)·파일 없음·내 기준이 더 최신이면 묻지 않음(오판 방지)
  - 확인 시점: 자동저장 직전(tick) + 탭 복귀(visibilitychange)
  - 외부 최신본 발견 시 자동저장 보류(`autoSaveRef.remotePending`) → 사용자 결정 전 덮어쓰기 안 함
  - 팝업 3선택: **최신본 불러오기**(`handleDriveLoadFile`) / **무시하고 계속**(기준 시각을 현재 최신으로 올려 재질문 방지, 다음 저장 때 현재 내용이 새 버전) / **잠시 보류**(닫기)
  - `driveSaveNewFile` 응답에 `fields=id,name,modifiedTime` 지정해 저장 직후 시각 확보
  - `handleDriveLoadFile(fileId, fileName, modifiedTime)`: 불러온 후 `lastSavedContentRef`/`lastSyncedTimeRef` 갱신 → 불러온 직후 자동저장 오판·재질문 방지

### Technical Notes
- 검증: 외부 최신본 판단 5케이스(동일시각/더새로움/기준없음/파일없음/내기준이최신) 통과
- 한계: 두 기기가 동시에 *편집*하는 순간까지 막지는 않음(저장 시도 시점에 비교). modifiedTime은 드라이브 서버 기준이라 기기 시계와 무관하게 안전

---

## [3.35.0] - 2026-06-01

### Changed
- **자동저장을 "내용 변경 시에만" 동작하도록 변경** — 무의미한 반복 저장 방지 + 다중 기기 충돌 완화
  - `lastSavedContentRef`(마지막 저장 내용 JSON 문자열) 추가. 자동저장 tick에서 현재 내용과 비교해 동일하면 skip
  - `serializeTreeContent(treeArg)` 헬퍼 추가: 레이아웃 필드(`_x/_y/_subH/_w/_h`) 제거 후 `JSON.stringify` → 변경 감지와 저장 payload가 **동일 기준** 사용(좌표만 바뀐 건 "내용 변경" 아님으로 처리)
  - 첫 저장(`lastSavedContentRef === null`)은 무조건 진행. 저장 성공 직후 `lastSavedContentRef` 갱신
  - 수동 "지금 저장"은 변경 감지 없이 항상 저장(누르면 무조건). 자동저장만 변경 감지 적용
  - 효과: 회사 브라우저를 켜둔 채 퇴근해도 안 건드리면 저장 안 함 → 집에서 이어 작업 시 동시 저장 충돌 가능성 대폭 감소, 드라이브 API 호출도 감소

### Technical Notes
- 검증: 변경 감지 시뮬레이션 6케이스(첫 저장 진행 / 동일 내용 skip / 좌표만 변경 skip / 라벨·노드추가·색변경 저장) 통과
- 다중 기기 동시 *편집*까지 막는 것은 아님(완전한 충돌 방지가 목표가 아니라, 가장 흔한 "켜두고 방치" 시나리오 해소)

---

## [3.34.1] - 2026-06-01

### Changed
- **"연결 끊김 알림 사용" 체크박스를 로그인 분기 밖으로 이동** — 로그아웃(연결 끊김) 상태에서도 표시
  - 기존: 체크박스가 `driveSignedIn` true 분기 안에 있어, 연결이 끊긴 화면에선 옵션에 접근 불가(정작 알림이 거슬릴 수 있는 상황)
  - 수정: 로그인/로그아웃 분기 바깥(섹션 공통 영역, `driveStatus` 다음)으로 이동 → 항상 표시
  - 기능·색 조건 변동 없음(위치만 이동)

---

## [3.34.0] - 2026-06-01

### Added
- **"연결 끊김 알림 사용" 옵션** (`driveAlertEnabled`, 기본 true) — 드라이브 연동 섹션
  - 끄면 헤더 "설정" 글자 색 변화(빨강·파랑)를 모두 비활성 → 평소 색 유지. 클릭 시 드라이브 섹션 자동 스크롤도 비활성
  - 설정 화면 안의 경고 배너는 이 옵션과 무관하게 유지(사용자 선택: 글자 색만 제어)
  - 색 결정에 `!settings.driveAlertEnabled` 최우선 분기 추가 + 누락 방어
  - 7개 상태 조합(알림 on/off × 정상/실패/끊김/자동저장꺼짐) 검증 통과

---

## [3.33.5] - 2026-06-01

### Added
- **자동저장 정상 작동 시 "설정" 글자 파랑 표시** — 위험(빨강)과 짝이 되는 안심 신호
  - 색 3갈래: `driveAutoSave && (driveAutoFailed || !driveSignedIn)` → 빨강(#e5484d) / `driveAutoSave && driveSignedIn && !driveAutoFailed` → 파랑(#0091ff) / 그 외 → 평소 색
  - 우선순위: 빨강 > 파랑 > 평소. 자동저장 꺼짐·연결 안 함은 평소 색(파랑/빨강 아님 — 자동저장이 실제로 안 도는데 안심 신호를 주지 않기 위함)
  - 6개 상태 조합 검증 통과

---

## [3.33.4] - 2026-06-01

### Fixed
- **헤더 "설정" 글자 빨강 조건과 드라이브 경고 배너 조건 불일치 수정** — 연결이 끊겨(로그아웃) 배너는 떴는데 설정 글자는 안 빨개지던 버그
  - 원인: 배너 = `driveAutoSave && !driveSignedIn` / 설정 글자 = `driveAutoSave && driveAutoFailed`. `driveAutoFailed`는 자동저장이 실제 1회 시도해 실패해야 true가 되므로, 끊긴 직후/시도 전에는 두 조건이 어긋남
  - 수정: 설정 글자 빨강 + 클릭 시 스크롤 조건을 모두 `settings.driveAutoSave && (driveAutoFailed || !driveSignedIn)`로 통일 → 배너와 동일 신호
  - 6개 상태 조합 검증(꺼짐/정상은 평소, 실패·끊김은 빨강) 통과

---

## [3.33.3] - 2026-06-01

### Changed
- **설정 섹션 카드 스타일 통일** — 일부 섹션만 `is-card`(박스)이고 나머지는 구분선만 있어 시각적으로 들쭉날쭉하던 것을 정리
  - 박스가 없던 8개 섹션(화면 표시, 노드 길이, 노드 폰트, 타이머, 저장 옵션, 구글 캘린더, AI 요약, 구글 드라이브 연동)에 `is-card` 추가 → 전 섹션 박스 통일(총 11개 카드)
  - 개발자 연락처는 기존 `contact-section` 카드 스타일 유지
  - `:not(.is-card)` 구분선 규칙은 매칭 대상이 없어져 자연 비활성(카드 인접 `::before` 구분선만 적용)

---

## [3.33.2] - 2026-06-01

### Fixed (자동저장 데이터 안전 — 코드 리뷰 후속)
- **중복 실행 방어** — `isSavingRef` 플래그 추가. 자동저장이 간격(예: 1분) 안에 끝나지 않아도 다음 tick이 겹쳐 실행되지 않음. 수동 "지금 저장"도 진행 중이면 차단 → 자동·수동이 동시에 같은 파일을 건드려 중복 파일/잘못된 삭제가 나는 위험 제거
- **취소 시 안전 중단** — `runVersionedSave(treeArg, prefixArg, shouldCancel)`로 취소 신호 전달. 자동저장 effect cleanup(끄기/로그아웃)이 일어나면 각 단계(목록→rename→delete→저장 직전) 전에 확인하여 중단. 단 저장이 이미 시작된 뒤에는 정리까지 마쳐 파일 상태 일관성 유지

### Technical Notes
- 새 ref: `isSavingRef`(수동·자동 공유). tick과 handleDriveSave 양쪽에서 진입 시 확인/설정, finally에서 해제
- shouldCancel은 선택적 인자(`typeof === 'function'` 가드) — 수동 저장은 미전달로 취소 없이 동작
- 검증: 중복방어(동시 3회 호출 → 1회만 실행, 2회 SKIP) + 취소(신호 시 미저장) 시뮬레이션 통과

---

## [3.33.1] - 2026-06-01

### Changed
- **수동/자동 저장 이름 규칙 통일** — "저장할 파일 이름" 입력칸이 자동저장의 "파일 이름 접두어"와 역할이 겹쳐 혼란 → 입력칸 통합
  - "저장할 파일 이름" 칸 제거. 수동 저장도 `runVersionedSave(tree, settings.drivePrefix)` 사용 → 접두어+날짜.버전, 5개 유지, 과거 정리 동일 적용
  - 수동 저장 버튼 라벨 "드라이브에 저장" → "지금 저장"
  - 안 쓰게 된 `driveFileName` 상태·props(`onDriveFileNameChange`)·시그니처 항목 완전 제거

### Technical Notes
- `handleDriveSave`가 `driveSaveNewFile(driveFileName,...)` → `runVersionedSave(tree, prefix)` 호출로 변경(자동저장과 동일 경로). 성공 시 `driveAutoFailed=false`도 함께 처리
- 수동 저장 UI 렌더 + driveFileName 제거 후 잔존 참조 0 확인

---

## [3.33.0] - 2026-06-01

### Improved
- **드라이브 연결 촘촘 감시 (3겹)** — 자동저장 끊김을 자동저장 간격과 무관하게 빨리 감지
  - (A) 30초마다 `ensureDriveToken`으로 토큰 만료 미리 감지·자동 갱신(예방)
  - (B) 10분마다 `drivePing`(about 엔드포인트, 최소 요청)으로 실제 연결 검사
  - (C) `visibilitychange`로 탭 복귀 시 즉시 연결 검사 — 다른 기기/탭에서 돌아왔을 때 바로 반영
  - 셋 중 하나라도 401/403/만료면 `driveAutoFailed=true`(설정 글자 빨강)+로그아웃 처리, 성공 시 해제
  - 자동저장이 켜져 있고 로그인된 동안만 동작(effect 의존성 `[driveAutoSave, driveSignedIn]`)

### Technical Notes
- 새 헬퍼 `drivePing()` — `ensureDriveToken` 후 `drive/v3/about?fields=user(displayName)` 호출
- 감시 effect는 `cancelled` 플래그로 cleanup 가드, 자동저장 tick과 동일한 위험상태 규칙 공유(일관성)
- 한계 명시: 탭 백그라운드/절전 시 브라우저가 타이머를 늦추거나 멈출 수 있음 → (C) 탭 복귀 즉시 검사로 보완

---

## [3.32.0] - 2026-06-01

### Added
- **자동저장 끊김 경고 (헤더 설정 글자 빨강)** — "동기화되는 줄 알았는데 멈춰 있었다" 방지
  - 위험상태 = `settings.driveAutoSave && driveAutoFailed`(자동저장 켜짐 + 마지막 시도 실패)일 때만 헤더 "설정" 글자가 빨강(#e5484d)
  - 위험상태에서 설정 클릭 → `scrollToDriveOnOpen` 신호 → SettingsModal에서 드라이브 섹션으로 `scrollIntoView` + 빨간 경고 배너 표시
  - `driveAutoFailed`: 자동저장 성공 시 false, 실패 시 true. 재연결 성공/자동저장 끄기 시 false로 해제
  - 정상/꺼짐/연결안됨 상태에서는 평소대로(빨강 없음)

### Technical Notes
- 새 상태: `driveAutoFailed`, `scrollToDriveOnOpen`
- SettingsModal에 `scrollToDrive`/`onScrollToDriveDone` props + `driveSectionRef` + 스크롤 useEffect 추가
- 상태 조합별 빨강/스크롤 조건 로직 검증 완료

---

## [3.31.0] - 2026-06-01

### Added
- **구글 드라이브 자동저장 (버전관리 해석 B)** — 설정 → 구글 드라이브 연동
  - "자동저장 사용" 토글, 간격(분, 기본 1분, 1~120), 파일 이름 접두어(prefix, 예: `회의_`) + 설명
  - 파일명 `[prefix]YYYY-MM-DD.N` — 저장마다 버전번호 N 증가, 오늘 것 **최신 5개만 유지**(초과 시 오래된 것 삭제)
  - 날짜 바뀌면 전날 정리: 전날 최신 1개만 `[prefix]날짜`(버전 없이)로 rename, 나머지 삭제 → 지난 날짜는 1개, 오늘은 최대 5개
  - 자동저장 중 토큰 만료/권한 실패(401/403) 시 조용히 중단 + 재연결 안내(`driveAutoStatus`)
  - 수동 작업(busy) 중에는 자동저장 건너뜀

### Technical Notes
- 새 settings: `driveAutoSave`(bool), `driveAutoSaveMinutes`(num), `drivePrefix`(string) + 각 누락 방어
- 핵심 함수 `runVersionedSave(treeArg, prefixArg)`: 과거정리(planPastCleanup→rename/delete) → 다음 버전 저장(driveSaveNewFile) → 오늘 5개 초과 삭제(filesToDeleteToday)
- setInterval effect + `autoSaveRef`로 클로저의 낡은 tree/prefix/signedIn 문제 회피
- SettingsModal에 `driveAutoStatus` props 추가 전달
- 검증: 버전관리 순수로직 단위 14개 + 흐름 통합 시뮬레이션 10개(오늘 6회 저장→최신5, 날짜바뀜 정리, prefix) 통과

---

## [3.30.2] - 2026-06-01

### Added (내부 토대 — 자동저장 준비)
- **토큰 자동 재발급** (`ensureDriveToken`) — 액세스 토큰 만료(약 1시간) 2분 전이면 `requestAccessToken({prompt:''})`로 조용히 갱신. 자동저장이 토큰 만료로 끊기지 않도록 하는 핵심
  - `_driveTokenExpiry`(만료 epoch ms) 추적, `requestDriveToken` 콜백에서 `expires_in`으로 기록
  - 드라이브 헬퍼 5종이 진입 시 `await ensureDriveToken()` 호출하도록 교체
- **파일 삭제/이름변경 헬퍼** (`driveDeleteFile`, `driveRenameFile`) — 버전관리(오래된 버전 삭제, 과거 최종본 rename)용
- **버전관리 해석 B 순수 로직** — `parseDriveFileName` / `maxVersionForDate` / `filesToDeleteToday` / `planPastCleanup`. 단위 테스트 14개 통과(파일명 파싱, 오늘 5개 유지, 과거 정리, prefix 처리)

### Notes
- 이번 버전은 내부 토대만. 화면상 동작 변화 없음(새 헬퍼·로직은 아직 자동저장 핸들러에서 호출 전)
- 작업 중 sed 일괄치환이 `ensureDriveToken` 자기 자신의 토큰 체크까지 바꿔 무한재귀가 발생했던 것을 발견·수정

---

## [3.30.1] - 2026-06-01

### Changed
- **설정 "구글 드라이브 연동" 섹션을 맨 아래로 이동** — 저장 옵션 다음 → 새 단어 다음(개발자 연락처 카드 바로 위)
  - 섹션 순서: 화면표시 → 노드길이 → 노드폰트 → 타이머 → 저장옵션 → 구글캘린더 → AI요약 → 시작동작 → 격언 → 새단어 → 구글드라이브연동 → 개발자연락처
  - JSX 블록만 이동(기능·핸들러·props 변동 없음)

---

## [3.30.0] - 2026-06-01

### Added
- **드라이브 저장: 날짜별 파일 + 앱 폴더 + 파일명 지정** — "회사↔집 + 백업" 용도에 맞게 개편
  - 앱 전용 폴더 `BrainBloom` 자동 생성(`driveGetOrCreateFolder`), 그 안에 저장
  - 저장 파일 이름 입력칸(설정), 기본값 오늘 날짜(`YYYY-MM-DD`), 사용자 수정 가능(`driveFileName` 상태)
  - 저장은 항상 **새 파일 생성**(`driveSaveNewFile`) — 덮어쓰지 않고 날짜별로 쌓임(백업)
  - 불러오기 2단계: "불러오기 목록"(`driveListFiles`, 최신순) → 파일 선택(`driveLoadFileById`)
  - `drive.file` 범위 유지(앱이 만든 폴더/파일만 접근, 민감 검수 불필요)

### Changed
- 기존 단일 파일 덮어쓰기 방식(`brainbloom-data.json`) → 폴더+날짜별 다중 파일 방식으로 전환
- 헬퍼 교체: `driveFindFile`/`driveSaveFile`/`driveLoadFile` 제거 → `driveGetOrCreateFolder`/`driveSaveNewFile`/`driveListFiles`/`driveLoadFileById`

### Technical Notes
- SettingsModal에 드라이브 props 추가 전달(`driveFiles`, `driveFileName`, `onDriveFileNameChange`, `onDriveListFiles`, `onDriveLoadFile`)
- react-dom 서버 렌더로 로그아웃/로그인/파일목록 상태 전부 검증(흰 화면 재발 방지)

---

## [3.29.1] - 2026-06-01

### Fixed
- **설정 화면을 열면 앱 전체가 흰 화면으로 죽던 문제 수정** — 3.29.0에서 드라이브 섹션을 별도 컴포넌트 `SettingsModal` 안에 넣으면서, 필요한 상태/핸들러(`driveSignedIn`, `driveBusy`, `driveStatus`, `handleDrive*`)를 props로 전달하지 않아 `driveSignedIn is not defined` ReferenceError 발생 → 설정 렌더 시 React 트리 전체 throw
  - App→SettingsModal에 props 전달, SettingsModal 시그니처에서 수신, 섹션 JSX의 핸들러명을 `onDrive*`로 정리
  - react-dom 서버 렌더로 로그인/로그아웃 양쪽 상태 렌더 검증

### Root Cause Note
- 설정 모달은 메인 App과 분리된 컴포넌트(`SettingsModal({ settings, onSettingsChange, onClose })`). 메인 컴포넌트의 상태를 모달에서 쓰려면 반드시 props 전달 필요 — 이후 모달에 기능 추가 시 동일 주의

---

## [3.29.0] - 2026-06-01

### Added
- **구글 드라이브 연동 (1단계: 수동 저장/불러오기)** — 회사↔집 등 기기 간 작업 이어가기
  - Google Identity Services(GIS) 토큰 방식 + Drive REST API. `drive.file` 범위(이 앱이 만든 파일만 접근, 민감 검수 불필요)
  - 설정 → "구글 드라이브 연동": 연결 / 드라이브에 저장 / 드라이브에서 불러오기 / 연결 해제
  - 파일명 `brainbloom-data.json` 하나로 저장(있으면 PATCH로 덮어쓰기, 없으면 생성)
  - 토큰은 메모리 보관(약 1시간 유효, 새로고침 시 재연결). 401/403 시 재연결 유도
  - OAuth 클라이언트 ID 내장(공개 가능 값), `accounts.google.com/gsi/client` 스크립트 로드

### Notes
- **배포 도메인(github.io)에서만 동작** — 로컬 `file://`에선 구글 OAuth 미작동
- "나 혼자" 모드: 구글 클라우드 콘솔 테스트 사용자에 등록된 계정만 사용(검수 불필요). 공개하려면 별도 검증 필요
- 2단계 예정: 자동 동기화(저장 시 자동 업로드), 회사·집 동시 수정 충돌 처리

### Technical Notes
- 저장 페이로드: `{version, savedAt, tree}` (트리는 cloneTree 후 _x/_y/_w/_h/_subH 제거)
- 불러오기: sanitizeTree로 검증 → setTree + treeToText로 텍스트박스 동기화

---

## [3.28.13] - 2026-06-01

### Removed
- **"오늘 N분"(집중 시간) 표시 제거** — 타이머 옆 집중 시간 표시 기능 삭제
  - 관련 코드 일괄 제거: `focusToday` 상태, `todayKey`, `focusLog` IndexedDB 로드, `.focus-today` CSS
  - (3.28.0 제안 5종 중 5번으로 추가됐던 기능. 사용자 요청으로 제거)

---

## [3.28.12] - 2026-06-01

### Fixed
- **편집 중 입력창 꼬리 여백 축소** — 3.28.11의 너비 계산이 과해 글자 뒤 빈 공간이 길던 문제
  - 입력창 너비 계수 `1.05em + 1.5em` → `1.0em + 0.6em`(최소 6em → 5em)
  - `.node-input` padding `2px 18px 2px 6px` → `2px 8px`(노드 폭이 늘어나므로 큰 오른쪽 여백 불필요)

---

## [3.28.11] - 2026-06-01

### Fixed
- **긴 한글 입력 시 끝 글자 잘림 근본 수정** — 3.28.10(오른쪽 패딩 확대)으로는 긴 텍스트에서 여전히 잘리던 문제를, 편집 중 노드 폭 확장으로 해결
  - 편집 중인 노드 div: `width: auto` + `minWidth: 원래 폭` + `maxWidth: 600` → left 고정이라 오른쪽으로만 확장, 트리 레이아웃(다른 노드 위치) 불변
  - `.node-input` 인라인 너비를 글자 수 기반(`editValue.length * 1.05 + 1.5` em, 최소 6em)으로 동적 계산 — 한글 최대폭 기준이라 안 잘림

### Technical Notes
- 노드가 `position:absolute`라 폭 확장이 형제 노드에 영향 없음. 단위 검증으로 글자 수별 너비 확인

---

## [3.28.10] - 2026-06-01

### Fixed
- **한글 입력 중 마지막 글자 가림 수정** — 노드 편집 시 IME 조합 중인 마지막 글자가 입력창 오른쪽 경계에 가려지던 문제
  - `.node-input` 오른쪽 padding을 6px → 18px로 확대, `box-sizing: border-box` 추가(패딩 확대로 입력창이 노드 밖으로 넘치지 않도록)

---

## [3.28.9] - 2026-06-01

### Changed
- **타이머 기본 시간 10분 → 3분** — 신규 사용자 기본값(`timerMinutes`)을 3으로 변경
  - 관련 폴백/누락 방어값도 3으로 통일(useState 초기값, 잘못된 값 복구, 동작 폴백, 캘린더 일정 길이)

### Compatibility
- 기존 사용자 영향 없음: 저장된 `timerMinutes`가 정상값(1~120)이면 누락 방어를 타지 않고 그대로 유지. 신규 사용자만 3분으로 시작

---

## [3.28.8] - 2026-06-01

### Changed
- **신규 사용자 기본 헤더 간결화** — 설정이 없는 첫 사용자에게는 로고·버전·타이머·새로 시작·캘린더·AI 요약·설정만 표시
  - `visibleSaveButtons` 기본값을 `[]`로(저장 버튼 숨김), `showUndoRedo` 기본값을 `false`로 변경
  - 사용자가 설정에서 켜면 그 값으로 표시됨(설정은 저장되어 유지)

### Compatibility
- 기존 사용자 영향 없음: 저장된 설정이 있으면 그대로 사용. `visibleSaveButtons` 키가 없던 옛 설정은 6개 전체로 복구(보던 대로), `showUndoRedo` 키가 없던 옛 설정은 true로 복구(보던 대로). 신규 사용자만 새 기본값 적용

---

## [3.28.7] - 2026-06-01

### Fixed
- **초기 로드 시 노드 겹침 수정** — 3.28.6에서 `.canvas-inner` 패딩을 `50vh 50vw`로 준 것이 원인. 좌우 패딩 합(100vw)이 컨테이너 너비와 같아져 flex 콘텐츠 공간이 0/음수가 되며 노드 배치가 한 점에 겹침
  - 패딩을 고정 `800px`로 변경 → 콘텐츠 공간이 음수가 되지 않아 레이아웃 정상, 동시에 사방 스크롤 여백 확보
  - 큰 패딩으로 초기 스크롤(0,0)이 맵을 벗어나므로, 최초 로드 시 루트 중앙 스크롤 effect 유지(`didInitCenterRef`, centerNode는 스크롤만 조정하여 레이아웃 불변)

### Notes
- 중앙 정렬 이슈 총정리(3.28.2~.7): 원인은 ① scrollTo 여백 부족 ② vw 패딩의 레이아웃 붕괴. 고정 px 패딩 + DOM 측정 기반 centerNode로 해결

---

## [3.28.6] - 2026-06-01

### Fixed
- **접기/펼치기 후 루트 중앙 정렬 — 근본 원인 해결** — 3.28.2~.5의 반복 실패 원인은 좌표 계산이 아니라, 맵이 뷰포트보다 작을 때 **스크롤 여백이 없어 `scrollTo`가 무력**했던 것
  - `.canvas-inner` 패딩을 `50vh 50vw`로 확대 → 맵 주위에 항상 뷰포트 절반의 스크롤 여백 확보, 어떤 노드도 화면 중앙까지 스크롤 가능
  - 비대칭 트리(루트 좌우 자식 수 불균형)에서 `justify-content:center`가 루트를 중앙에 못 놓던 문제도 함께 해소(스크롤로 루트 기준 정렬)
  - 큰 여백으로 초기 스크롤(0,0)이 맵을 벗어날 수 있어, 최초 로드 시 루트 중앙 정렬 effect(`didInitCenterRef`, 1회) 추가

### Known Tradeoff
- 캔버스 빈 공간이 이전보다 넓어짐(무한 캔버스 느낌). 기능 문제 없음. 과하면 패딩 비율 조정 가능

---

## [3.28.5] - 2026-06-01

### Fixed
- **접기/펼치기 후 루트 가로 치우침 최종 수정** — 3.28.4(좌표 재구성 방식)에서 세로는 맞았으나 가로가 왼쪽으로 치우치던 문제
  - 노드 div에 `data-node-id` 추가, `centerNode`가 `el.querySelector([data-node-id])`로 **노드 DOM의 실제 rect를 직접 측정**
  - 줌(scale)·flex 중앙정렬·레이아웃이 모두 반영된 최종 화면 좌표를 사용 → 좌표 재구성(`_x*zoom + wrapper offset`) 불필요, 오차 원천 제거
  - `behavior: 'auto'`(즉시)로 변경 — 펼치기→접기 연속 호출 시 smooth 스크롤 진행 중 측정하던 오차 방지

### Technical Notes
- 좌표 재구성 방식의 누적 실패(3.28.2~.4) 끝에, 브라우저가 렌더한 실제 위치를 신뢰하는 DOM 측정 방식으로 전환

---

## [3.28.4] - 2026-06-01

### Fixed
- **접기/펼치기 후 루트가 좌상단에 치우치던 문제 재수정** — 3.28.3에서 타이밍은 잡았으나 좌표 계산(`offsetLeft + _x*zoom`)이 줌·flex 정렬에서 오차를 내 루트가 화면 왼쪽 위에 위치
  - `centerNode`를 `getBoundingClientRect` 기반으로 재작성: 맵 래퍼의 실제 화면 좌표 + `_x*zoom`(scale transformOrigin 0,0)으로 노드 화면 중심을 구하고, 뷰포트 중심과의 차이만큼 스크롤
  - 브라우저가 실제 렌더한 위치를 측정하므로 줌 배율·중앙정렬 오프셋과 무관하게 정확

### Technical Notes
- 단위 검증: 스크롤 적용 후 노드 중심이 뷰포트 중심과 일치함을 좌표 계산으로 확인

---

## [3.28.3] - 2026-06-01

### Fixed
- **접기 후 루트가 좌상단으로 가던 문제 수정** — 3.28.2의 `setTimeout(80ms)` 방식이 갱신 전 좌표를 잡아, 접은 뒤 루트가 중앙이 아닌 좌측 상단에 위치하던 문제
  - `pendingCenterRef` + `useLayoutEffect([tree])` + 이중 `requestAnimationFrame`으로 변경: tree 갱신 → `layoutTree`가 `_x`/`_y` 재계산(useMemo) → 레이아웃 effect에서 페인트 후 `centerNode` 실행
  - 클로저가 옛 tree/좌표를 잡는 문제 제거(effect는 최신 tree를 참조), DOM 측정(`wrapper.offsetLeft`)도 페인트 후라 정확

---

## [3.28.2] - 2026-06-01

### Improved
- **접기/펼치기 후 루트 자동 중앙 정렬** — "전체 펼치기"/"1단계만 보기" 실행 시 메인 아이템(루트)을 화면 정중앙으로 이동. 모두 접었을 때 펼쳐진 트리 기준 스크롤 위치에 루트가 없어 화면 밖으로 사라지던 문제 해결
  - `centerNode(id)` 추가: 노드 중심을 뷰포트 중심에 맞춰 스크롤(기존 `scrollNodeIntoView`는 가장자리로만 당겨 정중앙이 아님)
  - 레이아웃 재계산 후 적용되도록 80ms 지연 호출

### Technical Notes
- 좌표: `targetX = nodeLeft + nodeW/2 - clientW/2` (Y 동일), 음수는 0으로 클램프
- 단위 검증: 중앙 정렬 좌표 계산 + 좌상단 노드 음수 방지 2종

---

## [3.28.1] - 2026-06-01

### Improved
- **검색 결과 시각 강조** — 검색으로 찾은 노드가 잘 안 보이던 문제 개선
  - 매칭된 노드 전체: 노란 테두리(`box-shadow 0 0 0 2px #f0b429`)로 "찾은 것들" 표시
  - 현재 포커스(Enter로 이동한) 노드: 빨간 펄스 애니메이션(`searchPulse`)으로 또렷하게 — 결과가 1개일 때도 확실히 인지됨
  - NodeView에 `isSearchMatch`/`isSearchFocus` prop 추가, `searchOpen`일 때만 적용

### Technical Notes
- CSS 우선순위: search-focus(펄스)가 search-match(정적 테두리)·selected보다 뒤에 정의되어 포커스 노드에 펄스가 표시됨

---

## [3.28.0] - 2026-06-01

### Added
- **접기/펼치기 일괄 토글** — 캔버스 툴바에 "1단계만 보기"(⊟)·"전체 펼치기"(⊞) 버튼 추가
  - `expandAll()`: 모든 노드 collapsed 해제. `collapseToFirstLevel()`: 루트 직계 자식 중 자식 있는 노드만 접음(루트는 펼친 상태)
- **URL 별명 표시** — 마크다운 링크 문법 `[이름](https://url)` 지원. 노드엔 "이름"만 표시, 🔗는 해당 URL로 연결
  - `resolveLabelLink(label)` → `{display, url}`. 마크다운 링크가 없으면 기존 동작(라벨 그대로 + 첫 URL 추출) 유지
- **오늘 집중 시간 기록** — 타이머 완료 시 그날 누적 분을 더해 "🔥 오늘 N분" 표시. IndexedDB `focusLog`에 `{date, minutes}` 저장, 날짜 바뀌면 0부터

### Technical Notes
- 제안 5종 완결: (3.27.0) 노드 검색·마크다운 내보내기 + (3.28.0) 접기/펼치기·URL 별명·집중 시간
- 단위 검증: 일괄 접기/펼치기 2종, resolveLabelLink 6종, 집중 시간 누적·날짜리셋 5종
- 집중 기록은 부가 기능이라 idb 실패 시 조용히 무시(앱 동작 영향 없음)

---

## [3.27.0] - 2026-06-01

### Added
- **노드 검색 (Ctrl+F)** — 캔버스 우상단에 검색창을 띄워 라벨로 노드를 찾음
  - 매칭 노드로 자동 스크롤(`scrollNodeIntoView` 재활용), `현재/전체` 카운트 표시
  - Enter=다음, Shift+Enter=이전(순환), Esc=닫기, ↑↓ 버튼도 제공
  - 텍스트 입력창/노드 편집 중에는 브라우저 기본 검색에 양보
- **마크다운(.md) 내보내기** — 저장 형식에 추가(`treeToMarkdown` 재활용). 노션·옵시디언 등에 붙여넣기 적합
  - `saveAll`에 `md` 분기, 설정 → 저장 옵션 칩에 MD 추가, 신규/복구 기본 목록에 포함

### Technical Notes
- 검색 상태: `searchOpen`/`searchQuery`/`searchMatchIds`/`searchPos`. 검색어 변경 시 effect로 트리 순서 매칭 수집
- 단위 검증: 매칭 수집(부분일치/무매칭) 3종, 순환 이동(처음↔끝) 3종

---

## [3.26.0] - 2026-06-01

### Added
- **Undo · Redo 버튼 표시 토글** — 설정 → 화면 표시에 추가. 끄면 상단바에서 Undo·Redo 버튼(과 앞 구분선)만 숨김. "새로 시작" 버튼·로고·타이머는 그대로 유지 (`settings.showUndoRedo`, 기본 켜짐)
  - 미니멀 상단바(`minimalHeader`)와 독립적으로 동작 — Undo·Redo만 콕 집어 숨기고 싶을 때 사용
  - 버튼을 숨겨도 단축키(Ctrl+Z / Ctrl+Shift+Z)는 계속 동작

### Technical Notes
- Undo·Redo 버튼과 앞 구분선을 `settings.showUndoRedo !== false` 조건의 Fragment로 감쌈
- `showUndoRedo` 누락 시 true로 정규화

---

## [3.25.1] - 2026-06-01

### Fixed
- **타이머 정중앙 정렬** — 3.25.0에서 타이머를 `flex:1` 존에 두어 우측 메뉴(actions) 폭만큼 왼쪽으로 치우치던 문제 수정
  - `.timer-zone`을 `position:absolute; left:50%; transform:translateX(-50%)`로 헤더(=화면) 정중앙에 고정 → 좌우 요소 폭과 무관하게 항상 가운데
  - `pointer-events` 처리로 빈 영역이 헤더 클릭을 막지 않게(칩 자체만 클릭 가능)
  - timer-zone이 flex 흐름에서 빠지므로 `.header.minimal`에 `justify-content:flex-end` 복원(actions 우측 유지)

---

## [3.25.0] - 2026-06-01

### Changed
- **타이머 칩을 헤더 중앙으로 분리 배치** — 기존엔 `brand`(로고) 안에 있어 좌측 패널과 겹쳐 보이고, 미니멀 모드에서 brand와 함께 숨겨졌음
  - 타이머를 독립 `.timer-zone`(`flex:1`, 중앙 정렬)으로 분리 → 헤더 가운데 위치, 좌측 로고·패널과 겹치지 않음
  - **미니멀 상단바에서도 타이머 표시** — 이제 미니멀 모드 구성은 타이머·캘린더·AI·설정
  - `.header.minimal`의 `justify-content: flex-end` 제거(timer-zone이 공간을 채우므로 actions는 자연히 우측)
  - 설정의 미니멀 상단바 설명 문구 갱신(타이머가 유지됨을 반영)

---

## [3.24.1] - 2026-06-01

### Fixed
- **미니멀 상단바 배경 톤 불일치 해소** — 헤더 영역과 캔버스의 배경이 미세하게 다르게 보이던 문제 수정. 원인은 은은한 색 그라데이션이 `.canvas-wrap`에만 적용되어 투명 헤더 영역엔 없었던 것
  - 색 그라데이션을 `#root` 배경으로 이관(점 패턴 `#root::before`와 함께 전역화) → 헤더·캔버스가 동일 배경 공유
  - `.canvas-wrap`은 투명 처리하여 root 배경이 그대로 비치도록

---

## [3.24.0] - 2026-06-01

### Added
- **설정 → 노드 폰트 섹션** — 마인드맵 노드 라벨의 글씨체를 선택
  - 프리셋: 시스템 기본 / 기본 스타일(Fraunces) / 맑은 고딕 / 나눔고딕 / 굴림 / 바탕
  - **직접 입력**: 임의 폰트명 입력 가능 (컴퓨터에 설치된 경우 적용, 없으면 폴백)
  - 버튼 자체가 해당 폰트로 렌더되어 선택 전 미리보기, 하단에 별도 샘플 미리보기 제공
  - 기본값을 **시스템 폰트 스택**으로 변경 (OS 기본 한글/영문 폰트 = 일반적인 앱 화면 느낌)

### Technical Notes
- `--node-font` CSS 변수 도입, `.node-label`·`.node-input`이 이를 참조 → 설정 변경 시 effect로 변수 갱신
- `NODE_FONT_OPTIONS` 상수 + `resolveNodeFont(id, custom)` 헬퍼 (custom은 따옴표 제거 후 폴백 체인 구성)
- `nodeFont`/`nodeFontCustom` 설정에 누락 방어(기본 'system'/'')
- 웹 보안상 설치 폰트 목록을 직접 열거할 수 없어, 프리셋 + 직접 입력 방식 채택 (Local Font Access API 미사용)
- 단위 테스트 7종 통과: 프리셋 해석 / custom 입력·빈값·따옴표제거 / 알 수 없는 id 폴백

---

## [3.23.0] - 2026-06-01

### Added
- **Shift+Enter로 위에 형제 추가** — 선택 노드에서 그냥 Enter는 아래(다음 형제), Shift+Enter는 위(이전 형제)에 새 노드 생성. `addSibling`에 `before` 옵션 추가(`splice(idx, 0)` vs `splice(idx+1, 0)`)
- **새 노드 자동 스크롤** — `addChild`/`addSibling` 후 `scrollNodeIntoView(newId)` 호출(레이아웃 계산 후 60ms). 가지를 화면 밖으로 확장해도 입력 중인 노드가 보이도록 유지

### Changed
- **노드 라벨 줄바꿈 보존** — 붙여넣은 텍스트의 `\n`이 노드 안에서 그대로 표시되도록 `.node-label`에 `white-space: pre-wrap` 적용. line-clamp 줄 수 제한과 공존(줄바꿈 포함해 설정 줄 수까지 표시 후 ...)

### Technical Notes
- 편집 모드의 Enter는 기존대로 "입력 확정"이므로 Shift 분기 불필요(편집 중에는 형제 추가 안 함)
- 단위 검증: before 삽입 위치(위/아래) 2종 통과

---

## [3.22.0] - 2026-06-01

### Added
- **설정 → 노드 길이 섹션** — 라벨이 길어질 때 어디까지 표시할지 설정
  - **외부 링크 최대 표시 길이**: `1줄` / `2줄` (URL 포함 노드, `settings.urlLabelLines`)
  - **일반 텍스트 최대 표시 길이**: `1줄` / `2줄` / `모두 보여주기` (`settings.plainLabelLines`)
- **호버 시 전체 텍스트 툴팁** — 라벨이 잘린 경우 `title` 속성으로 전체 내용 표시

### Technical Notes
- CSS `-webkit-line-clamp`으로 줄 단위 잘라내기 (모든 모던 브라우저 지원)
- 라벨에 URL이 포함되면 URL 룰을, 아니면 일반 룰을 적용
- **편집 모드에선 잘라내지 않음** — 입력 중 글자가 잘려 안 보이는 사고 방지
- NodeView에 `settings` prop 전달, 누락 방어로 잘못된 값은 기본값(1, 'all')로 정규화
- 단위 테스트 8종 통과: URL 1줄/2줄, 일반 1줄/2줄/all, URL 포함 문장, 빈 라벨, 설정 누락 폴백

---

## [3.21.0] - 2026-06-01

### Added
- **노드 라벨의 URL을 클릭 가능한 링크로** — 라벨에 `http://` 또는 `https://`로 시작하는 URL이 포함되면 노드 옆에 🔗 아이콘이 자동으로 표시. 아이콘 클릭 시 새 탭에서 해당 페이지가 열림
  - `extractFirstUrl()` 헬퍼: 라벨의 첫 URL 추출, 끝의 문장부호(괄호·따옴표·마침표 등) 자동 정리
  - 노드 자체 클릭(선택)·더블클릭(편집)·드래그는 그대로 작동하도록 아이콘에서 `stopPropagation` 처리
  - `target="_blank"` + `rel="noopener noreferrer"` 적용 (탭 노출/원본창 접근 차단)

### Technical Notes
- 라벨 영역을 `.node-label-row`로 감싸 flex 정렬: 라벨은 가용 공간 차지, 아이콘은 우측 고정
- 아이콘은 반투명 흰 배경 원형 버튼 — 어떤 노드 색에서도 가독성 확보, hover 시 살짝 확대
- URL 추출 단위 테스트 10종 통과: 단순/문장속/괄호닫힘/쿼리·해시포함/한국어혼합/비-http(s)/빈값·null

---

## [3.20.2] - 2026-06-01

### Fixed
- **미니멀 상단바의 점 패턴 연속성** — 3.20.1에서 헤더 배경색은 맞췄으나 캔버스의 점 격자가 헤더 자리엔 없어 미세한 단절이 있던 문제 해결. 점 패턴을 전역(`#root::before`)으로 올려 헤더~캔버스가 하나의 격자로 이어짐
  - 캔버스의 기존 `.canvas-wrap::before` 점 패턴 제거(전역으로 이관), 캔버스 배경은 색 그라데이션만 유지하고 투명화
  - `.header`·`.layout`에 `position:relative; z-index:1` 부여해 콘텐츠가 점 패턴(z-index:0) 위에 오도록 보장 — 일반 모드(불투명 헤더·패널)는 기존과 동일하게 점을 가림

### Technical Notes
- z-index 계층 점검: 점 패턴(0) < 헤더·레이아웃(1) < 툴바(10) < 노드 드래그(100) < 모달(1000+)

---

## [3.20.1] - 2026-06-01

### Fixed
- **미니멀 상단바의 흰색 띠 이질감 제거** — 미니멀 상단바를 켰을 때 헤더 영역(`background: var(--bg)`)이 점 패턴이 있는 캔버스와 달리 밋밋한 흰색 띠처럼 도드라지던 문제 수정
  - `.header.minimal`의 배경을 `transparent`로 변경 → body의 `--bg`가 비쳐 캔버스 영역과 색이 이어짐

---

## [3.20.0] - 2026-06-01

### Changed
- **"상단 메뉴 버튼 표시" 옵션 제거, "미니멀 상단바"로 통합** — 기능이 겹쳐 혼동을 주던 두 설정을 하나로 정리. 헤더 최소화는 이제 "미니멀 상단바" 토글로만 제어
  - 설정 UI에서 `showToolbarButtons` 토글 제거 (미니멀 상단바가 상위 개념으로 포함)

### Technical Notes
- 과거에 `showToolbarButtons: false`로 저장된 설정이 있어도 헤더 버튼이 정상 표시되도록, 불러올 때 항상 `true`로 정규화 (UI가 사라져 더는 끌 수 없으므로)
- 헤더 JSX의 기존 조건은 유지(`minimalHeader`가 실질 제어), 동작 변화 없음

---

## [3.19.0] - 2026-05-31

### Added
- **미니멀 상단바 토글** — 설정 → 화면 표시에 추가. 켜면 헤더에서 로고·버전·타이머·새로 시작·Undo·Redo와 헤더 아래 경계선까지 모두 숨기고, 캘린더·AI·설정 세 버튼만 우측에 남김 (`settings.minimalHeader`, 기본 꺼짐)
  - v3.18.0의 "상단 메뉴 버튼 표시" 토글과 독립적으로 동작 (미니멀 상단바가 더 포괄적)
  - Undo·Redo는 단축키로 계속 동작. 타이머 칩도 숨겨지므로 타이머를 쓰려면 이 옵션을 꺼야 함

### Technical Notes
- `.header.minimal`: `border-bottom: none` + `justify-content: flex-end`로 경계선 제거·우측 정렬
- brand 영역과 저장 버튼 블록을 `minimalHeader !== true` 조건으로 렌더, 툴바 버튼 조건에도 반영
- 캘린더·AI와 설정 사이 구분선은 유지 (설정 버튼 시각적 분리)
- `minimalHeader` 누락 시 false 폴백

---

## [3.18.0] - 2026-05-31

### Added
- **상단 메뉴 버튼 표시 토글** — 설정 → 화면 표시에서 헤더의 "새로 시작 · Undo · Redo" 버튼을 한 번에 숨기거나 표시. 끄면 캘린더·AI·설정 버튼만 남음 (`settings.showToolbarButtons`, 기본 표시)
  - Undo·Redo는 헤더에서 숨겨도 단축키(Ctrl+Z / Ctrl+Shift+Z)로 계속 동작

### Technical Notes
- 세 버튼과 그 사이 구분선을 Fragment로 묶어 조건부 렌더
- 저장 버튼(이미 별도 설정으로 제어)과 캘린더·AI·설정은 토글 대상에서 제외
- `showToolbarButtons` 누락 시 true 폴백

---

## [3.17.0] - 2026-05-31

### Changed
- **줌 컨트롤 자동 숨김** — 캔버스 줌 툴바(− 100% + ⊙)를 평소엔 숨기고, 줌이 변할 때만 2.5초간 표시 후 페이드아웃. 툴바에 마우스를 올린 동안에는 숨김을 보류
  - 최초 마운트(100%) 시에는 표시되지 않음 (첫 렌더 건너뛰기 가드)

### Added
- **캔버스 안내 힌트 표시 토글** — 설정 → 화면 표시에 "캔버스 안내 힌트(Ctrl+휠 · 드래그)" 켜고 끄기 추가 (`settings.showCanvasHint`, 기본 표시)

### Technical Notes
- `.canvas-toolbar`에 opacity/visibility 트랜지션, `.visible` 클래스로 표시 제어, `pointer-events`도 함께 토글
- 줌 변화 감지 effect + 호버 보류 ref로 자동 숨김 타이밍 관리
- `showCanvasHint` 누락 시 true 폴백

---

## [3.16.6] - 2026-05-31

### Changed
- **헤더 브랜드 영역 수평 배치로 롤백** — 3.16.5의 세로 배치를 되돌려, 로고와 버전 태그가 다시 가로로 나란히 표시됨 (`.brand-stack` 제거, `.brand` align-items baseline 복원)

---

## [3.16.5] - 2026-05-31

### Changed
- **헤더 브랜드 영역 세로 배치** — 로고(BrainBloom)와 버전 태그를 가로 나열에서 세로 스택으로 변경. 버전 태그는 로고 폭 안에서 가운데 정렬, 타이머 칩과는 세로 중앙으로 정렬
  - `.brand-stack` 추가, `.brand`의 `align-items`를 baseline→center로 조정

---

## [3.16.4] - 2026-05-31

### Changed
- 헤더 로고 옆 태그에서 "브레인스토밍 /" 텍스트 제거, 버전 표시(`v3.16.4`)만 유지

---

## [3.16.3] - 2026-05-31

### Changed
- **개발자 연락처: 메일 열기 → 클립보드 복사** — 이메일 버튼 클릭 시 `mailto:`로 메일 앱을 여는 대신 주소를 클립보드에 복사. 복사되면 버튼이 1.6초간 초록색 "✓ 복사됨!"으로 전환

### Technical Notes
- `navigator.clipboard.writeText` 사용, 비보안 컨텍스트/구형 브라우저용 `textarea + execCommand` 폴백 포함
- 복사 피드백은 SettingsModal 자체 상태(`mailCopied`)로 처리 — 메인 토스트에 의존하지 않아 모달에 가려질 염려 없음

---

## [3.16.2] - 2026-05-31

### Changed
- 개발자 연락처 이메일 주소를 `redmir@naver.com` → `redmirnet@naver.com`으로 변경 (표시 텍스트 + mailto 링크 양쪽)

---

## [3.16.1] - 2026-05-31

### Added
- **개발자에게 연락하기** — 설정 맨 아래에 연락처 카드 추가. 은은한 그라데이션 카드에 메일 주소(`redmir@naver.com`)를 배치, 클릭 시 `mailto:` 링크로 메일 앱이 열림
  - 메일 버튼은 hover 시 코랄색으로 채워지는 인터랙션

### Technical Notes
- `color-mix()` 기반 그라데이션·테두리에 단색 폴백을 함께 지정 (미지원 브라우저 대비)

---

## [3.16.0] - 2026-05-31

### Added
- **캘린더 마크다운 → 마인드맵 복원** — 구글 캘린더 일정 설명에 내보낸 마인드맵 텍스트를 좌측 입력 패널에 붙여넣으면 트리가 그대로 복원됨
  - `parseBrainBloomMarkdown`: `treeToMarkdown` 출력 형식을 역파싱 (`#`=루트, `##`=1뎁스, 들여쓰기 불릿=2뎁스 이하)
  - `splitLabelMeta`: 라벨에서 메타 꼬리표(📅 날짜 · ⚡ 노력 · 💰 비용)와 아이콘 접두사를 분리해 복원
  - `looksLikeBrainBloomMarkdown`: 붙여넣은 텍스트가 BrainBloom 마크다운인지 보수적으로 감지 (`# `+`## `/불릿 조합 또는 `/ BrainBloom` 서명)
  - `---` 이후 통계/생성 줄은 복원에서 제외

### Technical Notes
- 텍스트→트리 동기화 경로에서 마크다운 감지 시 전용 파서 사용, 실패하면 기존 `parseInput`으로 폴백
- 일반 들여쓰기/하이픈 입력은 마크다운으로 오인하지 않도록 감지 조건을 좁게 설정
- 복원된 트리만 반영하고 텍스트박스 원본은 보존 (트리→텍스트 역동기화 억제)

### Process
- 왕복(round-trip) 테스트 23종 통과: 기본 트리 / 메타데이터 / 4뎁스 중첩 / 실제 캘린더 캡처 형식 / 일반 입력 오인 방지
- 실제 사용자 캘린더 캡처의 다단계 들여쓰기 구조 정밀 복원 확인

---

## [3.15.0] - 2026-05-30

### Added
- **저장 데이터 검증/복구 (`sanitizeTree`)** — IndexedDB나 파일에서 불러온 트리를 사용 전에 검증. 손상된 부분은 복구하고, 복구 불가능하면 안내 후 안전하게 새로 시작
  - children이 배열이 아니면 빈 배열로 보정, label 누락/타입오류는 빈 문자열로, id 누락·중복은 고유 id 자동 부여
  - 망가진 자식 노드(null·문자열·숫자 등)는 제거, 정상 노드만 유지
  - 루트 자체가 객체가 아니면(null·배열·원시값) 복구 불가로 판정 → 새로 시작 폴백
  - 알려진 필드만 화이트리스트로 보존(meta/color/icons/pinnedSide/autoSide/collapsed), 알 수 없는 필드는 제거

### Changed
- **종료 시 저장 신뢰성 보강** — 기존 `beforeunload`(완료 보장이 어려운 fire-and-forget)에 더해 `visibilitychange`(hidden) 시점에도 저장. 탭 전환·숨김·모바일 앱 전환에서도 작동해 데이터 유실 위험을 줄임

### Technical Notes
- 트리 변경 시 1.5초 디바운스 자동저장은 기존부터 존재 → 이번 보강과 합쳐 3중 안전망(자동저장 + visibilitychange + beforeunload)
- 불러오기 경로에서 `sanitizeTree` 통과한 트리만 `restoreWork`/startupDialog로 전달

### Process
- `sanitizeTree` 단위 테스트 19종 통과: 정상 트리 / children 비배열 / label·id 손상 / id 중복 / 망가진 자식 / 복구불가 루트 / 화이트리스트 필드 / 20단계 중첩

---

## [3.14.4] - 2026-05-30

### Changed
- **카드 섹션끼리도 구분선 추가** — 3.14.3에서 카드 섹션은 자체 테두리만으로 구분했으나, 카드 사이가 허전하다는 피드백 반영. 카드와 카드 사이 여백 중앙에 가로 구분선을 넣어 영역을 더 명확히 분리
  - `.is-card + .is-card::before` 가상요소로 카드 바깥 여백에 독립 선을 그림 → 카드의 둥근 모서리·4면 테두리를 침범하지 않음
  - 적용 경계: 시작 시 동작↔오늘의 격언, 오늘의 격언↔새 노드 단어

---

## [3.14.3] - 2026-05-30

### Changed
- **설정 모달 섹션 사이에 구분선 추가** — 일반 섹션끼리 인접한 경계(화면 표시 / 타이머 / 저장 옵션 / 구글 캘린더 / AI 요약 사이)에 얇은 가로 구분선과 여백을 넣어 영역을 명확히 분리
  - `.settings-section:not(.is-card) + .settings-section:not(.is-card)` 규칙으로 두 섹션이 모두 일반일 때만 `border-top` 적용
  - 카드 섹션(`.is-card`)은 자체 4면 테두리로 경계가 명확하므로 구분선 대상에서 제외 (`:not(.is-card)`로 카드 테두리를 건드리지 않음)

### Process
- 8개 섹션 순서를 시뮬레이션해 구분선 위치 검증: 첫 섹션 제외, 일반끼리만 선, 카드는 선 없음 확인

---

## [3.14.2] - 2026-05-30

### Changed
- **설정 세 섹션을 묶음 카드로 정돈** — 시작 시 동작 / 오늘의 격언 / 새 노드 단어 섹션을 제목·설명·옵션이 한 덩어리로 보이도록 연한 박스(카드)로 감쌈
  - 재사용 가능한 `.settings-section.is-card` CSS 클래스로 구현
  - 카드 안에서는 라디오 옵션을 흰 배경으로 띄우고, 선택된 옵션에 강조 테두리(box-shadow ring)를 적용해 카드 배경과 명확히 구분

### Technical Notes
- 카드 배경(`--bg-2`)과 옵션 hover/active 배경이 겹치지 않도록, 카드 내부 옵션은 `--panel`(흰색) 배경으로 오버라이드

---

## [3.14.1] - 2026-05-30

### Changed
- **색상을 눈이 편한 차분한 톤으로 재조정** — 3.14.0의 밝은 테마가 장시간 작업 시 눈부심·피로를 유발한다는 피드백 반영
  - 배경: 거의 순백(`#f7fbff`, 휘도 0.96) → 부드러운 오프화이트(`#f4f6f9`, 휘도 0.92)로 눈부심 완화
  - 노드 14색 전체를 채도 낮춘 muted 톤으로 교체 (테라코타·세이지·다스티로즈·소프트블루 등)
  - 글씨는 순검정 대신 부드러운 다크 슬레이트(`#28303d`)
- 폴백 색과 내보내기 배경색도 함께 조정

### Technical Notes
- 밝기는 낮췄지만 14색 전부 흰 글씨 대비 WCAG 3.0+ 유지(단위 검증)
- 색상 키 이름 유지로 기존 저장 트리 호환

---

## [3.14.0] - 2026-05-30

### Changed
- **전체 색상 테마를 "상큼한 맑음" 톤으로 변경** — 하루를 활기차고 긍정적으로 만든다는 앱의 목적에 맞게, 칙칙한 베이지/네이비 톤에서 밝고 경쾌한 톤으로 전환
  - 배경: 누런 베이지(`#f6f3ec`) → 하늘빛 화이트(`#f7fbff`)
  - 글씨: 진회색 → 부드러운 딥네이비(`#15233a`), 보조텍스트는 푸른빛 회색
  - 선/테두리: 탁한 베이지 → 옅은 하늘(`#d6e4f0`)
  - 액센트: 벽돌빛 주황 → 코랄(`#f25540`)
  - 노드 팔레트 14색 전체를 선명한 코발트블루·코랄·민트·하늘파·로즈 등으로 교체
- 내보내기(SVG/PNG) 배경색도 새 배경과 일치시킴

### Technical Notes
- CSS 변수(`:root`)와 JS `COLORS` 객체 양쪽을 함께 갱신, 색상 키 이름(navy/orange/teal 등)은 그대로 유지 → 기존에 저장된 트리의 색 지정이 깨지지 않음
- 코드에 하드코딩돼 있던 폴백 색(`#5a6478`, `#1f3a68`)과 export 배경(`#f6f3ec`)도 새 팔레트로 교체
- 노드 글씨가 흰색이므로 14색 전부 흰 글씨 대비 WCAG 3.0+ 확보를 단위 검증 (mint·amber·gold 등 밝은 색은 가독성 위해 명도 보정)

### Process
- 색상 대비를 코드로 계산해 가독성 부족한 색을 반복 보정 후 적용
- 적용 전 미리보기로 실제 조합 시각 확인

---

## [3.13.1] - 2026-05-30

### Changed
- 변경 내용 화면 맨 아래 "GitHub에서 전체 보기" 링크를 실제 저장소 주소(`https://github.com/noainred/cleaninghead/blob/main/CHANGELOG.md`)로 연결

---

## [3.13.0] - 2026-05-30

### Added
- **설정 화면에 "변경 내용" 버튼 추가** — 설정 모달 헤더 우측의 🆕 버튼을 누르면 같은 모달 안에서 변경 이력 화면으로 전환, 최근 업데이트 내역을 앱 안에서 바로 확인 가능
  - 최근 2개 버전의 변경 내용을 앱에 내장 (`RECENT_CHANGES` 배열)
  - 그 이전 버전은 화면 맨 아래 GitHub 전체 이력 링크(`CHANGELOG_URL`)로 안내
  - 현재 실행 중인 버전에는 "현재 버전" 뱃지 표시
  - 변경 이력 화면에서 ← 버튼으로 설정으로 복귀

### Technical Notes
- 별도 모달 중첩 대신 SettingsModal 안에서 `showChangelog` state로 화면 전환 (설정 ↔ 변경 이력)
- `RECENT_CHANGES`는 버전별 `{ version, date, groups: [{ label, items[] }] }` 구조
- 새 버전 릴리스 시: 배열 맨 앞에 새 항목 추가 + 가장 오래된 항목 1개 제거(2개 유지), `CHANGELOG_URL`은 배포 주소로 교체 필요

### Process
- 단위 테스트: 데이터 구조 정합성(version/date/groups/items 누락 검사), 맨 앞=현재 버전 일치, "현재 버전" 뱃지 정확히 1개

---

## [3.12.1] - 2026-05-30

### Changed
- **저장 버튼 영역 깔끔 처리** — 설정에서 저장 버튼을 모두 끄면 "저장 버튼 없음 (설정에서 추가)" 안내 문구가 표시되던 것을 제거. 이제 버튼이 하나도 없으면 그 영역 자체가 보이지 않음
- 저장 버튼 영역의 좌우 구분선(divider)도 버튼이 없을 때 함께 숨겨, 헤더에 빈 구분선이 남지 않도록 정리

### Technical Notes
- 저장 버튼 IIFE를 앞뒤 구분선까지 포함해 하나의 조건부 블록으로 묶음 → 빈 경우 `null` 반환으로 통째 숨김
- 버튼이 있을 때의 동작(순서 고정 PDF→JPG→SVG→CSV→JSON, 마지막 버튼 primary 스타일)은 그대로 유지

### Process
- 단위 테스트: 빈 경우(구분선 0·문구 없음) / 1개 / 전체 / 순서 뒤섞임 / 설정값 누락 모두 의도대로 동작 확인

---

## [3.12.0] - 2026-05-30

### Added
- **좌측 텍스트 패널 표시/숨김 옵션** — 설정 → 화면 표시에서 좌측(텍스트 입력) 패널도 우측 패널처럼 켜고 끌 수 있음
  - `settings.showLeftPanel` (기본 true)
  - 좌·우 패널 4가지 조합 모두 지원 (둘 다 표시 / 좌측만 / 우측만 / 둘 다 숨김), 캔버스가 빈 공간만큼 자동 확장

### Changed
- **설정 메뉴 순서 재정렬** — 자주 쓰는 항목을 위로: 화면 표시 → 타이머 → 저장 옵션 → 구글 캘린더 → AI 요약 → 시작 시 동작 → 오늘의 격언 → 새 노드 단어
- 화면 표시 섹션 설명을 좌·우 패널 모두 설명하도록 갱신

### Technical Notes
- `.layout.no-left-panel`, `.layout.no-left-panel.no-right-panel` CSS 조합 추가 (grid-template-columns 4가지)
- 좌측 패널 숨김 시 textarea가 사라져도 `textInputRef` 사용처 모두 null 가드가 있어 안전, 텍스트↔트리 동기화는 state(inputText) 기반이라 영향 없음
- 옛 설정에 `showLeftPanel` 없으면 true로 폴백

### Process
- 단위 테스트: layout 클래스 4조합 + 기본값(undefined) = 5/5 통과
- CSS grid 정의와 클래스 로직 일치 확인, textInputRef null 가드 4곳 확인

---

## [3.11.0] - 2026-05-30

### Added
- **구글 캘린더 일정 방식 선택** — 설정 → 구글 캘린더에서 두 가지 중 선택
  - **하루 종일 일정** (`allday`, 기본): 제목 뒤에 업로드 시각이 붙음 (예: "브레인스토밍 18:00"), 종일 일정으로 등록
  - **시간 일정** (`timed`): 제목은 그대로, 지금 시각부터 **타이머 설정 시간**만큼 시간 블록으로 등록 (예: 타이머 10분 → 18:00~18:10)
- `settings.calendarMode` ('allday' | 'timed')

### Technical Notes
- 시간 일정은 `dates=YYYYMMDDTHHmmSS/YYYYMMDDTHHmmSS` 형식 + `ctz`(브라우저 타임존) 파라미터로 정확한 로컬 시각 해석
- 종료 시각은 `Date` 객체 산술로 계산 → 자정 넘김(23:55 + 10분 = 다음날 00:05)도 자동 처리
- 타이머 시간 누락 시 기본 10분 폴백
- 옛 설정에 `calendarMode` 없으면 'allday'로 안전 폴백 (기존 동작 유지)

### Process
- 단위 테스트 8개 시나리오 통과: 종일/시간 양방식 / 타이머 10·25분 / 자정 넘김 / 폴백 / 커스텀 제목 / 종일 시각 표기

---

## [3.10.1] - 2026-05-29

### Changed
- **구글 캘린더 일정 제목에 업로드 시각 자동 추가** — "📅 캘린더에 추가" 시 제목 뒤에 현재 시각이 `HH:MM`(24시간제)로 붙음
  - 예: "브레인스토밍" → "브레인스토밍 18:00"
  - 캘린더 URL을 만드는 그 순간의 시각 사용
  - 일정 형식은 그대로 종일 일정 유지 (제목에만 시각 표기)
- 설정 화면 안내문에 시각 자동 추가 설명 보강

### Process
- 단위 테스트로 시각 포맷 검증: 18:00 / 09:05(zero-padding) / 00:00(자정) / 23:59 / 빈 제목·공백 제목 폴백

---

## [3.10.0] - 2026-05-29

### Added
- **우측 패널 표시/숨김 옵션** — 설정 → 화면 표시 섹션에서 우측 패널(속성 편집 + 통계)을 켜고 끌 수 있음
  - 숨기면 마인드맵 캔버스가 그 공간(280px)까지 자동 확장 → 더 넓게 작업
  - `settings.showRightPanel` (기본 true)

### Technical Notes
- `.layout.no-right-panel` CSS 변형으로 grid 컬럼을 `320px 1fr 280px` → `320px 1fr`로 전환
- 캔버스 너비는 `getBoundingClientRect`/`clientWidth`를 실시간으로 읽으므로 패널 토글 시 자동 반영 (별도 재계산 불필요)
- 옛 설정에 필드 없을 때(`undefined`)도 기본 표시로 안전 폴백

### Note
- 패널을 숨긴 상태에서도 노드 이름 편집은 더블클릭/F2로 가능
- 단, 색상·메타데이터(날짜/노력/비용) 편집은 패널이 필요하므로, 그 작업을 할 땐 다시 패널을 켜야 함

### Process
- 단위 테스트로 토글 로직 검증: undefined/true/false 각각의 렌더 여부와 클래스 결정

---

## [3.9.1] - 2026-05-29

### Added
- **타이머 마지막 1분 빨강↔파랑 점멸** — 남은 시간이 60초 이하가 되면 칩 전체가 1.2초 주기로 빨강과 파랑을 오가며 점멸. 마감 임박 강한 시각 신호
- 점멸 상태에선 글자도 흰색으로 자동 전환 → 가독성 유지

### Technical Notes
- 발동 조건: `running` 상태 + 남은 시간 `> 0` + `≤ 60000ms`
  - 0초·음수에선 발동 안 함 (종료 직전·후 시각 충돌 방지)
  - paused/done/idle에선 발동 안 함
- CSS `@keyframes timer-urgent`로 구현 (JS interval 안 씀, 가벼움)
- CSS specificity 정리: `.timer-chip.urgent`가 `.timer-chip.running` 다음에 선언되어 자연스럽게 덮어씀

### Process
- 단위 테스트 13개 케이스 통과: 경계(60초 정확히) / 0초·음수 / 다른 상태 / null 값 등

---

## [3.9.0] - 2026-05-29

### Added
- **타이머 기능** — 브레인스토밍 시간 제약을 위한 카운트다운 타이머
  - **헤더 칩**: 시간 표시 + ▶/⏸ 시작/일시정지 토글 + ↺ 리셋 버튼
  - **상태별 시각 표시**:
    - `idle` (시작 전): 기본 색
    - `running` (진행 중): 주황 강조
    - `paused` (일시정지): 회색
    - `done` (종료): 네이비 배경 + 깜빡임 애니메이션
  - **종료 알림**: 토스트 메시지 "⏰ 타이머 종료!" + 칩 깜빡임 (5회)
- **설정 모달에 타이머 섹션**:
  - 프리셋 버튼 5/10/15/25/30분 (25분은 포모도로용)
  - 직접 입력 (1~120분)
  - 설정값은 `settings.timerMinutes`로 영구 저장

### Technical Notes
- 정확한 카운트다운을 위해 **목표 종료 시각**(`timerEndAt`) 저장 + 매 틱마다 `Date.now()`와 차이 계산
- 250ms 간격 갱신으로 부드러운 표시
- 백그라운드 탭에서 `setInterval`이 느려져도 정확한 종료 시점 보장
- 일시정지 시 남은 시간을 별도 저장(`timerRemainingMs`), 재개 시 새 종료 시각으로 변환
- 옛 설정 누락 시 기본값 10분으로 안전 폴백

### Kept
- 진행 중인 타이머 상태는 세션 내에서만 유효 (페이지 새로고침 시 리셋)
  - 작업 트리/텍스트는 IndexedDB에 저장되지만, 타이머는 의도적으로 휘발성 (사용자가 "어, 타이머 켜져있었네" 모르고 시간 지나가는 것 방지)

### Process
- 단위 테스트 5개 시나리오 통과: 시간 포맷 / 카운트다운 / 일시정지·재개 정확성 / 설정 변경 / 잘못된 값 방어
- 특히 일시정지/재개 검증: "3분 진행 → 2분 대기(카운트 안 됨) → 7분 재개 = 정확히 0:00 종료" 흐름 확인

---

## [3.8.1] - 2026-05-29

### Fixed
- **새 노드가 모두 네이비로 만들어지는 버그** — 루트의 색이 `navy`(항상 truthy)라서 `parent.color || PALETTE_ORDER[...]` 식의 폴백이 작동 안 함. 새 자식이 무조건 navy → 그 자식도 navy → 트리 전체가 navy로 통일되던 문제
- `addChild`/`addSibling`이 `colorForMovedNode(parent, tree)` 헬퍼를 사용하도록 통일:
  - **부모가 루트**면 팔레트에서 미사용 색 우선 (navy 회피)
  - **일반 부모**면 부모 색 상속 (가지 통일감)

### Process
- 사용자 보고("색깔이 왜 다 똑같지?") 받은 직후 원인 파악 → `parent.color || ...`의 falsy 함정 (navy는 truthy)
- 단위 테스트 4개 시나리오 통과: 7가지 다양화 / 팔레트 순환 / 부모 색 상속 / 옛 버전 vs 새 버전 비교

### Note
- **이미 만들어진 마인드맵의 navy 색은 유지됩니다** (사용자가 의도적으로 색칠했을 수도 있어서 자동 보정 안 함). 새로 추가하는 노드부터 다양한 색으로 생성됨. 옛 노드 색을 바꾸려면 노드 선택 후 우측 패널에서 직접 색 변경 필요

---

## [3.8.0] - 2026-05-29

### Added
- **자식 노드 접기/펼치기** — 자식이 있는 노드에 호버하면 자식이 뻗는 방향 면 바깥에 토글 버튼 (`−` 또는 숫자) 표시
  - 펼침 상태: `−` 표시, 호버 시에만 보임
  - 접힘 상태: 자식 수가 표시(예: `3`), 항상 보여 "여기 숨은 자식 있음" 알림 (9개 초과 시 `9+`)
- **Space 키 단축키** — 선택된 노드의 자식 토글
- **`walkVisible(root, fn)` 헬퍼** — 접힌 자식을 건너뛰는 순회 함수. 렌더링 전용
- **`toggleCollapse(id)` 핸들러** — 단일 진입점으로 클릭/키보드 모두 처리

### Changed
- `layoutTree`의 `measure`/`place`가 접힌 노드의 자식을 건너뜀 (자식 측정·배치 안 함 → 빈 공간 안 차지)
- 연결선과 노드 렌더가 `walkVisible` 사용 → 접힌 자식의 선과 노드 모두 숨김
- `addChild`/`addSibling`이 접힌 부모에 자식 추가 시 자동 펼침 (안 그러면 추가한 자식이 안 보임)
- `navigateToNode('right')`이 접힌 노드의 자식으로 이동 막음 (화면에 없으니까)
- `preserveMetadata`가 텍스트 동기화 시 `collapsed` 상태도 보존

### Kept
- 루트는 접힘 무시 — 루트가 접히면 화면 비니까 안전망
- 자식 없는 노드의 `collapsed`는 의미 없음 (UI도 자동 숨김)

### Process
- 단위 테스트 7개 시나리오 통과: walkVisible / walk 비교 / 루트 무시 / 토글 / 깊은 접힘 / 자식 없는 노드 / 자동 펼침

---

## [3.7.2] - 2026-05-29

### Fixed
- **편집 중 Enter가 형제 추가까지 발동되는 버그** — 노드 라벨을 편집하고 Enter로 마무리하면 그 노드 아래에 빈 형제 노드가 함께 추가되는 문제. 한글 IME 조합 종료와 React 이벤트 시스템 + window native listener의 타이밍 충돌이 원인
- **전역 키 핸들러에 강화된 가드 추가**:
  - `editingId` 체크 — 노드 편집 중이면 전역 단축키 모두 비활성화 (가장 강력한 방어선)
  - `e.isComposing` / `keyCode 229` 체크 — 한글 IME 조합 중 Enter 무시
- **NodeView input 핸들러에도 IME 가드 추가** — 조합 중 Enter는 finish() 호출 안 함 (한글 마지막 글자 확정과 충돌 방지)

### Process
- 사용자 스크린샷에서 "오늘 만난 사람" 노드가 편집 후 형제 노드 추가됨 → 한글 IME 시나리오 발견
- 단위 테스트 7개 시나리오로 가드 동작 검증
- 근본 원인: React SyntheticEvent의 `stopPropagation`은 window native listener를 막지 못함. React onKeyDown이 IME로 skip되는 동안 window listener가 Enter를 정상 키로 처리해서 형제 추가가 발동된 것

---

## [3.7.1] - 2026-05-29

### Added
- **노드 이동 시 가지 전체 색 통일** — outdent / indent / 드래그로 노드를 다른 부모 아래로 이동하면 그 노드와 모든 자손의 색이 새 부모의 색으로 자동 통일
- **`colorForMovedNode(newParent, treeRoot)` 헬퍼** — 새 색 결정 로직
  - 일반 부모: 그 부모의 색을 그대로 사용
  - 루트로 이동: 기존 루트 자식이 안 쓰는 팔레트 색 우선 (네이비는 루트 전용이라 회피)
- **`applyColorToBranch(node, color)` 헬퍼** — 가지 전체에 같은 색 일괄 적용

### Changed
- 3개 이동 경로(outdent / indent / 드래그) 모두 동일하게 색 통일 적용 — 일관성 확보
- `pinnedSide` / `autoSide` 제거와 함께 색 적용도 부모 변경 후처리에 통합

### Process
- 단위 테스트 5개 시나리오 통과: 일반 부모 / 가지 전체 / 루트로 이동 / 팔레트 포화 / 사용자 보고 케이스 재현

---

## [3.7.0] - 2026-05-29

### Added
- **Alt + ← / →** 키보드 단축키로 계층 이동 (outdent / indent)
  - **Alt + ←** : 한 단계 바깥으로 (부모의 형제가 됨, 부모 바로 다음 위치)
  - **Alt + →** : 한 단계 안쪽으로 (이전 형제의 자식이 됨, 마지막 자식 위치)
  - 위/아래(순서)와 좌/우(계층)의 직관적 짝 — Word/Notion/Workflowy 등에서 익숙한 패턴
- **`outdentNode(id)` / `indentNode(id)` 함수** — 트리 조작 + 부모 변경 + 좌/우 지정 정리 + 히스토리 기록

### Changed
- 부모가 바뀌는 모든 경로(드래그 / outdent / indent)가 동일하게 `pinnedSide`/`autoSide` 자동 제거 — 새 위치에서 다시 결정되도록
- 우측 패널 단축키 안내에 새 단축키 추가, 기존 항목도 설명 보강

### Edge Cases Handled
- 루트는 부모가 없으므로 outdent 불가 (무시)
- 루트의 직계 자식을 outdent하면 "더 이상 바깥으로 이동할 수 없습니다" 토스트
- 첫째 자식은 이전 형제가 없으므로 indent 시 "이전 형제가 없어 안쪽으로 이동할 수 없습니다" 토스트
- textarea/input 포커스 시엔 브라우저 기본 동작(단어 단위 이동) 유지 — 가드 이미 존재

### Process
- 단위 테스트 7개 시나리오 통과: 일반 outdent / 루트 자식 막힘 / indent / 첫째 막힘 / 좌/우 지정 제거 / 연속 indent로 깊이 만들기 / 연속 outdent로 위로

---

## [3.6.0] - 2026-05-29

### Added
- **새 노드 트렌디 단어** — Tab/Enter로 새 노드를 만들 때 "새 항목"/"새로운 아이디어 01" 대신 영감 있는 단어가 랜덤으로 채워짐
  - **`SAMPLE_IDEA_WORDS` 200개 큐레이션** — 영감/창의, 액션/실행, 감성/관계, 트렌디/라이프스타일, 일상/관찰 5개 카테고리, 각 40개
  - **연속 중복 방지** — 최근 5개 안에 사용한 단어는 회피
  - 너무 길지 않은 단어로 큐레이션 (대부분 10자 이내, 노드에 한 줄로 들어감)
- **`settings.ideaWordSource`** — `'sample'` (기본만) / `'custom'` (내 단어만) / `'both'` (둘 다 섞기) 격언과 동일한 3단계
- **`settings.customIdeaWords`** — 사용자가 직접 단어 추가/삭제 가능
- **`pickRandomIdeaWord(settings, recentWords)`** — 풀 결정 + 최근 회피 + 안전 폴백 헬퍼

### Changed
- `addChild`/`addSibling`에서 자동 라벨 생성 로직 변경: `nextIdeaLabel()` (번호) → `pickRandomIdeaWord()` (단어)
- `QuoteEditor` 컴포넌트 일반화 — `label`/`placeholder`/`emptyText` props 추가로 격언과 단어 양쪽에 재사용
- 옛 사용자 설정에 `ideaWordSource`/`customIdeaWords` 누락 시 기본값 자동 보정

### Kept
- `_autoLabel` 플래그 메커니즘은 그대로 — ESC 취소, Blur 취소 동작 보존
- 사용자가 라벨을 한 글자라도 편집하면 `_autoLabel` 해제되어 일반 노드로 전환

### Process
- 단위 테스트 8개 시나리오 통과: 풀 선택 / 폴백 / 최근 회피 / 빈 풀 / 분포 균일성

---

## [3.5.3] - 2026-05-29

### Added
- **자동 번호 라벨** — 새 노드의 기본 라벨이 "새 항목" → **"새로운 아이디어 01"**, "새로운 아이디어 02" 같은 자동 번호로 변경
  - 트리 전체에서 가장 큰 번호 + 1로 부여 (충돌 방지)
  - 사용자가 직접 "새로운 아이디어 10"이라고 지어도 다음은 11로 (카운트 포함)
  - 빈 자리는 채우지 않음 (예: 02를 지워도 다음은 04). 예측 가능성 우선
  - 두 자리 zero-padded 형식 (01, 02, ..., 09, 10, 11)
- **`_autoLabel` 플래그** — 자동 생성된 라벨을 사용자가 한 번도 안 만진 상태를 추적
  - 사용자가 라벨을 편집하면 자동으로 플래그 제거 → 일반 노드로 전환
  - JSON 저장 시 `serializeTree`가 임시 필드처럼 정리

### Changed
- ESC 취소 판정 강화: "빈 라벨" 또는 "`_autoLabel` 상태에서 입력 안 함" 둘 중 하나 → 노드 삭제
- Blur(포커스 잃음) 판정도 동일: 자동 라벨을 안 만지고 다른 곳 클릭하면 자동 삭제

### Process
- 단위 테스트 7개 시나리오 통과 (번호 생성, 충돌, ESC, Blur)

---

## [3.5.2] - 2026-05-29

### Added
- **노드 삭제 후 자동 선택 이동** — 노드를 지우면 자동으로 이전 형제(위쪽)가 선택됨. 마우스 클릭 없이 키보드만으로 연속 삭제 가능
- 선택 우선순위: 이전 형제 → 다음 형제 → 부모 (외동이었을 때)

### Fixed
- 노드 삭제 시 `setSelectedId(null)`로 선택을 잃어버려, 다음 작업을 위해 매번 마우스 클릭이 필요했던 문제

### UX
- 작업 흐름 개선: 삭제 → Delete → Delete (연속), 또는 삭제 → F2 (즉시 편집), 또는 삭제 → Enter (즉시 형제 추가) 가 모두 키보드만으로 가능

---

## [3.5.1] - 2026-05-29

### Added
- **`autoSide` 메커니즘** — 자동 분배가 한 번 결정한 좌/우 위치를 노드에 영구 기록. 같은 트리 구조면 같은 위치 유지
- 우선순위: `pinnedSide` (사용자 명시) > `autoSide` (자동 분배 기록) > 새 분배

### Fixed
- **Enter로 형제 추가 시 마인드맵 점프 버그** — 새 형제 노드가 `autoSide` 없이 추가되어 자동 분배에서 왼쪽으로 분류되고, 그 결과 트리 전체 좌표가 시프트되며 점프하던 문제. 옆 형제(current)의 `pinnedSide`/`autoSide`를 새 노드에 즉시 상속하도록 수정
- `addChild`도 같이 개선 — 부모가 루트면 기존 형제들의 다수파(오른쪽 vs 왼쪽)를 따라가도록

### Changed
- `serializeTree`가 모든 레이아웃 임시 필드(`_x`, `_y`, `_w`, `_h`, `_subH`, `_subW`, `_side`)를 깨끗하게 제거
- `pinnedSide` + `autoSide` 모두 JSON 저장·복원·텍스트 동기화(`preserveMetadata`)에서 보존
- 드래그로 부모 변경 시 `autoSide`도 함께 제거 (새 위치에서 다시 결정)

### Process
- 첫 시도(`autoSide` 메커니즘만)로는 버그가 잡히지 않아, 사용자 보고("F2는 정상, Enter는 점프")를 받은 뒤에야 실제 원인(새 노드의 autoSide 미부여)을 정확히 파악함

---

## [3.5.0] - 2026-05-29

### Added
- **🤖 AI 요약 기능** — 헤더 버튼 한 번으로 마인드맵을 AI 채팅 도구에 보내기
  - 클립보드에 프롬프트+마크다운 자동 복사
  - 선택한 AI 서비스(ChatGPT / Claude / Gemini)의 새 채팅 화면을 새 탭으로 열기
  - 사용자는 Ctrl+V로 붙여넣기만 하면 됨
- **설정에서 AI 서비스 선택** — ChatGPT / Claude / Gemini 중 사용할 서비스 지정
- **프롬프트 템플릿 커스터마이징** — 설정 모달에서 자유 편집. `{tree}` 토큰 위치에 마인드맵 마크다운 자동 삽입
- **"↺ 기본 프롬프트로 되돌리기" 버튼** — 사용자가 수정했다가 원래로 돌아가고 싶을 때
- **`copyToClipboard` 헬퍼** — modern Clipboard API + execCommand fallback. file:// 프로토콜이나 권한 거부 시에도 동작

### Changed
- API 키 노출 위험 없는 "복사+새 탭" 방식 채택 — 정적 호스팅 구조 유지
- 기존 사용자 설정에 `aiService`, `aiPrompt` 누락 시 기본값 자동 보정

### Design Decisions
- **백엔드 없이 AI 연동**: API 직접 호출은 키 노출 위험이 있어 거부. 사용자가 자기 AI 계정으로 직접 받는 방식이 안전+무료
- **3가지 AI 동시 지원**: 사용자가 가입한 서비스 / 좋아하는 서비스로 선택 가능

---

## [3.4.0] - 2026-05-29

### Added
- **노드에 ‹ › 좌/우 이동 버튼** — 루트의 직계 자식 노드에 호버하면 양 옆에 작은 화살표 버튼이 나타남. 클릭으로 바로 좌/우 고정. 우측 패널까지 가지 않아도 됨
- **토글 동작** — 같은 방향 버튼을 다시 누르면 고정 해제 (자동 분배로 복귀)
- **활성 상태 시각화** — 현재 고정된 방향의 버튼은 호버하지 않아도 강조 표시되어 항상 보임

### Changed
- 루트 직계 자식 판정에 `Set` 사용 — `O(1)` lookup으로 매 렌더마다 효율적
- NodeView가 `isRootChild`, `onSetSide` props를 받음

---

## [3.3.0] - 2026-05-29

### Added
- **노드 좌/우 수동 고정** — 우측 패널의 "순서 / 구조" 섹션에 `← 왼쪽` / `오른쪽 →` 버튼 추가. 사용자가 직접 노드를 한쪽으로 보내면 자동 분배가 그 결정을 덮어쓰지 않음
- **`pinnedSide` 속성** — 노드 데이터에 'left' | 'right' 저장. JSON 저장·복원·텍스트 동기화에서 보존
- **"↺ 자동 분배로 되돌리기" 버튼** — 고정을 해제하고 자동 분배에 맡김 (선택된 노드에 `pinnedSide`가 있을 때만 표시)
- **현재 고정 상태 시각화** — 고정된 방향 버튼이 강조 표시됨

### Changed
- 자동 분배 로직이 `pinnedSide` 우선 처리하도록 개선
  1. 수동 지정 자식들의 오른쪽 누적 높이를 먼저 계산
  2. 미지정 자식들은 남은 오른쪽 공간을 채우다가 넘치면 왼쪽
  3. 입력 순서는 모든 경우에 보존
- 드래그로 부모가 바뀌면 `pinnedSide` 자동 제거 (새 위치에서 다시 결정)
- 좌/우 고정 동작도 Undo/Redo 히스토리에 기록됨

---

## [3.2.0] - 2026-05-29

### Added
- **양방향 마인드맵 레이아웃** — 루트의 자식들이 한쪽으로만 길게 늘어지지 않고 좌/우로 자동 분배. 오른쪽 누적 높이가 800px(한 화면)을 넘으면 그다음 자식부터 왼쪽으로 배치. 양쪽 다 넘으면 계속 왼쪽에 쌓음
- **`_side` 속성** — 각 노드가 'left' 또는 'right' 방향 정보를 가지며, 자식들에게 상속
- **양방향 연결선** — 왼쪽 자식은 부모 좌측면 → 자식 우측면으로 베지어 곡선 그리기 (화면·SVG 출력 모두)

### Changed
- `layoutTree`가 측정/분배/배치 3단계로 분리됨 (가독성·확장성 개선)
- `_subW`(가지 전체 너비) 측정 추가 — 향후 충돌 검사·X 정렬 활용 가능

---

## [3.1.0] - 2026-05-29

### Added
- **구글 캘린더 일정 제목 설정** — 설정 모달의 "구글 캘린더" 섹션에서 일정 이름을 자유롭게 변경 가능. 빈 값/공백은 자동으로 기본값("브레인스토밍")으로 폴백
- **GitHub Pages 배포용 `index.html`** — 작업본과 100% 동일한 사본을 배포용으로 자동 생성. 매 배포마다 md5 해시 일치 확인

### Changed
- `buildGoogleCalendarUrl(root, title)`로 시그니처 변경 — 외부에서 일정 제목 주입 가능

### Fixed
- 옛 사용자 설정(`calendarEventTitle` 필드 없음) 자동 보정 — 설정 로드 시 누락 시 기본값으로 채움

---

## [3.0.0] - 2026-05-28 (캘린더 + 패딩 최적화)

### Added
- **📅 구글 캘린더에 추가** — 헤더 버튼 한 번으로 현재 마인드맵을 오늘 종일 일정으로 캘린더에 등록. 트리를 마크다운으로 변환 후 `calendar.google.com/calendar/render` URL로 새 탭 열기
- **`treeToMarkdown()`** — 루트=h1, 1뎁스=h2, 그 아래=들여쓰기 불릿. 아이콘/메타데이터/통계 포함
- **URL 길이 자동 점검** — 7,500자 초과 시 토스트로 경고 (구글 캘린더 ~8KB 제한 대비)
- **새 노드 ESC 취소** — Tab/Enter로 만든 빈 노드를 ESC로 취소하면 노드 자체가 사라짐. 직전 히스토리도 pop해서 Undo 스택 노이즈 제거. 포커스 잃을 때도 같은 동작

### Changed
- **노드 박스 패딩 축소** — 좌우 22→11px, 상하 14→9px (요청에 따라 절반 수준으로). 화면 CSS와 SVG 출력 양쪽 일관 적용
- 레이아웃 상수 동기 조정: `NODE_PAD_X` 44→22, `NODE_H` 56→44, `NODE_MIN_W` 140→120

### Fixed
- **`addChild`/`addSibling`의 빈 라벨 처리** — `opts.label || '새 항목'`이 falsy 함정으로 빈 문자열을 `'새 항목'`으로 바꾸던 버그. `opts.label !== undefined ? opts.label : '새 항목'`으로 수정. **이 버그가 ESC 취소가 안 되던 진짜 원인**

### Process
- 단위 테스트 도입 — 사용자에게 전달 전 Node.js로 핵심 로직을 실제 실행해 검증. 직전 "ESC 취소 안 됨" 사건의 교훈

---

## [2.1.0] - 2026-05-28 (격언 + 노드 미세 조정)

### Added
- **오늘의 격언** — 좌측 패널 위쪽에 매일 바뀌는 격언 표시. 날짜 기반 인덱스(`dayIndex`)로 같은 날엔 같은 격언, 매일 자동 순환
- **200개 샘플 격언** — 공공영역/위인 명언 큐레이션 (아리스토텔레스, 공자, 노자, 아인슈타인, 링컨, 처칠, 간디, 잡스, 다빈치, 괴테, 워런 버핏 외). 저작권 안전
- **사용자 격언 관리** — 설정 모달에 `QuoteEditor` 컴포넌트 추가. 직접 격언 추가/삭제, Enter로 입력
- **격언 출처 3가지** — 기본 격언 / 내 격언만 / 둘 다 섞기

### Changed
- **좌측 패널 안내 문구 제거** — "들여쓰기(2칸)로..." 안내를 제거하고 그 자리에 오늘의 격언 카드 배치
- **격언 카드 위아래 구분선** — 패널 헤더 border와 대칭이 되도록 격언을 `today-quote-wrap`으로 감싸 아래쪽 구분선 추가

---

## [2.0.0] - 2026-05-28 (아이콘 시스템)

### Added
- **노드 이모지 아이콘** — 7개 카테고리, 47개 이모지를 노드에 붙일 수 있음
  - 우선순위 (1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣)
  - 상태 (✅ ☑️ ⬜ 🔲 ⏳ 🚧 ✔️ ❌)
  - 중요도 (⭐ 🔥 ❗ ‼️ 🔝 ⏫ 🔺)
  - 감정/반응, 분류, 기호, 활동
- **카테고리당 1개 제한** — 같은 카테고리에서 다른 아이콘을 클릭하면 자동 교체. `iconCategoryOf` + `sortIconsByCategory`로 정렬 자동화
- **우측 패널 아이콘 팔레트** — 노드 선택 후 카테고리별 그리드에서 클릭으로 추가/제거
- **PDF/JPG/SVG 출력에 아이콘 포함** — 노드 위쪽에 아이콘 줄로 렌더링

### Changed
- 아이콘이 포함된 노드는 너비/높이 자동 확장
- 텍스트→트리 동기화 시 `preserveMetadata`가 색상·메타뿐 아니라 **아이콘도 라벨 경로 기준으로 보존**

### Removed
- **노드 호버 ☺ 버튼 + 인-캔버스 아이콘 picker 팝업** — 다른 노드를 가려서 사용성을 해치는 문제로 제거. 우측 패널 팔레트만 사용하는 단일 흐름으로 통일 (옵션 A 결정)

---

## [1.5.0] - 2026-05-28 (가변 노드 + 중앙 정렬)

### Added
- **가변 노드 크기** — 라벨 길이/줄바꿈/아이콘 개수에 맞춰 노드 너비·높이 자동 조정
- **한글 폭 추정** — `estimateTextWidth`가 CJK 1.0em / 영문 0.55em 비율로 계산
- **`wrapLabel` 자동 줄바꿈** — 단어 단위 → 글자 단위로 폴백, 박스 안에서 라벨 자동 줄바꿈
- **맵 중앙 정렬** — `map-wrapper`(줌 적용 실제 크기) + flex 중앙 정렬. 화면 좌상단이 아니라 가운데에 다이어그램 표시

### Changed
- SVG 출력도 `<tspan>` 멀티라인으로 라벨 줄바꿈 지원

---

## [1.4.0] - 2026-05-28 (자동 들여쓰기 + 그 외)

### Added
- **textarea 자동 들여쓰기** — 들여쓰기된 줄에서 Enter 시 같은 들여쓰기 유지. 한글 IME 조합 중(`isComposing`)에는 가로채지 않음
- **시작 시 textarea 자동 포커스** — 커서를 두 번째 줄 첫 칸에 위치. 이중 rAF + setTimeout(30ms)로 React 커밋 후 보장
- **JPG/SVG 저장** — 5가지 형식(PDF/JPG/SVG/CSV/JSON) 완비. `svgToRaster`로 PNG/JPEG 변환
- **저장 버튼 표시 설정** — 헤더에 어떤 형식 버튼을 보여줄지 설정 모달에서 선택

### Changed
- 한글 깨짐 방지를 위해 PDF 생성을 **SVG → PNG → PDF** 방식으로 전환 (이미지로 삽입)

### Removed
- 폴더 지정 자동저장 기능 — File System Access API 제약으로 제거 (다운로드 방식만 유지)

---

## [1.3.0] - 2026-05-28 (UX 개선)

### Added
- **루트 노드 자동 라벨** — "2026년 5월 28일 + 슬로건" 형식으로 매번 생성 (`generateRootLabel`, `formatTodayKR`)
- **새로 시작 버튼** — Ctrl+Z로 복구 가능. 새 명언과 함께 빈 다이어그램 시작
- **모든 다이얼로그 키보드 지원** — Enter(확정)/Esc(취소). 다이얼로그 열림 시 전역 단축키 비활성화 가드
- **파비콘** — BrainBloom 브랜드 마크 (네이비 중심 노드 + 컬러풀 가지). 인라인 SVG data URL

### Changed
- 다이어그램 시작 노드를 고정값 "Brainstorm"이 아니라 동적 슬로건으로

---

## [1.2.0] - 2026-05-28 (키보드 + 패닝)

### Added
- **화살표 키 노드 이동** — ←(부모) →(첫 자식) ↑↓(형제). `scrollNodeIntoView`로 선택 노드 자동 스크롤
- **빈 공간 드래그 패닝** — 지도 앱처럼 화면 이동. 3px threshold로 클릭과 구분
- **휠 줌** — Ctrl/⌘+휠 또는 트랙패드 핀치. 마우스 위치 기준 확대/축소

---

## [1.1.0] - 2026-05-27 (Undo + 자동 저장)

### Added
- **Undo/Redo** — Ctrl+Z / Ctrl+Shift+Z. history/future 스택 (최대 100). `maybePushHistory(label, coalesceKey)` + 800ms 합치기로 연속 변경 묶음
- **시작 다이얼로그** — 어제(IndexedDB `lastWork`) 작업이 있으면 복원/새 파일 선택
- **명언 배너** — 새 파일 시작 시 짧은 한 줄 격언 표시
- **설정 모달** — `visibleSaveButtons`, `filenameBase`, `startupBehavior` (ask/restore/new) 관리. IndexedDB 저장
- **다이어그램 자동 저장** — beforeunload + 디바운스(1.5s)로 트리를 IndexedDB에 백업

### Removed
- 자동 파일 저장 기능 — 사용자 요청으로 제거

---

## [1.0.0] - 2026-05-27 (초기 릴리즈)

### Added
- **단일 HTML 파일 마인드맵 도구** — React 18 + Babel(브라우저 컴파일), 외부 백엔드 없음
- **양방향 동기화** — 텍스트 입력과 다이어그램이 자동 양방향 갱신. `syncSourceRef`로 방향 제어
- **들여쓰기/하이픈 파서** — 2칸 들여쓰기 또는 `AA-A` 하이픈 표기로 계층 구조 파싱
- **인라인 노드 편집** — Tab(자식+즉시 입력), Enter(형제+즉시 입력), F2/더블클릭(편집), Esc(취소)
- **드래그 앤 드롭** — 노드 끌어서 부모 변경. `isDescendant`로 순환 참조 차단
- **순서 이동** — 우측 ↑↓ 버튼 + Alt+↑↓ 단축키
- **PDF/CSV/JSON 저장** — jsPDF + 커스텀 변환
- **컬러 팔레트** — 14색 (네이비/오렌지/앰버/틸/블루/로즈/모스/슬레이트/플럼/러스트/포레스트/차콜/골드/코랄)
- **메타데이터 필드** — 날짜/작업량/비용
- **줌 컨트롤** — 0.2x~2x, 키보드/버튼

### Design
- **Fraunces + Plus Jakarta Sans + JetBrains Mono** — 글꼴 조합
- **베이지 배경(#f6f3ec) + 네이비 루트** — 차분한 톤
- **도트 그리드 + 색상 hint 그라데이션** — 캔버스 배경

---

## 참고 — 버전 분기 이력

이 프로젝트는 한 차례 버전 분기를 거쳤습니다:

- **v2 동결 (`html01.html`)** — 2026-05-28, 캘린더 기능 추가 이전 시점 보존
- **v3 작업본 (`brainstorm.html` / `index.html`)** — 현재 활성 버전

`html01.html`은 안전 백업 용도로 보존되며 더 이상 수정되지 않습니다.

---

## 향후 검토 항목

- 외부 CDN 의존 제거 (오프라인 지원) — React/Babel/jsPDF 내장화
- 클라우드 저장 옵션 (현재는 IndexedDB만)
- 협업 기능 (실시간 멀티 사용자 편집)
- 모바일 터치 최적화
- 다국어 지원 (현재 한국어 중심)
