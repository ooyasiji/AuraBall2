import SwiftUI

struct LoadingOverlay: View {
    let message: String
    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().scaleEffect(1.2)
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
            .accessibilityAddTraits(.isModal)
        }
    }
}