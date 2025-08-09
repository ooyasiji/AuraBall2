import Foundation

extension Locale {
    static func displayName(forLanguageIdentifier identifier: String) -> String? {
        let current = Locale.current
        if let full = current.localizedString(forIdentifier: identifier) {
            return full
        }
        let comps = Locale.components(fromIdentifier: identifier)
        if let lang = comps[NSLocale.Key.languageCode.rawValue] {
            return current.localizedString(forLanguageCode: lang)
        }
        return nil
    }
}