#!/bin/bash
#
# ScreenSnap DMG 생성 스크립트
# "앱을 Applications 폴더로 드래그" 방식의 디스크 이미지를 만든다.
#
# 사용법:
#   ./make_dmg.sh
#
# 요구사항:
#   - macOS
#   - create-dmg  (brew install create-dmg)
#   - 먼저 build.sh 로 ScreenSnap.app 이 빌드되어 있어야 함 (없으면 자동 빌드)
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ScreenSnap"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME}"
BACKGROUND="scripts/dmg-background.png"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ DMG 생성은 macOS 에서만 가능합니다 (현재: $(uname))."
    exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "❌ create-dmg 가 필요합니다:  brew install create-dmg"
    exit 1
fi

# 앱이 없으면 빌드
if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "ℹ️  ${APP_BUNDLE} 이 없어 먼저 빌드합니다."
    ./build.sh
fi

rm -f "${DMG_NAME}"

echo "💿 ${DMG_NAME} 생성 중..."
# create-dmg 는 내부적으로 임시 마운트를 사용한다. 일부 환경에서 깔끔히
# 해제되도록 재시도 여지를 둔다.
create-dmg \
    --volname "${VOL_NAME}" \
    --background "${BACKGROUND}" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 120 \
    --icon "${APP_BUNDLE}" 165 200 \
    --hide-extension "${APP_BUNDLE}" \
    --app-drop-link 495 200 \
    --no-internet-enable \
    "${DMG_NAME}" \
    "${APP_BUNDLE}"

echo "✅ 완료: $(pwd)/${DMG_NAME}"
echo "   DMG 를 열고 ${APP_NAME} 을 Applications 폴더로 드래그하세요."
