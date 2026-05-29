import Foundation
import Carbon.HIToolbox

/// 단축키 충돌 검사 결과
struct ConflictResult {
    var hasConflict: Bool
    var description: String   // 사용자에게 보여줄 설명 ("" 면 충돌 없음)

    static let none = ConflictResult(hasConflict: false, description: "")
}

/// 단축키가 다른 곳에서 이미 사용 중인지 검사한다.
///
/// macOS 에는 "임의의 제3자 앱이 등록한 전역 단축키" 목록을 조회하는 공개 API 가
/// 없다. 따라서 다음 단계로 최대한 검출한다.
///   1. macOS 시스템 단축키 (com.apple.symbolichotkeys.plist 의 활성 항목)
///   2. 잘 알려진 macOS 기본 단축키 (Spotlight, 스크린샷, Mission Control 등)
///   3. 앱 자체의 다른 슬롯과의 중복
///   4. RegisterEventHotKey 시도 — 실패하면 누군가 이미 점유한 것
enum HotKeyConflict {

    /// 종합 검사. `otherHotKeys` 에는 같은 앱의 다른 단축키들을 넣는다.
    ///
    /// 주의: 호출 전에 이 앱이 점유한 단축키는 해제해 두어야 4단계(실제 등록 시도)가
    /// 자기 자신을 충돌로 오인하지 않는다.
    static func check(_ hotKey: HotKey,
                      against otherHotKeys: [(label: String, key: HotKey)]) -> ConflictResult {

        // 0) 수정자 없는 단축키는 위험 — 일반 타이핑을 가로챈다
        if !hotKey.hasModifier {
            return ConflictResult(
                hasConflict: true,
                description: "수정자 키(⌘/⌃/⌥/⇧) 없이 단독 키는 전역 단축키로 사용할 수 없습니다."
            )
        }

        // 1) 같은 앱 내 다른 슬롯과 중복
        for other in otherHotKeys where other.key == hotKey {
            return ConflictResult(
                hasConflict: true,
                description: "이 앱의 ‘\(other.label)’ 단축키와 동일합니다."
            )
        }

        // 2) macOS 기본/시스템 단축키와 중복
        if let name = systemReservedName(for: hotKey) {
            return ConflictResult(
                hasConflict: true,
                description: "macOS 시스템 단축키 ‘\(name)’ 와 겹칩니다."
            )
        }

        // 3) 실제 등록 시도로 점유 여부 확인.
        //    임시 슬롯으로 등록해 보고, 성공하면 즉시 해제한다.
        if !canRegister(hotKey) {
            return ConflictResult(
                hasConflict: true,
                description: "다른 프로그램이 이미 사용 중인 단축키입니다."
            )
        }

        return .none
    }

    // MARK: - 실제 등록 가능 여부

    /// 임시로 등록을 시도한다. RegisterEventHotKey 가 오류를 반환하면 점유된 것.
    private static func canRegister(_ hotKey: HotKey) -> Bool {
        let probeSignature: OSType = "PROB".utf16.reduce(0) { ($0 << 8) + OSType($1) }
        let hotKeyID = EventHotKeyID(signature: probeSignature, id: 9999)
        var ref: EventHotKeyRef?

        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr, let ref = ref {
            UnregisterEventHotKey(ref)   // 점유하지 않도록 즉시 해제
            return true
        }
        return false
    }

    // MARK: - macOS 시스템 단축키 검사

    /// 활성화된 시스템 단축키와 겹치면 그 이름을 반환.
    static func systemReservedName(for hotKey: HotKey) -> String? {
        // 2-a) 코드에 내장된 잘 알려진 기본값
        if let name = builtInReserved[Pair(keyCode: hotKey.keyCode, modifiers: hotKey.modifiers)] {
            return name
        }
        // 2-b) symbolichotkeys.plist 의 활성 항목
        if symbolicHotKeysContains(hotKey) {
            return "단축키 환경설정에 등록된 시스템 단축키"
        }
        return nil
    }

    private struct Pair: Hashable {
        var keyCode: UInt32
        var modifiers: UInt32
    }

    /// macOS 가 기본으로 점유하는 대표 단축키들.
    private static let builtInReserved: [Pair: String] = [
        // Spotlight ⌘Space
        Pair(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey)): "Spotlight 검색",
        // 스크린샷 ⌘⇧3 / ⌘⇧4 / ⌘⇧5
        Pair(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey)): "전체 화면 스크린샷",
        Pair(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey)): "영역 스크린샷",
        Pair(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)): "스크린샷 도구 모음",
        // 앱 전환/숨김
        Pair(keyCode: UInt32(kVK_Tab), modifiers: UInt32(cmdKey)): "앱 전환(⌘Tab)",
        Pair(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey)): "앱 가리기",
        Pair(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey)): "앱 종료",
        Pair(keyCode: UInt32(kVK_ANSI_W), modifiers: UInt32(cmdKey)): "창 닫기",
        Pair(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | optionKey)): "Finder 검색",
    ]

    /// `com.apple.symbolichotkeys.plist` 를 읽어 활성 단축키와 겹치는지 검사.
    private static func symbolicHotKeysContains(_ hotKey: HotKey) -> Bool {
        let path = NSHomeDirectory() + "/Library/Preferences/com.apple.symbolichotkeys.plist"
        guard let dict = NSDictionary(contentsOfFile: path),
              let hotkeys = dict["AppleSymbolicHotKeys"] as? [String: Any]
        else { return false }

        // symbolichotkeys 는 Cocoa(NSEvent) 수정자 마스크를 쓴다. Carbon → Cocoa 변환.
        let targetKeyCode = Int(hotKey.keyCode)
        let targetCocoaMods = cocoaModifierMask(fromCarbon: hotKey.modifiers)

        for (_, value) in hotkeys {
            guard let entry = value as? [String: Any],
                  let enabled = entry["enabled"] as? Bool, enabled,
                  let valueDict = entry["value"] as? [String: Any],
                  let params = valueDict["parameters"] as? [Any],
                  params.count >= 3,
                  let keyCode = (params[1] as? NSNumber)?.intValue,
                  let modMask = (params[2] as? NSNumber)?.intValue
            else { continue }

            // params[1] == -1 (0xFFFF) 인 항목은 키 코드가 없는(문자 기반) 항목 → 건너뜀
            if keyCode < 0 { continue }

            if keyCode == targetKeyCode &&
               (modMask & relevantCocoaMask) == (Int(targetCocoaMods) & relevantCocoaMask) {
                return true
            }
        }
        return false
    }

    // Cocoa 수정자 마스크 비트 (NSEvent.ModifierFlags 의 raw 값)
    private static let cocoaCommand = 1 << 20
    private static let cocoaShift   = 1 << 17
    private static let cocoaOption  = 1 << 19
    private static let cocoaControl = 1 << 18
    private static let relevantCocoaMask = (1 << 20) | (1 << 17) | (1 << 19) | (1 << 18)

    private static func cocoaModifierMask(fromCarbon carbon: UInt32) -> UInt {
        var mask = 0
        if carbon & UInt32(cmdKey)     != 0 { mask |= cocoaCommand }
        if carbon & UInt32(shiftKey)   != 0 { mask |= cocoaShift }
        if carbon & UInt32(optionKey)  != 0 { mask |= cocoaOption }
        if carbon & UInt32(controlKey) != 0 { mask |= cocoaControl }
        return UInt(mask)
    }
}
