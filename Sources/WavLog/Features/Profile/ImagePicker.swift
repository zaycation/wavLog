import PhotosUI
import SwiftUI

struct ImagePicker: View {
    var onImageSelected: (UIImage) -> Void
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text("Select Photo")
        }
        .photosPickerStyle(.inline)
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data)
                {
                    onImageSelected(image)
                    dismiss()
                }
            }
        }
    }
}
