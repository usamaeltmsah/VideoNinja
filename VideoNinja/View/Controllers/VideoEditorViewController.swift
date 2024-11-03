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
