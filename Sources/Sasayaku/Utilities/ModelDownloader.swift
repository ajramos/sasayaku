import Foundation

actor ModelDownloader {
    func download(model: WhisperModelType, onProgress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let modelsDir = WhisperModelType.modelsDirectory
        try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

        if model.isDownloaded {
            return model.localURL
        }

        let (tempURL, response) = try await downloadWithProgress(url: model.downloadURL, onProgress: onProgress)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DownloadError.badResponse
        }

        try FileManager.default.moveItem(at: tempURL, to: model.localURL)
        return model.localURL
    }

    private func downloadWithProgress(url: URL, onProgress: @escaping @Sendable (Double) -> Void) async throws -> (URL, URLResponse) {
        let delegate = DownloadDelegate(onProgress: onProgress)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let (tempURL, response) = try await session.download(from: url, delegate: delegate)
        return (tempURL, response)
    }
}

enum DownloadError: LocalizedError {
    case badResponse

    var errorDescription: String? {
        switch self {
        case .badResponse: "Failed to download model"
        }
    }
}

final class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let onProgress: @Sendable (Double) -> Void

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled by async download call
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress(progress)
    }
}
