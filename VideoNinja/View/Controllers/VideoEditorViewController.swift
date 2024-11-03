//
//  VideoEditorViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit
import AVFoundation
import CoreImage
import Photos

class VideoEditorViewController: UIViewController {
    // Views for trimming controls
    @IBOutlet weak var mainVideoContainerView: UIView!
    @IBOutlet weak var trimView: UIView!
    @IBOutlet weak var startHandleContainer: UIView!
    @IBOutlet weak var endHandleContainer: UIView!
    @IBOutlet weak var selectedRangeViewContainer: UIView!
    
    // Filter selection buttons
    @IBOutlet weak var grayscaleButton: UIButton!
    @IBOutlet weak var sepiaButton: UIButton!
    // Reset filters button
    @IBOutlet weak var resetButton: UIButton!
    
    // Preview controls
    @IBOutlet weak var previewContainer: UIView!
    @IBOutlet weak var videoPlayPauseButton: UIButton!
    @IBOutlet weak var videoPreviewPlayPauseButton: UIButton!
    private var progressView: UIProgressView!
    
    private var videoModel: VideoEditingViewModel?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var previewPlayer: AVPlayer?
    private var previewPlayerLayer: AVPlayerLayer?
    
    var startTime: Double = .zero // Define trimming start time
    var endTime: Double? // Define trimming end time, optional if you want till end
    
    private var ciContext: CIContext?
    private var currentFilter: CIFilter?
    
    private var isMainVideoPlaying = false {
        didSet {
            if isMainVideoPlaying {
                videoPlayPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            } else {
                videoPlayPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    private var isPreviewPlaying = false {
        didSet {
            if isPreviewPlaying {
                videoPreviewPlayPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            } else {
                videoPreviewPlayPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    var videoAsset: AVAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ciContext = CIContext()
        
        requestPhotoLibraryAccess()
        configProgressView()
        setupVideoModel()
        setupVideoPlayer()
        setupTrimControls()
        setupPreviewControls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the video when the view disappears
        player?.pause()
        previewPlayer?.pause()
        isMainVideoPlaying = false
        isPreviewPlaying = false
    }
    
    private func configProgressView() {
        // Initialize and set up the progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Add constraints for the progress view
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
        
        // Hide the progress view initially
        progressView.isHidden = true
    }
    
    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Access granted")
                // You can proceed with saving videos
            case .denied:
                print("Access denied")
                // Handle the case where access is denied
            case .restricted:
                print("Access restricted")
                // Handle the case where access is restricted
            case .notDetermined:
                print("Access not determined")
                // This case shouldn't occur if you've already requested authorization
                break
            default:
                break
            }
        }
    }
    
    
    private func setupVideoModel() {
        guard let videoAsset else { return }
        videoModel = VideoEditingViewModel(videoAsset: videoAsset)
    }
    
    private func setupVideoPlayer() {
        guard let videoAsset = videoModel?.videoAsset else { return }
        let playerItem = AVPlayerItem(asset: videoAsset)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = mainVideoContainerView.frame
        if let playerLayer {
            mainVideoContainerView.layer.addSublayer(playerLayer)
        }
        
        player?.play()
        isMainVideoPlaying = true
    }
    
    private func setupTrimControls() {
        // Add a darker overlay for selected range
        let selectedRangeView = UIView()
        selectedRangeView.frame = CGRect(x: 0, y: 0, width: 0, height: 40) // Start with zero width
        selectedRangeView.backgroundColor = UIColor.systemBrown // Darker color for the selected range
        selectedRangeViewContainer.addSubview(selectedRangeView)
        
        // Add gestures to handles
        let startPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        let endPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        
        startHandleContainer.isUserInteractionEnabled = true
        endHandleContainer.isUserInteractionEnabled = true
        startHandleContainer.addGestureRecognizer(startPanGesture)
        endHandleContainer.addGestureRecognizer(endPanGesture)
    }
    
    private func setupPreviewControls() {
        // Preview Container
        previewContainer.backgroundColor = UIColor.black
        
        // Preview Player Layer
        previewPlayerLayer = AVPlayerLayer(player: previewPlayer)
        previewPlayerLayer?.frame = previewContainer.bounds
        if let previewPlayerLayer {
            previewContainer.layer.addSublayer(previewPlayerLayer)
        }
    }
    
    private func previewFilteredVideo() {
        guard let playerItem = player?.currentItem else { return }
        let asset = playerItem.asset
        
        // Create a composition for the video
        let composition = AVMutableComposition()
        
        // Calculate start and end times based on handle positions
        let totalWidth = trimView.bounds.width
        startTime = (videoAsset?.duration.seconds ?? 0) * Double(startHandleContainer.frame.origin.x / totalWidth)
        endTime = (videoAsset?.duration.seconds ?? 0) * Double(endHandleContainer.frame.origin.x / totalWidth)
        
        // Ensure the end time is greater than the start time
        guard endTime ?? 0 > startTime else { return }
        
        // Create time range for the selected portion
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 600),
                                    duration: CMTime(seconds: (endTime ?? 0) - startTime, preferredTimescale: 600))
        
        // Add video track
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        // Use the existing video track
        let assetVideoTrack = asset.tracks(withMediaType: .video).first
        do {
            // Insert the selected range of video into the composition
            try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: .zero)
        } catch {
            print("Error inserting video track: \(error)")
            return
        }
        
