import Foundation

struct DetectedLanguage: Hashable, Codable {
    let code: String
    let displayName: String
    let confidence: Double?
}