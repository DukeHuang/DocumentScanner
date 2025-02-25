//
//  ContentView.swift
//  DocumentScanner
//
//  Created by sakuragi on 2025/2/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("showIntroView") private var showIntroView: Bool = true

    var body: some View {
        Home()
            .sheet(isPresented: $showIntroView) {
                IntroScreen()
                    .interactiveDismissDisabled()
            }
    }
}

#Preview {
    ContentView()
}
