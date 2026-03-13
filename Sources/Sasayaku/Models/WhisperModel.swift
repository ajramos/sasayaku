import Foundation

enum WhisperModelType: String, CaseIterable, Identifiable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    case largev3 = "large-v3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny: "Tiny (~39 MB)"
        case .base: "Base (~150 MB)"
        case .small: "Small (~430 MB)"
        case .medium: "Medium (~1.5 GB)"
        case .largev3: "Large v3 (~2.9 GB)"
        }
    }

    var description: String {
        switch self {
        case .tiny: "Fastest, lower accuracy"
        case .base: "Good balance of speed & accuracy"
        case .small: "Better accuracy, recommended"
        case .medium: "High accuracy, slower"
        case .largev3: "Best accuracy, needs more RAM"
        }
    }
}
