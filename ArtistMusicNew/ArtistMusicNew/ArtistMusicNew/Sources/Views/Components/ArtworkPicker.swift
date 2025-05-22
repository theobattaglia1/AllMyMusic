import SwiftUI

struct ArtworkPicker: View {
    @Binding var image: UXImage?
    /// Called whenever the user picks or drops an image.
    var onImagePicked: (UXImage) -> Void

    var body: some View {
        ZStack {
            if let img = image {
                Image(uxImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray, lineWidth: 1)
                Text("Drag & drop\nor tap to browse")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 120, height: 120)
        .onTapGesture {
            DocumentPickerHelper.shared.pickImage { url in
                guard let url,
                      let data = try? Data(contentsOf: url),
                      let ui   = UXImage(data: data)
                else { return }
                DispatchQueue.main.async {
                    self.image = ui
                    onImagePicked(ui)
                }
            }
        }
        .onDrop(of: ["public.image"], isTargeted: nil) { providers in
            guard let prov = providers.first else { return false }
            prov.loadObject(ofClass: UXImage.self) { object, _ in
                if let img = object as? UXImage {
                    DispatchQueue.main.async {
                        self.image = img
                        onImagePicked(img)
                    }
                }
            }
            return true
        }
    }
}
