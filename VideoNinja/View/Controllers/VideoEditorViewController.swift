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
    
    @IBAction func playPauseMainVideo(_ sender: Any) {
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
