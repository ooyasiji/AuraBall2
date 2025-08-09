import Foundation

final class AzureTranslateService: TranslationService {
    private let apiKey: String
    private let region: String
    private let endpointBase: URL

    init?(apiKey: String?, region: String?) {
        guard let key = apiKey, !key.isEmpty else { return nil }
        guard let region = region, !region.isEmpty else { return nil }
        self.apiKey = key
        self.region = region
        guard let url = URL(string: "https://\(region).api.cognitive.microsofttranslator.com") else { return nil }
        self.endpointBase = url
    }

    func translate(text: String, from source: String?, to target: String) async throws -> TranslationResult {
        var components = URLComponents(url: endpointBase.appending(path: "/translate"), resolvingAgainstBaseURL: false)!
        var query = [
            URLQueryItem(name: "api-version", value: "3.0"),
            URLQueryItem(name: "to", value: target)
        ]
        if let source, !source.isEmpty {
            query.append(URLQueryItem(name: "from", value: source))
        }
        components.queryItems = query

        guard let url = components.url else { throw TranslationError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.addValue(region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        let body = [[ "Text": text ]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await sendWithRetry(request: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            if let http = response as? HTTPURLResponse, http.statusCode == 429 { throw TranslationError.rateLimited }
            throw TranslationError.invalidResponse
        }

        struct AzureDetected: Decodable { let language: String?; let score: Double? }
        struct AzureTranslation: Decodable { let text: String; let to: String }
        struct AzureItem: Decodable { let detectedLanguage: AzureDetected?; let translations: [AzureTranslation] }

        let decoded = try JSONDecoder().decode([AzureItem].self, from: data)
        guard let first = decoded.first, let translation = first.translations.first else {
            throw TranslationError.invalidResponse
        }

        let detectedCode = first.detectedLanguage?.language ?? source ?? ""
        let detectedDisplay = Locale.displayName(forLanguageIdentifier: detectedCode) ?? detectedCode
        let detected = detectedCode.isEmpty ? nil : DetectedLanguage(code: detectedCode, displayName: detectedDisplay, confidence: first.detectedLanguage?.score)

        return TranslationResult(
            originalText: text,
            detectedSourceLanguage: detected,
            targetLanguageCode: translation.to,
            translatedText: translation.text
        )
    }

    private func sendWithRetry(request: URLRequest, maxRetries: Int = 2) async throws -> (Data, URLResponse) {
        var attempt = 0
        var lastError: Error?
        while attempt <= maxRetries {
            do {
                return try await URLSession.shared.data(for: request)
            } catch {
                lastError = error
                attempt += 1
                if attempt > maxRetries { break }
                let jitter = UInt64.random(in: 200_000_000...800_000_000)
                try? await Task.sleep(nanoseconds: jitter)
            }
        }
        throw TranslationError.network(lastError ?? TranslationError.unknown)
    }
}