class Screensnap < Formula
  desc "macOS 메뉴바 화면 캡처 도구 (영역/전체, 분리된 단축키)"
  homepage "https://github.com/noainred/cleaninghead/tree/main/ScreenSnap"
  license "MIT"
  head "https://github.com/noainred/cleaninghead.git", branch: "main"

  # 정식 릴리스가 생기면 아래 stable 블록의 주석을 풀고 tag/revision 을 채우세요.
  # stable do
  #   url "https://github.com/noainred/cleaninghead.git",
  #       tag:      "screensnap-v1.0.0",
  #       revision: "<full-commit-sha>"
  #   version "1.0.0"
  # end

  depends_on :macos
  # Swift Package Manager(swift build)는 Command Line Tools 만으로 빌드 가능하므로
  # 전체 Xcode.app 을 요구하지 않는다. (depends_on xcode 는 의도적으로 사용하지 않음)

  def install
    cd "ScreenSnap" do
      system "swift", "build", "--disable-sandbox", "-c", "release"
      # 메뉴바 앱은 main.swift 에서 setActivationPolicy(.accessory) 를 호출하므로
      # 단일 실행 파일만으로도 Dock 없이 동작한다. CLI 로 설치한다.
      bin.install ".build/release/ScreenSnap" => "screensnap"
    end
  end

  def caveats
    <<~EOS
      ScreenSnap 은 메뉴바 전용 앱입니다. 다음 명령으로 실행하세요:
        screensnap &

      처음 캡처할 때 화면 기록 권한이 필요합니다:
        시스템 설정 → 개인정보 보호 및 보안 → 화면 기록 → ScreenSnap(터미널) 허용

      자동 시작을 원하면 로그인 항목에 추가하거나 launchd 에 등록하세요.
    EOS
  end

  test do
    assert_path_exists bin/"screensnap"
  end
end
