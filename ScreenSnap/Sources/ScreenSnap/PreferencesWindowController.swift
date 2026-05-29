import AppKit

/// 설정 창. 동작 방식 / 저장 경로 / 단축키 / 소리 옵션을 편집한다.
final class PreferencesWindowController: NSWindowController {

    private weak var controller: AppController?

    private var actionPopup: NSPopUpButton!
    private var pathField: NSTextField!
    private var areaRecorder: HotKeyRecorderView!
    private var fullRecorder: HotKeyRecorderView!
    private var areaWarning: NSTextField!
    private var fullWarning: NSTextField!
    private var soundCheckbox: NSButton!

    init(controller: AppController) {
        self.controller = controller

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenSnap 설정"
        window.center()
        super.init(window: window)
        buildUI()
        syncFromSettings()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - UI 구성

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor)
        ])

        // 1) 동작 방식
        stack.addArrangedSubview(sectionLabel("캡처 동작"))
        actionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for action in CaptureAction.allCases {
            actionPopup.addItem(withTitle: action.localizedTitle)
            actionPopup.lastItem?.representedObject = action.rawValue
        }
        actionPopup.target = self
        actionPopup.action = #selector(actionChanged)
        stack.addArrangedSubview(actionPopup)

        // 2) 저장 경로
        stack.addArrangedSubview(sectionLabel("저장 경로"))
        let pathRow = NSStackView()
        pathRow.orientation = .horizontal
        pathRow.spacing = 8
        pathField = NSTextField(string: "")
        pathField.isEditable = false
        pathField.isSelectable = true
        pathField.lineBreakMode = .byTruncatingMiddle
        pathField.translatesAutoresizingMaskIntoConstraints = false
        pathField.widthAnchor.constraint(equalToConstant: 300).isActive = true
        let chooseButton = NSButton(title: "선택…", target: self,
                                    action: #selector(chooseDirectory))
        chooseButton.bezelStyle = .rounded
        pathRow.addArrangedSubview(pathField)
        pathRow.addArrangedSubview(chooseButton)
        stack.addArrangedSubview(pathRow)

        // 3) 단축키
        stack.addArrangedSubview(sectionLabel("단축키"))

        let (areaRow, areaRec, areaWarn) = hotKeyRow(label: "영역 캡처")
        areaRecorder = areaRec
        areaWarning = areaWarn
        areaRecorder.onRecorded = { [weak self] hk in self?.recorded(hk, slot: .area) }
        stack.addArrangedSubview(areaRow)
        stack.addArrangedSubview(areaWarning)

        let (fullRow, fullRec, fullWarn) = hotKeyRow(label: "전체 화면 캡처")
        fullRecorder = fullRec
        fullWarning = fullWarn
        fullRecorder.onRecorded = { [weak self] hk in self?.recorded(hk, slot: .full) }
        stack.addArrangedSubview(fullRow)
        stack.addArrangedSubview(fullWarning)

        // 4) 소리
        soundCheckbox = NSButton(checkboxWithTitle: "캡처 시 셔터 소리 재생",
                                 target: self, action: #selector(soundChanged))
        stack.addArrangedSubview(soundCheckbox)

        // 안내
        let hint = NSTextField(wrappingLabelWithString:
            "단축키 칸을 클릭한 뒤 원하는 조합을 누르세요. 다른 프로그램이나 macOS 시스템 단축키와 겹치면 경고가 표시되고 적용되지 않습니다.")
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.preferredMaxLayoutWidth = 410
        stack.addArrangedSubview(hint)
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        return label
    }

    private func hotKeyRow(label: String)
        -> (row: NSStackView, recorder: HotKeyRecorderView, warning: NSTextField) {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 12

        let title = NSTextField(labelWithString: label)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.widthAnchor.constraint(equalToConstant: 120).isActive = true

        let recorder = HotKeyRecorderView(frame: NSRect(x: 0, y: 0, width: 160, height: 26))
        recorder.translatesAutoresizingMaskIntoConstraints = false
        recorder.widthAnchor.constraint(equalToConstant: 160).isActive = true
        recorder.heightAnchor.constraint(equalToConstant: 26).isActive = true

        row.addArrangedSubview(title)
        row.addArrangedSubview(recorder)

        let warning = NSTextField(labelWithString: "")
        warning.font = NSFont.systemFont(ofSize: 11)
        warning.textColor = .systemRed

        return (row, recorder, warning)
    }

    // MARK: - 설정 ↔ UI 동기화

    private func syncFromSettings() {
        guard let s = controller?.settings else { return }

        // 동작
        if let index = CaptureAction.allCases.firstIndex(of: s.action) {
            actionPopup.selectItem(at: index)
        }
        // 경로
        pathField.stringValue = s.saveDirectory
        // 단축키
        areaRecorder.hotKey = s.areaHotKey
        fullRecorder.hotKey = s.fullHotKey
        // 소리
        soundCheckbox.state = s.playSound ? .on : .off
    }

    // MARK: - 액션 핸들러

    @objc private func actionChanged() {
        guard let raw = actionPopup.selectedItem?.representedObject as? String,
              let action = CaptureAction(rawValue: raw) else { return }
        controller?.setAction(action)
    }

    @objc private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "선택"
        if let current = controller?.settings.saveDirectory {
            panel.directoryURL = URL(fileURLWithPath: current)
        }
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.controller?.setSaveDirectory(url.path)
            self?.pathField.stringValue = url.path
        }
    }

    @objc private func soundChanged() {
        controller?.setPlaySound(soundCheckbox.state == .on)
    }

    private func recorded(_ hotKey: HotKey, slot: HotKeyManager.Slot) {
        guard let controller = controller else { return }
        let result = controller.tryUpdateHotKey(hotKey, for: slot)

        let recorder = (slot == .area) ? areaRecorder! : fullRecorder!
        let warning = (slot == .area) ? areaWarning! : fullWarning!

        if result.hasConflict {
            // 적용하지 않고 기존 값 유지 + 경고
            recorder.hotKey = (slot == .area) ? controller.settings.areaHotKey
                                              : controller.settings.fullHotKey
            warning.stringValue = "⚠︎ \(result.description)"
        } else {
            recorder.hotKey = hotKey
            warning.stringValue = ""
        }
    }
}
