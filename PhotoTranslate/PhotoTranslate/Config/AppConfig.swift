import Foundation

enum ActiveTranslator: String {
    case google = "GOOGLE"
    case azure = "AZURE"
}

enum AppConfig {
    static func value(for key: String) -> String? {
        if let v = Bundle.main.object(forInfoDictionaryKey: key) as? String, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return v
        }
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        return nil
    }

    // Runtime fallback defaults
    static let defaultActiveTranslator = ProcessInfo.processInfo.environment["ACTIVE_TRANSLATOR"] ?? "GOOGLE"
    static let defaultGoogleKey = ProcessInfo.processInfo.environment["GOOGLE_TRANSLATE_API_KEY"] ?? "dummy"
    static let defaultAzureKey = ProcessInfo.processInfo.environment["AZURE_TRANSLATE_API_KEY"] ?? "dummy"
    static let defaultAzureRegion = ProcessInfo.processInfo.environment["AZURE_TRANSLATE_REGION"] ?? "eastus"

    static var googleApiKey: String? { value(for: "GOOGLE_TRANSLATE_API_KEY") ?? defaultGoogleKey }
    static var azureApiKey: String? { value(for: "AZURE_TRANSLATE_API_KEY") ?? defaultAzureKey }
    static var azureRegion: String? { value(for: "AZURE_TRANSLATE_REGION") ?? defaultAzureRegion }

    static var activeTranslator: ActiveTranslator {
        let raw = value(for: "ACTIVE_TRANSLATOR")?.uppercased() ?? defaultActiveTranslator
        return ActiveTranslator(rawValue: raw) ?? .google
    }

    static func activeTranslationService() -> TranslationService {
        switch activeTranslator {
        case .google:
            if let service = GoogleTranslateService(apiKey: googleApiKey) { return service }
        case .azure:
            if let service = AzureTranslateService(apiKey: azureApiKey, region: azureRegion) { return service }
        }
        return MissingKeyTranslationService()
    }
}

private final class MissingKeyTranslationService: TranslationService {
    func translate(text: String, from source: String?, to target: String) async throws -> TranslationResult {
        throw TranslationError.missingAPIKey
    }
}