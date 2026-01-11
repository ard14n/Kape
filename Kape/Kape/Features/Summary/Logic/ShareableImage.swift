import SwiftUI
import UniformTypeIdentifiers

/// Wrapper for UIImage to enable sharing via SwiftUI ShareLink
/// Architecture: Features/Summary/Logic/ShareableImage.swift
/// Story 3.4: Native Sharing Integration (AC: 1, 2)
struct ShareableImage: Identifiable, Transferable {
    let id = UUID()
    let uiImage: UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareableImage in
            shareableImage.uiImage.pngData() ?? Data()
        }
    }
}
