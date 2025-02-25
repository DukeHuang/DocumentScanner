//
//  CGSize+Extensions.swift
//  DocumentScanner
//
//  Created by sakuragi on 2025/2/23.
//

import SwiftUI

extension CGSize {
    /// This function will ruturn a new size that fits the given size in an aspect ratio
    func aspectFit(_ to: CGSize) -> CGSize {
        let scaleX = to.width / self.width
        let scaleY = to.height / self.height
        
        let aspectRatio = min(scaleX, scaleY)
        return .init(width: aspectRatio * width, height: aspectRatio * height)
    }
}
