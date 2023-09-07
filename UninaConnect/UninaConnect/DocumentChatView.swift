//
//  DocumentChatView.swift
//  UninaConnect
//
//  Created by Valerio Domenico Conte on 03/09/23.
//

import SwiftUI
import QuickLook

struct DocumentChatView: View {
    @ObservedObject var cm: ChatManager
    @State private var showPicker = false

    var body: some View {
        VStack {
            List(cm.documents, id: \.id) { document in
                DocumentItemView(document: document)
            }
            
            HStack {
                
                Button {
                    showPicker = true
                } label: {
                    Text("Scegli documento")
                }
            }
            .padding()
        }
        .navigationTitle("Documenti")
        .sheet(isPresented: $showPicker) {
            PickerView(cm: cm)
        }
    }
}

struct DocumentItemView: View {
    var document: ChatDocument
    
    var body: some View {
        HStack {
            NavigationLink {
                DocumentDetailView(documentURL: document.fileURL)
            } label: {
                Text(document.fileName)
                    .padding(10)
                    .background(document.isSentByCurrentUser ? CustomColor.uninaColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct PickerView: View {
    @ObservedObject var cm: ChatManager
    
    var body: some View {
        DocumentPicker { url in
            cm.sendDocument(fileURL: url)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onDocumentPicked(url)
            }
        }
    }
}

struct DocumentView: UIViewControllerRepresentable {
    let documentURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: DocumentView

        init(_ parent: DocumentView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.documentURL as QLPreviewItem
        }
    }
}

struct DocumentDetailView: View {
    let documentURL: URL
    @State private var isPresentingShareSheet = false

    var body: some View {
        VStack {
            DocumentView(documentURL: documentURL)
                .edgesIgnoringSafeArea(.all)
                .navigationBarTitle(Text(documentURL.lastPathComponent), displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    isPresentingShareSheet.toggle()
                }) {
                    Image(systemName: "square.and.arrow.up")
                })
                .sheet(isPresented: $isPresentingShareSheet) {
                    ActivityViewController(activityItems: [documentURL], applicationActivities: nil)
                }
        }
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}

struct DocumentChatView_Previews: PreviewProvider {
    static let cm = ChatManager()
    static var previews: some View {
        DocumentChatView(cm: cm)
    }
}
