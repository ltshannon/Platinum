//
//  StorageService.swift
//  FirebaseDemo
//
//  Created by Larry Shannon on 1/5/24.
//

import Foundation
import FirebaseStorage
import SwiftUI
import PhotosUI

class StorageService {
    static let share = StorageService()
    @Published var url: String = ""
    let storage = Storage.storage().reference()
    
    func saveImage(item: PhotosPickerItem) {
        let storageMetaData = StorageMetadata()
        storageMetaData.contentType = "image/jpeg"
        let path = "\(UUID().uuidString).jpeg"
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let result = try await storage.child(path).putDataAsync(data, metadata: storageMetaData)
                    debugPrint("🦁", "saveImage Success: \(result.path ?? "no path")")

                    if let path = result.path {
                        let storage = Storage.storage()
                        storage.reference().child(path).downloadURL(completion: { url, error in
                            guard let url = url, error == nil else {
                                return
                            }
                            debugPrint("🌎", "url: \(url.absoluteString)")
//                            DispatchQueue.main.async {
                                self.url = url.absoluteString
//                            }
                        })
                    }
                }
            } catch {
                debugPrint("🧨", "saveImage \(error.localizedDescription)")
            }
        }
    }
}
