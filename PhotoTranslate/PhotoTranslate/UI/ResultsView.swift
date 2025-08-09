import SwiftUI
import UniformTypeIdentifiers

struct ResultsView: View {
    let result: TranslationResult
    let onNewImage: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    if let detected = result.detectedSourceLanguage {
                        Text("Detected: \(detected.displayName) (\(detected.code))")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                            .accessibilityLabel("Detected language \(detected.displayName)")
                    } else {
                        Text("Detected: Auto")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                            .accessibilityLabel("Detected language auto")
                    }

                    let targetName = Locale.displayName(forLanguageIdentifier: result.targetLanguageCode) ?? result.targetLanguageCode
                    Text("Target: \(targetName) (\(result.targetLanguageCode))")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityLabel("Target language \(targetName)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Text")
                        .font(.headline)
                    Text(result.originalText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Original text")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Translated Text")
                        .font(.headline)
                    Text(result.translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Translated text")
                }

                HStack {
                    Button {
                        UIPasteboard.general.string = result.translatedText
                    } label: {
                        Label("Copy Translation", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    ShareLink(item: result.translatedText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    onNewImage()
                } label: {
                    Label("New Image", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}