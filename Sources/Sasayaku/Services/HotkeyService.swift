import AppKit

@MainActor
final class HotkeyService {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onRecordingStarted: (() -> Void)?
    var onRecordingStopped: (() -> Void)?

    private var isOptionPressed = false

    func start() {
        // Use DispatchQueue.main.async instead of Task to avoid latency
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleFlagsChanged(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleFlagsChanged(event)
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let optionDown = event.modifierFlags.contains(.option)

        if optionDown && !isOptionPressed {
            isOptionPressed = true
            onRecordingStarted?()
        } else if !optionDown && isOptionPressed {
            isOptionPressed = false
            onRecordingStopped?()
        }
    }

    deinit {
        // Cleanup handled by stop() — caller must call stop() before releasing
    }
}
