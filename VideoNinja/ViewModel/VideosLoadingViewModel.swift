//
//  VideosLoadingViewModel.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import Foundation
import AVFoundation
import Photos
import Combine

class VideosLoadingViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var videoAssets: [PHAsset] = []
    @Published var selectedAVAsset: AVAsset? // AVAsset for the selected video
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
    
    // Request permission to access the photo library
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.hasPermission = true
                    self?.fetchVideoAssets()
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
    
    // Fetch video assets from the library
    private func fetchVideoAssets() {
        videoAssets.removeAll()
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let assets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        assets.enumerateObjects { [weak self] (asset, _, _) in
            self?.videoAssets.append(asset)
        }
    }
    
    // Convert a selected PHAsset to AVAsset for editing
    func loadAVAsset(for asset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .current
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
            DispatchQueue.main.async {
                self?.selectedAVAsset = avAsset
                completion(avAsset)
            }
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.fetchVideoAssets()
        }
    }
}
