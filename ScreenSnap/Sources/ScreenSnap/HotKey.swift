import Foundation
import Carbon.HIToolbox
import AppKit

/// 단축키 하나를 표현하는 값 타입.
/// `keyCode` 는 가상 키 코드(virtual key code), `modifiers` 는 Carbon 수정자 플래그.
struct HotKey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32   // Carbon: cmdKey, shiftKey, optionKey, controlKey 조합

    /// 사람이 읽을 수 있는 표기 (예: "⌘⇧4")
    var displayString: String {
        var parts = ""
        if modifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { parts += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { parts += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { parts += "⌘" }
        parts += HotKey.keyName(for: keyCode)
        return parts
    }

    /// 수정자 키가 하나도 없으면 전역 단축키로 부적합 (오작동 위험)
    var hasModifier: Bool {
        modifiers & UInt32(cmdKey | shiftKey | optionKey | controlKey) != 0
    }

    // MARK: - Cocoa(NSEvent) → Carbon 변환

    /// NSEvent 의 수정자 플래그를 Carbon 수정자 플래그로 변환
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    // MARK: - 가상 키 코드 → 이름

    static func keyName(for keyCode: UInt32) -> String {
        if let name = specialKeyNames[Int(keyCode)] {
            return name
        }
        // 문자/숫자 키는 현재 키보드 레이아웃으로 변환
        if let char = characterForKeyCode(keyCode) {
            return char.uppercased()
        }
        return "Key\(keyCode)"
    }

    /// 키보드 레이아웃을 사용해 키 코드를 실제 문자로 변환
    private static func characterForKeyCode(_ keyCode: UInt32) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let dataRef = unsafeBitCast(layoutData, to: CFData.self)
        let keyLayoutPtr = CFDataGetBytePtr(dataRef)
        let keyLayout = unsafeBitCast(keyLayoutPtr, to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var realLength = 0

        let status = UCKeyTranslate(
            keyLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,                              // 수정자 없음
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &realLength,
            &chars
        )

        guard status == noErr, realLength > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: realLength)
    }

    /// 문자로 표현되지 않는 특수 키들의 이름 표
    private static let specialKeyNames: [Int: String] = [
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Space: "Space",
        kVK_Delete: "⌫",
        kVK_Escape: "⎋",
        kVK_ForwardDelete: "⌦",
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_ANSI_KeypadEnter: "⌤"
    ]
}
