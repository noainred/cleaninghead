import Foundation
import Carbon.HIToolbox

/// 캡처 후 동작 방식
enum CaptureAction: String, Codable, CaseIterable {
    case clipboardOnly   // 캡처만 (클립보드로 복사)
    case saveOnly        // 저장만 (파일로 저장)
    case both            // 캡처 + 저장 (클립보드 + 파일)

    var localizedTitle: String {
        switch self {
        case .clipboardOnly: return "캡처만 (클립보드)"
        case .saveOnly:      return "저장만 (파일)"
        case .both:          return "캡처 + 저장 (클립보드 + 파일)"
        }
    }

    var savesToFile: Bool { self == .saveOnly || self == .both }
    var copiesToClipboard: Bool { self == .clipboardOnly || self == .both }
}

/// 사용자 설정. UserDefaults 에 JSON 으로 저장된다.
struct Settings: Codable {
    var action: CaptureAction
    var saveDirectory: String        // 절대 경로
    var areaHotKey: HotKey
    var fullHotKey: HotKey
    var playSound: Bool

    static let defaultsKey = "com.screensnap.settings.v1"

    static var `default`: Settings {
        let pictures = FileManager.default
            .urls(for: .picturesDirectory, in: .userDomainMask)
            .first?.path
            ?? (NSHomeDirectory() + "/Pictures")

        return Settings(
            action: .both,
            saveDirectory: pictures,
            // 기본값: ⌃⇧4 (영역), ⌃⇧3 (전체) — macOS 기본 캡처(⌘⇧4/⌘⇧3)와 겹치지 않게 ⌃ 사용
            areaHotKey: HotKey(keyCode: UInt32(kVK_ANSI_4),
                               modifiers: UInt32(controlKey | shiftKey)),
            fullHotKey: HotKey(keyCode: UInt32(kVK_ANSI_3),
                               modifiers: UInt32(controlKey | shiftKey)),
            playSound: true
        )
    }

    // MARK: - 영속화

    static func load() -> Settings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(Settings.self, from: data)
        else { return .default }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Settings.defaultsKey)
        }
    }
}
