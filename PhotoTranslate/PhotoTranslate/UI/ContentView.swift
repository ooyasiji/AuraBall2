import SwiftUI
import PhotosUI
import Vision
import NaturalLanguage

@MainActor
struct ContentView: View {
    let ocrService: OCRServicing
    let languageDetector: LanguageDetecting
    let translationService: TranslationService

    @State private var selectedImage: UIImage?
    @AppStorage("targetLang") private var targetLanguageCode: String = "ar"

    @State private var isProcessing: Bool = false
    @State private var processingMessage: String = ""
    @State private var errorMessage: String?
    @State private var ocrText: String = ""
    @State private var detection: DetectedLanguage?
    @State private var result: TranslationResult?
    @State private var navigateToResults: Bool = false
    @State private var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    @State private var preserveLineBreaks: Bool = true

    @AppStorage("history") private var historyData: Data = Data()
    private let maxHistory = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("Selected image preview")
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(.secondary)
                            .frame(maxHeight: 260)
                        Text("No image selected")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("No image selected")
                }

                HStack(spacing: 12) {
                    CameraImagePickerButton(selectedImage: $selectedImage)
                    LibraryImagePicker(selectedImage: $selectedImage)
                }

                NavigationLink {
                    LanguagePickerView(selectedCode: $targetLanguageCode)
                } label: {
                    HStack {
                        let langName = Locale.displayName(forLanguageIdentifier: targetLanguageCode) ?? targetLanguageCode
                        Label("Target: \(langName)", systemImage: "globe")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityLabel("Choose target language")
                .accessibilityHint("Opens the list of languages")

                VStack(spacing: 8) {
                    Toggle(isOn: $preserveLineBreaks) {
                        Text("Preserve line breaks")
                    }
                    .toggleStyle(.switch)

                    Picker("Recognition", selection: $recognitionLevel) {
                        Text("Accurate").tag(VNRequestTextRecognitionLevel.accurate)
                        Text("Fast").tag(VNRequestTextRecognitionLevel.fast)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("OCR Recognition level")
                }
                .padding(.top, 4)

                Button {
                    Task { await extractAndTranslate() }
                } label: {
                    Label("Extract & Translate", systemImage: "text.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedImage == nil || targetLanguageCode.isEmpty || isProcessing)

                if let errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Text(errorMessage).font(.subheadline)
                        HStack {
                            Button("Retry") { Task { await extractAndTranslate() } }
                            Button("Dismiss") { self.errorMessage = nil }
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.red)
                    .accessibilityElement(children: .combine)
                }

                Spacer(minLength: 0)

                NavigationLink(isActive: $navigateToResults) {
                    if let result {
                        ResultsView(result: result) {
                            resetForNewImage()
                        }
                    } else {
                        EmptyView()
                    }
                } label: { EmptyView() }
            }
            .padding()
            .navigationTitle("PhotoTranslate")
        }
        .overlay {
            if isProcessing { LoadingOverlay(message: processingMessage) }
        }
    }

    private func resetForNewImage() {
        selectedImage = nil
        ocrText = ""
        detection = nil
        result = nil
        navigateToResults = false
        errorMessage = nil
    }

    private func extractAndTranslate() async {
        guard !isProcessing else { return }
        errorMessage = nil
        guard let image = selectedImage, let cgImage = image.cgImage else {
            errorMessage = "Please select an image first."
            return
        }

        isProcessing = true
        processingMessage = "Extracting text…"
        do {
            var ocr = try await ocrService.recognizeText(in: cgImage, level: recognitionLevel)
            if !preserveLineBreaks {
                ocr = OCRResult(
                    text: ocr.text
                        .components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " "),
                    confidence: ocr.confidence
                )
            }
            self.ocrText = ocr.text

            let detected = languageDetector.detectLanguage(for: ocr.text)
            self.detection = detected

            processingMessage = "Translating…"
            let translated = try await translationService.translate(
                text: ocr.text,
                from: detected?.code,
                to: targetLanguageCode
            )
            self.result = translated
            self.navigateToResults = true

            appendToHistory(translated)
        } catch let e as OCRError {
            self.errorMessage = e.localizedDescription
        } catch let e as TranslationError {
            self.errorMessage = e.localizedDescription
        } catch {
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        isProcessing = false
    }

    private func appendToHistory(_ item: TranslationResult) {
        var list: [TranslationResult] = (try? JSONDecoder().decode([TranslationResult].self, from: historyData)) ?? []
        list.insert(item, at: 0)
        if list.count > maxHistory { list.removeLast(list.count - maxHistory) }
        if let data = try? JSONEncoder().encode(list) {
            historyData = data
        }
    }
}