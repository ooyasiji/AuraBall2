import Foundation
import Vision
import CoreGraphics
import UIKit

struct OCRResult {
    let text: String
    let confidence: Double
}

enum OCRError: Error, LocalizedError {
    case noText
    case processingFailed(Error)
    var errorDescription: String? {
        switch self {
        case .noText: return "No text detected in the image."
        case .processingFailed(let err): return "OCR failed: \(err.localizedDescription)"
        }
    }
}

protocol OCRServicing {
    func recognizeText(in image: CGImage, level: VNRequestTextRecognitionLevel) async throws -> OCRResult
}

final class OCRService: OCRServicing {
    func recognizeText(in image: CGImage, level: VNRequestTextRecognitionLevel = .accurate) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, err in
                if let err {
                    continuation.resume(throwing: OCRError.processingFailed(err))
                    return
                }
                guard let observations = req.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noText)
                    return
                }

                var collectedLines: [String] = []
                var confidences: [Double] = []

                for obs in observations {
                    guard let candidate = obs.topCandidates(1).first else { continue }
                    collectedLines.append(candidate.string)
                    confidences.append(Double(candidate.confidence))
                }

                let joined = collectedLines.joined(separator: "\n")
                let avgConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Double(confidences.count)

                if joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continuation.resume(throwing: OCRError.noText)
                } else {
                    continuation.resume(returning: OCRResult(text: joined, confidence: avgConfidence))
                }
            }

            request.recognitionLevel = level
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }
}