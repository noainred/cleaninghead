import AppKit
import Carbon.HIToolbox

/// 클릭하면 다음 키 입력을 단축키로 녹화하는 버튼형 컨트롤.
final class HotKeyRecorderView: NSView {

    /// 새 단축키가 녹화되면 호출. 호출 측에서 충돌 검사 후 반영한다.
    var onRecorded: ((HotKey) -> Void)?

    var hotKey: HotKey? {
        didSet { needsDisplay = true }
    }

    private var isRecording = false {
        didSet { needsDisplay = true }
    }

    private var eventMonitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 160, height: 26) }
    override var acceptsFirstResponder: Bool { true }

    // MARK: - 그리기

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        let radius: CGFloat = 6
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1),
                                xRadius: radius, yRadius: radius)

        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.15).setFill()
            NSColor.controlAccentColor.setStroke()
        } else {
            NSColor.controlBackgroundColor.setFill()
            NSColor.separatorColor.setStroke()
        }
        path.fill()
        path.lineWidth = 1
        path.stroke()

        let text: String
        if isRecording {
            text = "키 입력 대기 중…"
        } else if let hk = hotKey {
            text = hk.displayString
        } else {
            text = "단축키 없음"
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13,
                                     weight: isRecording ? .regular : .medium),
            .foregroundColor: isRecording ? NSColor.controlAccentColor
                                          : NSColor.labelColor
        ]
        let attr = NSAttributedString(string: text, attributes: attrs)
        let size = attr.size()
        let point = NSPoint(x: (bounds.width - size.width) / 2,
                            y: (bounds.height - size.height) / 2)
        attr.draw(at: point)
    }

    // MARK: - 녹화 토글

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)

        // 로컬 모니터로 keyDown / flagsChanged 가로채기
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isRecording else { return event }

            // ESC 단독 → 녹화 취소
            if event.keyCode == UInt16(kVK_Escape) &&
               !event.modifierFlags.contains(.command) &&
               !event.modifierFlags.contains(.control) &&
               !event.modifierFlags.contains(.option) {
                self.stopRecording()
                return nil
            }

            let mods = HotKey.carbonModifiers(from: event.modifierFlags)
            let recorded = HotKey(keyCode: UInt32(event.keyCode), modifiers: mods)
            self.stopRecording()
            self.onRecorded?(recorded)
            return nil   // 이벤트 소비
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
