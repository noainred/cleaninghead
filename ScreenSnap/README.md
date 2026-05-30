# ScreenSnap 📸

> macOS 메뉴바 화면 캡처 도구 — 영역/전체를 분리된 단축키로, 클립보드·저장을 자유롭게

순수 Swift + AppKit 으로 작성된 가벼운 메뉴바 앱입니다. Dock 아이콘 없이
상단 메뉴바에서만 동작하며, 전역 단축키로 어디서든 화면을 캡처합니다.

## ✨ 주요 기능

- **분리된 단축키** — *영역 캡처* 와 *전체 화면 캡처* 에 각각 다른 단축키 지정
- **3가지 동작 모드** (설정에서 선택)
  - `캡처만 (클립보드)` — 파일을 만들지 않고 클립보드로만 복사
  - `저장만 (파일)` — 지정한 폴더에 PNG 로 저장
  - `캡처 + 저장` — 클립보드 복사와 파일 저장을 동시에
- **저장 경로 지정** — 원하는 폴더를 직접 선택 (기본값: `~/Pictures`)
- **단축키 사용자 지정** — 칸을 클릭하고 원하는 조합을 누르면 즉시 녹화
- **단축키 충돌 검사** — 다른 프로그램/시스템 단축키와 겹치면 경고하고 적용을 막음
- **셔터 소리 on/off**

## 🖼 동작 방식

캡처는 macOS 내장 `/usr/sbin/screencapture` 를 사용합니다. 덕분에 영역 선택 UI,
다중 디스플레이, 화면 기록 권한 등이 OS 기본 동작과 동일하게 처리됩니다.

| 모드 | 영역 | 전체 |
|---|---|---|
| 캡처만 | `screencapture -i -c` | `screencapture -c` |
| 저장만 | `screencapture -i <파일>` | `screencapture <파일>` |
| 캡처+저장 | 파일 저장 후 이미지를 클립보드에도 복사 | 동일 |

## ⌨️ 기본 단축키

| 동작 | 기본값 |
|---|---|
| 영역 캡처 | `⌃⇧4` (Control+Shift+4) |
| 전체 화면 캡처 | `⌃⇧3` (Control+Shift+3) |

> macOS 기본 스크린샷(`⌘⇧4`/`⌘⇧3`)과 겹치지 않도록 `⌃`(Control) 조합을 기본값으로 둡니다.

## 🔍 단축키 충돌 검사 방식

macOS 에는 "제3자 앱이 등록한 전역 단축키"를 조회하는 공개 API 가 없습니다.
ScreenSnap 은 다음을 단계적으로 확인해 최대한 검출합니다.

1. **수정자 없는 단독 키 차단** — 일반 타이핑을 가로채지 않도록 `⌘/⌃/⌥/⇧` 필수
2. **앱 내부 중복** — 영역/전체 두 단축키가 같으면 거부
3. **macOS 시스템 단축키** — 내장된 대표 단축키 목록 + `com.apple.symbolichotkeys.plist`
   의 *활성화된* 항목과 대조 (Spotlight, 스크린샷, Mission Control 등)
4. **실제 등록 시도** — `RegisterEventHotKey` 로 임시 등록을 시도해, 실패하면 누군가
   이미 점유한 것으로 보고 거부 (성공하면 즉시 해제)

> 4단계는 OS 가 거부하는 경우만 잡아냅니다. 일부 앱은 다른 메커니즘으로 단축키를
> 잡으므로 100% 검출은 기술적으로 불가능합니다. 이 한계는 의도된 것입니다.

## 🚀 설치 & 실행

### 방법 0: DMG 로 설치 — 드래그 한 번 (권장)

직접 컴파일하거나 Homebrew/Xcode 를 설치할 필요 없이, macOS CI 가 빌드해 둔
`ScreenSnap.dmg` 를 내려받아 **앱을 Applications 폴더로 드래그**하면 끝입니다.

1. GitHub 저장소 **Actions** 탭 → `ScreenSnap Build` 최근 실행 열기
2. 하단 **Artifacts** 에서 **`ScreenSnap-dmg`** 다운로드 → 압축 해제 → `ScreenSnap.dmg`
3. `ScreenSnap.dmg` 더블클릭 → 열린 창에서 **ScreenSnap 아이콘을 Applications 폴더로 드래그**

