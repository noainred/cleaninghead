import AppKit

/// 실제 화면 캡처를 수행한다. macOS 내장 `screencapture` CLI 를 사용하므로
/// 화면 기록 권한 프롬프트 등 OS 동작과 자연스럽게 연동된다.
enum CaptureKind {
    case area   // 사용자가 영역 선택
    case full   // 전체 화면(모든 디스플레이)
}

final class CaptureService {

    private let settings: () -> Settings

    init(settings: @escaping () -> Settings) {
        self.settings = settings
    }

    /// 캡처 실행. 설정의 action 에 따라 클립보드/파일로 처리한다.
    func capture(_ kind: CaptureKind) {
        let cfg = settings()

        if cfg.action.savesToFile {
            captureToFile(kind, cfg: cfg)
        } else {
            captureToClipboardOnly(kind, cfg: cfg)
        }
    }

    // MARK: - 클립보드 전용

    private func captureToClipboardOnly(_ kind: CaptureKind, cfg: Settings) {
        var args = ["-c"]               // -c: 클립보드로
        if !cfg.playSound { args.append("-x") }
        if kind == .area { args.append("-i") }   // -i: 인터랙티브 영역 선택
        runScreenCapture(args: args) { _ in /* 결과는 클립보드에 */ }
    }

    // MARK: - 파일 저장 (필요 시 클립보드 동시)

    private func captureToFile(_ kind: CaptureKind, cfg: Settings) {
        guard let fileURL = makeFileURL(in: cfg.saveDirectory) else {
            notify(title: "저장 경로 오류", body: "저장 폴더를 만들 수 없습니다: \(cfg.saveDirectory)")
            return
        }

        var args: [String] = []
        if !cfg.playSound { args.append("-x") }
        if kind == .area { args.append("-i") }
        args.append(fileURL.path)

        runScreenCapture(args: args) { [weak self] success in
            guard let self = self else { return }
            // 사용자가 ESC 등으로 취소하면 파일이 생성되지 않는다.
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

            if cfg.action.copiesToClipboard {
                self.copyFileToClipboard(fileURL)
            }
            self.notify(title: "스크린샷 저장됨", body: fileURL.lastPathComponent)
        }
    }

    private func copyFileToClipboard(_ url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    // MARK: - 파일 경로 생성

    private func makeFileURL(in directory: String) -> URL? {
        let fm = FileManager.default
        let dirURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath,
                         isDirectory: true)

        if !fm.fileExists(atPath: dirURL.path) {
            try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }
        guard fm.fileExists(atPath: dirURL.path) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let name = "Screenshot \(formatter.string(from: Date())).png"
        return dirURL.appendingPathComponent(name)
    }

    // MARK: - screencapture 프로세스 실행

    private func runScreenCapture(args: [String], completion: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = args

        process.terminationHandler = { proc in
            DispatchQueue.main.async {
                completion(proc.terminationStatus == 0)
            }
        }

        do {
            try process.run()
        } catch {
            DispatchQueue.main.async {
                self.notify(title: "캡처 실패", body: error.localizedDescription)
                completion(false)
            }
        }
    }

    // MARK: - 사용자 알림

    private func notify(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        NSUserNotificationCenter.default.deliver(notification)
    }
}
