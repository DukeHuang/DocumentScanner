//
//  DocumentScannerApp.swift
//  DocumentScanner
//
//  Created by sakuragi on 2025/2/23.
//

import SwiftUI

@main
struct DocumentScannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: Document.self)
        }
    }
}