> 정식 릴리스가 있으면 **Releases** 탭에서 `ScreenSnap.dmg` 를 바로 받을 수 있습니다.
> `.app` 자체만 원하면 `ScreenSnap-app` 아티팩트(zip)도 제공됩니다.

**처음 실행 시 (서명 없는 앱이므로 Gatekeeper 차단)**

다운로드한 앱은 격리(quarantine) 속성이 붙어 “확인되지 않은 개발자” 경고가 뜹니다.
다음 중 하나로 엽니다.

- **우클릭 → 열기 → 열기** (한 번만 하면 이후엔 더블클릭으로 실행)
- 또는 터미널에서 격리 속성 제거:
  ```bash
  xattr -dr com.apple.quarantine /Applications/ScreenSnap.app
  open /Applications/ScreenSnap.app
  ```

### 방법 1: Homebrew (설치 / 업그레이드)

이 저장소를 Homebrew tap 으로 추가해 설치합니다.

```bash
# tap 추가 (저장소 이름이 homebrew- 접두사가 아니므로 URL 명시)
brew tap noainred/cleaninghead https://github.com/noainred/cleaninghead

# 설치 (main 브랜치 소스에서 빌드) — HEAD-only formula 이므로 --HEAD 필요
brew install --HEAD screensnap

# 업그레이드 (최신 소스로 다시 빌드)
brew upgrade --fetch-HEAD screensnap
```

설치 후 메뉴바 앱 실행:

```bash
screensnap &
```

> 빌드에는 **Command Line Tools** 만 있으면 됩니다 (`xcode-select --install`). 전체
> Xcode.app 은 필요 없습니다. 처음 캡처 시 **시스템 설정 → 개인정보 보호 및 보안 →
> 화면 기록** 에서 권한을 허용하세요.
> 정식 릴리스 태그가 생기면 `--HEAD`/`--fetch-HEAD` 없이 일반 `brew install/upgrade screensnap` 으로 버전 설치·업그레이드가 됩니다.

### 방법 2: 소스에서 직접 빌드

```bash
cd ScreenSnap
./build.sh          # ScreenSnap.app 생성
open ScreenSnap.app # 실행
```

또는 빌드 후 바로 실행:

```bash
./build.sh --run
```

드래그 설치용 DMG 를 직접 만들려면 (`brew install create-dmg` 필요):

```bash
./make_dmg.sh      # ScreenSnap.dmg 생성
```

### 요구사항
- macOS 12 (Monterey) 이상
- Xcode Command Line Tools (`xcode-select --install`)

### 권한 설정
처음 캡처할 때 macOS 가 권한을 요청합니다.
**시스템 설정 → 개인정보 보호 및 보안 → 화면 기록** 에서 **ScreenSnap** 을 허용하세요.
(전역 단축키가 모든 앱 위에서 동작하려면 **손쉬운 사용** 권한이 필요할 수 있습니다.)

## 🗂 프로젝트 구조

```
ScreenSnap/
├─ Package.swift                 # Swift Package 매니페스트
├─ build.sh                      # 빌드 + .app 번들 생성 스크립트
├─ Resources/Info.plist          # 번들 설정 (LSUIElement: 메뉴바 전용)
└─ Sources/ScreenSnap/
   ├─ main.swift                 # 앱 진입점 (NSApplication, .accessory)
   ├─ AppController.swift        # 중심 컨트롤러: 메뉴바·설정·캡처 연결
   ├─ Settings.swift             # 설정 모델 + UserDefaults 영속화
   ├─ CaptureService.swift       # screencapture 실행 + 클립보드/파일 처리
   ├─ HotKey.swift               # 단축키 값 타입 + 키 이름 변환
   ├─ HotKeyManager.swift        # Carbon 전역 단축키 등록/해제
   ├─ HotKeyConflict.swift       # 단축키 충돌 검사
   ├─ HotKeyRecorderView.swift   # 단축키 녹화 컨트롤
   └─ PreferencesWindowController.swift  # 설정 창 UI
```

## 📄 라이선스

MIT
