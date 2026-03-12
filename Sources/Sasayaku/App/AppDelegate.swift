import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            let micAccess = await Permissions.checkMicrophoneAccess()
            if !micAccess {
                print("⚠️ Microphone access not granted")
            }

            if !Permissions.isAccessibilityEnabled {
                print("⚠️ Accessibility not enabled — grant in Settings > Privacy > Accessibility")
            }
        }
    }
}
