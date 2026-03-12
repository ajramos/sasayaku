import AppKit
import CoreGraphics

enum TextInsertionService {
    static func insertText(_ text: String) {
        print("[Sasayaku] Inserting text: '\(text)'")

        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure clipboard is set before paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
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
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("[Sasayaku] ERROR: Failed to create CGEvent — Accessibility permission missing?")
            return
        }

        keyDown.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)

        keyUp.flags = .maskCommand
        keyUp.post(tap: .cghidEventTap)

        print("[Sasayaku] Paste event sent (Cmd+V)")
    }
}
