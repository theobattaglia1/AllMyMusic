//  DocumentPickerHelper.swift
//  One helper that works on both platforms.

import Foundation
#if os(iOS)
import SwiftUI
import UIKit
#else
import AppKit
#endif

final class DocumentPickerHelper {

    static let shared = DocumentPickerHelper()   // singleton
    private init() {}

    // MARK: Audio --------------------------------------------------------------
    func pickAudio(completion: @escaping (URL?) -> Void) {
    #if os(iOS)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        picker.allowsMultipleSelection = false
        picker.delegate = ClosureDelegate { urls in completion(urls.first) }
        keyWindow?.rootViewController?.present(picker, animated: true)
    #else
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.begin { res in
            completion(res == .OK ? panel.url : nil)
        }
    #endif
    }

    // MARK: Image --------------------------------------------------------------
    func pickImage(completion: @escaping (URL?) -> Void) {
    #if os(iOS)
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image])
        picker.allowsMultipleSelection = false
        picker.delegate = ClosureDelegate { urls in completion(urls.first) }
        keyWindow?.rootViewController?.present(picker, animated: true)
    #else
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.begin { res in
            completion(res == .OK ? panel.url : nil)
        }
    #endif
    }
}

#if os(iOS)
// Helper wrapper to avoid a separate NSObject subclass
private final class ClosureDelegate: NSObject, UIDocumentPickerDelegate {
    let onPick: ([URL]) -> Void
    init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) { onPick(urls) }
}

private var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first
}
#endif
