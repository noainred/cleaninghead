import AppKit

/// 메뉴바 전용 앱. Dock 아이콘 없이 상태 막대에서만 동작한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // 메뉴바 전용 (Dock 미표시)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
