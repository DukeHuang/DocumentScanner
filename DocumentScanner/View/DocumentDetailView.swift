//
//  DocumentDetailView.swift
//  DocumentScanner
//
//  Created by sakuragi on 2025/2/24.
//

import SwiftUI
import PDFKit
import LocalAuthentication

struct DocumentDetailView: View {
    var document: Document
    /// View Properties
    @State private var isLoading: Bool = false
    @State private var showFileMover: Bool = false
    @State private var fileURL: URL?
    /// Local Screen Properties
    @State private var isLockAvailable: Bool?
    @State private var isUnLocked: Bool = false
    /// Environment Values
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var body: some View {
        if let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) {
            VStack(spacing: 10) {
                HeaderView()
                    .padding([.horizontal, .top], 15)
                TabView {
                    ForEach(pages) { page in
                        if let image = UIImage(data: page.pageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
                .tabViewStyle(.page)
                FooterView()
            }
            .background(.black)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .loadingScreen(status: $isLoading)
            .overlay(content: {
                LockView()
            })
            .fileMover(isPresented: $showFileMover, file: fileURL) { result in
                if case .failure(_) = result {
                    /// Removing the temporary file
                    guard let fileURL else { return }
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
            .onAppear {
                guard document.isLocked else {
                    isUnLocked = true
                    return
                }
                
                let context = LAContext()
                isLockAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                
            }
        }
    }
    
    @ViewBuilder
    private func HeaderView() -> some View {
        Text(document.name)
            .font(.callout)
            .foregroundStyle(.white)
            .hSpacing(.center)
            .overlay(alignment: .trailing) {
                /// Lock Button
                Button {
                    document.isLocked.toggle()
                    isUnLocked = !document.isLocked
                    try? context.save()
                } label: {
                    Image(systemName: document.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
    }
    
    @ViewBuilder
    private func FooterView() -> some View {
        HStack {
            Button(action: createAndShareDocument) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            
            Spacer(minLength: 0)
            
            Button {
                dismiss()
                Task { @MainActor in
                    /// Giving some time to finish zoom transition effect
                    try? await Task.sleep(for: .seconds(0.3))
                    context.delete(document)
                    try? context.save()
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding([.horizontal,.bottom], 15)
    }
    
    @ViewBuilder
    private func LockView() -> some View {
        if document.isLocked {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 6) {
                    if let isLockAvailable, !isLockAvailable {
                        Text("Please enable biometric access in Setting to unlock this document!")
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                        Text("Tap to unlock!")
                            .font(.callout)
                    }
                }
                .padding(15)
                .background(.bar, in: .rect(cornerRadius: 10))
                .contentShape(.rect)
                .onTapGesture(perform: authenticateUser)
            }
            .opacity(isUnLocked ? 0 : 1)
            .animation(snappy, value: isUnLocked)
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Locked Document") { status, _ in
                DispatchQueue.main.async {
                    self.isUnLocked = status
                }
            }
        } else {
            isLockAvailable = false
            isUnLocked = false
        }
        
    }
    private func createAndShareDocument() {
        /// Converting SwiftData document into a PDF Document
        guard let pages = document.pages?.sorted(by: { $0.pageIndex < $1.pageIndex }) else { return }
        isLoading = true
        
        Task.detached(priority: .high) { [document] in
            try? await Task.sleep(for: .seconds(0.2))
            
            let pdfDocument = PDFDocument()
            for index in pages.indices {
                if let pageImage = UIImage(data: pages[index].pageData),
                   let pdfPage = PDFPage(image: pageImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            var pdfURL = FileManager.default.temporaryDirectory
            let fileName = "\(document.name).pdf"
            pdfURL.append(path: fileName)
            if pdfDocument.write(to: pdfURL) {
                await MainActor.run { [pdfURL] in
                    fileURL = pdfURL
                    showFileMover = true
                    isLoading = false
                }
            }
        }
        
    }
}
