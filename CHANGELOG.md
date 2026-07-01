# Changelog

BrainBloom의 모든 변경사항이 이 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)을 따르며,
이 프로젝트는 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)을 준수합니다.

---

## [Unreleased]

향후 추가 예정인 기능이 여기에 기록됩니다.

---

## [3.86.2] - 2026-06-29

### Changed
- **문서 관리자 `☁ Google Drive` 목록: 기본은 최신본만, "🗂 백업 보기" 토글** — Backup 폴더로 옮겨진 이전 버전들이 목록을 가득 채우던 문제. 드라이브 뷰가 기본적으로 `_backup === false`(메인 최신본)만 표시하고, 툴바의 `🗂 백업 보기` 버튼을 켜면 Backup 파일까지 함께 보여준다. 레일의 Google Drive 개수 배지·빈 상태 안내도 토글을 반영. 관리자를 열 때마다 토글은 꺼진 상태로 초기화.

### Technical Notes
- 신규 상태 `showDriveBackups`(기본 false). 드라이브 파일 렌더 필터에 `.filter(f => showDriveBackups || !f._backup)` 추가. `loadDriveDocs`는 그대로 메인+Backup을 모두 받아오고(토글은 표시만 제어), 열기/가져오기/미리보기는 백업 파일도 `id`로 동일 동작.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.86.2.html`(스냅샷), `CHANGELOG.md`.

---

## [3.86.1] - 2026-06-29

### Fixed
- **드라이브 Backup 이동이 다른 접두어(리조트) 파일을 안 옮기던 문제** — `runVersionedSave`의 이동/정리가 현재 브라우저 접두어와 일치하는 파일(`parseDriveFileName(...,prefix)`)만 대상으로 해, 다른 브라우저/세션 코드명(예: 마우이·마이애미·모나코)으로 저장된 기존 파일이 메인 폴더에 그대로 남았다. `drive.file` 범위라 폴더엔 앱이 만든 파일만 존재하므로, **접두어 필터를 제거**하고 (방금 저장본·설정파일 제외) **메인의 나머지 전부를 Backup으로 이동**하도록 수정 → 메인엔 최신 1개만 유지.
- **Backup 정리(삭제)를 계열별로** — 전체를 한꺼번에 `keepCount`로 깎지 않고, **같은 이름 계열(버전번호 제외)별로 `keepCount`개씩** 남기고 오래된 것만 삭제. 서로 다른 날짜·작업본 이력을 보존(대량 삭제 방지).

### Technical Notes
- 이동: `movables = after.filter(f => f.id !== saved.id && f.name !== SETTINGS_FILE_NAME)`. 정리: `seriesKey(name)=name.replace(/\.json$/i,'').replace(/[_.]\d+$/,'')`로 그룹화 후 그룹별 `modifiedTime` 오래된 것부터 초과분 삭제.
- 첫 저장 시 기존 메인 파일이 다수면 순차 이동(파일 수만큼 PATCH)이라 잠깐 걸릴 수 있음.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.86.1.html`(스냅샷), `CHANGELOG.md`.

---

## [3.86.0] - 2026-06-16

### Changed
- **드라이브 저장 구조 개편 — 메인엔 최신 1개, 이전 버전은 `Backup` 하위 폴더로** — 자동·수동 저장 시 새 버전을 메인 `BrainBloom` 폴더에 저장한 뒤, 메인의 다른 같은-형식 파일들을 **`BrainBloom/Backup/`으로 이동**한다. 그래서 메인 폴더는 항상 **가장 최신 1개만** 깔끔하게 유지. `Backup`은 설정의 **보관 개수(`driveKeepCount`, 기본 5)** 를 넘으면 오래된 것부터 삭제.
- **불러오기 시 메인 + Backup 병합** — 문서 관리자의 `☁ Google Drive` 목록과 설정의 `⬇ 불러오기 목록`이 **메인과 Backup을 합쳐** 같은 이름은 최신만, 최신순으로 보여준다. 백업 항목은 `백업` 배지로 구분(관리자). → 두 폴더를 비교해 항상 최신을 보여줌.

### Technical Notes
- 신규 헬퍼: `driveFindBackupFolder`(없으면 null, 생성 안 함) · `driveGetOrCreateBackupFolder` · `driveListBackupFiles` · `driveMoveFile`(addParents/removeParents). 모두 `drive.file` 범위(앱이 만든 폴더/파일만).
- `runVersionedSave` 재작성: ①새 버전 메인 저장 → ②메인의 나머지 우리-형식 파일을 Backup으로 이동(`saved.id`로 새 저장본 식별, id 없으면 재배치 건너뜀) → ③Backup `modifiedTime` 오래된 것부터 keep 초과분 삭제. **충돌 감지가 의존하는 `driveListFiles()`(메인만 반환)는 그대로 둬** 최신이 항상 메인에 있어 다중기기 비교 로직 유효. (옛 `planPastCleanup`/`filesToDeleteToday`는 미사용.)
- 불러오기 병합: 메인·Backup 목록을 합쳐 `name` 기준 최신만 남기고 `modifiedTime` 내림차순 정렬. 백업 파일도 `driveLoadFileById(id)`로 동일하게 열림.
- 출시 전 데이터-안전 적대적 코드리뷰 반영.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.86.0.html`(스냅샷), `CHANGELOG.md`, `README.md`, `BrainBloom_UserGuide.html`.

---

## [3.85.0] - 2026-06-16

### Added
- **드라이브 목록 정렬** — 문서 관리자의 `☁ Google Drive` 뷰에 정렬 드롭다운 추가: **최신순 · 오래된순 · 이름순 · 크기순**. (로컬 문서 정렬과 동일한 위치·스타일)
- **문서 태그 · 메모** — 각 문서에 **태그(여러 개)** 와 **메모**를 달 수 있다. 관리자 카드의 `🏷` 버튼으로 편집:
  - **태그**: 칩 입력(Enter/쉼표로 추가, ×로 삭제, 빈칸 Backspace로 마지막 삭제, 최대 12개·24자). 카드에 `#태그`로 표시되고 **클릭하면 그 태그로 빠른 검색**.
  - **메모**: 여러 줄 메모(최대 500자), 카드에 한 줄 요약으로 표시.
  - **검색**이 이름·가지뿐 아니라 **태그·메모까지** 매칭. 태그/메모는 문서와 함께 저장되어 새로고침 후에도 유지.

### Technical Notes
- 드라이브 정렬은 `driveSort` 상태로 클라이언트 정렬(목록을 `.slice().sort()` — 원본 불변, `modifiedTime`/`size` 누락 안전 처리).
- 문서 모델에 `tags:string[]`·`memo:string` 추가(하위호환: `normalizeDocItem`이 옛 항목에 기본값 채움, 길이/개수 정규화). 신규 헬퍼 `patchDocItem`·`addDocTag`·`removeDocTag`. 편집 상태는 단일 `editingMetaDocId`+`tagDraft`/`memoDraft`(한 번에 하나만), 메모는 `onBlur`+완료+토글+관리자 닫기 모든 경로에서 커밋(미저장 손실 방지). `writeActiveDoc`(자동저장)은 항목 리맵 시 `...d` 전개로 태그·메모 보존. 생성/복제/가져오기 항목에 기본값(복제는 원본 태그·메모 복사).
- 출시 전 적대적 코드리뷰 반영.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.85.0.html`(스냅샷), `CHANGELOG.md`, `README.md`, `BrainBloom_UserGuide.html`.

---

## [3.84.0] - 2026-06-16

### Added
- **문서 관리자 → 구글 드라이브에서 읽어오기** — 관리자 왼쪽 레일에 `☁ Google Drive` 소스 추가. 워드·파워포인트의 "열기"처럼 드라이브에 저장된 마인드맵을 골라 **현재 문서를 덮지 않고 새 문서로 가져온다.**
  - **미연결 시** 안내 + `☁ Google Drive 연결` 버튼(기존 `handleDriveSignIn`/`drive.file` 범위 재사용).
  - **파일 카드**: 이름 · 수정일 · 크기(KB). **클릭=미리보기**(노드 수·중심 주제·상위 가지 칩·본문 일부), **더블클릭=열어서 편집**.
  - **📂 열기**(가져와 바로 열고 관리자 닫기) / **📥 가져오기**(새 문서로만 추가) / **🔄 새로고침** / 이름 검색. 가져온 파일엔 `가져옴` 배지.
  - 로딩·빈 목록·오류·세션 만료(401/403) 상태 처리. 다크모드·모바일 대응.

### Technical Notes
- 기존 드라이브 헬퍼 재사용: `driveListFiles()`(앱 폴더의 JSON, 최신순)·`driveLoadFileById(id)`. 파싱은 `JSON.parse → data.tree||data → sanitizeTree → walk(meta)/assignDefaultColors`로 기존 "불러오기"와 동일. 설정 백업 파일(`SETTINGS_FILE_NAME`)은 목록에서 제외.
- 신규 상태: `driveDocs`(null/'loading'/'error'/배열)·`mgrDrivePreview`·`driveImportedIds`·`driveImportingId`. 신규 함수: `loadDriveDocs`·`previewDriveFileInMgr`·`importDriveFile(file, open)`. 드라이브 소스 진입 시 목록 자동 로드(useEffect, deps `[showDocs, docFolderView, driveSignedIn]`, `driveDocs===null` 가드로 루프 방지). 관리자 열 때 `driveDocs`/`mgrDrivePreview` 초기화로 매번 신선한 목록.
- 가져오기는 로컬 문서로만 추가(IndexedDB `doc:<id>` + `docMeta`), `lastWork` 거울·기존 자동저장 경로 영향 없음. 드라이브 쓰기(저장/삭제/이름변경)는 건드리지 않음 — 읽기 전용 추가.
- 출시 전 적대적 코드리뷰로 확인된 항목 반영.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.84.0.html`(스냅샷), `CHANGELOG.md`, `README.md`, `BrainBloom_UserGuide.html`.

---

## [3.83.0] - 2026-06-16

### Added
- **문서 관리자 (파일 관리)** — 기존 평면 목록 모달을 일반 브레인스토밍 툴 수준의 파일 매니저로 확장. 헤더 `📄 문서` 버튼으로 연다.
  - **폴더 정리**: 왼쪽 레일에서 `전체`·`★즐겨찾기`·`미분류`·사용자 폴더로 분류. 폴더 만들기·이름변경·삭제(삭제 시 문서는 미분류로 이동)·문서 이동(카드의 폴더 셀렉트).
  - **카드 미리보기 그리드**: 각 문서를 카드로 표시 — 이름, 상위 가지 칩, 노드 수, 수정 날짜, 현재 문서 배지, ★고정 토글.
  - **검색·정렬**: 이름·가지 검색, 최근 수정/생성일/이름 정렬(고정 문서는 항상 상단).
  - **복제(⧉)**: 문서를 통째로 복사해 "…사본"으로 새로 만듦.
  - **JSON 새 문서로 가져오기(📥)**: 백업 JSON을 현재 문서를 덮지 않고 새 문서로 추가(기존 "열기"는 현재 문서 교체였음).

### Fixed
- (출시 전 자체 코드리뷰로 발견·수정) 관리자를 연 채 현재 문서를 편집해도 카드 통계가 최신을 보이도록 현재 문서는 라이브 트리에서 노드 수·가지를 계산. 모달 닫기 경로(닫기·Esc·전환·새 문서) 간 상태 초기화 불일치로 재오픈 시 가져오기 안내/폴더 이름편집 잔상이 남던 문제를 열기 시점 초기화로 통일. 터치 기기에서 폴더 ✎/🗑이 안 보이는데 탭되던 오작동 방지(`pointer-events`). 다른 탭에서 폴더 삭제 시 빈 목록에 갇히지 않게 폴더 보기 유효성 보정.

### Technical Notes
- 저장 모델 확장(하위호환): `docMeta.list` 항목에 `createdAt·pinned·folderId·nodeCount·branches` 추가 + `docMeta.folders:[{id,name}]`. `normalizeDocItem`이 옛 항목을 안전히 채움(트리 미접근, 다음 저장 시 통계 자가치유). `persistDocMeta(list,currentId,folders)`는 folders 미전달 시 `docFoldersRef`로 폴백. `writeActiveDoc`는 저장 시 `docStatsOf`로 노드 수·가지를 갱신하며 `createdAt/pinned/folderId` 보존. 신규: `createFolder/commitFolderRename/deleteFolder/moveDocToFolder/togglePinDoc/duplicateDoc/importDocFromFile`, `visibleDocs` 메모(폴더·검색·정렬·고정우선).
- 출시 전 **다차원 코드리뷰 + 적대적 검증**(React/저장/동작/UI/회귀 5축) 후 확인된 7건을 반영.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.83.0.html`(스냅샷), `CHANGELOG.md`, `README.md`, `BrainBloom_UserGuide.html`.

---

## [3.82.2] - 2026-06-15

### Added
- **Shift+←/→로 하위 접기·펼치기 (마인드맵 화면)** — 노드를 고른 상태에서 `Shift`+`←`는 하위 접기, `Shift`+`→`는 펼치기. 평범한 `←`/`→`는 기존대로 노드 사이 이동을 유지한다(충돌 없이 Shift로 구분). 접힌 노드는 숨은 자식 개수 배지로 표시된다.

### Technical Notes
- 맵 keydown 핸들러에 `Shift`+`ArrowLeft/Right` 분기 추가 — `findNode`로 선택 노드를 찾아 자식이 있을 때만, 접힘 상태(`collapsed`)에 따라 기존 `toggleCollapse(id)`를 재사용(접힘→펼치기는 →, 펼침→접기는 ←). 평범한 화살표 경로(`isPlainArrow`)는 `e.shiftKey`를 제외하므로 이동 동작과 분리됨. 아웃라인 뷰는 기존 `navigateOutlineH`(평범한 ←/→) 사용으로 영향 없음.
- 변경 파일: `index.html`(keydown·`RECENT_CHANGES`·버전), `seahyun/brainstorm_v3.82.2.html`(스냅샷), `CHANGELOG.md`, `README.md`, `BrainBloom_UserGuide.html`.

---

## [3.82.1] - 2026-06-11

### Changed
- **내보내기 파일명에 문서 이름 포함** — PDF·JPG·SVG·CSV·MD·JSON 내보내기 파일명이 `문서이름_시각.확장자`(예: `회사 프로젝트_2026-06-11T14-30-45.json`)로 저장된다. 다중 문서(3.82.0)에서 여러 문서를 내보내도 파일명으로 구분 가능. 문서 이름을 쓸 수 없으면(빈 이름·금지 문자뿐) 기존 `filenameBase` 접두사로 대체. 설정 → 저장의 "파일명 접두사" 설명도 새 동작에 맞게 갱신.

### Technical Notes
- `sanitizeFilePart(s, maxLen=40)` 헬퍼 추가 — Windows·맥 공통 금지 문자(`\ / : * ? " < > |`)와 제어 문자를 공백으로 치환, 연속 공백 정리, 40자 제한, Windows 제약(끝의 점·공백 불가) 처리.
- `saveAll()`의 `base`만 변경(문서 이름 우선, `filenameBase` 폴백). **구글 드라이브 자동저장 파일명은 기존 규칙(접두어+날짜+버전) 그대로** — 동기화 파싱(`buildDriveBase`) 호환 유지.
- 변경 파일: `index.html`, `seahyun/brainstorm_v3.82.1.html`(스냅샷), `CHANGELOG.md`, `README.md`, `CLAUDE.md`(워크플로 기록).

---

## [3.82.0] - 2026-06-11

### Added
- **다중 문서 — 여러 문서를 따로 만들고 전환·편집** — 헤더에 `📄 문서` 버튼(미니멀·모바일 포함 항상 표시)을 추가. 누르면 문서 패널이 열려 문서 목록(이름·마지막 수정 시각, 현재 문서 강조)을 보고 **클릭으로 전환 / `＋ 새 문서` 생성 / `✎` 이름 변경 / `🗑` 삭제**(마지막 1개는 보호)할 수 있다. 각 문서는 자신의 마인드맵(`tree`)과 텍스트(`inputText`)를 따로 보관하며, 새로고침·재오픈 후에도 마지막에 열어 둔 문서가 복원된다. 문서 이름은 루트 노드 라벨을 따라 자동 부여되고, 사용자가 바꾸면 그 이름으로 고정(`auto:false`)된다.

### Changed
- 문서 전환·생성·삭제 시 화면을 맵 편집 모드로 정리(`viewMode='edit'`, 아웃라인·간트/타임라인 닫기, 선택/편집 해제, Undo 히스토리 초기화) — `resetViewForDocChange()`.

### Technical Notes
- **저장 구조(하위호환 우선)**: IndexedDB `kv` 스토어에 `docMeta`(`{currentId, list:[{id,name,savedAt,auto}]}`)와 문서별 `doc:<id>`(`{savedAt,tree,inputText,name}`)를 추가. 기존 `lastWork` 키는 **현재 열린 문서의 거울**로 계속 유지해 시작 복원·"어제 작업?" 다이얼로그·구글 드라이브 동기화 등 기존 로직을 그대로 둔다(회귀 위험 최소화).
- **마이그레이션**: 첫 실행 시 `docMeta`가 없으면 기존 `lastWork`(또는 새로 시작한 내용)를 "문서 1"로 자동 승격 → 기존 사용자 데이터 보존.
- **자동저장**: 기존 3곳의 `idbSet('lastWork', …)`를 `writeActiveDoc()`로 교체 — `lastWork` 미러와 `doc:<현재id>` 슬롯을 함께 기록하고 목록 메타(`savedAt`·자동이름)를 갱신. 디바운스(1.5초) 핫패스에서 `setState` 없이 `ref`+IndexedDB만 갱신해 렌더 비용을 더하지 않는다(`docListRef`/`currentDocIdRef`).
- 자동단어 `_autoLabel`·일정(`meta.start` 등)은 트리에 포함되어 문서와 함께 자연히 이동한다(추가 처리 불필요).
- `idbDel(key)` 헬퍼 추가(문서 삭제 시 `doc:<id>` 슬롯 제거). 앱 내장 릴리스 노트(`RECENT_CHANGES`)에 3.82.0 항목 추가.
- 변경 파일: `index.html`(상태·헬퍼·동작·헤더 버튼·문서 패널 모달·CSS·`RECENT_CHANGES`), `seahyun/brainstorm_v3.82.0.html`(스냅샷), `CHANGELOG.md`, `README.md`.

---

## [3.81.2] - 2026-06-10

