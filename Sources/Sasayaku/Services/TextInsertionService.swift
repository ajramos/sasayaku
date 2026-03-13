import AppKit
import CoreGraphics

enum TextInsertionService {
    static func insertText(_ text: String) {
        print("[Sasayaku] Inserting text: '\(text)'")

        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Delay to ensure modifier keys (Option) are fully released before pasting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            Self.simulatePaste()

            // Restore previous clipboard after paste has been processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let previousContents {
                    pasteboard.clearContents()
                    pasteboard.setString(previousContents, forType: .string)
                }
            }
        }
    }

    private static func simulatePaste() {
        // Use a dedicated event source to avoid inheriting current modifier state
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("[Sasayaku] ERROR: Failed to create CGEvent — Accessibility permission missing?")
            return
        }

        // Explicitly set ONLY Command flag — no Option, no Shift, nothing else
        keyDown.flags = CGEventFlags.maskCommand
        keyUp.flags = CGEventFlags.maskCommand

        keyDown.post(tap: .cghidEventTap)
        usleep(10000) // 10ms between key down and up
        keyUp.post(tap: .cghidEventTap)

        print("[Sasayaku] Paste event sent (Cmd+V)")
    }
}
