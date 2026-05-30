import Foundation
import Carbon.HIToolbox

/// 전역 단축키 등록/해제를 담당. Carbon 의 RegisterEventHotKey 사용.
///
/// 콜백은 메인 스레드에서 호출된다.
final class HotKeyManager {

    enum Slot: UInt32 {
        case area = 1
        case full = 2
    }

    /// 단축키가 눌렸을 때 호출되는 콜백 (slot 전달)
    var onHotKey: ((Slot) -> Void)?

    private var refs: [Slot: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?
    private let signature: OSType = {
        // 4글자 시그니처 'SNAP'
        let s = "SNAP".utf16.reduce(0) { ($0 << 8) + OSType($1) }
        return s
    }()

    init() {
        installHandler()
    }

    deinit {
        unregisterAll()
        if let handlerRef = handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    // MARK: - 핸들러 설치

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let eventRef = eventRef, let userData = userData else {
                    return OSStatus(eventNotHandledErr)
                }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hkID = EventHotKeyID()
                let status = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard status == noErr else { return status }
                if let slot = Slot(rawValue: hkID.id) {
                    DispatchQueue.main.async { manager.onHotKey?(slot) }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )
    }

    // MARK: - 등록 / 해제

    /// 지정한 슬롯에 단축키 등록. 성공 여부 반환.
    @discardableResult
    func register(_ hotKey: HotKey, for slot: Slot) -> Bool {
        unregister(slot)

        var hotKeyID = EventHotKeyID(signature: signature, id: slot.rawValue)
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
            refs[slot] = ref
            return true
        }
        return false
    }

    func unregister(_ slot: Slot) {
        if let ref = refs[slot] {
            UnregisterEventHotKey(ref)
            refs[slot] = nil
        }
    }

    func unregisterAll() {
        for slot in refs.keys {
            unregister(slot)
        }
    }
}
