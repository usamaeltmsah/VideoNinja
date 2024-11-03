//
//  VideoEditorViewModel.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import Foundation
import Photos
import Combine

class VideoEditorViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var videoAssets: [PHAsset] = []
    @Published var hasPermission: Bool = false
    @Published var permissionMessage: String? = "Please grant access to view your videos."
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        requestPhotoLibraryPermission()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // Request photo library permission and handle different authorization statuses
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.hasPermission = true
                    self?.fetchSelectedVideos()
                case .denied, .restricted:
                    self?.hasPermission = false
                    self?.permissionMessage = "Access Denied. Go to Settings to allow access."
                case .notDetermined:
                    self?.hasPermission = false
                @unknown default:
                    break
                }
            }
        }
    }
    
    // Fetch selected videos based on permission status
    func fetchSelectedVideos() {
        videoAssets.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        assets.enumerateObjects { [weak self] (asset, _, _) in
            self?.videoAssets.append(asset)
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.fetchSelectedVideos()
        }
    }
}