### Changed
- **자동 채움 영감 단어를 ★기울임꼴★로 구분 표시 (새로고침 후에도 유지)** — `Tab`/`Enter`로 새 노드를 만들 때 자동으로 들어가는 영감 단어(`_autoLabel` 플래그)를 맵(`NodeViewBase`)·아웃라인(`OutlineRow`) 라벨에서 앞뒤 `★`와 기울임꼴(흐리게)로 렌더링. 사용자가 한 글자라도 입력해 라벨이 바뀌면 `_autoLabel`이 제거되어 일반 표시로 전환. 맵 편집에서 `Enter`/`Tab`으로 "안 바꾸고 끝내기"(`finish()`)할 때 자동 라벨이면 라벨·플래그를 건드리지 않아 표시 유지(`onFinishEdit(label, keepAuto)` 경로 추가) — 기존엔 Enter가 자동 라벨을 그대로 "확정"해 일반 노드처럼 보였음. → 엔터를 연달아 눌러도 '직접 입력한 노드'와 '아직 자동 단어 그대로인 노드'를 한눈에 구분.

### Technical Notes
- **영구화**: `_autoLabel`을 `serializeTree`에서 더 이상 제거하지 않고 저장에 포함, `sanitizeNode`가 로드 시 보존 → 새로고침·재오픈·드라이브 동기화 후에도 ★샘플★ 표시 유지. `nodesEqual`는 이미 `_autoLabel`을 비교(변경 감지 정상).
- 변경 파일: `index.html` (`NodeViewBase`·`OutlineRow` 라벨 렌더, `finish()`, NodeView `onFinishEdit`, `serializeTree`, `sanitizeNode`).

---

## [3.81.0] - 2026-06-09

### Added
- **간트 차트 · 타임라인 뷰** — 마인드맵/아웃라인에 더해 일정 중심의 두 뷰를 추가. 헤더의 `📊 간트`·`🕒 타임라인` 버튼, 단축키 `G`·`T`, 캔버스 우클릭 메뉴로 전환. 마인드맵·아웃라인과 상호 배타(전환 시 서로 해제).
  - **데이터 모델**: 노드 `meta.start`·`meta.end`(ISO `YYYY-MM-DD`)·`meta.milestone`(bool) 구조화 필드 신설. 기존 자유 텍스트 `meta.date/effort/cost`는 표시용으로 유지. `sanitizeNode`·`preserveMetadata`가 새 필드를 보존(텍스트 동기화·내보내기 안전).
  - **일정 계산** `computeSchedule(root)`: 노드별 시작/종료 + **하위 롤업**(부모 = 자식 범위 min~max 요약 막대), 진행률은 `computeTaskProgress`(하위 완료 비율)로 막대 채움. 날짜 없는 노드는 목록에만 표시.
  - **간트**: 좌측 아웃라인(접기·색·할 일 체크) + 우측 시간축 막대(주별 눈금·**오늘선**). **막대 드래그=일정 이동**, **우측 끝 핸들 드래그=기간 조절**(pointer 이벤트, px↔일 환산, 드롭 시 커밋·Undo 1건). 관계선(크로스링크)을 **의존성 화살표**(SVG)로 표시. 마일스톤은 ◆.
  - **타임라인**: 상위 가지별 **스윔레인**에 시작일 기준 점(pill·◆)을 배치한 경량 뷰.
  - **우측 패널 “일정” 섹션**: `시작일`·`종료일`(`<input type=date>`) + `마일스톤` 체크. 마일스톤이면 종료일 비활성.
- 단축키 `G`(간트)·`T`(타임라인) 추가. README 단축키 표 반영.

### Technical Notes
- 신규 컴포넌트 `GanttView`·`TimelineView`·`ChartTopBar`와 헬퍼 `bbParseISO/bbToISO/bbAddDays/bbDayDiff/bbFmtMD/bbHex/bbDarken`·`computeSchedule`. App에 `chartView` 상태 + `schedule = useMemo(computeSchedule(tree),[tree])` + `chartActions`. 맵 노드 렌더 가드를 `!outlineView && !chartView && nodeEls`로 확장(기본 동작 불변).
- babel transform PASS(447,166 chars). 일정 로직 단위 테스트(롤업·진행률·마일스톤·미배치·드래그 수학) 통과. `index.html` ↔ `seahyun/brainstorm_v3.81.0.html` md5 일치.

---

## [3.80.27] - 2026-06-08

### Changed
- **새 노드가 기준 노드의 모양(shape)을 상속** — 모양을 지정한 노드에서 `Tab`(자식 추가)·`Enter`(형제 추가)로 새 노드를 만들면 같은 모양으로 생성됨. `addChild`는 `parent.shape`를, `addSibling`은 기준 형제(`current.shape`)를 새 노드에 복사. 가지 단위로 모양을 일관되게 유지(이미 모양이 없으면 기본 둥근 그대로). 모든 추가 경로(전역 키보드 Tab/Enter, 플로팅 ＋ 버튼, 패널 +자식/+형제, 아웃라인 추가)가 두 함수를 거치므로 일괄 적용됨.

