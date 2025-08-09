import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedCode: String
    @State private var searchText: String = ""

    private var filtered: [String] {
        if searchText.isEmpty { return Self.commonLanguages }
        return Self.commonLanguages.filter { code in
            let name = Locale.displayName(forLanguageIdentifier: code) ?? code
            return name.localizedCaseInsensitiveContains(searchText) || code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filtered, id: \.self) { code in
                Button {
                    selectedCode = code
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Locale.displayName(forLanguageIdentifier: code) ?? code)
                                .font(.body)
                            Text(code).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedCode == code {
                            Image(systemName: "checkmark").foregroundStyle(.accent)
                                .accessibilityLabel("Selected")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Target Language")
    }

    static let commonLanguages: [String] = [
        "ar", "de", "en", "es", "fr", "hi", "id", "it", "ja", "ko", "nl", "pt", "pt-BR",
        "ru", "sv", "tr", "vi", "zh", "zh-Hans", "zh-Hant", "uk", "pl", "fa", "he", "th",
        "bn", "ta", "te", "mr", "gu"
    ]
}