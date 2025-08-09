import SwiftUI

@main
struct PhotoTranslateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                ocrService: OCRService(),
                languageDetector: LanguageDetectService(),
                translationService: AppConfig.activeTranslationService()
            )
        }
    }
}