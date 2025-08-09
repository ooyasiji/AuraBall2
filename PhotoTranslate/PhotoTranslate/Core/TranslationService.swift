import Foundation

enum TranslationError: Error, LocalizedError {
    case missingAPIKey
    case network(Error)
    case invalidResponse
    case unsupportedLanguage
    case rateLimited
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing API key. Add keys in Configs/Secrets.xcconfig."
        case .network(let err): return "Network error: \(err.localizedDescription)"
        case .invalidResponse: return "Invalid response from the translation service."
        case .unsupportedLanguage: return "Unsupported language."
        case .rateLimited: return "Rate limited. Please try again shortly."
        case .unknown: return "Unknown error."
        }
    }
}

protocol TranslationService {
    func translate(text: String, from source: String?, to target: String) async throws -> TranslationResult
}