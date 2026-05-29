import AppKit

/// 앱의 중심 컨트롤러. 설정·단축키·캡처·메뉴바를 모두 소유한다.
final class AppController: NSObject {

    private(set) var settings: Settings {
        didSet { settings.save() }
    }

    private let hotKeyManager = HotKeyManager()
    private lazy var captureService = CaptureService(settings: { [weak self] in
        self?.settings ?? .default
    })

    private var statusItem: NSStatusItem!
    private var prefsController: PreferencesWindowController?

    override init() {
        self.settings = Settings.load()
        super.init()
    }

    // MARK: - 시작

    func start() {
        setupStatusItem()
        hotKeyManager.onHotKey = { [weak self] slot in
            self?.handleHotKey(slot)
        }
        applyHotKeys()
    }

    private func handleHotKey(_ slot: HotKeyManager.Slot) {
        switch slot {
        case .area: captureService.capture(.area)
        case .full: captureService.capture(.full)
        }
    }

    /// 현재 설정의 단축키를 전역 등록한다.
    func applyHotKeys() {
        hotKeyManager.register(settings.areaHotKey, for: .area)
        hotKeyManager.register(settings.fullHotKey, for: .full)
        refreshMenu()
    }

    // MARK: - 메뉴바

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder",
                                   accessibilityDescription: "ScreenSnap")
            button.image?.isTemplate = true
        }
        refreshMenu()
    }

    private func refreshMenu() {
        let menu = NSMenu()

        menu.addItem(withTitle: "영역 캡처   \(settings.areaHotKey.displayString)",
                     action: #selector(captureArea), keyEquivalent: "").target = self

        menu.addItem(withTitle: "전체 화면 캡처   \(settings.fullHotKey.displayString)",
                     action: #selector(captureFull), keyEquivalent: "").target = self

        menu.addItem(.separator())

        let modeItem = NSMenuItem(title: "동작: \(settings.action.localizedTitle)",
                                  action: nil, keyEquivalent: "")
        modeItem.isEnabled = false
        menu.addItem(modeItem)

        menu.addItem(.separator())

        menu.addItem(withTitle: "설정…", action: #selector(openPreferences),
                     keyEquivalent: ",").target = self
        menu.addItem(withTitle: "ScreenSnap 종료", action: #selector(quit),
                     keyEquivalent: "q").target = self

        statusItem.menu = menu
    }

    // MARK: - 메뉴 액션

    @objc private func captureArea() { captureService.capture(.area) }
    @objc private func captureFull() { captureService.capture(.full) }

    @objc private func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        if prefsController == nil {
            prefsController = PreferencesWindowController(controller: self)
        }
        prefsController?.showWindow(nil)
        prefsController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - 설정 변경 API (PreferencesWindowController 에서 호출)

    func setAction(_ action: CaptureAction) {
        settings.action = action
        refreshMenu()
    }

    func setSaveDirectory(_ path: String) {
        settings.saveDirectory = path
    }

    func setPlaySound(_ on: Bool) {
        settings.playSound = on
    }

    /// 단축키 변경 시도. 충돌이 있으면 적용하지 않고 결과를 반환한다.
    func tryUpdateHotKey(_ hotKey: HotKey, for slot: HotKeyManager.Slot) -> ConflictResult {
        let others: [(label: String, key: HotKey)]
        switch slot {
        case .area: others = [("전체 화면 캡처", settings.fullHotKey)]
        case .full: others = [("영역 캡처", settings.areaHotKey)]
        }

        // 자기 자신이 점유한 단축키를 충돌로 오인하지 않도록 먼저 모두 해제한 뒤 검사.
        hotKeyManager.unregisterAll()
        let result = HotKeyConflict.check(hotKey, against: others)
        if result.hasConflict {
            applyHotKeys()   // 기존 단축키 복원
            return result
        }

        switch slot {
        case .area: settings.areaHotKey = hotKey
        case .full: settings.fullHotKey = hotKey
        }
        applyHotKeys()
        return .none
    }
}