        // Add audio track if exists
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            do {
                // Insert the audio track corresponding to the selected video range
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            } catch {
                print("Error inserting audio track: \(error)")
                return
            }
        }
        
        // Apply the filter to the video
        let videoComposition = AVMutableVideoComposition(asset: composition) { request in
            var outputImage = request.sourceImage.clampedToExtent()
            if let filter = self.currentFilter {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage!.cropped(to: request.sourceImage.extent)
            }
            request.finish(with: outputImage, context: nil)
        }
        
        // Create a new player item with the video composition
        let previewPlayerItem = AVPlayerItem(asset: composition)
        previewPlayerItem.videoComposition = videoComposition
        
        // Assign the preview player item
        previewPlayer = AVPlayer(playerItem: previewPlayerItem)
        previewPlayer?.volume = 0.0 // Make the preview is muted
        previewPlayerLayer?.player = previewPlayer
        
        self.previewPlayer?.play() // Play the preview automatically
        self.isPreviewPlaying = true
    }
    
    private func saveFilteredAndTrimmedVideo() {
        // Check if video asset exists
        guard let videoAsset = videoModel?.videoAsset else { return }
        
        // Create a composition for the video
        let composition = AVMutableComposition()
        
        // Calculate start and end times based on handle positions
        let totalWidth = trimView.bounds.width
        startTime = (videoAsset.duration.seconds) * Double(startHandleContainer.frame.origin.x / totalWidth)
        endTime = (videoAsset.duration.seconds) * Double(endHandleContainer.frame.origin.x / totalWidth)
        
        // Ensure the end time is greater than the start time
        guard endTime ?? 0 > startTime else { return }
        
        // Create time range for the selected portion
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 600), duration: CMTime(seconds: (endTime ?? 0) - startTime, preferredTimescale: 600))
        
        // Add video track
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        // Use the existing video track
        let assetVideoTrack = videoAsset.tracks(withMediaType: .video).first
        do {
            // Insert the selected range of video into the composition
            try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack!, at: .zero)
        } catch {
            print("Error inserting video track: \(error)")
            return
        }
        
        // Add audio track if exists
        if let audioTrack = videoAsset.tracks(withMediaType: .audio).first {
            guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            do {
                // Insert the audio track corresponding to the selected video range
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            } catch {
                print("Error inserting audio track: \(error)")
                return
            }
        }
        
        // Apply the filter to the video
        let videoComposition = AVMutableVideoComposition(asset: composition) { request in
            var outputImage = request.sourceImage.clampedToExtent()
            if let filter = self.currentFilter {
                filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = filter.outputImage!.cropped(to: request.sourceImage.extent)
            }
            request.finish(with: outputImage, context: nil)
        }
        
        // Create an export session
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("videoNinja_trimmed_filtered_video.mov")
        
        // Remove any existing file at the output URL
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        exportSession?.videoComposition = videoComposition
        
        // Show the progress view and start the export
        progressView.isHidden = false
        progressView.progress = 0.0
        
        // Present saving alert
        let alertController = UIAlertController(title: "Saving Video", message: "Your video is being saved. Please wait...", preferredStyle: .alert)
        present(alertController, animated: true, completion: nil)
        
        // Observe export progress
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                // Dismiss the saving alert once export is completed or failed
                alertController.dismiss(animated: true, completion: nil)
                
                switch exportSession?.status {
                case .completed:
                    print("Export successful")
                    self.saveToPhotos(url: outputURL)
                    self.progressView.isHidden = true
                case .failed:
                    print("Export failed: \(exportSession?.error?.localizedDescription ?? "unknown error")")
                    self.progressView.isHidden = true
                case .cancelled:
                    print("Export cancelled")
                    self.progressView.isHidden = true
                default:
                    break
                }
            }
        }
        
        // Update progress periodically
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let progress = exportSession?.progress {
                self.progressView.progress = Float(progress)
                if exportSession?.status == .completed || exportSession?.status == .failed || exportSession?.status == .cancelled {
                    timer.invalidate() // Stop updating progress
                }
            }
        }
    }
    
    // Helper function to save video to Photos
    private func saveToPhotos(url: URL) {
        // Check if the video can be saved to the Photos library
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            if creationRequest != nil {
                print("Video saved successfully.")
            }
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.presentSavedSuccessfullyAlert()
                } else {
                    print("Error saving video: \(error?.localizedDescription ?? "unknown error")")
                    self.presentErrorAlert(message: error?.localizedDescription ?? "Could not save video.")
                }
            }
        }
    }
    
    private func presentSavedSuccessfullyAlert() {
        let alertController = UIAlertController(title: "Success", message: "Your video has been saved successfully!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func presentErrorAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let handleContainer = gesture.view else { return }
        
        let translation = gesture.translation(in: trimView)
        
        if handleContainer == startHandleContainer {
            // Update start handle position
            let newX = max(0, min(startHandleContainer.frame.origin.x + translation.x, endHandleContainer.frame.origin.x - 20))
            startHandleContainer.frame.origin.x = newX
            
            // Update player current time to start time when start handle is moved
            let startTime = (videoAsset?.duration.seconds ?? 0) * Double(startHandleContainer.frame.origin.x / trimView.bounds.width)
            player?.pause() // Pause before seeking
            isMainVideoPlaying = false
            player?.seek(to: CMTime(seconds: startTime, preferredTimescale: 600)) { [weak self] _ in
                self?.player?.play() // Resume playing after seeking
                self?.isMainVideoPlaying = true
            }
        } else if handleContainer == endHandleContainer {
            // Update end handle position
            let newX = min(trimView.bounds.width - 20, max(endHandleContainer.frame.origin.x + translation.x, startHandleContainer.frame.origin.x + 20))
            endHandleContainer.frame.origin.x = newX
        }
        
        gesture.setTranslation(.zero, in: trimView)
        
        // Update the selected range view
        let selectedRangeView = selectedRangeViewContainer.subviews.first(where: { $0.backgroundColor == UIColor.systemBrown })
        selectedRangeView?.frame = CGRect(x: startHandleContainer.frame.origin.x, y: 0, width: endHandleContainer.frame.origin.x - startHandleContainer.frame.origin.x - 20, height: 40)
    }
    
    @IBAction func playPauseMainVideo(_ sender: Any) {
        if isMainVideoPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isMainVideoPlaying.toggle()
    }
    @IBAction func togglePreviewPlayback(_ sender: Any) {
    }
    @IBAction func applyGrayscaleFilterAction(_ sender: Any) {
    }
    @IBAction func applySepiaFilterAction(_ sender: Any) {
    }
    @IBAction func resetFiltersAction(_ sender: Any) {
    }
    @IBAction func saveAction(_ sender: Any) {
    }
