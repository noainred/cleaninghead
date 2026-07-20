# BrainBloom — Claude 작업 지침

브라우저 단일 HTML(`index.html`, React 18 + Babel Standalone) 마인드맵 앱. `main`이 GitHub Pages(www.redmir.net)로 곧장 배포된다.

## 릴리스 워크플로 (기능/수정 1건마다)

1. `index.html` 수정 + `APP_VERSION`·`APP_BUILD_DATE` 갱신
   - 버전 규칙: 기능 추가 = 마이너(x.Y.0), 버그 수정·미세 조정 = 패치(x.y.Z)
2. `RECENT_CHANGES` 배열(앱 내장 업데이트 안내)에 새 버전 항목을 맨 앞에 추가 — 사용자向 한국어 설명
3. `seahyun/brainstorm_v<버전>.html` 스냅샷 생성 (= index.html 복사본, 완전 동일해야 함)
4. `CHANGELOG.md` 최상단([Unreleased] 아래)에 항목 추가 — Keep a Changelog 형식 + Technical Notes
5. 사용자向 기능이면 `README.md`(필요시 UserGuide/TechDoc)도 갱신
6. 검증: babel 스크립트 블록을 추출해 `@babel/standalone`(presets `env,react`)로 컴파일 확인

## 배포 (사용자 지시: 매번 자동으로 끝까지)

**커밋 → 푸시 → PR 생성 → main으로 머지(= 배포)까지 묻지 말고 자동 진행한다.** (2026-06-11 사용자 지시: "앞으로는 PR 및 github 배포까지 해줘")

- 커밋 메시지: 한국어, `feat:`/`fix:`/`docs:` 접두 + `(v<버전>)` 꼬리표
- 머지 방식: merge commit (저장소 관례 — `merge: v<버전> — <요약>` 제목)
- git 신원: `Claude <noreply@anthropic.com>`

## 주의사항

- 채팅 응대는 한국어로. 사용자 호칭은 **"준호님"** (사장님 등 다른 호칭 쓰지 말 것 — 2026-07-06 본인 요청).
- 사용자가 `.` 만 입력하면: **진행 중 작업 / 대기 중 작업을 표로 정리**해 보여줄 것 (2026-07-13 본인 요청).
- `lastWork`(IndexedDB)는 "현재 열린 문서의 거울" — 시작 복원·드라이브 동기화가 의존하므로 항상 유지
- 드라이브 자동저장 파일명 규칙(접두어+날짜+버전)은 동기화 파싱(`buildDriveBase`)이 의존 — 함부로 바꾸지 말 것
- Edit 도구로 `\uXXXX`가 든 문자열을 넣으면 리터럴 제어 바이트가 들어갈 수 있음 — 정규식엔 `\x00` 표기 사용, 편집 후 파일이 텍스트인지 확인