### Technical Notes
- babel transform PASS(426,121 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.27.html` md5 일치.

---

## [3.80.26] - 2026-06-08

### Fixed
- **노드 모양 선택이 적용되지 않던 버그** — 우측 패널 "모양"(둥근·각짐·알약·타원)이 `borderRadius`를 배경·테두리가 없는 바깥 `.node` div에 인라인으로 적용해 화면상 아무 변화가 없었음. 실제로 배경·모서리를 그리는 `.node-body`(CSS `border-radius:14px`)로 옮겨, `node.shape`에 따라 rect→3 / pill→999 / ellipse→50% / 둥근→기본 14px가 적용되게 함. 선택·편집 강조 링(`.node-body`의 box-shadow)도 고른 모양을 따라가도록 일관성 확보. (메모이제이션 `nodeViewPropsEqual`은 이미 `a.shape!==b.shape`를 비교하고 있어 리렌더는 정상 — 순수 CSS 적용 위치 버그였음.)

### Technical Notes
- babel transform PASS(425,753 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.26.html` md5 일치.

---

## [3.80.25] - 2026-06-08

### Added
- **Ctrl/⌘ + 드래그 노드 복제** — 노드를 `Ctrl`(맥 `⌘`)을 누른 채 다른 노드 위로 끌어다 놓으면 그 노드와 모든 하위 노드를 복제해 대상의 자식으로 추가. 원본은 그대로 유지. `handleDragStart`에서 `effectAllowed='copyMove'`, `handleDragOver`/`handleDrop`은 `e.ctrlKey||e.metaKey`로 복제 모드를 판정해 커서에 `dropEffect='copy'`(+ 표시) 피드백. 복제 시 `cloneTree`로 스냅샷을 떠 `walk`로 전체에 새 id(`c{stamp}_{seq}`)를 부여하고 휘발성 좌표(`_x/_y/_w/_h/_subH`)·`pinnedSide`·`autoSide`를 제거한 뒤 자식으로 push, 접힌 부모는 펼치고 `applyColorToBranch(colorForMovedNode(...))`로 새 부모 톤을 입힘. 복제본은 독립 스냅샷이라 자기 자손 위에 떨궈도 순환이 생기지 않아 `isDescendant` 순환 가드를 건너뜀(이동은 기존대로 가드 유지). `maybePushHistory('노드 복제')`로 `Ctrl+Z` 되돌리기를 지원하고, 토스트에 복제된 노드 개수를 표시.

### Technical Notes
- babel transform PASS(425,466 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.25.html` md5 일치.

---

## [3.80.24] - 2026-06-06

### Changed
- **경계 박스 세로 인접 겹침 완화** — `boundaryEls`의 단일 `pad`를 `padX`(가로, `max(2,13-depth*10)`)·`padY`(세로, `max(2,8-depth*6)`)로 분리. 위·아래로 인접한 다른 그룹 박스가 세로로 가까워 점선이 겹치던 문제를, 세로 여백을 형제 간격보다 작게 잡아 해소(배치 엔진 미수정 — 저위험). rx 14→13.

### Technical Notes
- babel transform PASS(423,740 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.24.html` md5 일치.

---

## [3.80.23] - 2026-06-06

### Changed
- **경계(그룹) 박스 겹침 추가 완화** — `boundaryEls` pad를 `max(6,16-depth*6)`(3.80.20) → `max(2,13-depth*10)`로. 중첩 깊이 1부터 안쪽 여백을 3~2로 확 줄여 부모·자식 박스의 점선 간격을 ~10px 확보, 바깥 여백도 16→13으로 줄여 인접 그룹 겹침 완화. (노드 배치가 매우 가까운 경우의 인접 겹침은 레이아웃 여백 조정이 필요한 별도 작업.)

### Technical Notes
- babel transform PASS(423,412 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.23.html` md5 일치.

---

## [3.80.22] - 2026-06-06

### Security
- **About iframe sandbox** (보안 #2) — `sandbox="allow-same-origin allow-popups allow-popups-to-escape-sandbox"` + `referrerPolicy="no-referrer"`. about.html은 정적이라 정상 동작하며, 혹시 모를 스크립트 실행 차단(allow-scripts 미부여).

### Changed
- **아웃라인 ↑/↓ 이동 캐시** (최적화 #5) — `navigateOutline`이 매 입력마다 `walkVisible` 전체 평탄화 + `groupIdOf`(O(N))×2 하던 것을, `outlineFlat`/`outlineGroupMap` useMemo([tree])로 캐시. 키 연타 시 트리 미변경이면 재계산 없음.

### Notes (보류/정정)
- 최적화 #1(layoutTree useMemo): **의도적 설계**라 보류 — 코드 주석에 "메모 시 동시성 렌더에서 좌표 mutate 누락→전노드 (0,0) 겹침 버그" 명시. 매 렌더 직접 호출 유지.
- 최적화 #2(crossLinkEls deps)·#4(nodeEls deps): 선택-여백 기능·설정 반영 회귀 위험 > 효과 → 보류.
- 최적화 #3(boundaryEls O(B²)): 경계 수가 통상 한 자리라 실효 미미 → 보류.
- 보안 #1(라벨 링크): URL_RE/MD_LINK_RE가 이미 http(s)만 추출(실위험 낮음). v3.80.21에서 출력 시점 `safeLinkUrl` 심층방어로 처리 완료.

### Technical Notes
- babel transform PASS(423,134 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.22.html` md5 일치.

---

## [3.80.21] - 2026-06-06

### Security
- **라벨 링크 href 스킴 화이트리스트(심층 방어)** — `safeLinkUrl()` 추가: 제어문자 제거 후 스킴이 있으면 `http/https/mailto`만 허용, `javascript:`·`data:`·`vbscript:` 등은 `null`(링크 미생성). `resolveLabelLink`의 두 경로(MD_LINK_RE, extractFirstUrl)에 적용. 현재 `URL_RE`/`MD_LINK_RE`가 이미 `https?://`만 추출해 실제 노출은 없었으나, 출력 시점에도 막아 정규식 변경·불러온 데이터 등 회귀에 대비. 시뮬: js/data/vbscript(대소문자·개행 우회 포함) 전부 차단 확인.

### Technical Notes
- babel transform PASS(422,337 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.21.html` md5 일치.

---

## [3.80.20] - 2026-06-06

### Added
- **노드 폭 드래그 리사이즈** — 노드 우측 안쪽 끝에 핸들(`.node-resize-handle`, 호버·선택 시 표시) 추가. 좌우 드래그로 `node.w`(NODE_MIN_W~NODE_RESIZE_MAX 720) 지정, 더블클릭=자동 폭(`delete node.w`). 드래그 중엔 DOM `style.width`만 바꿔 부드럽게, 놓을 때 `setNodeWidth`로 확정→`layoutTree` 재배치. `nodeWidth()`가 `node.w` 우선(없으면 라벨 기반). `nodeHeight`/`labelLineCount`는 새 폭 반영(넓히면 줄 수↓). `sanitizeNode`·`preserveMetadata`에 `w` 보존(저장/텍스트 재편집 유지). `startNodeResize`/`setNodeWidth`/`resetNodeWidth`를 nodeActionsRef로, NodeView에 `onResizeStart`/`onResizeReset` prop.

### Changed
- **경계(그룹) 박스 겹침 완화** — `boundaryEls` pad 16 고정 → 중첩 깊이(다른 경계 앵커의 하위인 횟수)만큼 단계적 축소 `max(6,16-depth*6)`. `.boundary-rect` 채움/선 투명도 낮춤(0.06→0.045, 0.5→0.4), rx 16→14.

### Technical Notes
- babel transform PASS(421,387 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.20.html` md5 일치.

---

## [3.80.19] - 2026-06-06

### Fixed
- **편집 중 노드 가로 확장으로 옆 노드와 겹치던 문제(근본 수정)** — 기존엔 편집 시 노드 `width:auto`+`minWidth:_w`+`maxWidth:600`, input `width=글자수*em`이라 입력이 길수록 노드가 우측으로 늘어나 자식/형제 노드를 물리적으로 침범. 편집 중에도 노드 `width=node._w`로 **고정**하고 input `width:100%`(노드 폭 채움, 긴 글은 내부 가로 스크롤)로 변경 → 가로 확장 제거. v3.80.18의 `.node.editing{z-index:200}`은 보조로 유지. babel PASS. md5 일치.

---

## [3.80.18] - 2026-06-06

### Fixed
- **편집 중 노드가 옆 노드에 가려지던 문제** — 편집 시 입력값 길이에 맞춰 노드 폭이 늘어나는데(우측 확장) `.node.editing`에 z-index가 없어 나중에 그려진 옆/자식 노드가 위로 겹쳐 편집 내용이 가려짐. `.node.editing { z-index: 200 }`(dragging 100보다 위) 추가로 편집 노드를 최상위로. 편집 종료 시 폭이 원래대로 줄어 겹침도 사라짐. babel PASS. md5 일치.

---

## [3.80.17] - 2026-06-06

### Changed
- **화면 탭 항목 순서 조정** — "배경 점 패턴 표시"(배경 테마 카드에서 분리)·"미니멀 상단바"를 "좌측 패널 표시" 위로 이동(자주 쓰는 토글 상단 배치). 기능 동일, 배치만 변경. babel PASS(418,189 chars). md5 일치.

---

## [3.80.16] - 2026-06-06

### Changed
- **설정 메뉴 종류별 정리(6개 탭)** — 한 화면에 쭉 나열되던 12개 섹션을 사용자 지정 순서의 6개 종류 탭으로 묶음: 정보 → 화면 → 타이머 → 작업·콘텐츠 → 저장·드라이브 → 연동. `SETTINGS_CATS` 상수 + `cat` 상태(기본 'disp'), `modal-body`에 `settings-catbody`+`data-cat`, 상단 가로 탭 네비, 각 `settings-section`에 `cat-*` 클래스 부여 후 CSS로 선택 종류만 표시. 문서 바로가기는 정보 탭에만 조건부 렌더. 기능·설정값·로직 변화 없이 **배치만** 변경(About/변경이력 오버레이는 그대로). 시안은 세로 사이드바였으나 모달 폭·모바일 고려해 가로 탭으로 구현.

### Technical Notes
- babel transform PASS(417,942 chars). 섹션 12개 모두 카테고리 태깅(화면3·작업3·저장2·연동2·타이머1·정보1). `index.html` ↔ `seahyun/brainstorm_v3.80.16.html` md5 일치.

---

## [3.80.15] - 2026-06-06

### Added
- **+ / − 키 화면 배율 조정** — 전역 키보드 핸들러에 단독 `+`(=Shift+`=`)·`=` → `zoomBy(0.1)`, `-`·`_` → `zoomBy(-0.1)` 추가. 입력/편집 중 가드 이후, 수식키 없을 때, `!outlineView`(맵 화면)에서만. Ctrl+± 브라우저 줌은 그대로 둠.

### Technical Notes
- babel transform PASS(416,766 chars). `index.html` ↔ `seahyun/brainstorm_v3.80.15.html` md5 일치.

---

## [3.80.14] - 2026-06-06

### Added
- **저장본 비교 화면(좌우 아웃라인 + 결정)** — 드라이브 최신본 충돌(`remoteNewer`) 시, 기존 텍스트 요약 다이얼로그를 **좌우 2-pane 아웃라인 비교**로 교체. 상단 요약 카드(이 기기/드라이브, 노드 수·수정시각, "더 최신 ▲") + 차이 배지(추가/삭제/변경 개수) + 각 트리를 전체 펼친 읽기전용 아웃라인. 신규: `nodeDiffStatus(local,remote)`(id별 same/added/removed/changed) + `CompareOutline` 컴포넌트(노드별 색: 🟢added·🔴removed(취소선)·🟡changed). `remoteCmpStatus`(useMemo, [remoteNewer,remoteCompare,tree]). 결정 버튼 4종: 현재 유지·무시(기준시각 갱신) / 드라이브 것 불러오기(`handleDriveLoadFile`) / 둘 합치기(Merge)(`handleMergeRemote`, "복원" 가지) / **Google Drive 저장 파일 삭제**(`handleDeleteRemote`→`driveDeleteFile`, window.confirm 2차 확인). 모달 `.cmp-*` 스타일·반응형(<720px 세로 stack) 추가.

### Technical Notes
- babel transform PASS(416,112 chars). 기존 `diffTrees`/`mergeRemoteIntoLocal`/`driveDeleteFile` 재사용. 사용자 시안 승인 후 라벨 확정(Merge·"Google Drive 저장 파일 삭제"). `index.html` ↔ `seahyun/brainstorm_v3.80.14.html` md5 일치.

---

## [3.80.13] - 2026-06-06

### Changed
- **관계선 끝점 여백 일정화(선택 강조 링 보정)** — cross-link가 노드 논리 경계(`rectEdge`)에 gap 0으로 닿아, 선택 노드의 box-shadow 강조 링(약 9px, 레이아웃 미포함) 때문에 선택/비선택 끝의 여백이 불균형하던 문제. 끝점에 `endGap(node)=BASE_GAP(3)+(selectedId===node.id?SELECT_RING(9):0)`를 적용하고 `pushOut(edge,cx,cy,gap)`으로 중심 반대 방향으로 밀어, 직선/곡선/꺾은선 3종 모두 "보이는 경계에서 일정한 3px"로 통일. `crossLinkEls` deps에 `selectedId` 추가.

### Technical Notes
- babel transform PASS(414,139 chars). 끝점 여백 시뮬 PASS(비선택 3px · 선택 링밖 +3px). `index.html` ↔ `seahyun/brainstorm_v3.80.13.html` md5 일치.

---

## [3.80.12] - 2026-06-06

### Added
- **아웃라인 ←/→ 키 = 펼치기·접기/계층 이동** — 글로벌 키보드 핸들러에서 `outlineView`일 때 ←/→를 `navigateOutlineH(dir)`로 처리. →: 접힌 노드면 펼치기(`toggleCollapse`), 이미 펼쳐졌으면 첫 자식 선택. ←: 펼쳐진 노드면 접기, 그 외(접힘/잎)는 부모로 이동(`findParent`) → "펼친 상태에서 ← 접기 → 다시 ← 부모로"가 자연스럽게 동작. 아웃라인 헤더 도움말에 `↑↓=이동 · →펼치기 ←접기` 반영. (↑/↓ 그룹 경계 이동은 기존 `navigateOutline` 유지)

### Changed
- **드라이브 자동저장 표시색 → 테마 소프트블루(채도↓)** — 헤더 "설정" 버튼이 자동저장 정상일 때 쓰던 진한 파랑 `#0091ff`(fontWeight 700)을 테마 변수 `var(--navy)`(#3a6ea5, 차분한 소프트블루) + fontWeight 600으로 변경. 상시 노출되는 상태색이라 채도·굵기를 낮춰 집중 방해 최소화(빨강 경고색 `#e5484d`는 알림 목적이라 유지).
- **하단 토스트가 아이콘/태그 바와 겹침 해소** — `.bottom-bars`(아이콘·태그 모아보기, `position:fixed; bottom:16px`)와 `.toast`(`bottom:24px`)가 모두 하단 중앙이라 저장 안내(💾 sticky 토스트)가 바와 겹치던 문제. `bottomBarsRef`+`ResizeObserver`로 바 높이를 측정(`bottomBarsH`)해, 바가 있으면 토스트 `bottom`을 `bottomBarsH + 28`로 인라인 적용해 바 위로 띄움(없으면 기존 24px).

### Technical Notes
- babel transform PASS(413,432 chars). 아웃라인 ←/→ 로직 시뮬 PASS(펼침서 ←접기→다시←부모, 접힘서 →펼침→다시→첫자식). `index.html` ↔ `seahyun/brainstorm_v3.80.12.html` md5 일치.

---

## [3.80.11] - 2026-06-06

### Changed
- **아웃라인 → 맵 복귀 시 선택 노드 중앙 정렬 + 배율 복원** — 아웃라인에서 F(또는 헤더 버튼·우클릭 메뉴)로 마인드맵으로 돌아갈 때, 아웃라인에서 선택했던 노드를 화면 중앙에 보이게 하고 진입 직전 배율로 되돌림. `outlineView` 전이 감지 effect 추가: 진입(false→true) 시 `preOutlineZoomRef = zoomRef.current` 저장, 복귀(true→false) 시 `setZoom(preOutlineZoomRef)` + `requestAnimationFrame×2 → centerNode(selectedId)`(맵 노드가 다시 렌더된 뒤 실행). `centerNode`는 스크롤만 해 배율 불변이고, autoFit은 `didAutoFitRef`로 1회뿐이라 토글에 재발동 없음.

### Technical Notes
- babel transform PASS(411,141 chars). zoomBy/zoomReset의 setZoom+이중 rAF+centerNode 패턴과 동일. `index.html` ↔ `seahyun/brainstorm_v3.80.11.html` md5 일치.

---

## [3.80.10] - 2026-06-06

### Fixed
- **아웃라인 Enter = 입력 끝(편집 종료)** — v3.80.4에서 넣은 "Enter→형제 추가 후 연속 편집"이 "엔터를 쳐도 입력이 안 끝나고 새 항목으로 넘어간다"는 불만으로 이어져 되돌림. `OutlineEdit`의 Enter를 `onCommit`(라벨 확정 + `setEditingId(null)`)으로 변경 — 맵 노드 편집과 동일. 미사용이 된 `onEnter` 프롭·`enterAddSibling` 액션 제거(Tab=자식 추가는 유지). 새 항목은 + 버튼/Tab, 또는 편집이 아닐 때 전역 Enter(형제 추가)로.

### Changed
- **우클릭 메뉴 "아웃라인으로 보기" 위치 이동** — 성격이 다른 화면 전환 항목을 메뉴 맨 위 → 맨 아래(보기 모드 아래)로 옮기고 위 항목과 구분선 추가.

### Technical Notes
- babel transform PASS(410,114 chars). 잔여 onEnter/enterAddSibling 0건, bgMenu 내 토글 1개(최하단). `index.html` ↔ `seahyun/brainstorm_v3.80.10.html` md5 일치.

---

## [3.80.9] - 2026-06-06

### Changed
- **아웃라인 깊이별 중첩 박스(블록) 시각화** — 사용자 스케치 반영. 평탄 행 + 행별 들여쓰기/그룹 파스텔 밴드를 **자식이 보이는 노드를 박스로 감싸는 중첩 구조**로 교체. `OutlineRow`가 잎/접힘은 행만, 깊이≥1의 펼친 노드는 `<div.outline-block>{행}{<div.outline-children>}</div>`로 렌더(루트는 박스 없이 fragment). 깊이별 색 `depthRGB()`(6색 순환: 파랑/초록/주황/핑크/보라/시안)로 `--block-border`(0.4)·`--block-bg`(0.05) 지정 → 중첩 박스가 계층을 색으로 구분. 들여쓰기는 `.outline-children{padding-left:13px}` 중첩으로 처리(행의 `paddingLeft:depth*20` 인라인 제거, 고정 패딩). 전체를 `.outline-tree`(max-width 940·중앙)로 감쌈. 선택 항목의 최상위 그룹 박스는 `.group-active`로 살짝 강조. 기존 그룹 파스텔 밴드(`.in-group`/`--group-tint`/`--group-edge`) 제거(그룹 개념은 내비게이션·group-active로 유지). 선택/호버/편집/네비게이션/그룹 경계 동작은 그대로.

### Technical Notes
- babel transform PASS(410,536 chars). sharp로 중첩 박스 레이아웃 시각 확인(스케치와 일치). 잔여 in-group/group-tint 참조 0건. `index.html` ↔ `seahyun/brainstorm_v3.80.9.html` md5 일치.

---

## [3.80.8] - 2026-06-06

### Added
- **아웃라인 그룹 강조(파스텔) + 그룹 단위 화살표 이동** — (1) 선택 항목이 속한 "그룹"(최상위 가지=루트의 깊이1 자식과 그 자손)을 그 가지 색의 옅은 파스텔(`--group-tint` 0.16, 좌측 띠 `--group-edge` 0.5)로 묶어 표시. `OutlineRow`에 `groupId`/`groupColor` 프롭 드릴, `tintColor()`(hex→rgba)·`groupIdOf()` 헬퍼 추가, `outlineSelectedGroupId`(useMemo) → ctx. CSS는 `.in-group`을 `:hover`/`.selected`보다 먼저 두어 선택/호버가 덮어쓰게. (2) 아웃라인 ↑/↓는 `navigateOutline()`로 `walkVisible` 평탄 목록을 차례 이동. 같은 그룹/루트 경유는 자유 이동, **그룹 경계**에선 한 번=안내만(멈춤), 700ms 내 두 번=다음/이전 그룹으로 교차(`outlineBoundaryRef`). 키보드 핸들러에서 `outlineView`일 때 ↑/↓만 가로채고 deps에 `outlineView`,`settings.hideOutlineGroupHint` 추가. 선택 행 `scrollIntoView({block:'nearest'})` 효과 추가(맵 centerNode는 아웃라인 미렌더라 무동작).
- **그룹 경계 안내 팝업 + "다음부터 보지 않기"** — 경계 첫 진입 시 방향별 안내(↓/↑) 팝업, 5초 자동 닫힘. 체크박스로 `settings.hideOutlineGroupHint` 토글(IndexedDB 영속, 기본값·로드 마이그레이션 추가). 끈 뒤에도 두 번 누름 교차는 그대로 동작.

### Technical Notes
- babel transform PASS(410,076 chars). 내비 시뮬 PASS(R→G1→a→b 자유, b에서 ↓=경계, 느리게=재경계, 700ms내 두 번=G2 교차). sharp로 파스텔 밴드+선택 강조 시각 확인. `index.html` ↔ `seahyun/brainstorm_v3.80.8.html` md5 일치.

---

## [3.80.7] - 2026-06-06

### Fixed
- **아웃라인 편집 포커스 가로채기 버그** — 아웃라인에서 Enter(형제)·Tab(자식)·더블클릭으로 항목을 추가/편집하면 새 항목이 곧바로 편집 상태로 들어가야 하는데, 추가만 되고 편집이 즉시 끊기던 문제. 원인: 아웃라인 오버레이 **아래에 가려진 마인드맵**(`nodeEls`)도 `editingId`에 반응해 `NodeView` 입력창을 만들고 `setTimeout(...focus(), 10)`으로 포커스를 가져가, 아웃라인 입력창이 blur→`cancelEmpty`로 편집이 종료(자동라벨이라 노드는 삭제 안 됨)됨. 해결: `outlineView`가 켜져 있으면 맵 노드를 렌더하지 않도록 `{!outlineView && nodeEls}` — 경쟁 입력창 제거(가려진 맵 미렌더로 성능도 이득). `ensureNodeVisible`는 노드 DOM 없으면 early-return이라 영향 없음.

### Added
- **F 키 = 마인드맵 ↔ 아웃라인 토글** — 전역 키보드 핸들러에 단독 F(수식키 없음, 입력/편집 중 아닐 때) 추가. 기존 검색은 Ctrl/Cmd+F라 충돌 없음.
- **우클릭 메뉴 "아웃라인으로 보기"** — 캔버스 컨텍스트 메뉴(`bgMenu`) 최상단에 화면 전환 항목(아이콘+단축키 F 표기) 추가. 메뉴 높이 클램프 보정(+48px).

### Technical Notes
- babel transform PASS(403,343 chars). 근본 원인 확인: `NodeViewBase` 포커스 `useLayoutEffect`(isEditing→setTimeout focus 10ms)와 아웃라인 `OutlineEdit` 포커스 경쟁. `index.html` ↔ `seahyun/brainstorm_v3.80.7.html` md5 일치.

---

## [3.80.6] - 2026-06-06

### Changed
- **미니멀 상단바 = 아이콘 전용** — `settings.minimalHeader`가 켜지면 헤더에 남는 버튼(아웃라인·캘린더·AI 요약·설정)의 글자 라벨을 숨기고 아이콘만 표시. CSS만으로 처리: `.header.minimal .btn-label { display:none }` + `.header.minimal .btn.icon-btn { padding:6px 9px }`(라벨 제거 후 정사각형 느낌). 버튼별 `title`이 있어 호버 시 이름 확인 가능.

### Technical Notes
- 스타일 전용 변경(스크립트 무수정). babel 영향 없음. `index.html` ↔ `seahyun/brainstorm_v3.80.6.html` md5 일치.

---

## [3.80.5] - 2026-06-06

### Changed
- **아웃라인/지도 토글 아이콘 리디자인(컬러 SVG)** — 헤더 `view-toggle-btn`의 단색 이모지(🗂/🗺)를 캘린더(📅)·AI(🤖)처럼 컬러풀한 커스텀 인라인 SVG로 교체. `OutlineGlyph`(들여쓰기 줄 + 브랜드 색 글머리 점 4개 — 파랑/핑크/그린/앰버)·`MapGlyph`(중심 노드 + 색색의 가지) 컴포넌트 추가. 줄은 `currentColor`+opacity로 라이트/다크 테마 자동 적응, 점은 로고 팔레트(#3a86ff·#ff5d8f·#06d6a0·#ffb703). `.btn`(inline-flex)의 정렬·gap에 맞춰 `.vt-glyph { display:block; flex:0 0 auto }`.

### Technical Notes
- babel transform PASS(401,481 chars). sharp로 18px/확대/라이트·다크 렌더 미리보기 확인. `index.html` ↔ `seahyun/brainstorm_v3.80.5.html` md5 일치.

---

## [3.80.4] - 2026-06-06

### Changed
- **아웃라인 연속 입력(Enter→새 항목 즉시 편집)** — 인라인 편집 중 Enter를 치면 라벨을 확정하고 곧바로 아래에 형제 항목을 만들어 **편집 상태로 진입**하도록 바꿨어요(기존엔 편집만 종료돼 새 항목이 편집 모드로 안 들어가던 문제). Tab은 자식 항목을 만들어 편집, 빈 줄/미변경 자동라벨에서 Enter는 취소(연속 입력 종료). 루트는 형제가 없으므로 확정만. `OutlineEdit`에 `onEnter`/`onTab` 분리, 확정은 `commitNodeLabelSilent`(히스토리 없음) + `addSibling/addChild`(히스토리 1건)로 처리해 "타이핑+추가"가 Undo 1회로 되돌아가게 함. IME 조합 중 Enter/Tab은 조합 종료에 양보.

### Technical Notes
- babel transform PASS(399,849 chars). Enter/Tab 라우팅 시뮬 PASS(내용 있음→확정+형제/자식 편집 진입, 빈칸/미변경 자동라벨→취소, 루트→확정만). `index.html` ↔ `seahyun/brainstorm_v3.80.4.html` md5 일치.

---

## [3.80.3] - 2026-06-06

### Added
- **아웃라인(목록) 뷰 — MindNode 참고 #2** — 헤더의 🗂 버튼으로 마인드맵 ↔ 아웃라인 전환. `.canvas-wrap` 안에 `position:absolute; inset:0; z-index:25` 불투명 오버레이(`outlineView` 상태)로 맵을 덮어 렌더 — 맵·연결선 메모는 그대로 두고 시각적으로만 대체(좌/우 패널 유지). 최상위 컴포넌트 `OutlineRow`(재귀, `key=child.id`)/`OutlineEdit`(IME-safe 인라인 편집) 추가. 행: 접기 ▶/▼, 할 일 체크박스(완료 토글), 색 점, 라벨(클릭=선택·더블클릭/F2=편집), 태그/진행률(0/1)/노트 배지, 호버 시 ＋자식·🗑삭제. 진행률은 `computeTaskProgress(tree)`를 `outlineTaskMap`(useMemo, dep `[tree]`)으로 재사용. 추가/삭제/이동/접기는 기존 전역 단축키(Enter·Tab·Space·Del·Alt+화살표)가 `selectedId` 기준으로 그대로 동작 — 편집 종료(commit) 시 `editingId`만 풀어 일관 유지. 토글 버튼은 `view-toggle-btn` 클래스로 모바일(≤640px) 헤더 숨김 예외에 추가해 항상 노출. 터치 기기(`@media (hover:none)`)는 행 동작 버튼 상시 표시.

### Changed
- **노드 진행률 배지 줄바꿈** — 하위 할 일 진행률(예: `0/1`) 배지를 `.node-label-row`에서 빼내 라벨 아래 별도 줄(`.node-progress-row`)로 이동. 긴 이름이 배지에 밀려 잘리던 문제 해결(사용자 요청). 체크박스(할 일 토글)는 라벨 옆 유지.

### Technical Notes
- babel transform PASS(397,855 chars). computeTaskProgress(root 1/3 · leaf null · mid 1/2) 및 OutlineEdit settle 규칙(자동라벨 미변경/양쪽 공백→취소, Esc→원본 유지, commit) 시뮬 PASS. `index.html` ↔ `seahyun/brainstorm_v3.80.3.html` md5 일치.

---

## [3.80.2] - 2026-06-06

### Added
- **노드 간격 선택(컴팩트) — 레이아웃 #4 1단계** (MindNode 참고 #4) — 설정 → 화면 표시에 "노드 간격" 촘촘/보통/넓게. 핵심 배치 로직은 그대로 두고 간격만 스케일: 모듈 상수 `H_SPACING/V_SPACING` → `BASE_H_SPACING(80)/BASE_V_SPACING(22)`로 이름 변경, `layoutTree(root, spaceMul=1)`가 함수 내부에서 지역 `const H/V_SPACING = BASE * spaceMul`로 섀도잉(기존 ~15개 사용처 무수정). `spaceMul`: compact 0.55 · normal 1 · wide 1.6. 간격 변경 시 `useEffect`로 트리를 재클론해 위치 메모(노드·연결선·그룹·경계·관계선)를 한 번에 갱신(첫 렌더는 ref 가드로 스킵).
- (가로형/조직도형 레이아웃은 layoutTree 재구성이 필요한 별도 작업 — 후속.)

### Technical Notes
- spaceMul 매핑 검증 PASS. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.80.2.html` md5 일치.

---

## [3.80.1] - 2026-06-06

### Added
- **노드 모양 선택** (MindNode 참고 #3) — `node.shape`: 기본(둥근) / `rect`(각짐) / `pill`(알약) / `ellipse`(타원). 노드 인라인 `borderRadius`만 덮어써 **크기·레이아웃은 그대로**(겹침 없음). 인스펙터 "모양" 섹션에 4개 버튼(미리보기 모양). 비교함수에 `a.shape` 추가, `sanitizeNode`·`preserveMetadata` 보존.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.80.1.html` md5 일치.

---

## [3.80.0] - 2026-06-06

### Added
- **작업(체크박스) + 진행률** (MindNode 참고 #1) — 노드를 할 일로 표시(`node.task`)하고 완료(`node.done`) 처리. 데이터모델·보존·렌더·인스펙터 전반 구현.
  - **렌더**: `node.task`면 라벨 앞에 ☐/☑ 체크박스(클릭 시 완료 토글, `stopPropagation`으로 선택/패닝과 분리), 완료 시 라벨 취소선+흐리게. 하위에 할 일이 있는 부모는 `node-progress` 배지로 `완료/전체`(예 2/4) 표시.
  - **진행률**: `computeTaskProgress(tree)` bottom-up O(n) → 노드별 `{done,total}`(자기 + 모든 하위 task 합산). `nodeEls` 메모에서 1회 계산해 값 prop(`isTask/isDone/taskDone/taskTotal`)으로 전달, `nodeViewPropsEqual`에 4개 비교 추가(정확한 리렌더).
  - **인스펙터**: "할 일" 섹션 — "할 일로 표시" 토글 + "완료함" 체크박스(`updateNode`).
  - **보존**: `sanitizeNode`(로드)·`preserveMetadata`(재파싱) 화이트리스트에 `task/done` 추가. 저장·드라이브는 비-`_` 필드라 자동 유지.
- node 시뮬: 진행률 합산 PASS(root 2/4 · 하위 1/2 · 완료 leaf 1/1).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.80.0.html` md5 일치.

---

## [3.79.13] - 2026-06-05

### Changed
- **변경 이력 페이지 크기 10 → 50** — `clVisible` 초기값·리셋·증가폭을 모두 50으로(처음 50개 → "더 읽기"로 +50씩). 50 페이징이 의미 있도록 **`RECENT_CHANGES`에 이전 버전(3.76.2 → 3.63.0) 사용자용 한 줄 요약 28개 추가**(총 51개). 그 이전 전체 이력은 변경 이력 하단의 외부 링크로 계속 접근 가능.

### Technical Notes
- RECENT_CHANGES 51개 항목 구조 검증 통과. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.13.html` md5 일치.

---

## [3.79.12] - 2026-06-05

### Changed
- **업데이트 팝업 "전체 변경 이력 보기" → 앱 내 변경 이력 화면으로 연결** — 기존엔 외부 `CHANGELOG.md`(기술 문서)로 새 탭이 열렸음. → 클릭 시 `setShowUpdate(false)` + `setSettingsToChangelog(true)` + `setShowSettings(true)`로 **설정 모달을 변경 이력 뷰로 바로 연다.** `SettingsModal`에 `startChangelog` prop 추가 → `useState(!!startChangelog)`로 초기 뷰 결정, 설정 닫을 때 App의 `settingsToChangelog` 플래그 리셋(다음 일반 열기는 설정 뷰). 변경 이력 뷰 하단의 "그 이전 버전의 전체 변경 이력 보기"(외부) 링크는 그대로라 전체 이력도 계속 접근 가능.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.12.html` md5 일치.

---

## [3.79.11] - 2026-06-05

### Fixed
- **설정 클릭 시 빈 화면 — 근본 원인 수정(`driveLinkedPending is not defined`)** — v3.78.8에서 드라이브 자동연결을 지연시키며 `driveLinkedPending`(App 상태)을 도입했는데, **`SettingsModal` 내부의 드라이브 상태 배지/경고**(연결됨 표시 등)가 이 값을 참조하면서도 **prop으로 전달받지 못해** 설정 모달 렌더 시 `ReferenceError` → 전체 크래시(빈 화면). v3.79.10의 ErrorBoundary가 이 메시지를 노출해 확정. → App의 `<SettingsModal>` 호출에 `driveLinkedPending={driveLinkedPending}` 전달 + 컴포넌트 시그니처에 prop 추가. 헤더 쪽 참조(App 스코프)는 원래 정상이었음.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.11.html` md5 일치.

---

## [3.79.10] - 2026-06-05

### Fixed
- **렌더 오류 시 빈 화면 방지 — ErrorBoundary 추가** (감사 #4.8) — 그동안 렌더 중 예외가 나면 React가 루트를 언마운트해 **전체가 빈 화면**이 됐음(설정 클릭 시 화면이 사라진다는 제보). → `<App/>`을 `ErrorBoundary`로 감싸 예외를 잡고, 빈 화면 대신 **오류 메시지 + 새로고침 버튼**을 표시(작업은 IndexedDB에 보존). 이제 문제가 재발해도 사용자가 실제 오류 내용을 확인·전달할 수 있어 원인 추적이 가능.

### Technical Notes
- 설정 모달/변경이력/타임스탬프 코드 정적 점검 및 RECENT_CHANGES 20개 항목 구조 검증은 정상이었음 → 잔여 런타임 원인은 ErrorBoundary가 드러낸 메시지로 후속 확정 예정.
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.10.html` md5 일치.

---

## [3.79.9] - 2026-06-05

### Changed
- **사이트 아이콘 — 굵게 다듬고 다중 크기/형식 파일로 생성(서버 등록용)** — 기존엔 인라인 SVG data-URI 1종뿐이라 서버 등록(검색엔진·PWA·홈 화면)에 필요한 실제 파일이 없었음. → 동일 마크(깔때기+점+반짝임, 파랑→청록 그라데이션)를 더 굵게 렌더해 루트에 실제 파일로 생성:
  - `favicon.svg`(벡터·무손실), `favicon.ico`(16·32·48 멀티), `favicon-16x16.png`/`favicon-32x32.png`/`favicon-48x48.png`
  - `apple-touch-icon.png`(180), `icon-192.png`/`icon-512.png`(PWA any), `icon-192-maskable.png`/`icon-512-maskable.png`(maskable, 78% 안전영역)
  - `site.webmanifest`(name/theme_color #3a86ff/icons)
- `index.html <head>`를 인라인 data-URI에서 **파일 기반 링크 세트 + `<link rel="manifest">` + `<meta theme-color>`** 로 교체. (Pillow로 1536px 슈퍼샘플 렌더 후 LANCZOS 축소)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.9.html` md5 일치.

---

## [3.79.8] - 2026-06-05

### Added
- **노드별 생성·수정 시각 자동 기록(읽기 전용)** — "언제 이 아이디어를 냈는지" 확인용. 각 노드에 `createdAt`(생성)·`updatedAt`(마지막 수정) ISO 타임스탬프를 시스템이 자동 기록.
  - **생성**: `addChild`/`addSibling`(다이어그램)과 텍스트 재파싱으로 새로 생긴 노드(`preserveMetadata`에서 신규 노드에 부여). **수정**: `updateNode`가 `updater` 실행 후 `updatedAt` 갱신.
  - **보존**: `sanitizeNode` 화이트리스트에 `createdAt/updatedAt` 추가(로드 시 유지), `preserveMetadata`가 재파싱 간 보존(라벨 경로 매칭). `serializeTree`·`serializeTreeContent`는 비-`_` 필드라 자동 유지(저장·드라이브 동기화 포함).
  - **표시**: 우측 패널 "기록" 섹션에 `🟢 생성`/`✏️ 수정`(다를 때만) 읽기 전용 텍스트(`fmtTimestamp` → `YYYY.MM.DD HH:mm`). 편집 입력칸 없음 → **사용자가 임의로 바꿀 수 없음**. (기록이 없는 기존 노드는 표시 안 함.)

### Technical Notes
- node 시뮬 6/6 통과(생성=수정 / 수정 시 createdAt 유지 / 로드 보존 / 비문자 무시 / 포맷).
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.8.html` md5 일치.

---

## [3.79.7] - 2026-06-05

### Changed (모바일)
- **터치 제스처 지원 — Pointer Events 전환 + 핀치 줌** (감사 #5) — 팬/줌/관계선 핸들 드래그가 마우스 전용(`mousedown/move/up`, `wheel`)이라 휴대폰·태블릿에서 캔버스 팬·줌이 사실상 불가능했음. → 패닝을 **Pointer Events**(`pointerdown/move/up/cancel` + `setPointerCapture`)로 전환(마우스·터치·펜 공통). **두 포인터 = 핀치 줌**(두 손가락 거리 비율로 줌, 중점 기준 스크롤 보정), 한 포인터 = 패닝. `.canvas-scroll`에 `touch-action: none`을 줘 브라우저 기본 제스처와 충돌 제거. 관계선 핸들 드래그도 `onPointerDown` + `pointermove/up`으로 전환해 터치로 점 이동 가능. 마우스 동작은 동일하게 유지(Pointer Events가 마우스도 처리).

### Technical Notes
- 후속(미적용): 호버로만 보이는 노드 버튼을 `@media (hover:none)`에서 상시 표시, 탭 타깃 44px 확대 — 별도 진행 예정.
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.7.html` md5 일치.

---

## [3.79.6] - 2026-06-05

### Changed
- **변경 이력 창 페이지네이션(앱 내 더 보기)** — 기존엔 앱 내장 이력이 2개뿐이고 그 이전은 외부 링크였음. → `RECENT_CHANGES`를 최근 사용자용 16개 버전으로 확장하고, 변경 이력 뷰에서 **처음 10개만 표시 → "더 읽기"로 10개씩 추가**(`clVisible` 상태, 뷰 열 때 10으로 리셋). 모두 표시하면 "그 이전 버전의 전체 변경 이력 보기" 외부 링크로 폴백. 업데이트 팝업은 `find(version===APP_VERSION)`로 현재 버전만 보여주므로 목록 확장에 영향 없음.

### Technical Notes
- 워크플로 변경: `RECENT_CHANGES`를 2개 고정에서 "최근 사용자용 다수 버전 유지"로 전환(신규 버전은 맨 위에 prepend).
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.6.html` md5 일치.

---

## [3.79.5] - 2026-06-05

### Changed (접근성)
- **시작 다이얼로그 키보드 접근 + 전역 포커스 표시** (감사 #4) — 첫 실행/재방문 시 뜨는 "다시 오셨네요" 선택지가 클릭 전용 `<div>`였음(키보드/스크린리더로 선택 불가). → `role="radiogroup"`/`role="radio"`·`tabIndex={0}`·`aria-checked`와 Enter/Space 핸들러, 모달에 `role="dialog" aria-modal="true" aria-label` 추가. 입력칸 `outline:none`으로 키보드 포커스가 안 보이던 것을 전역 `:focus-visible` 규칙으로 보완.

### Technical Notes
- 후속(미적용): 모든 아이콘 버튼 `aria-label`, 모달 Tab 포커스 트랩/복원 — 별도 진행 예정.
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.5.html` md5 일치.

---

## [3.79.4] - 2026-06-05

### Fixed (정확성)
- **트리 변경자를 함수형 `setTree(prev => …)` 업데이트로 전환** (감사 #2) — 기존엔 변경자들이 바깥 `tree`를 비함수형으로 `cloneTree(tree)`해, 같은 렌더 세대에서 두 동작이 연달아 fire되면 두 번째가 첫 번째 변경을 덮어써 편집이 누락될 수 있었음(키보드 반복 Alt+방향/Space, 빠른 연속 입력 등). → 키보드·반복으로 도달 가능한 구조 변경자(`updateNode`·`addChild`·`addSibling`·`deleteNode`·`moveSibling`·`outdentNode`·`indentNode`·`toggleNodeIcon`·`setNodeSide`·`toggleCollapse`·`expandAll`·`collapseToFirstLevel`)를 `setTree(prev => { const nt = cloneTree(prev); …; return nt; })`로 전환. 생성/삭제는 `id`·다음 선택값을 미리 계산해 부수효과를 보존하면서 실제 변경은 `prev` 위에서 수행. (단일 클릭 전용 링크/그룹/경계 op은 경쟁이 불가능해 그대로 둠.)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.4.html` md5 일치.

---

## [3.79.3] - 2026-06-05

### Changed (성능 · 정확성)
- **캔버스 SVG/노드 요소를 `useMemo`로 분리** (감사 #1) — 렌더 본문의 4개 인라인 IIFE(자유그룹·경계·부모자식 연결선·노드)가 매 렌더마다 전체 트리를 재순회하고 React 요소를 재생성했음(토스트·줌바·드라이브 상태·검색 타이핑·호버 등 무관한 리렌더 포함). → `groupEls`(`[tree, selectedGroupId]`)·`boundaryEls`(`[tree]`)·`connectorEls`(`[tree]`)·`nodeEls`(`[tree, selectedId, dropTargetId, editingId, searchOpen, searchMatchIds, searchPos, focusIds, tagVisibleIds, iconVisibleIds, groupSelectIds, settings]`)로 분리. `_x/_y`는 `layoutTree(tree)`가 매 렌더 갱신하지만 값은 tree 변경 시에만 달라지므로 tree를 키로 둠(콜백은 기존 `nodeActionsRef`로 라우팅돼 항상 최신). 무관한 리렌더에서 트리 재순회·요소 재생성을 건너뜀.
- **`autoSide`를 내용 해시에서 제외** (감사 #3) — `serializeTreeContent`가 `_` 접두 키만 제거해 `layoutTree`가 렌더 중 배정하는 파생값 `autoSide`가 콘텐츠에 포함됐음 → 파싱/로드 직후 사용자가 아무것도 안 해도 "내용 변경"으로 보여 헛자동저장·가짜 "다른 기기 최신본" 경고 유발. → `delete n.autoSide` 추가(사용자 의도인 `pinnedSide`는 유지). node 시뮬 3/3 통과.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.3.html` md5 일치.

---

## [3.79.2] - 2026-06-05

### Changed (성능)
- **타이머 표시를 `<TimerChip>` 컴포넌트로 분리** — 기존엔 250ms `tick`이 `setTimerDisplayMs`로 App 전체를 **초당 4회 리렌더**(매번 `layoutTree` + SVG 4블록 재생성)했음. → 카운트다운 표시·urgent 판정을 자체 250ms 인터벌을 가진 `TimerChip`이 담당하게 분리. App의 `tick`은 마일스톤·종료 처리만 남겨 빈번한 리렌더 제거(`timerDisplayMs` 상태 및 setter 6곳·관련 effect 2개 삭제). 타이머 동작(시작/일시정지/재개/리셋/마일스톤/이스터에그)은 동일.
- **jsPDF 지연 로드** — 렌더 차단 `<script>`(head)를 제거하고 `loadJsPDF()`로 **PDF 내보낼 때 처음 1회만** 동적 주입(SRI 유지). `buildPDFBlob`이 `await loadJsPDF()` 후 사용. 대부분 세션에서 ~350KB 다운로드·파싱이 사라져 초기 로딩이 빨라짐.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.2.html` md5 일치.

---

## [3.79.1] - 2026-06-05

### Fixed
- **About 메뉴가 파일 다운로드되던 문제** — iframe `src`가 확장자 없는 `https://www.redmir.net/about`였는데, 이 경로는 `text/html`로 서빙되지 않아 브라우저가 인라인 렌더 대신 **다운로드**로 처리(iframe은 빈 화면). → 문서(`/BrainBloom_UserGuide.html`)와 동일하게 **`https://www.redmir.net/about.html`**(명시적 `.html`)로 변경 → `text/html`로 정상 렌더, 앱 안에서 바로 열림.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.1.html` md5 일치.

---

## [3.79.0] - 2026-06-05

### Added
- **설정에 'About' 메뉴 추가 — 공지·개발자의 말** — 설정 상단 문서 바로가기 줄에 `About` 카드를 추가. 클릭하면 앱 안에서 오버레이(`iframe`)로 **`https://www.redmir.net/about`** 를 불러와 보여줌(열 때마다 `?t=nonce` 캐시버스트로 최신본). 개발자는 새로 추가한 **`about.html`** 한 파일만 편집·커밋하면 앱 재배포 없이 공지/메시지가 즉시 반영됨. `showAbout`/`aboutNonce` 로컬 상태로 SettingsModal에 자체 포함, 바깥/✕ 클릭으로 닫힘.

### Changed
- 설정의 **사용 설명서·기술 문서 카드 아이콘 크기를 절반으로** 축소(`fontSize` 20 → 10).

### Technical Notes
- 신규 파일 `about.html`(GitHub Pages가 `/about`로 서빙). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.79.0.html` md5 일치.

---

## [3.78.8] - 2026-06-05

### Changed
- **같은 탭 새로고침 시 OAuth 팝업 완전 제거 — 토큰 탭-세션 보관(사용자 동의)** — v3.78.7로 팝업을 '첫 상호작용 1회'로 줄였지만, 새로고침마다 여전히 GIS 토큰 창이 떴음. → 액세스 토큰을 **sessionStorage**(`bb_drive_tok`, `{t, e}`)에 보관: 토큰 수신 시 저장(`saveDriveTokenToSession`), 마운트 시 만료 2분 전까지 유효하면 메모리로 복원(`restoreDriveTokenFromSession`)해 **`requestAccessToken` 호출 자체를 생략**(→ 같은 탭 새로고침에 팝업 0회, 즉시 `driveSignedIn` + `syncBaselineOnConnect`). 만료/없으면 기존 '대기 → 첫 상호작용 연결'로 폴백. 로그아웃·revoke 시 세션 토큰 삭제(`clearDriveTokenSession`). **localStorage가 아닌 sessionStorage라 탭을 닫으면 자동 삭제**되고 권한은 `drive.file`·약 1시간 한정이라 노출 위험이 작음(사용자 동의 하 결정). 새 탭·새 방문·1시간 경과는 보안상 1회 팝업 유지(백엔드 없는 한 불가피).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.8.html` md5 일치.

---

## [3.78.7] - 2026-06-05

### Changed
- **새로고침 시 구글 드라이브 OAuth 팝업 깜빡임 제거 — 지연 연결** — 마운트 시 즉시 `requestDriveToken`을 호출해 GIS 토큰 팝업이 매 새로고침마다 잠깐 열렸다 닫혔음(백엔드 없는 implicit 플로우는 완전 무팝업이 불가). → 새로운 `driveLinkedPending` 상태를 도입해, 연결 이력이 있으면 마운트 땐 토큰을 받지 않고 '연결됨(대기)'로 두었다가, **첫 `pointerdown`/`keydown`(사용자 제스처) 때 `requestDriveToken(false)`로 1회 조용히 연결**(제스처 직후라 팝업 차단도 덜 됨). 보기만 하고 떠나면 팝업 0회. 대기 중에는 헤더 '설정' 색·연결 배지가 빨강/미연결로 깜빡이지 않도록 `(!driveSignedIn && !driveLinkedPending)` 조건으로 보정. 모니터(30초/10분)·자동저장은 기존대로 `driveSignedIn` 게이트라 대기 중엔 동작하지 않고, 재연결 후 정상 동작.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.7.html` md5 일치.

---

## [3.78.6] - 2026-06-05

### Fixed
- **★ 접힘 상태 새로고침 시 노드 겹침 — 진짜 근본 원인 수정** — `layoutTree` 4단계 정규화가 `walk`(전체 순회)로 좌표 경계를 계산했는데, **접힌 노드의 자식은 `measure`/`place`에서 제외되어 `_x/_y`가 `undefined`**. `walk`이 이들을 방문하면서 `Math.min(Infinity, undefined) = NaN` 이 전파 → 모든 노드의 `_x`가 `NaN` → 전부 원점(0,0)에 쌓여 겹쳐 보였음. "전체 펼치기"를 누르면 모든 자식이 측정·배치돼 `undefined`가 사라지므로 정상화됐던 것(그동안의 미스터리). → 정규화의 경계 계산·시프트를 **`walkVisible`(접힌 자식 제외)** 로 변경. node 시뮬레이션으로 재현·검증(`walk`: minX=NaN, span=0 → 겹침 / `walkVisible`: span=440 → 정상). 이로써 `v3.77.4`의 자가복구 "전체 펼치기"는 더 이상 오발동하지 않으며 접힘 상태가 보존됨.
- 부수 효과: `layoutTree`가 반환하는 `width/height`도 이제 **보이는 노드 기준**의 정확한 크기(이전엔 접힌 자식의 무효 좌표 포함).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.6.html` md5 일치.

---

## [3.78.5] - 2026-06-05

### Fixed
- **새로고침 시 화면이 선택 노드로 튀던 문제** — 뷰 복원이 `centerNode`로 마지막 선택 노드를 강제로 화면 중앙에 옮겨서, 선택을 해제하지 않은 채 줌만 줄여 전체를 보고 있을 때 새로고침하면 화면이 그 노드로 휙 끌려갔음(배율도 달라 보임). → 복원을 **"떠날 때 화면 그대로"**로 변경: 선택 highlight만 복원하고 스크롤(배율·위치)은 저장값 그대로 두어 화면이 움직이지 않음. 접힘 상태를 먼저 동일하게 맞추므로 저장된 `scrollLeft/scrollTop`이 정확히 일치. `rAF` + 240ms/700ms 3회 같은 좌표로 재적용해 지연 레이아웃이 덮는 것을 방지.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.5.html` md5 일치.

---

## [3.78.4] - 2026-06-05

### Changed
- **접힘/펼침 상태까지 1초 저장·복원** — 1초 간격 `viewState` 저장에 `collapsedIds`(현재 접힌 노드 id 배열, `walk`로 수집)를 추가. 복원 시 저장된 `collapsedIds`를 `cloneTree`로 트리에 반영(`setTree` 후 effect 재실행 → 중앙 정렬로 이어짐). 새로고침하면 접은 가지·펼친 가지가 그대로 복원됨. interval 클로저가 최신 트리를 보도록 `viewTreeRef` 추가.
- **선택 노드 중앙 복원 강화** — 우측 치우침 보정. 복원 시 `requestAnimationFrame` ×2 후 `centerNode`, 그리고 t1(220ms)·t2(720ms) 2단계로 재보정해 자동맞춤이 덮어쓴 경우에도 정확히 중앙에 맞춤.

### Added
- **드라이브 연결 시 자동저장 기본 ON** — `handleDriveSignIn`에서 베이스라인 동기화 후, 사용자가 토글을 직접 만진 적(`autoSaveSetByUser`) 없으면 `driveAutoSave`를 켜고 안내 토스트 표시. 자동저장 토글 변경 시 `autoSaveSetByUser: true` 기록.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.4.html` md5 일치.

---

## [3.78.3] - 2026-06-05

### Changed
- **뷰 복원 방식 개선 — 선택 노드 중앙 + 1초 저장** — 기존 스크롤 좌표 저장은 맵 크기가 바뀌면 어긋났음(우측 치우침 등). → `viewState`에 `{zoom, selectedId, scrollLeft, scrollTop}`를 **1초 간격(`setInterval`)** 저장. 복원 시 줌을 맞추고, 선택했던 노드가 있으면 `centerNode`로 화면 중앙에(없으면 저장된 스크롤 폴백). `selectedIdRef`로 interval 클로저 최신화.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.3.html` md5 일치.

---

## [3.78.2] - 2026-06-05

### Fixed
- **자가복구 오판으로 정상 맵이 펼쳐지던 문제** — 겹침 판정을 `getBoundingClientRect`(화면 좌표)로 했는데, 자동맞춤으로 줌이 작아지면 정상 맵도 화면상 노드 간격이 좁아져 "겹침"으로 오판 → 자동 전체 펼침/배율 변경이 일어남. → 판정을 **줌·스크롤과 무관한 논리 좌표(`_x/_y`) span**(`walkVisible`, < 60px)으로 변경. 정상 맵은 논리 span이 수천 px라 발동 안 함 → 접힘·배율·위치 유지. 진짜 겹침(논리 span ≈ 0)일 때만 복구.

### Changed
- **드라이브 저장 안내 간소화** — 저장 시작 토스트를 `💾 저장중`으로 변경.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.2.html` md5 일치.

---

## [3.78.1] - 2026-06-05

### Changed
- **드라이브 저장 시작 안내 문구** — Ctrl/⌘+Shift+S 저장 시작 토스트를 3줄로 변경("💾 저장을 시작했어요 / 💾 구글 드라이브(클라우드)라 보통 10초쯤 걸려요, / 💾 저장은 제가 할 테니 집중해서 정리하고 계세요"). `.toast`에 `white-space: pre-line`·`text-align:center`·`line-height`·`max-width` 추가(여러 줄 지원).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.1.html` md5 일치.

---

## [3.78.0] - 2026-06-05

### Added
- **뷰 상태(줌·스크롤) 유지** — 새로고침해도 맵의 줌 비율·스크롤 위치를 그대로 복원. IndexedDB `viewState`에 `{zoom, scrollLeft, scrollTop}` 디바운스(500ms) 저장, 로드 시 복원하며 `didAutoFitRef.current=true`로 자동 맞춤보다 우선. 스크롤은 레이아웃·줌이 잡힌 뒤(`pendingScrollRef`) 적용.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.78.0.html` md5 일치.

---

## [3.77.4] - 2026-06-05

### Fixed
- **겹침 응급 복구 — 접힘 상태면 자동 전체 펼침** — 사용자 확인 결과 겹침이 났을 때 **"전체 펼치기"(collapsed 해제)만 정상화**시킴(줌·스크롤·`cloneTree` 자가복구 모두 무효). → 자가복구가 겹침을 감지하고 `tree`에 접힌 노드가 있으면, `cloneTree` + 모든 `collapsed` 제거 + `setTree`로 자동 펼침(`showToast` 안내). 접힘이 없으면 기존 줌/스크롤/배치 리셋 폴백. 진단 로그에 `layoutW`/`hasCollapsed` 추가.
  - 근본 원인(접힘 상태에서 `layoutTree`가 겹침 좌표를 내는 정확한 조건)은 정적 분석으로 미특정 — 추적 중. 본 변경은 확실한 응급 복구.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.77.4.html` md5 일치.

---

## [3.77.3] - 2026-06-05

### Fixed
- **겹침 자가복구 강화** — v3.77.2 자가복구는 표본 노드가 `완전 동일 좌표`일 때만 발동(`Set.size <= 1`)이라, "약간 어긋난 채" 겹친 경우(특히 Drive 팝업/버전업 첫 로드)를 놓쳤음. → 표본 12개의 화면 좌표 `span`(가로/세로 펼침)이 30px 미만이면 겹침으로 감지. 복구도 `setZoom(1)` + 스크롤 0 + `didAutoFitRef` 리셋 + `setTree(cloneTree)`로 강화(최대 4회). 진단용 `console.warn`(span·zoom·layoutW) 추가.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.77.3.html` md5 일치.

---

## [3.77.2] - 2026-06-05

### Fixed
- **노드 겹침 진짜 원인 — React.memo가 in-place 좌표 변경을 못 봄** — `layoutTree`가 노드 객체를 in-place로 좌표만 바꿔치기(참조 동일)하는데, `nodeViewPropsEqual`이 `if (a === b) return true`로 노드 참조만 보고 리렌더를 건너뛰어, 첫 렌더에 잘못 잡힌 좌표(특히 Drive 연결 팝업 등으로 타이밍이 어긋난 버전업 첫 로드)가 이후 고쳐져도 화면에 반영되지 않음. → 좌표를 값 prop(`nx/ny/nw/nside`)으로 전달하고 `nodeViewPropsEqual`에서 값으로 비교(`a===b`보다 먼저)해 변화 감지.
- **겹침 자가 감지·복구(이중 안전장치)** — 표본 노드 12개의 실제 화면 좌표(`getBoundingClientRect`)가 전부 동일하면(겹침) `setZoom` 정상화 + `setTree(cloneTree)`로 강제 재배치(최대 3회).

### Added
- **통계에 "경계 수"** — `.stats`에 `tree.boundaries.length` 행 추가. (자유 그룹 "그룹 수"와 별개)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.77.2.html` md5 일치.

---

## [3.77.1] - 2026-06-05

### Added
- **통계에 "그룹 수" 추가** — 우하단 `.stats`에 자유 그룹 개수(`tree.groups.length`) 행 추가. `stats` useMemo에 `groups` 포함.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.77.1.html` md5 일치.

---

## [3.77.0] - 2026-06-05

### Added
- **영감 격언 (노드 미선택 시)** — 우측 패널이 빈 상태일 때 `INSPIRATION_QUOTES`(창작 격려문 100개)에서 랜덤 1개 표시 + 회색 안내문("다이어그램의 노드를 클릭하면 …"). 선택 해제(`selectedId`가 null)될 때마다 `emptyQuoteIdx`를 새로 뽑아 신선하게.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.77.0.html` md5 일치.

---

## [3.76.2] - 2026-06-05

### Fixed
- **새로고침 시 가끔 노드가 중앙에 겹쳐 보이던 문제** — `layoutTree`는 tree에 좌표(`_x/_y`)를 써넣는 side-effect가 있는데 이를 `useMemo`(deps `[tree]`)에서 호출했음. React 동시성 렌더 등 드문 타이밍에 이 mutate가 누락되면 모든 노드가 `_x` 미설정 → `left:0`으로 한 점에 겹침. `layoutInfo`를 매 렌더 `layoutTree(tree)` 직접 호출로 변경해 좌표를 항상 보장(결정적·O(n), 노드는 `React.memo`로 `_x` 동일 시 리렌더 skip이라 비용 미미).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.76.2.html` md5 일치.

---

## [3.76.1] - 2026-06-05

### Added
- **좌측 패널 하단 "패널 닫기" 버튼** — 우측 패널과 대칭으로 좌측 "아이디어 입력" 패널 하단에 `panel-close-btn`(`✕ 패널 닫기`) 추가. 클릭 시 `settings.showLeftPanel=false`. (다시 켜기: 설정 > 화면.)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.76.1.html` md5 일치.

---

## [3.76.0] - 2026-06-05

### Added
- **관계선 우클릭 옵션 메뉴** — 관계선(hit 영역) 위에서 `contextmenu` → 옵션 메뉴(`linkMenu`). 모양(곡선/직선/직각·`type`), 선(점선/실선·`dash`), 두께(가늘게1/보통2/굵게3.5·`width`), 삭제(`removeLink`).
  - 데이터: `link.dash`(`'solid'`, 점선이 기본), `link.width`(숫자, 2가 기본). `updateLinkStyle(from,to,patch)`로 변경(기본값이면 키 제거). `sanitizeNode`/`preserveMetadata`에 `dash`/`width` 보존.
  - 렌더: `cross-link-path`에 인라인 `strokeWidth`/`strokeDasharray`(점선은 두께 비례 `lw*3 lw*2`). hit `onContextMenu`로 메뉴 오픈(`preventDefault`+`stopPropagation`으로 배경 메뉴와 분리).

### Technical Notes
- babel OK, 노드 시뮬 12/12(스타일 토글·sanitize·점선 패턴), `index.html` ↔ `seahyun/brainstorm_v3.76.0.html` md5 일치.

---

## [3.75.2] - 2026-06-05

### Fixed
- **선택된 관계선이 노드에 가려 핸들이 안 보이던 문제** — 관계선/핸들은 연결선 SVG(`.connections`, 노드 아래 레이어)에 있어, 선택해도 노드 뒤로 가려졌음. `crossLinkEls`를 `{ base, overlay }`로 분리: 선택된 관계선의 **선·핸들 3개는 노드 위 오버레이 SVG(`.connections-overlay`, z-index 50)** 로 올리고, 선택 해제 시 `base`로 원복.
  - hit 영역·라벨은 `base`에 유지(노드보다 아래) → 노드 클릭을 가로채지 않음. `cross-link-path`는 `pointer-events:none`이라 overlay 선 클릭은 통과해 base hit로 선택/해제.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.75.2.html` md5 일치.

---

## [3.75.1] - 2026-06-05

### Fixed
- **관계선 곡선 핸들을 좌클릭으로 못 옮기던 문제** — 핸들/hit/그룹은 `pointer-events:auto`로 클릭 가능하게 했지만 패닝 제외 목록(`isPanTarget`)에 없어, 좌클릭이 캔버스 패닝(native `mousedown`)에 가로채였음(React `stopPropagation`은 native 리스너를 못 막음). `isPanTarget`에 `.cross-link-handle`, `.cross-link-hit`, `.group-rect`, `.group-label` 제외 추가 → 좌클릭 드래그로 핸들 이동.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.75.1.html` md5 일치.

---

## [3.75.0] - 2026-06-05

### Changed
- **관계선 곡선 — 제어 핸들 1개 → 3개(Catmull-Rom 스플라인)** — 곡선(type curve)을 2차 베지어(제어점 1개)에서 3 웨이포인트를 통과하는 부드러운 스플라인으로 변경. 선택 시 핸들 3개가 나타나 S자 등 자유 곡선 가능.
  - 데이터: `link.points: [{dx,dy}×3]`(두 노드 중심 중점 기준 오프셋). 레거시 `link.curve`(단일)는 fallback으로 중간 웨이포인트로 승격. `sanitizeNode`/`preserveMetadata` 재매핑에 `points` 보존.
  - 렌더: `catmullRomPath([s, P1, P2, P3, e])`(Catmull-Rom→cubic), 시작/끝은 P1/P3 방향 `rectEdge`. 라벨은 P2.
  - 드래그: `startLinkDrag(e, l, mid, index, basePoints)` — 잡은 핸들(index)만 갱신, 나머지 유지. `linkDrag`에 `index` 추가, `setLinkPoints`로 3점 저장.
  - 자동 회피: 사용자가 핸들을 안 건드린 기본 모양(`points` 없음)일 때만 중간점에 적용. `points`가 있으면 의도 존중(회피 안 함).

### Technical Notes
- babel OK, 노드 시뮬 8/8(catmullRom·기본3점·드래그 index 교체), `index.html` ↔ `seahyun/brainstorm_v3.75.0.html` md5 일치.

---

## [3.74.0] - 2026-06-05

### Added
- **자유 그룹 (떨어진 노드 여러 개 묶기)** — 기존 "경계/그룹"(한 노드+하위)과 별개로, **Shift+클릭**으로 임의의 노드 여러 개를 골라 하나의 그룹으로 묶음.
  - 데이터: `tree.groups: [{ id, nodeIds[], label, color }]`. `sanitizeNode`(노드 2개 미만/중복 정리, 라벨 40자·기본값), `preserveMetadata` 재매핑(라벨키→새 id, 살아남은 노드 2개 이상일 때만 유지).
  - 다중 선택: `groupSelectIds` + Shift+클릭 토글(`onSelect(e)`로 이벤트 전달, `NodeViewBase` `onClick`도 `onSelect(e)`). 선택 노드는 `.node.group-sel`로 강조(`nodeViewPropsEqual`에 `isGroupSel` 추가).
  - 2개 이상 선택 시 상단 "그룹으로 묶기" 배너(`createGroup`). 그룹 박스(노드 묶음 bbox + pad, 가장 아래 SVG 레이어)를 클릭하면 관리 배너에서 이름(`updateGroup`)·색(6색 팔레트)·해제(`removeGroup`). 빈 캔버스 클릭 시 다중선택·그룹선택 해제.
  - SVG가 `pointer-events:none`이라 `group-rect`/`group-label`에 재활성화.

### Technical Notes
- babel OK, 노드 시뮬 9/9(다중선택 토글·bbox·sanitize·remap), `index.html` ↔ `seahyun/brainstorm_v3.74.0.html` md5 일치.

---

## [3.73.0] - 2026-06-05

### Performance
- **관계선 렌더 메모이제이션** — 연결선 SVG의 관계선(cross-link) 그리기를 매 렌더 IIFE에서 `crossLinkEls = useMemo([tree, selectedLinkKey, linkDrag])`로 추출. 타이머·토스트·호버 등 관계없는 리렌더에서 관계선(+자동 회피 충돌검사)을 다시 계산하지 않음 → 관계선·노드가 많은 큰 맵에서 편집/드래그 부드러움 개선.
  - 드래그 핸들의 `startLinkDrag`는 `startLinkDragRef`(매 렌더 갱신)로 참조해 메모 의존성에서 제외(stale 클로저 방지). 로직 자체는 동일(기존 곡선/종류 시뮬 6/6 유효).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.73.0.html` md5 일치.

---

## [3.72.2] - 2026-06-05

### Removed
- **죽은 코드 제거** — 어디서도 호출되지 않던 함수/상수 제거: `ALL_ICONS`, `nextIdeaLabel`, `hexToRgb`, `exportCSV`, `exportJSON`, `exportMarkdown`. (실제 내보내기는 `buildCSVString`/`treeToMarkdown`/`JSON.stringify`를 직접 쓰는 경로가 담당 — 동작 변화 없음.) 약 65줄·2.4KB 감소.

### Technical Notes
- babel OK, 제거 심볼 잔존 0 확인, `index.html` ↔ `seahyun/brainstorm_v3.72.2.html` md5 일치.

---

## [3.72.1] - 2026-06-05

### Fixed
- **트랙패드 팬에서 줌 바가 안 뜨던 문제** — 캔버스 패닝 시 줌 바 표시는 마우스 드래그(`isPanning`)에만 연결돼 있어, 맥북 트랙패드 2손가락 스와이프(=`Ctrl` 없는 `wheel`)로 캔버스를 밀 땐 줌 바가 뜨지 않았음. `handleWheel`의 비줌(else) 분기에서도 줌 바를 표시(2.5초 자동 숨김, 툴바 hover 시 유지)하도록 추가.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.72.1.html` md5 일치.

---

## [3.72.0] - 2026-06-05

### Added
- **관계선 종류 선택(곡선/직선/직각선)** — 관계선을 클릭해 선택하면 상단에 종류 선택 배너(`link-edit-banner`)가 떠서 곡선·직선·직각선 중 고를 수 있음. 데이터: `link.type` (`'curve'` 기본 | `'straight'` | `'elbow'`).
  - `straight`: 두 노드 중심 방향 가장자리 직선. `elbow`: 수평 우선 ㄱ자(`M s L midx,sy L midx,ey L e`). `curve`: 기존 2차 베지어 + 핸들.
- **곡선 자동 노드 회피** — 곡선이고 수동 `curve` 조절이 없을 때, 베지어를 샘플링(`bezierHitsNode`)해 다른 노드 사각형(끝점 노드 제외, 4px 여유)과 충돌하면 제어점을 1.4~4.2배까지·양방향으로 키워가며 안 걸치는 곡률을 탐색. 수동 조절(`l.curve`) 관계선은 의도 존중으로 회피 안 함.
  - 보존: `sanitizeNode`(`type` 화이트리스트), `preserveMetadata` 링크 재매핑에 `type` 유지.

### Technical Notes
- babel OK, 노드 시뮬 6/6(elbow path·직선 가장자리·자동회피 충돌해소·장애물 없을 때 무회피), `index.html` ↔ `seahyun/brainstorm_v3.72.0.html` md5 일치.

---

## [3.71.1] - 2026-06-05

### Changed
- **하단 모아보기 바 라벨·버튼 문구 정리** — 라벨을 영어로(`🎨 아이콘`→`🎨 Icons`, `🏷 태그`→`🏷 Tags`). 선택을 지우는 버튼 문구를 "선택 해제"로 통일(아이콘 `✕ 필터 해제`→`✕ 선택 해제`, 태그 `✕ 전체`→`✕ 선택 해제`). 선택된 칩 hover 툴팁도 `필터 해제`→`선택 해제`.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.71.1.html` md5 일치.

---

## [3.71.0] - 2026-06-05

### Added
- **관계선 곡선 + 드래그 조절** — cross-link를 직선(`<line>`)에서 2차 베지어 곡선(`<path d="M s Q c e">`)으로 변경. 관계선을 클릭해 선택하면 제어점에 핸들이 나타나고, 핸들을 끌어 곡선 모양을 자유롭게 조절. 조절값은 저장됨.
  - 제어점은 두 끝점 **중점 기준 오프셋**(`link.curve = {dx, dy}`, 맵 논리좌표)으로 저장 → 노드가 이동해도 곡률 유지. `curve`가 없으면 기본 곡률(선분 수직 방향, 길이의 18%·상한 80) 적용.
  - 시작/끝점은 제어점 방향으로 노드 사각형 가장자리(`rectEdge`)에서 출발/도착. 라벨은 베지어 t=0.5 지점.
  - 드래그: 핸들 `onMouseDown` → `window` `mousemove`/`mouseup`. 마우스 화면좌표→맵 논리좌표 변환은 `(clientX − svgRect.left) / zoom`(연결선 SVG는 `transform: scale(zoom)` 부모 안). 드래그 중엔 `linkDrag` 상태로 미리보기, 놓을 때 `setLinkCurve`로 확정(`maybePushHistory`).
  - 선택/해제: hit 영역(투명 굵은 `path`, `pointer-events:stroke`) 클릭으로 토글, 빈 캔버스 클릭 시 해제. 부모 SVG가 `pointer-events:none`이라 hit·handle에 재활성화.
  - 보존: `sanitizeNode`(curve 유효성 검사·반올림)·`preserveMetadata` 링크 재매핑에 `curve` 유지.

### Technical Notes
- babel OK, 곡선 수학 노드 시뮬 13/13(rectEdge·기본곡률·좌표변환·커밋임계·라벨), `index.html` ↔ `seahyun/brainstorm_v3.71.0.html` md5 일치.

---

## [3.70.4] - 2026-06-05

### Changed
- **하단 모아보기 — 뷰포트 기준 정중앙 고정** — `.bottom-bars`를 `position: absolute`(캔버스 영역 기준, 우측 패널이 열리면 영역이 좁아져 왼쪽으로 치우침) → `position: fixed`(뷰포트 기준)로 변경. 좌/우 패널 유무와 무관하게 브라우저 전체 폭의 정중앙에 고정.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.70.4.html` md5 일치.

---

## [3.70.3] - 2026-06-05

### Changed
- **하단 모아보기 정중앙 정렬** — `.bottom-bars` 래퍼를 `left:50% + translateX(-50%)`(absolute+flex 환경에서 너비 계산이 모호)에서 `left:0/right:0` 전체 폭 + `justify-content:center`로 변경해, 아이콘 바+태그 바 묶음을 화면 정중앙에 정확히 정렬. 컨테이너는 `pointer-events:none`(빈 공간 클릭 통과), 바(자식)만 `pointer-events:auto`.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.70.3.html` md5 일치.

---

## [3.70.2] - 2026-06-05

### Changed
- **하단 모아보기 한 줄 배치** — 캔버스 하단의 "아이콘 모아보기" 바와 "태그 필터" 바를 세로로 쌓던 것을 한 줄(가로)에 나란히 배치. 화면 폭을 넘으면 `flex-wrap`으로 자동 줄바꿈.
  - 새 `.bottom-bars` 래퍼(absolute 하단 중앙)로 두 바를 감싸고, `.icon-filter-bar`/`.tag-filter-bar`는 절대위치를 떼고 래퍼 안의 static pill로 전환(각 `max-width: 100%`). 아이콘 바의 동적 `bottom`(58/16) 인라인 스타일 제거.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.70.2.html` md5 일치.

---

## [3.70.1] - 2026-06-05

### Changed
- **아이콘 모아보기 바 — 한 줄(가로)로 펼침** — 줄(iconRows) 구성에 따라 세로로 쌓던 방식을 폐기하고, 사용 중 아이콘을 하나의 바에 가로로 나열. 화면 폭(`max-width: min(92vw, 900px)`) 안에서 한 줄로 펼치고 넘칠 때만 `flex-wrap`으로 자동 줄바꿈. 정렬 순서는 줄 구성 순서를 따르고, 어느 줄에도 없는 사용 아이콘은 맨 뒤로.
  - `iconFilterRows`(줄별 묶음) → `iconFilterChips`(단일 배열, 중복 제거)로 교체. `.icon-filter-row` 제거, `.icon-filter-bar`를 단일 pill(둥근 사각형)로. 우측 패널 피커·설정 줄 편집기는 그대로(줄 구성 유지).

### Technical Notes
- babel OK, 시뮬 5/5, `index.html` ↔ `seahyun/brainstorm_v3.70.1.html` md5 일치.

---

## [3.70.0] - 2026-06-05

### Added
- **아이콘 모아보기 (하단 바)** — 맵의 노드에 붙어 있는 아이콘을 화면 하단 바에 모아 표시. 아이콘을 누르면 그 아이콘이 붙은 노드 + 상위만 또렷하게(나머지는 흐리게) — 태그 필터와 동일한 강조 방식.
  - `allNodeIcons`(사용 중 아이콘 집합) → `iconFilterRows`(설정 줄 구성에 맞춰 사용 아이콘만 줄별로 묶고, 어느 줄에도 없는 사용 아이콘은 "기타" 줄). `iconFilter`/`iconVisibleIds`로 강조, `isDimmed`에 합산. 더 이상 없는 아이콘은 필터에서 자동 제거.
  - 하단 바는 태그 바 위에 줄 단위로 쌓임(`bottom`을 태그 유무에 따라 16/58px로 조정).
- **아이콘 줄(행) 구성** — 설정 > 아이콘에서 아이콘을 여러 "줄"로 나눠 정리. 줄 추가/삭제/비우기, 줄을 선택한 뒤 팔레트에서 아이콘을 누르면 그 줄에 추가(다른 줄에 있으면 이동, 중복 방지). 우측 패널 아이콘 피커와 하단 모아보기 바가 이 구성을 따름.
  - 데이터: `settings.iconRows: string[][]`. 옛 `settings.iconChoices`(평면)는 로드 시 1줄짜리 `iconRows`로 승격(마이그레이션) 후 레거시로만 유지. 기본값은 2줄.

### Technical Notes
- 우측 패널 아이콘 피커는 `iconChoices` 평면 그리드 → `iconRows` 줄별 그리드로 변경. `SettingsModal`에 줄 편집 상태(`iconRowSel`)와 헬퍼(`addIconRow`/`removeIconRow`/`clearIconRow`/`toggleIconInSelRow`) 추가.
- babel OK, 로직 노드 시뮬 12/12 통과, `index.html` ↔ `seahyun/brainstorm_v3.70.0.html` md5 일치.

---

## [3.69.1] - 2026-06-05

### Added
- **이스터에그(숨은 연출)** — 화면을 가리지 않는 전체 오버레이(`pointer-events:none`, 5.6초 자동 소멸)로 두 가지 숨은 연출을 추가.
  - **타이머 11연속 클릭**(1.2초 안쪽 간격) → 떠오르는 하트 파티클 + 개인 메시지 카드.
  - **코나미 코드**(↑↑↓↓←→←→ B A) → 떨어지는 꽃잎 파티클 + BrainBloom 메시지.
  - 구현: `easterEgg`/`eggKey` 상태 + `triggerEgg`. 전역 `keydown`(입력칸 무시·`preventDefault` 없음)으로 코나미 시퀀스 추적, 타이머 칩 `onClick` 래퍼(`handleTimerClick`)에서 연속 클릭 카운트. 파티클은 `eggKey`로 매번 재생성, CSS `eggFall`/`eggRise`/`eggBeat`/`eggMsg` 애니메이션.
  - 업데이트 팝업 안내는 트리거를 노출하지 않도록 의도적으로 모호하게("숨은 재미 요소 🥚") 표기.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.69.1.html` md5 일치.

---

## [3.69.0] - 2026-06-05

### Added / Changed
- **아이콘 복원 + 설정 큐레이션** — 아이콘 표시를 되살리되, **설정 > 아이콘**에서 카테고리별로 "보여줄 아이콘"을 고르면(`settings.iconChoices`), 우측 패널의 아이콘 피커(**태그 아래** 배치)에는 **고른 것만** 노출. 노드에 붙인 아이콘은 **태그 아래** 줄에 표시. `nodeHeight`에 아이콘 줄 높이 반영(겹침 방지), `sanitizeNode`/`preserveMetadata` 보존 복구.
- **메타데이터 표시 토글** — 설정에서 노드 "메타데이터(날짜·작업량·비용)" 편집 섹션의 표시 여부(`settings.showMetaPanel`)를 켜고 끌 수 있음.

### Technical Notes
- 아이콘 로직(`ICON_CATEGORIES`/`toggleNodeIcon`)은 이전에 비활성으로 남겨둔 것을 재활용. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.69.0.html` md5 일치.

---

## [3.68.1] - 2026-06-05

### Changed
- 노드 "비용" 입력칸 예시를 달러(`예: $20,040.00`) → **원화(`예: ₩20,000,000`)**로 변경. (비용은 자유 입력 텍스트라 형식 제약 없음.)

---

## [3.68.0] - 2026-06-05

### Added
- **경계/그룹 (⑤)** — 노드 우클릭 "경계로 묶기"(또는 우측 패널 "경계/그룹")로 그 노드 + 보이는 하위 묶음을 둥근 박스로 감쌈. 다시 누르면 해제.
  - 데이터: 루트 `tree.boundaries: [{nodeId}]`. `sanitizeNode` 보존, `preserveMetadata`에서 라벨경로 id 재매핑(노드 삭제 시 자동 드롭). 렌더: 연결선 SVG 맨 아래 레이어에 하위 묶음 bbox(접힘 제외) + `pad`, 색은 anchor 노드 색.

### Technical Notes
- node 시뮬 4/4(접힘 bbox 제외·bbox 계산·경계 remap·삭제 드롭). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.68.0.html` md5 일치.

---

## [3.67.1] - 2026-06-05

### Added
- **패닝 중 배율 버튼 표시** — 바탕(빈 공간) 드래그로 화면을 이동할 때도 줌 툴바(−/＋/⊙/⊡/⊟/⊞)가 표시되고, 멈추면 2.5초 뒤 자동 숨김(툴바에 마우스 올려두면 유지). `isPanning` 변화에 연동한 `useEffect`로 처리.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.67.1.html` md5 일치.

---

## [3.67.0] - 2026-06-05

### Added
- **노드 노트 (④)** — 노드별 긴 메모. 우측 패널 "노트" `textarea`에 입력, 지도에는 절대배치 `📝` 배지(높이 영향 없음, hover 시 미리보기)만 표시.
  - 데이터 `node.note: string`. `sanitizeNode` 보존(4000자 제한), `preserveMetadata`로 텍스트 재파싱 후에도 유지, `React.memo` 비교에 포함. 저장·드라이브 동기화에 반영.

### Technical Notes
- 📝 배지는 `position:absolute`라 노드 높이/레이아웃에 영향 없음(태그 겹침 같은 이슈 회피). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.67.0.html` md5 일치.

---

## [3.66.1] - 2026-06-05

### Changed
- **아이콘(이모지) 기능 제거** — 노드 아이콘 렌더·`nodeWidth`/`nodeHeight`의 아이콘 치수·`sanitizeNode`의 `icons` 보존·관련 CSS(`.node-icons`/`.selected-icons`/`.panel-icon-*`)를 제거. 기존에 붙어 있던 아이콘도 표시되지 않고, 다음 로드 시 데이터에서 정리됨.
  - (참고) `ICON_CATEGORIES`/`toggleNodeIcon` 등 일부 코드는 참조 연쇄가 있어 이번엔 비활성(무해) 상태로 남김 — 추후 죽은 코드 정리 패스에서 제거 예정.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.66.1.html` md5 일치.

---

## [3.66.0] - 2026-06-05

### Added
- **관계선(cross-link) (③)** — 부모-자식이 아닌 임의의 두 노드를 점선 화살표로 연결. 노드 우클릭 → "관계선 시작" → 대상 노드 클릭(Esc 취소). 우측 패널 "관계선"에서 목록·삭제, "관계선 시작" 버튼도 제공.
  - 데이터: 루트 `tree.links: [{from,to[,label]}]`. `sanitizeNode` 화이트리스트 포함, `preserveMetadata`에서 **라벨 경로 기준 id 재매핑**으로 텍스트 재파싱 후에도 유지(끝점 사라지면 자동 드롭). 렌더는 사각형 가장자리↔가장자리 점선 + 화살표 마커.

### Fixed
- **태그 노드가 화면 중앙에 겹쳐 뭉치던 문제** — `nodeHeight`가 태그 칩 줄 높이를 반영하지 않아 노드가 슬롯보다 커져 겹쳤음. 태그 줄 수를 높이에 더하도록 수정.
- **태그 한글 입력 중복** — "가나다" 입력 시 "가나다"+"다"로 두 번 들어가던 문제. 태그 입력에 IME 조합 가드(`isComposing`/keyCode 229) 추가. `preserveMetadata`가 **태그도 보존**하도록 보완(텍스트 편집 시 태그 유실 방지).

### Changed
- 우측 패널에서 **"태그"를 색상 바로 아래로** 이동.
- 우측 패널의 **아이콘(이모지) 선택 목록(분류·기호·활동) 제거** — 패널 정리(기존 노드에 이미 붙은 아이콘 표시는 유지).

### Technical Notes
- node 시뮬: 태그 7/7 + 관계선 5/5 통과. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.66.0.html` md5 일치.

---

## [3.65.0] - 2026-06-05

### Added
- **태그 + 태그 필터** — 노드에 태그를 달고, 캔버스 하단 "🏷 태그" 바에서 원하는 태그만 또렷하게 보기(매칭 노드 + 조상 강조, 나머지 흐림). "수백 개 → 핵심만"이라는 앱 컨셉을 강화하는 첫 기능(추천 ②).
  - 노드 데이터에 `tags: string[]` 추가. `sanitizeNode` 화이트리스트에 포함(중복·공백 정리, 24자/30개 제한) → 저장·불러오기·드라이브 동기화에 보존.
  - 우측 패널 "태그" 구역: 입력 후 Enter로 추가, 칩 클릭으로 제거. 노드에는 `#태그` 칩으로 표시.
  - 필터는 기존 흐림(dim) 메커니즘 재활용: `tagVisibleIds`(매칭+조상)를 `isDimmed`에 결합. 사라진 태그는 필터에서 자동 제거. `React.memo` 비교에 태그 포함.

### Technical Notes
- node 시뮬 7/7 통과(필터 가시집합·다중 태그 OR·allTags 수집·태그 정규화). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.65.0.html` md5 일치.

---

## [3.64.2] - 2026-06-05

### Fixed
- **버전 업 후 첫 접속 시 "지도가 중앙에 뭉쳐 멈춘 듯" 보이던 문제** — 원인은 레이아웃이 아니라 **업데이트 소개 팝업**이었음. 이 팝업은 전체화면 `.modal-backdrop`(`backdrop-filter: blur(4px)` + 딤 + `z-index:2000` 클릭 차단)을 써서, 정상적으로 그려진 지도를 흐리게 덮고 클릭을 막아 "노드가 가운데 흐릿하게 뭉친 채 아무것도 안 되는" 것처럼 보였음(첫 접속에만 뜨므로 증상도 그때만 발생).
  - 업데이트 소개를 **전체화면 모달 → 화면을 가리지 않는 비차단 알림 카드**(상단 중앙 고정, backdrop 없음)로 변경. 닫지 않아도 캔버스를 바로 조작 가능. 닫기는 ×/확인.

### Technical Notes
- 레이아웃(`layoutTree`)·복원·중앙정렬(`centerNode`, 스크롤만 조정)·자동맞춤(`fitToScreen`, 최소 줌 0.2)은 정상으로 확인됨 — 증상이 "첫 접속에만" 발생하는 점이 팝업이 유일한 차이라는 결정적 단서였음. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.64.2.html` md5 일치.

---

## [3.64.1] - 2026-06-05

### Changed
- **외부 링크·흔적 정리** — 대외 공개를 앞두고, 앱·문서·변경 이력·스냅샷에서 외부 코드 저장소로 연결되던 링크와 표현을 모두 제거.
  - 설정 > 안내의 **피드백 창구를 이메일(`redmirnet@naver.com`)로 단일화**(기존 외부 이슈 링크 제거).
  - `README.md`·`BrainBloom_TechDoc.html`의 관련 문구 정리(배포 표기를 "정적 웹 호스팅"으로). `CHANGELOG.md`와 `seahyun/` 스냅샷 전반의 외부 저장소 주소·플랫폼 표현 일괄 치환.

### Technical Notes
- 서빙되는 모든 파일에서 외부 저장소 흔적 0 확인. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.64.1.html` md5 일치.

---

## [3.64.0] - 2026-06-05

### Added
- **색상 변경 시 하위 노드 일괄 적용 확인** — 우측 패널 색상 그리드에서 색을 고를 때, 그 노드에 자식이 있으면 다이얼로그로 물어봄.
  - **"하위 전체 변경"** → 이 노드와 모든 하위 노드(`walk`로 자기+자손 순회)를 같은 색으로. **"이 노드만"** → 클릭한 노드만 변경(기존 동작).
  - 자식이 없으면 다이얼로그 없이 바로 적용. 다이얼로그에 선택한 색 미리보기 + 하위 노드 개수(자기 제외) 표시.
  - 단일 `updateNode` 호출이라 **Ctrl+Z 한 번**으로 되돌릴 수 있음.

### Technical Notes
- 상태 `colorCascade = { nodeId, colorKey, count }`. `updateNode`는 `cloneTree` 후 노드를 찾아 updater를 적용하므로, `walk(n, c => c.color = key)`로 하위까지 정확히 반영됨.
- node 시뮬 4/4 통과(하위 전체·이 노드만·다른 가지 보존·개수 카운트). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.64.0.html` md5 일치.

---

## [3.63.2] - 2026-06-05

### Changed
- **우측 패널 헤더 제거** — 우측 패널 위쪽의 `.panel-header`(번호 "02" + 제목 "속성 편집" + 선택 노드 라벨을 비추던 `"…" 편집 중` 줄)를 삭제해 패널을 간결하게. 상단 "패널 닫기" 버튼과 편집 내용(`.panel-content`: 라벨·색상·아이콘·메타데이터·구조·단축키), 하단 통계·"패널 닫기" 버튼은 그대로 유지.
  - 좌측 패널 헤더는 변경 없음(우측 패널의 헤더 블록만 제거).

### Technical Notes
- `.panel-header`/`.panel-sub` CSS는 좌측 패널이 계속 사용하므로 유지. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.63.2.html` md5 일치.

---

## [3.63.1] - 2026-06-05

### Changed
- **바탕 클릭으로 우측 패널 닫기 (조건부)** — "노드 세부 정보"로 임시로 연 우측 패널은 빈 바탕(캔버스)을 클릭하면 닫힘. **단, 설정 '우측 패널 표시'가 켜져 있으면 바탕 클릭으로 닫지 않음**(영구 표시 유지).
  - 임시 열림 상태 `panelTempOpen`(useState, 비영구) 도입. 패널 표시 여부 `rightPanelVisible = settings.showRightPanel !== false || panelTempOpen` 로 일원화(레이아웃 클래스·렌더 조건 모두 사용).
  - "노드 세부 정보" 클릭 → `setPanelTempOpen(true)`(영구 설정은 안 바꿈). 바탕 클릭 → `setPanelTempOpen(false)`(설정이 켜져 있으면 그대로 표시). "패널 닫기" 버튼 → 임시·영구 둘 다 끔(`panelTempOpen=false` + `showRightPanel=false`).
  - 노드 클릭은 `stopPropagation`이라 바탕 클릭과 분리되어, 노드 선택 시엔 닫히지 않음.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.63.1.html` md5 일치.

---

## [3.63.0] - 2026-06-05

### Added
- **노드 우클릭 → "노드 세부 정보" 메뉴** — 노드 위에서 우클릭하면 컨텍스트 메뉴(`bgMenu`) 맨 위에 "🔍 노드 세부 정보" 항목이 추가로 표시됨. 누르면 해당 노드를 선택(`setSelectedId`)하고 우측 패널(`showRightPanel: true`)을 엶.
  - 우클릭 핸들러가 `e.target.closest('.node')`의 `data-node-id`를 읽어 `bgMenu.nodeId`로 전달. 빈 공간 우클릭이면 이 항목은 표시되지 않음.
- **우측 패널 "패널 닫기" 버튼(상·하단)** — 우측 패널 맨 위와 맨 아래에 `✕ 패널 닫기` 버튼 추가. 누르면 `showRightPanel: false`로 패널을 숨김. 스크롤 영역(`panel-content`) 밖 고정이라 항상 보임.

### Technical Notes
- 닫은 뒤 다시 열기: 노드 우클릭 → 노드 세부 정보, 또는 설정 > 화면의 "우측 패널 표시" 토글. (`showRightPanel`은 설정에 저장되어 유지)
- `.panel-close-btn`(+`.top`/`.bottom`) CSS 추가. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.63.0.html` md5 일치.

---

## [3.62.3] - 2026-06-05

### Fixed
- **우클릭 시 앱 메뉴가 안 뜨던 문제** — 캔버스 우클릭 핸들러(`.canvas-inner`)에 `if (e.target.closest('.node')) return;` 제외 규칙이 있어, 노드 위에서 우클릭하면 앱의 커스텀 메뉴(배율·보기 모드) 대신 브라우저 기본 메뉴가 떴음. 노드가 빽빽한 화면에선 우클릭이 자꾸 노드에 닿아 앱 메뉴가 안 나오는 것처럼 보였음.
  - 제외 규칙을 제거해 **빈 공간이든 노드 위든** 캔버스 어디서 우클릭해도 앱 메뉴가 뜨도록 변경. (6/3 '몰입모드 추가' 때부터 있던 동작)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.62.3.html` md5 일치.

---

## [3.62.2] - 2026-06-05

### Changed
- **드라이브 저장 파일 번호 규칙 변경** — 첫 저장부터 번호를 붙이고, 번호를 **두 자리(0-패딩)**로 표시. 번호는 **0부터 시작**: `2026-06-05_발리_00`, `_01`, `_02` … (예전엔 `_1`부터, 패딩 없음).
  - `buildDriveBase`에 `pad2(n)`(=`String(n).padStart(2,'0')`) 적용 — 0→00, 9→09, 10→10, 100→100.
  - `maxVersionForDate`(없으면 0 반환)를 `nextVersionForDate`(없으면 0=첫 저장 `_00`, 있으면 최댓값+1)로 교체. 호출부(runVersionedSave) 1곳 갱신.
  - `parseDriveFileName`은 패딩 번호(`_00`/`_07`)와 버전 0을 정확히 해석(`version != null` 기준 유지).
  - 과거 날짜 정리(하루 1개 최종형식 `날짜_이름`, 번호 없음)와 보관 개수 삭제(최신 N개 유지) 동작은 그대로.

### Technical Notes
- 순수 함수 node 시뮬레이션 15/15 통과(패딩·첫저장 00·연속 번호·parse 라운드트립·keep 초과 삭제·과거 정리). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.62.2.html` md5 일치.

---

## [3.62.1] - 2026-06-05

### Added
- **구글 드라이브 연결 상태 배지** — 설정 > 구글 드라이브 연동 섹션 제목 오른쪽에 현재 연결 상태를 표시. 연결 시 초록 **"연결됨"**(점이 은은하게 펄스), 미연결 시 회색 **"연결 안 됨"**. `driveSignedIn` 상태에 연동.

### Technical Notes
- 배지 스타일은 `.drive-status-badge`(+`.on`)·`.drive-status-dot`·`@keyframes drivePulse`로 추가. 섹션 제목은 해당 div에만 인라인 flex(`space-between`)를 적용해 다른 섹션 제목엔 영향 없음.
- 색 변수(`--ink-soft`/`--line`/`--bg-2`)를 사용해 라이트·다크 테마 모두 자동 대응. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.62.1.html` md5 일치.

---

## [3.62.0] - 2026-06-05

### Added
- **업데이트 소개 팝업** — 새 버전으로 올라오면 접속 시 이번 버전의 변경점(RECENT_CHANGES의 현재 버전 항목)을 보여 주는 팝업을 1회 표시. 팝업 안에 **"다음부터 업데이트 보지 않기"** 체크박스 포함.
- **설정 > "업데이트 알림 사용하기"** 토글(`updateNotify`, 기본 켬) — 끄면 업데이트 팝업이 더 이상 뜨지 않음.

### Technical Notes
- `lastSeenVersion`(이 브라우저에서 마지막으로 본 버전)을 IndexedDB에 영구 저장. 마운트 시 비교해 `isNewerVersion(APP_VERSION, lastSeenVersion)`이면 팝업 표시 후 현재 버전을 기록.
- 완전 신규 사용자(설정 없음)는 팝업 없이 현재 버전만 기록. 기존 사용자가 이 기능 도입 버전으로 올라올 때는 1회 표시.
- 팝업은 `startupDialog`(어제 작업 묻기)가 닫힌 뒤 표시(렌더 조건 `showUpdate && !startupDialog`). 체크박스/설정 토글은 `settings.updateNotify`를 공유.
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.62.0.html` md5 일치.

---

## [3.61.1] - 2026-06-05

### Fixed
- **새로고침마다 "다른 기기 최신본" 안내가 반복되던 오탐 해결** — `lastSyncedTimeRef`(동기화 기준 시각)가 메모리 `useRef`라 새로고침 시 `null`로 초기화 → `syncBaselineOnConnect`가 로컬·원격 내용이 다르면 매번 배너를 띄우던 문제.
  - **동기화 기준 시각을 IndexedDB(`driveSyncedTime`)에 영구 저장**하고 마운트 시 복원하도록 변경. 새로 추가한 `setSyncedTime(t)` 헬퍼가 ref + IDB를 함께 갱신(저장·병합·불러오기·"무시하고 계속"·동일내용 확인 5개 지점 모두 통일).
  - `syncBaselineOnConnect`의 "내용 다름" 분기를 **시각 인지형**으로 변경 — 최신 원격본이 내 기준 시각보다 *새롭지 않으면* 배너를 띄우지 않음(= 로컬이 권위). 반대로 다른 기기가 더 새 버전을 올렸으면(`latest > base`) 그대로 안내 → **집↔회사 충돌 보호는 유지**.

### Technical Notes
- 한 번 확인(무시/불러오기/합치기)한 최신본은 새로고침 후에도 다시 묻지 않음. 자동저장이 켜져 있으면 이후 로컬이 새 버전으로 저장되어 완전히 정합.
- node 시뮬레이션 8/8 통과(사용자 케이스·동일내용·진짜 충돌·확인 후 재질문 없음·저장 후·가지치기 과거본). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.61.1.html` md5 일치.

---

## [3.61.0] - 2026-06-04

### Changed
- **브랜드 아이콘 전면 교체** — 기존 마인드맵 마크(네이비 노드+가지)를 새 "깔때기" 마크로 변경. *수백 개의 생각을 걸러 핵심(별) 하나만 남긴다*는 앱 컨셉을 형상화 (블루 그라데이션 타일 + 상단 컬러 점 5개 + 흰 깔때기 + 아래 별).
  - **favicon** (`rel="icon"`)과 **apple-touch-icon**을 새 마크로 교체 (인라인 SVG data URI, 외부 요청 없음).
  - **헤더 로고** 신규 추가 — `BrainBloom` 텍스트 왼쪽에 30px 마크 표시. `.brand`를 `align-items: center`로, `.brand-logo` 스타일 추가.
  - 보조 문서 `BrainBloom_TechDoc.html`·`BrainBloom_UserGuide.html`에도 동일 favicon 추가(기존엔 없었음)해 브랜드 통일.

### Technical Notes
- favicon SVG는 `linearGradient`(id=`g`) + `url(%23g)`로 그라데이션, 헤더 인라인 SVG는 id=`bbFunnel` 사용(충돌 없음).
- 모바일(≤640px)에선 `.brand`가 숨겨지므로 로고도 함께 숨김(기존 동작 유지).
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.61.0.html` md5 일치.

---

## [3.60.7] - 2026-06-04

### Changed
- **타이머 시작 문구 끝 마침표 제거** — `{N}분 타이머 시작.` → `{N}분 타이머 시작`. (시작·완료 팝업 중앙정렬은 v3.60.6에서 적용됨)

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.7.html` md5 일치.

---

## [3.60.6] - 2026-06-04

### Changed
- **타이머 시작·완료 알림 문구 변경** — 시작: `{N}분 타이머 시작.\n짜릿한 짜내기 시간을 즐기세요!` / 완료: `짜릿한 시간이셨나요?\n아주, 잘 하셨어요!` (2줄). `.timer-popup`에 `white-space: pre-line` + `text-align:center` + `line-height` 추가해 줄바꿈(`\n`)·중앙정렬 지원.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.6.html` md5 일치.

---

## [3.60.5] - 2026-06-04

### Changed
- **상단 메뉴 버튼 콤팩트화** — `.btn.icon-btn`(캘린더·AI 요약·설정 등 헤더 버튼) 내부 여백 `9px 12px` → `5px 8px`. 글자와 테두리 사이 공백을 줄여 더 타이트하게.

### Technical Notes
- CSS 1줄. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.5.html` md5 일치.

---

## [3.60.4] - 2026-06-04

### Fixed
- **새로고침 시 "다른 기기 최신본" 오탐** — 편집 없이 새로고침만 해도 충돌 안내 배너가 뜨던 버그. 원인 ①`serializeTreeContent`(내용 비교 기준)가 레이아웃 캐시 `_side`·`_subW`를 안 지워, 렌더된 로컬엔 있고 sanitize된 원격엔 없어 불일치 ②`syncBaselineOnConnect`가 원격만 sanitize(정규화)하고 로컬은 안 해 비대칭.
  - 수정: `serializeTreeContent`가 **모든 `_` 접두 레이아웃 필드 제거**(순수 내용만), `syncBaselineOnConnect`는 **원격도 raw로 비교**(저장 당시와 동일 기준).
  - node 시뮬: 편집없음→일치(배너X) / 레이아웃만 변동→일치(배너X) / 실제 편집→불일치(배너O) 검증.

### Technical Notes
- 부수 효과(개선): 자동저장 변경 감지도 레이아웃 변동에 영향받지 않음(불필요 저장 감소). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.4.html` md5 일치.

---

## [3.60.3] - 2026-06-04

### Added
- **설정 하단 저작권 표기** — 설정 모달 맨 아래(개발자 연락처 다음)에 `© 2026 BrainBloom · All rights reserved.` 한 줄 추가(중앙·muted). 독점 라이선스(v3.60.0)와 일관.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.3.html` md5 일치.

---

## [3.60.2] - 2026-06-04

### Changed
- **드라이브 저장 파일명 형식 변경** — `{휴양지}_{날짜}.{번호}` → **`{날짜}_{휴양지}_{번호}`** (예: `발리_2026-06-04.1` → `2026-06-04_발리_1`). `buildDriveBase` 헬퍼 신설, `parseDriveFileName`(신·구형 모두 인식), 과거 정리 `newBase`, `runVersionedSave` 전부 갱신. 설정 라벨("파일 이름 접두어"→"파일 이름")·설명·표시값(휴양지 이름만)·"지금 저장" 안내 문구 동기화.
  - 순수 함수 **11개 시나리오 node 시뮬 통과**(빌드·파싱·maxVersion·보관삭제·과거정리, 신형 + 구형 안전망).

### Technical Notes
- 기존 구형 파일은 사용자가 모두 삭제 — 구형 파싱은 무해한 안전망으로 유지. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.2.html` md5 일치.

---

## [3.60.1] - 2026-06-04

### Fixed
- **모바일 상단 메뉴 간소화** — 좁은 화면(≤640px)에선 로고·타이머·캘린더·AI 요약 등을 숨기고 **'설정'만** 표시. CSS 미디어쿼리(`.header-actions > *:not(.settings-btn)` + `.brand`·`.timer-zone` 숨김), 설정 버튼에 `settings-btn` 클래스 추가.
- **모바일 키보드 시 배율 축소 버그** — 키보드·주소창이 뜰 때 '높이'만 변하는데도 resize 자동 맞춤이 발동해 배율이 작아지던 문제. resize 핸들러를 **폭(width) 변화가 있을 때만** 맞추도록 수정(높이만 변하면 무시).

### Technical Notes
- 데스크톱(>640px) 동작 무영향. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.1.html` md5 일치.

---

## [3.60.0] - 2026-06-04

### Added
- **줌 시 선택 노드 중앙 유지** — 노드를 선택한 상태에서 줌 버튼(−/+/⊙, 툴바·우클릭 메뉴 모두)으로 배율을 바꾸면 선택 노드를 화면 중앙에 둔 채 확대·축소. `zoomBy(delta)`·`zoomReset()` 헬퍼 + 줌 후 `centerNode(selectedId)`(렌더 DOM 측정 기반, 새 배율 자동 반영). 선택 노드 없으면 기존 동작, ⊡·Ctrl+휠은 그대로.
- **실행 도메인 잠금** — 마운트 직전 `location` 검사로 로컬(file://·localhost) 또는 공식 도메인(`redmir.net`·하위)에서만 렌더, 그 외(타인 웹호스팅)에선 공식 주소 안내만 표시. ⚠️ 클라이언트 측이라 소스 수정으로 우회 가능한 *억제책*.

### Changed
- **라이선스 MIT → All rights reserved(독점)** — 무단 복제·재배포·재호스팅·2차적 저작물 금지. README 저작권 문구 동기화. (이미 배포된 과거 MIT 버전은 소급 취소 불가)
- **README 전면 갱신** — v3.60.0 기능 기준 재작성, 공식 주소(www.redmir.net) 안내, 자체 호스팅 가이드 제거, 낡은 파일/기능 정정.

### Technical Notes
- 도메인 잠금 로직 node 시뮬 검증(redmir.net·www·하위·로컬 허용 / 외부·유사 도메인 차단, 자기차단 없음). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.60.0.html` md5 일치.

---

## [3.59.2] - 2026-06-04

### Changed
- **설정 변경 이력 링크 정리** — `CHANGELOG_URL`을 외부 저장소 주소 → `https://www.redmir.net/CHANGELOG.md`로 변경. 푸터 문구 "그 이전 버전의 전체 변경 이력은 전체 보기 →" → **"그 이전 버전의 전체 변경 이력 보기"**(링크 하나로 통합).

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.59.2.html` md5 일치.

---

## [3.59.1] - 2026-06-04

### Changed
- **파일명 접두어 = 브라우저 고정값(변경 불가)** — 접두어를 브라우저마다 1회 배정 후 `localStorage('bb_drive_prefix')`에 보존하는 `getBrowserPrefix(seed)` 도입. 빈 값이면 휴양지 20곳 중 랜덤, 기존에 직접 지정한 값이 있으면 그 값을 고정(시드 보존). 설정 로드 완료 시 1회 적용(신규·기존 공통). 입력칸은 `readOnly`로 잠금, 라벨 "(선택)→(필수)" + 마우스오버 툴팁 "다른 브라우저의 중복저장 방지". placeholder·설명 동기화.
  - 효과: 브라우저/기기마다 접두어가 달라 자동저장 파일이 안 섞임(중복저장 방지), 매 로드 재랜덤 없이 고정.
  - v3.59.0의 "기본값 랜덤(직접 변경 가능)"을 대체.

### Technical Notes
- 헬퍼 node 시뮬 검증(1회 배정·고정 유지·시드 보존). babel OK, `index.html` ↔ `seahyun/brainstorm_v3.59.1.html` md5 일치. `.text-input`은 `color: var(--ink)` 보유(다크 가독성 OK).

---

## [3.59.0] - 2026-06-04

### Added
- **파일 이름 접두어 기본값 = 랜덤 휴양지** — `drivePrefix` 기본값을 `''`에서 세계 유명 휴양지 20곳(`RESORT_PREFIXES`: 발리·몰디브·산토리니·푸켓·니스 등) 중 랜덤 1개 + `_`로 변경. 신규/초기 상태에서 파일명이 예: `발리_2026-06-04.1`처럼 시작. 사용자가 직접 지우거나 바꿀 수 있음. (버튼 방식 검토했다가 "그냥 입력칸 기본값"으로 단순화)

### Reverted
- **불러오기 자동 맞춤(v3.58.3) 롤백** — 파일 불러올 때 1회 자동 맞춤이 트리 교체 직후 줌+스크롤을 일으켜 큰 트리에서 *렌더 잔상(노드 이중 표시)* 글리치가 간헐 발생(스크린샷 제보). 안정성 우선으로 로드 핸들러의 `didAutoFitRef` 리셋 2곳을 제거해 v3.58.2 동작(편집·로드 모두 배율 고정, ⊡ 수동)으로 복귀. 원인(레이아웃 settle 전 fit 합성) 재현·수정 후 재도입 예정.

### Technical Notes
- babel OK, `index.html` ↔ `seahyun/brainstorm_v3.59.0.html` md5 일치. `.text-input`은 `color: var(--ink)` 보유로 다크 가독성 OK(추가 수정 불필요).

---

## [3.58.3] - 2026-06-04

### Added
- **파일 불러올 때 자동 맞춤 1회** — JSON 백업 열기·드라이브 파일 불러오기(파일 목록 + 최신본 배너 "⬇ 불러오기")에서 트리 교체 후 `didAutoFitRef.current = false`로 가드를 리셋 → 자동 맞춤 effect가 "처음 열 때"처럼 1회 재평가. 큰 지도를 불러와도 ⊡ 없이 즉시 전체가 보임. 편집·노드 추가로는 여전히 배율 고정(v3.58.0 동작 유지).

### Technical Notes
- 가드 리셋은 로드 핸들러 2곳(`handleDriveLoadFile`·`handleJsonFileSelected`)에만 추가 — 편집용 `setTree` 다수에는 영향 없음. `handleDriveLoadFile`은 파일 목록·최신본 배너 양쪽이 공유. 🔀 합치기(merge)는 미포함. babel OK, `index.html` ↔ `seahyun/brainstorm_v3.58.3.html` md5 일치.

---

## [3.58.2] - 2026-06-04

### Fixed
- **텍스트 입력칸 다크 테마 가독성** — `.text-field`(검색·설정 입력·AI 프롬프트 등 공용 클래스)에 `color`가 없어 글자가 브라우저 기본 검정으로 떨어졌고, 다크 테마에선 회색 배경(`var(--bg)` #1c1c1e 등) 위 검정 글자가 되어 거의 안 읽히던 문제. `color: var(--ink)` + `::placeholder { color: var(--ink-soft); opacity: 1 }` 추가로 모든 테마에서 본문·placeholder 모두 또렷하게.

### Technical Notes
- 라이트 테마에선 우연히 읽혀 드러나지 않던 전역 버그. CSS만 수정(JS 무변화). babel OK, `index.html` ↔ `brainstorm_v3.58.2.html` md5 일치.

---

## [3.58.1] - 2026-06-04

### Fixed
- **타이머 마일스톤 팝업 위치 튐** — `.timer-popup`의 중앙 정렬 `transform: translate(-50%, -50%)`이 키프레임 안에만 있어, In 애니메이션 종료(0.25s)~Out 시작(2.2s) 구간엔 어떤 애니메이션도 적용되지 않아 base로 리셋 → 좌상단 기준점(`top/left: 50%`)만 남아 팝업이 화면 중앙에서 우하단으로 튀어 보이던 문제. base 규칙에 동일 `transform`을 추가해 애니메이션 사이에도 중앙 고정.

### Technical Notes
- CSS 1줄 수정. JSX 렌더 1곳(중복 아님) 확인. babel 변환(JS 무변화) OK, `index.html` ↔ `brainstorm_v3.58.1.html` md5 일치.

---

## [3.58.0] - 2026-06-04

### Changed
- **자동 맞춤(autoFitMap) 동작 변경 — 편집·노드 추가 시 배율 고정** — 노드를 편집하거나 엔터로 새 노드를 추가할 때 더 이상 줌이 바뀌지 않음. 자동 축소는 *처음 열 때(최초 레이아웃 측정 1회) · 창 크기 변경 · ⊡ 버튼*에서만 동작.
  - `didAutoFitRef` 가드 도입: 최초 레이아웃 측정 시 1회만 `fitToScreen()` 평가, 이후 `layoutInfo`/`editingId` 변화로는 재맞춤하지 않음. 편집 종료(`editingId`→null)가 더 이상 재맞춤을 유발하지 않음.
  - autoFitMap을 끄면 가드 리셋 → 다시 켜면 1회 재맞춤. 창 크기 변경 시 맞춤(resize effect)은 그대로 유지.

### Added
- **빈 곳 우클릭 메뉴에 배율 조절** — 기존 '보기 모드'(편집/몰입) 위에 '배율' 행 추가: `−` / 현재 %(라이브) / `+` / `⊙`(100%) / `⊡`(전체 맞춤). 줌 버튼은 메뉴를 닫지 않아 연속 조절 가능(바깥 클릭으로 닫힘). 기존 `setZoom`·`fitToScreen` 재사용, `.toolbar-btn`/`.toolbar-label` 스타일 공유. 메뉴 위치 클램프·minWidth 조정.
- 설정 '지도 자동 맞춤' 설명 + UserGuide(자동 맞춤·우클릭 메뉴) 동기화

### Technical Notes
- babel 변환(SYNTAX/BABEL OK) 통과. `index.html` ↔ `brainstorm_v3.58.0.html` md5 일치.

---

## [3.57.1] - 2026-06-04

### Changed
- **트리 깊은 복제 최적화** — `cloneTree`를 `JSON.parse(JSON.stringify())`에서 네이티브 `structuredClone()`으로 교체(예외·미지원 시 JSON 폴백 유지). undo 스냅샷(최대 100개)·자동저장 내용 비교 등 24개 호출부에서 사용되며 동작은 동일, 큰 트리에서 복제 비용 감소.

### Technical Notes
- 안전한 드롭인: 평면 JSON 데이터라 결과 동일. `try { structuredClone } catch { JSON 폴백 }`으로 회귀 위험 0. Chrome/Edge(타깃) 지원.
- 검증: babel 변환(SYNTAX/BABEL OK) 통과.

---

## [3.57.0] - 2026-06-04

### Added — 타이머 마일스톤 팝업 (정중앙 반투명, 자동 소멸, 클릭 통과)
- **팝업 시스템** — `.timer-popup`(fixed 중앙, rgba 0.78 다크, 22px, **pointer-events:none**), 진입 0.25s/퇴장 0.4s@2.2s 애니메이션 + 2.6s 상태 소멸, key=timestamp로 연속 알림 시 애니메이션 재시작
- **마일스톤 엔진**(250ms 틱 내) — `timerMilestoneRef` 중복 방지 + `timerTotalMsRef` 경과 계산:
  - 시작: "⏱ X분 타이머가 시작합니다" / 종료: 기존 토스트 → 정중앙 팝업으로 승격
  - 경과: `timerNotifyMinutes`(분)마다 "N분 지났어요 · 남은 M분" — 마지막 3분 구간·시작 60초 내 침묵, 0=끄기
  - 잔여: 3·2·1분 전 — **총 길이보다 긴 마크 억제**(3분 타이머에 "3분 전" 안 뜸), 시작 5초 침묵, 일시정지 점프 시 가장 가까운 마크만
- **설정 > 타이머 > 경과 알림 간격(0~60, 기본 10)** + 머지 방어, 틱 deps에 간격 포함(낡은 클로저 방지)
- UserGuide 타이머 항목 갱신

### Technical Notes
- 검증: 엔진 5시나리오(30분·간격10 풀시퀀스 / 3분 타이머 억제 / 간격0 / 일시정지 점프 / 경계 7분=잔여3분 침묵) 통과

---

## [3.56.2] - 2026-06-04

### Changed
- 첫 실행 시작 가지 3→4개: ①"머리속에 있는 모든 생각 여기에 적고, 정리하시면 두통이 사라집니다!"(**rose** — 팔레트에 순수 검정·핑크가 없어 핑크=rose) ②개인적으로 할일(amber) ③회사에서 할일(teal) ④"그냥 생각"(**charcoal** — 검정 대용, 진짜 검정은 팔레트 추가 필요 시 별도)
- UserGuide 동기화

---

## [3.56.1] - 2026-06-04

### Changed
- 첫 실행 시작 가지 1번 라벨: "오늘의 할일" → **"머리속에 있는 모든 생각 적기"** (브레인 클리닝 취지 반영). UserGuide 동기화

---

## [3.56.0] - 2026-06-04

### Added — 첫 실행 온보딩 (요청: 처음 화면 단순화 + 격언 팝업)
- **첫 실행 감지** — 초기 로드에서 `!lastWork && !savedSettings`(저장된 작업·설정 모두 없음)일 때만 발동. 데이터만 비운 기존 사용자(`설정 있음`)는 기존 startFresh 흐름 유지 — 분기 5케이스 시뮬 통과
- **단순 화면 프리셋** — `minimalHeader:true`(캘린더·AI·설정만) + `showLeftPanel/RightPanel:false`. 설정에 저장돼 유지되며, 설정 > 화면 표시 토글로 언제든 해제(미니멀 헤더 토글 7576 존재 확인)
- **startFirstRun()** — 날짜 루트(navy) + 시작 가지 3개: 오늘의 할일(orange)/개인적으로 할일(amber)/회사에서 할일(teal), treeToText 동기화. 목업과 동일 구성
- **격언 팝업** — `welcomeQuote` 상태 + 가운데 모달(✨ 오늘의 격언 + 🌱 시작하기). 기존 구석 quote-banner는 새로시작 흐름에 그대로
- UserGuide "바로 시작하기"에 첫 화면 안내 추가

### Technical Notes
- 검증: 분기 5케이스 + 시작 트리 3케이스(라벨·색·id 무중복) = 8/8

---

## [3.55.1] - 2026-06-04

### Changed — 구글 애널리틱스 도입 (G-0VW2H7JDP4)
- head에 GA4 스니펫 — **호스트 가드**: www.redmir.net/redmir.net에서만 로드(file:// 개발 사본·타 도메인 복사본 미수집), 기본 페이지뷰만 수집
- gtag.js는 SRI 불가(구글이 수시 갱신) — 주석으로 명기
- **문구 정직화**: 앱 안내 카드·README "외부 전송 코드 없음" → "마인드맵 내용은 전송 안 됨 + 방문 통계(GA) 사용" 으로 수정, RECENT_CHANGES로 사용자 고지
- 검증: GA 스니펫 node --check, 호스트 가드 5케이스(공식 2 도메인 수집 / file·비공식 도메인·복사본 미수집)

---

## [3.55.0] - 2026-06-04

### Added — 지도 자동 맞춤 (제보: 깊은 가지가 화면 오른쪽 밖으로 잘림)
- **fitToScreen** — pad 48 기준 가용 영역에 맞춰 `zoom = min(availW/W, availH/H, 1)`(축소 전용, floor 2자리, 하한 0.2). 더블 rAF 후 지도 전체 중앙 스크롤. 기존 zoom 인프라(래퍼 크기 ×zoom + scale 변환, centerNode·ensureNodeVisible 모두 zoom 보정/rect 기반) 재사용이라 좌표 수학 무손상
- **자동 맞춤 effect** — layoutInfo.width/height 변화 시 넘침 판정 후 fit. **편집 중 보류**(editingId 가드 — 타이핑 폭 증가로 줌 출렁임 방지, 종료 시 재평가), **수동 줌 존중**(zoom을 deps에서 제외 — 확대해 둔 화면을 즉시 되돌리지 않음, 다음 레이아웃 변화 때만 개입). 창 리사이즈 리스너 동일 판정
- **⊡ 버튼**(줌 막대, ⊙ 옆) — 수동 전체 맞춤
- **설정 > 화면 표시 > "지도 자동 맞춤"** 토글(기본 ON, `autoFitMap` — 32→33번째 설정 필드, 드라이브 설정 백업 화이트리스트에 자동 포함)

### Technical Notes
- 검증: fit 수식·넘침 판정 8케이스(가로/세로/양축 초과, 작으면 1 유지, 0.2 클램프, 맞춤 후 무넘침, 수동확대 판정) + 정책 코드 검사 3종(zoom deps 제외, editingId 가드, effect 구조) — 1건은 테스트 수치 오기(900→1100) 정정 후 전체 통과

---

## [3.54.1] - 2026-06-04

### Removed — 모바일 기능 롤백 (사용자 결정: 3.52.1 동작으로 복귀)
- **3.54.0 철회**: head 모바일 감지·리다이렉트 스크립트 제거, `mobile.html` 배포 목록에서 제외
- **3.53.0 철회**: 터치 패닝(touchstart/move/end), 더블탭 편집(onTouchEnd+lastTapRef), CSS(`touch-action: manipulation`, `@media (hover:none)` node-actions 노출), UserGuide 📱 팁 제거
- 역적용 후 잔재 전수 검사 0건(onTouch*/touch-action/mobile.html/bb_force_desktop 등), 동작은 3.52.1과 동일
- 버전 번호는 3.54.1로 전진(배포된 3.54.0과의 갱신 순서 유지). 모바일 지원은 보류 목록으로 복귀
- 배포 안내: index.html 교체만으로 게이트 소멸. 저장소에 mobile.html을 올렸다면 삭제 권장(남아도 무해). 휴대폰에 남은 bb_force_desktop 플래그는 무해

---

## [3.54.0] - 2026-06-04

### Added — 모바일 게이트 (요청: 페이지가 휴대폰에 너무 무거움)
- **`mobile.html` 신설** — 외부 의존 0(폰트 CDN조차 없음)·인라인 CSS/SVG의 초경량 안내 페이지: 로고, "컴퓨터에서 가장 잘 동작" 안내, www.redmir.net 표시, 만화·설명서 링크(모바일 OK 표기), "그래도 휴대폰에서 열기 →"(index.html?desktop=1)
- **본편 head 최상단 감지 스크립트** — 3MB Babel 등 **무거운 다운로드가 시작되기 전에** 실행되도록 viewport 메타 직후 배치
  - 분기: `?desktop=1` → localStorage `bb_force_desktop` 기억 후 본편 / 플래그 있으면 본편 / 모바일 UA 또는 (≤768px AND pointer:coarse) → `mobile.html` replace / 감지 예외 시 본편(안전)
- UserGuide 모바일 팁에 안내 페이지 흐름 반영

### Technical Notes
- 검증: 리다이렉트 스크립트 node --check, 감지 분기 6케이스(아이폰/안드로이드/그래도열기+기억/기억된 사용자/데스크톱 크롬/맥 사파리), mobile.html 태그 균형
- 배포 주의: **mobile.html을 저장소 루트에 반드시 업로드** — 없으면 모바일 접속이 404로 감

---

## [3.53.0] - 2026-06-04

### Added — 모바일 기본 지원 (요청: 화면 이동 + 입력)
- **터치 패닝** — 캔버스 pan effect에 touchstart/move/end 추가(한 손가락, 마우스 패닝과 동일 로직). isPanTarget 가드로 노드/버튼 탭과 구분, 5px 임계 후 preventDefault(passive:false)로 당겨서 새로고침·네이티브 스크롤 방지. 두 손가락(핀치)은 패닝 제외(브라우저 확대에 위임)
- **더블탭 편집** — 네이티브 dblclick이 터치에서 불안정 → NodeView에 onTouchEnd 더블탭 감지(300ms, lastTapRef). 마우스 onClick/onDoubleClick은 그대로(데스크톱 무영향)
- **CSS** — `.node { touch-action: manipulation }`(더블탭 확대·300ms 지연 제거 → 더블탭 편집 즉각), `@media (hover: none) { .node-actions { opacity:1 } }`(터치 기기에서 +/× 버튼 상시 노출)
- 뷰포트 메타는 기존 존재(width=device-width)

### 범위 메모
- 이번엔 "보기·이동·편집"의 핵심만. 좌우 패널·상단 툴바의 좁은 화면 밀집, 핀치 줌은 별도(브라우저 확대로 대체). 새 노드 대량 생성은 데스크톱 키보드(Tab/Enter)가 여전히 유리

### Technical Notes
- 검증: 더블탭 타이밍 4케이스(첫탭 선택/150ms 편집/리셋/500ms 비더블탭) 통과

---

## [3.52.1] - 2026-06-04

### Improved
- **충돌 안내 창에 최신본 내용 미리보기** — 비교 박스 하단에 treeToText 앞 12줄(+외 N줄), 드라이브 목록 미리보기와 동일 형식. 비교용으로 이미 내려받은 트리 재사용(추가 통신 없음)
- 검증: 자르기 로직 2케이스(30줄→12+외18 / 짧은 내용) 통과

---

## [3.52.0] - 2026-06-04

### Added — 충돌 안내 창: 비교 + 🔀 합치기("복원" 방식)
- **자동 비교** — 창이 뜨면 최신본을 1회 내려받아 `diffTrees`(id 기준)로 차이 요약 표시: 양쪽 노드 수 / ＋최신본에만(5개+외N) / －화면에만 / ✎내용 다름(3개+외N) / 차이 없음 안내. 로딩·실패 상태 처리(실패해도 불러오기·무시 가능)
  - `remoteCompare` state + `remoteNewer.file.id` effect(취소 가드). 순차 id 특성상 "내용 다름"에 양쪽 각자 만든 노드가 집계될 수 있음(표시용 참고) — 주석 명기
- **🔀 합치기** — `mergeRemoteIntoLocal(local, remote, date)`: 중심 아래 **"복원" 노드**(meta.date=최신본 저장일)를 만들어 최신본 **전체를 통째로** 그 밑에 부착. 지금 화면 무변경, 구조 추측 없음 → 결과 항상 예측 가능
  - 붙는 모든 노드에 **새 id(`r{stamp}_{seq}`) 발급** — 순차 id(n계열) 중복으로 선택·편집이 깨지는 문제 원천 차단. 루트가 다른 문서끼리도 동작
  - `maybePushHistory('최신본 합치기(복원)')` → Ctrl+Z 복구. 합친 뒤 기준 시각 인정(`lastSyncedTimeRef`=최신본 시각) → 다음 저장 때 새 버전으로
- 선택지 설명 3종으로 warning-note 재작성, 합치기 버튼(비교 미로딩/실패 시 비활성+사유 툴팁)
- UserGuide 충돌 tip 전면 갱신

### Technical Notes
- 검증: 실제 diffTrees·mergeRemoteIntoLocal 추출 12케이스(집계 4 + 복원구조·기존무변경·날짜메타·id무중복·r접두어·addedCount·타문서 8) 통과 — 1건은 테스트 기대값 오기(4→5) 정정 후 전체 통과

---

## [3.51.1] - 2026-06-04

### Changed
- **헤더 "저장"(JSON) 버튼 강조색 제거** — `primary` 클래스 삭제, 주변 저장 버튼(PDF·JPG 등)과 동일한 기본 스타일로 통일. JSON 백업 설명 툴팁은 유지

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
- **공식 주소 변경: `www.redmir.net` → `www.redmir.net`** — 9개 링크 일괄 교체
  - 앱: 설정 문서 바로가기 2곳 (UserGuide·TechDoc)
  - README.md: 바로 써보기·만화·가이드·기술문서·빠른 시작 등 6곳
  - 만화(BrainBloom_Comic.html): 아웃트로 주소 1곳
  - 이메일 링크는 저장소 주소라 유지(redmirnet@naver.com)
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
  - 피드백: 이메일 링크(`target="_blank" rel="noopener noreferrer"`)

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
  - 정적 웹 호스팅 배포 문서로 연결: `BrainBloom_UserGuide.html`, `BrainBloom_TechDoc.html`
  - `target="_blank" rel="noopener noreferrer"`(새 탭 + 보안), 테마 변수(`--bg-2/--line/--ink`) 기반 스타일이라 다크 테마에서도 자연스러움
  - hover 시 테두리 강조

### Notes
- 이 버전부터 배포 zip은 5파일 구성: 앱 2(brainstorm/index) + CHANGELOG + **TechDoc + UserGuide**
- 문서 링크가 동작하려면 코드 저장소에 두 문서 파일을 함께 업로드해야 함

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
- **공식 배포 도메인에서만 동작** — 로컬 `file://`에선 구글 OAuth 미작동
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
- 변경 내용 화면 맨 아래 "전체 보기" 링크를 실제 저장소 주소(`https://www.redmir.net/CHANGELOG.md`)로 연결

---

## [3.13.0] - 2026-05-30

### Added
- **설정 화면에 "변경 내용" 버튼 추가** — 설정 모달 헤더 우측의 🆕 버튼을 누르면 같은 모달 안에서 변경 이력 화면으로 전환, 최근 업데이트 내역을 앱 안에서 바로 확인 가능
  - 최근 2개 버전의 변경 내용을 앱에 내장 (`RECENT_CHANGES` 배열)
  - 그 이전 버전은 화면 맨 아래 전체 이력 링크(`CHANGELOG_URL`)로 안내
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
- **정적 웹 호스팅 배포용 `index.html`** — 작업본과 100% 동일한 사본을 배포용으로 자동 생성. 매 배포마다 md5 해시 일치 확인

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
