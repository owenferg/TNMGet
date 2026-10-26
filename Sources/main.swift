import SwiftUI

@main
struct OGet: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @StateObject private var dl = Downloader.shared

    var body: some Scene {
        Window("oGet", id: "main") {
            ContentView().environmentObject(dl)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ app: NSApplication, open urls: [URL]) {
        if let url = urls.first, !Downloader.shared.active { Downloader.shared.start(url) }
    }
}

struct ContentView: View {
    @EnvironmentObject var dl: Downloader
    private var hover: Bool { dl.hover }

    var body: some View {
        VStack(spacing: 0) {
            if dl.total == 0 {
                Text("Drop your data.txt downloaded from TNM Downloader")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            content
                .frame(maxHeight: .infinity)
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 20)
        .frame(width: 380, height: 220)
        .onAppear { DispatchQueue.main.async(execute: addTitle) }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, !dl.active else { return false }
            dl.start(url)
            return true
        } isTargeted: { dl.hover = $0 && !dl.active }
        .animation(.easeOut(duration: 0.15), value: hover)
    }

    @ViewBuilder private var content: some View {
        if dl.total == 0 {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(hover ? Color.accentColor : .secondary.opacity(0.5))
                .background(RoundedRectangle(cornerRadius: 14).fill(hover ? Color.accentColor.opacity(0.08) : .clear))
                .overlay(
                    Image(systemName: "arrow.down")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(hover ? Color.accentColor : .secondary)
                )
                .contentShape(Rectangle())
                .onTapGesture(perform: pick)
        } else {
            VStack(spacing: 14) {
                ProgressView(value: dl.progress)
                    .progressViewStyle(.linear)
                    .tint(dl.failed.isEmpty ? .accentColor : .orange)
                HStack(spacing: 12) {
                    Text("\(dl.finished) / \(dl.total)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !dl.active && !dl.failed.isEmpty {
                        Button(action: dl.retry) {
                            Label("\(dl.failed.count)", systemImage: "arrow.clockwise")
                        }
                        .foregroundStyle(.orange)
                    }
                    if !dl.active && dl.failed.isEmpty {
                        Image(systemName: "checkmark").foregroundStyle(.green)
                    }
                    Button { if let f = dl.folder { NSWorkspace.shared.open(f) } } label: {
                        Image(systemName: "folder")
                    }
                }
                .buttonStyle(.borderless)
                .font(.callout)
            }
            .padding(.horizontal, 8)
            .overlay(hover ? RoundedRectangle(cornerRadius: 14).stroke(Color.accentColor, lineWidth: 1.5).padding(-14) : nil)
        }
    }

    // Places "oGet" just right of the traffic-light buttons.
    private func addTitle() {
        guard let zoom = NSApp.windows.lazy.compactMap({ $0.standardWindowButton(.zoomButton) }).first,
              let bar = zoom.superview else { return }
        let label = NSTextField(labelWithString: "oGet")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.sizeToFit()
        label.setFrameOrigin(NSPoint(x: zoom.frame.maxX + 12, y: zoom.frame.midY - label.frame.height / 2))
        bar.addSubview(label)
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url { dl.start(url) }
    }
}

final class Downloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = Downloader()

    @Published var total = 0
    @Published var finished = 0
    @Published var failed: [URL] = []
    @Published var progress = 0.0
    @Published var folder: URL?
    @Published var active = false
    @Published var hover = false

    private let parallel = 4
    private let maxAttempts = 3
    private var queue: [URL] = []
    private var attempts: [URL: Int] = [:]
    private var running: [Int: URL] = [:]
    private var fractions: [Int: Double] = [:]
    private var activity: NSObjectProtocol?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)

    func start(_ list: URL) {
        guard let text = try? String(contentsOf: list, encoding: .utf8) else { return }
        let urls = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { URL(string: $0) }
            .filter { $0.scheme?.hasPrefix("http") == true }
        guard !urls.isEmpty else { return }

        let dir = list.deletingPathExtension()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        folder = dir
        total = urls.count
        failed = []
        attempts = [:]
        queue = urls.filter { !FileManager.default.fileExists(atPath: destination($0).path) }
        finished = total - queue.count
        run()
    }

    func retry() {
        finished -= failed.count
        queue = failed
        failed = []
        attempts = [:]
        run()
    }

    private func run() {
        active = true
        activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Downloading")
        fill()
        update()
    }

    private func destination(_ url: URL) -> URL {
        folder!.appendingPathComponent(url.lastPathComponent)
    }

    private func fill() {
        while running.count < parallel, !queue.isEmpty {
            let url = queue.removeFirst()
            let task = session.downloadTask(with: url)
            running[task.taskIdentifier] = url
            fractions[task.taskIdentifier] = 0
            task.resume()
        }
        if running.isEmpty && queue.isEmpty {
            active = false
            if let a = activity { ProcessInfo.processInfo.endActivity(a); activity = nil }
            if failed.isEmpty { NSSound(named: "Glass")?.play() }
        }
    }

    private func update() {
        guard total > 0 else { return }
        progress = (Double(finished) + fractions.values.reduce(0, +)) / Double(total)
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten w: Int64, totalBytesExpectedToWrite e: Int64) {
        guard e > 0 else { return }
        fractions[t.taskIdentifier] = Double(w) / Double(e)
        update()
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = running[t.taskIdentifier],
              (t.response as? HTTPURLResponse)?.statusCode == 200 else { return }
        let dest = destination(url)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: location, to: dest)
        try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: dest.path)
    }

    func urlSession(_ s: URLSession, task t: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = running.removeValue(forKey: t.taskIdentifier) else { return }
        fractions.removeValue(forKey: t.taskIdentifier)
        let ok = error == nil && FileManager.default.fileExists(atPath: destination(url).path)
        if ok {
            finished += 1
        } else {
            attempts[url, default: 0] += 1
            if attempts[url]! < maxAttempts {
                queue.append(url)
            } else {
                failed.append(url)
                finished += 1
            }
        }
        fill()
        update()
    }
}
