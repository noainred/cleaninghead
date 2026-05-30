#!/bin/bash
#
# ScreenSnap 빌드 스크립트
# Swift Package 를 릴리스로 컴파일한 뒤 ScreenSnap.app 번들로 묶는다.
# 아이콘(.icns)을 생성해 임베드하고, 배포용 zip 도 함께 만든다.
#
# 사용법:
#   ./build.sh            # 빌드 + .app + zip 생성
#   ./build.sh --run      # 빌드 후 바로 실행
#
# 요구사항: macOS, Xcode Command Line Tools (swift)
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ScreenSnap"
BUILD_CONFIG="release"
BUILD_DIR=".build/${BUILD_CONFIG}"
APP_BUNDLE="${APP_NAME}.app"
ZIP_NAME="${APP_NAME}.app.zip"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 이 앱은 macOS 에서만 빌드/실행됩니다 (현재: $(uname))."
    exit 1
fi

echo "🔨 Swift 릴리스 빌드 중..."
swift build -c "${BUILD_CONFIG}"

echo "📦 ${APP_BUNDLE} 번들 생성 중..."
rm -rf "${APP_BUNDLE}" "${ZIP_NAME}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# 아이콘 생성: Resources/AppIcon.png → AppIcon.icns
if [[ -f "Resources/AppIcon.png" ]] && command -v iconutil >/dev/null 2>&1; then
    echo "🎨 앱 아이콘(.icns) 생성 중..."
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "${ICONSET}"
    for size in 16 32 128 256 512; do
        sips -z "${size}" "${size}"   "Resources/AppIcon.png" \
            --out "${ICONSET}/icon_${size}x${size}.png"      >/dev/null
        double=$((size * 2))
        sips -z "${double}" "${double}" "Resources/AppIcon.png" \
            --out "${ICONSET}/icon_${size}x${size}@2x.png"   >/dev/null
    done
    iconutil -c icns "${ICONSET}" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "${ICONSET}")"
else
    echo "⚠️  아이콘 생성 생략 (AppIcon.png 또는 iconutil 없음)."
fi

# 임시(ad-hoc) 코드 서명 — 전역 단축키/화면 기록 권한 부여를 안정화한다.
codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null || \
    echo "⚠️  코드 서명 생략 (codesign 사용 불가)."

# 배포용 zip (Finder 와 호환되는 방식으로 압축)
echo "🗜  ${ZIP_NAME} 생성 중..."
ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${ZIP_NAME}" 2>/dev/null || \
    zip -r -q "${ZIP_NAME}" "${APP_BUNDLE}"

echo "✅ 완료:"
echo "   앱  : $(pwd)/${APP_BUNDLE}"
echo "   배포: $(pwd)/${ZIP_NAME}"
echo ""
echo "실행: open ${APP_BUNDLE}"
echo "처음 실행 시 시스템 설정 → 개인정보 보호 및 보안 → ‘화면 기록’ 에서 ScreenSnap 을 허용해야 합니다."

if [[ "${1:-}" == "--run" ]]; then
    echo "🚀 실행 중..."
    open "${APP_BUNDLE}"
fi
