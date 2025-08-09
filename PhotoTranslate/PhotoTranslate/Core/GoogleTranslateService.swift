import Foundation

final class GoogleTranslateService: TranslationService {
    private let apiKey: String
    private let endpoint = URL(string: "https://translation.googleapis.com/language/translate/v2")!

    init?(apiKey: String?) {
        guard let key = apiKey, !key.isEmpty else { return nil }
        self.apiKey = key
    }

    func translate(text: String, from source: String?, to target: String) async throws -> TranslationResult {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else { throw TranslationError.invalidResponse }

        var bodyItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "target", value: mapTargetCodeForGoogle(target))
        ]
        if let source, !source.isEmpty {
            bodyItems.append(URLQueryItem(name: "source", value: mapSourceCodeForGoogle(source)))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyItems
            .map { "\($0.name)=\(($0.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await sendWithRetry(request: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            if let http = response as? HTTPURLResponse, http.statusCode == 429 { throw TranslationError.rateLimited }
            throw TranslationError.invalidResponse
        }

        struct GoogleResponse: Decodable {
            struct DataObj: Decodable {
                struct TranslationObj: Decodable {
                    let translatedText: String
                    let detectedSourceLanguage: String?
                }
                let translations: [TranslationObj]
            }
            let data: DataObj
        }

        let decoded = try JSONDecoder().decode(GoogleResponse.self, from: data)
        guard let first = decoded.data.translations.first else { throw TranslationError.invalidResponse }

        let detectedCode = first.detectedSourceLanguage ?? source ?? ""
        let detectedDisplay = Locale.displayName(forLanguageIdentifier: detectedCode) ?? detectedCode
        let detected = detectedCode.isEmpty ? nil : DetectedLanguage(code: detectedCode, displayName: detectedDisplay, confidence: nil)

        return TranslationResult(
            originalText: text,
            detectedSourceLanguage: detected,
            targetLanguageCode: target,
            translatedText: decodeHTMLEntities(first.translatedText)
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

    private func mapTargetCodeForGoogle(_ code: String) -> String {
        switch code {
        case "zh-Hans": return "zh-CN"
        case "zh-Hant": return "zh-TW"
        default: return code
        }
    }

    private func mapSourceCodeForGoogle(_ code: String) -> String {
        switch code {
        case "zh-Hans": return "zh-CN"
        case "zh-Hant": return "zh-TW"
        default: return code
        }
    }

    private func decodeHTMLEntities(_ text: String) -> String {
        guard let data = text.data(using: .utf8) else { return text }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attr.string
        }
        return text
    }
}