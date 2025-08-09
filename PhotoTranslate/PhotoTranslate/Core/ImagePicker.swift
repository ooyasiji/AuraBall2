import SwiftUI
import PhotosUI
import UIKit

struct LibraryImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(
            selection: $pickerItem,
            matching: .images
        ) {
            Label("Choose Photo", systemImage: "photo.on.rectangle")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Choose photo from library")
                .accessibilityHint("Opens your photo library to select an image")
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run { selectedImage = uiImage }
                }
            }
        }
    }
}

struct CameraImagePickerButton: View {
    @Binding var selectedImage: UIImage?
    @State private var isPresentingCamera = false

    var body: some View {
        Button {
            isPresentingCamera = true
        } label: {
            Label("Take Photo", systemImage: "camera")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
        .accessibilityLabel("Take photo with camera")
        .accessibilityHint("Opens the camera to capture a new photo")
        .sheet(isPresented: $isPresentingCamera) {
            CameraPicker(image: $selectedImage)
                .ignoresSafeArea()
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}