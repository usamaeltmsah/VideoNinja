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
