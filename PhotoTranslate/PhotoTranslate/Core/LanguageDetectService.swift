import Foundation
import NaturalLanguage

protocol LanguageDetecting {
    func detectLanguage(for text: String) -> DetectedLanguage?
}

final class LanguageDetectService: LanguageDetecting {
    private let minConfidence: Double = 0.45
    private let minLengthForDetection = 20

    func detectLanguage(for text: String) -> DetectedLanguage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLengthForDetection else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let language = recognizer.dominantLanguage else { return nil }

        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        let confidence = hypotheses[language] ?? 0.0

        guard confidence >= minConfidence else { return nil }

        let code = language.rawValue
        let display = Locale.displayName(forLanguageIdentifier: code) ?? code
        return DetectedLanguage(code: code, displayName: display, confidence: confidence)
    }
}