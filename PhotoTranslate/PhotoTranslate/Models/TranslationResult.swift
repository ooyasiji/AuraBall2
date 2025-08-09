import Foundation

struct TranslationResult: Hashable, Codable {
    let originalText: String
    let detectedSourceLanguage: DetectedLanguage?
    let targetLanguageCode: String
    let translatedText: String
}