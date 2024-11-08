//
//  TimelineViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 04/11/2024.
//

import UIKit
import AVFoundation
import AVKit
import Combine

class TimelineViewController: UIViewController, UIScrollViewDelegate {
    private let viewModel: TimelineViewModel
    private var cancellables = Set<AnyCancellable>()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var thumbnailImages: [UIImage] = []
    private var splitPoints: [CMTime] = []
    private var splitTracks: [UIView] = []
    private var isDraggingIndicator = false
    

    private let videoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let splitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Split", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.5) // Semi-transparent background for visibility
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var currentZoomScale: CGFloat = 1.0
    private var dragIndicator: UIView!

    init(videoAsset: AVAsset) {
        self.viewModel = TimelineViewModel(videoAsset: videoAsset)
        super.init(nibName: nil, bundle: nil)
        self.setupPlayer(with: videoAsset)
        self.loadThumbnailImages(for: videoAsset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        bindViewModel()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == progressScrollView else { return }
        
        let offsetX = scrollView.contentOffset.x
        let progress = Double(offsetX / scrollView.contentSize.width)
        let time = CMTime(seconds: progress * CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero), preferredTimescale: 600)
        
        // Ensure dragIndicator does not move outside the scrollView bounds
        let indicatorPosition = offsetX
        let maxIndicatorPosition = progressScrollView.contentSize.width - dragIndicator.frame.width
        dragIndicator.frame.origin.x = min(max(0, indicatorPosition), maxIndicatorPosition)
        
        player?.seek(to: time)
    }
    
    private func setupPlayer(with asset: AVAsset) {
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        if let playerLayer = playerLayer {
            videoContainerView.layer.addSublayer(playerLayer)
        }
        // Bring the button to the front
        videoContainerView.bringSubviewToFront(playPauseButton)
        videoContainerView.clipsToBounds = false
        playPauseButton.layer.zPosition = 1
        
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.updateProgress(time: time)
        }
    }
    
    private func loadThumbnailImages(for asset: AVAsset) {
        let duration = CMTimeGetSeconds(asset.duration)
        let thumbnailCount = 20
        let step = duration / Double(thumbnailCount)
        
        let assetGenerator = AVAssetImageGenerator(asset: asset)
        assetGenerator.appliesPreferredTrackTransform = true
        assetGenerator.maximumSize = CGSize(width: 80, height: 45)
        
        for i in 0..<thumbnailCount {
            let time = CMTime(seconds: Double(i) * step, preferredTimescale: 600)
            assetGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] requestedTime, image, _, _, _ in
                if let image = image {
                    let thumbnail = UIImage(cgImage: image)
                    self?.thumbnailImages.append(thumbnail)
                    if self?.thumbnailImages.count == thumbnailCount {
                        DispatchQueue.main.async {
                            self?.updateProgressScrollView()
                        }
                    }
                }
            }
        }
    }
    
    private func updateProgressScrollView() {
        let imageWidth: CGFloat = 80 * currentZoomScale
        let spacing: CGFloat = 10
        
        // Remove existing image subviews to refresh content
        progressScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        for (index, thumbnail) in thumbnailImages.enumerated() {
            let imageView = UIImageView(image: thumbnail)
            imageView.frame = CGRect(x: CGFloat(index) * (imageWidth + spacing), y: 0, width: imageWidth, height: 45)
            progressScrollView.addSubview(imageView)
        }
        
        // Set the content size of the scroll view
        progressScrollView.contentSize = CGSize(width: CGFloat(thumbnailImages.count) * (imageWidth + spacing), height: 45)
        
        // Add the dragIndicator if not already added to the scroll view
        if dragIndicator.superview == nil {
            view.addSubview(dragIndicator)
        }

        // Bring the dragIndicator to the front
        progressScrollView.bringSubviewToFront(dragIndicator)
    }

    
    private func setupUI() {
        view.addSubview(videoContainerView)
        view.addSubview(progressScrollView)
        view.addSubview(splitButton)
        videoContainerView.addSubview(playPauseButton)
        
        dragIndicator = UIView()
        dragIndicator.backgroundColor = .blue
        dragIndicator.layer.zPosition = 1
        view.addSubview(dragIndicator)
        
        progressScrollView.delegate = self
        
        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            videoContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoContainerView.heightAnchor.constraint(equalToConstant: 300),
            
            progressScrollView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 10),
            progressScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressScrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            progressScrollView.heightAnchor.constraint(equalToConstant: 45),
            
            splitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            splitButton.topAnchor.constraint(equalTo: progressScrollView.bottomAnchor, constant: 20),
            splitButton.widthAnchor.constraint(equalToConstant: 100),
            splitButton.heightAnchor.constraint(equalToConstant: 50),
            
            playPauseButton.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor),
//            playPauseButton.topAnchor.constraint(equalTo: splitButton.bottomAnchor, constant: 20),
            playPauseButton.widthAnchor.constraint(equalToConstant: 50),
            playPauseButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.dragIndicator.frame = CGRect(x: 20, y: self.progressScrollView.frame.origin.y - 15, width: 5, height: 75)
            self.progressScrollView.clipsToBounds = false // Allows views to extend outside its bounds
        }
        
        splitButton.addTarget(self, action: #selector(addSplitPoint), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        progressScrollView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        dragIndicator.addGestureRecognizer(panGesture)
        dragIndicator.isUserInteractionEnabled = true
    }
    
    private func bindViewModel() {
        viewModel.$segments
            .sink { segments in
                print("Segments updated: \(segments)")
            }
            .store(in: &cancellables)
    }
    
    @objc private func addSplitPoint() {
        guard let currentTime = player?.currentTime() else { return }
        
        let splitTrack = createSplitTrack(at: currentTime)
        splitTracks.append(splitTrack)
        progressScrollView.addSubview(splitTrack)
        layoutSplitTracks()
        
        self.viewModel.mergeSegments()
    }

    
    @objc private func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            currentZoomScale = max(0.5, min(sender.scale, 2.0))
            updateProgressScrollView()
        } else if sender.state == .ended {
            sender.scale = 1.0
        }
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard sender.view === dragIndicator else { return }

        if sender.state == .began {
            isDraggingIndicator = true
        } else if sender.state == .ended || sender.state == .cancelled {
            isDraggingIndicator = false
        }

        let translation = sender.translation(in: view)
        let newX = max(0, min(progressScrollView.contentSize.width - dragIndicator.frame.width, sender.view!.center.x + translation.x))
        
        sender.view!.center.x = newX
        sender.setTranslation(.zero, in: view)
        
        let progress = Double(newX / progressScrollView.contentSize.width)
        let time = CMTime(seconds: progress * CMTimeGetSeconds((player?.currentItem?.duration)!), preferredTimescale: 600)
        player?.seek(to: time)
    }
    
    @objc private func togglePlayPause() {
        if player?.rate == 0 {
            player?.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            player?.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    
    private func layoutSplitTracks() {
        for (index, splitTrack) in splitTracks.enumerated() {
            let offset = CGFloat(index) * (80 + 10)
            splitTrack.frame.origin.x = offset
        }
    }
    
    private func createSplitTrack(at time: CMTime) -> UIView {
        let splitTrack = UIView()
        splitTrack.backgroundColor = .red
        splitTrack.frame = CGRect(x: 0, y: 0, width: 80, height: 45)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanOnSplitTrack(_:)))
        splitTrack.addGestureRecognizer(panGesture)

        splitPoints.append(time)
        return splitTrack
    }
    
    @objc private func handlePanOnSplitTrack(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        sender.view?.center.x += translation.x
        sender.setTranslation(.zero, in: view)
    }
    
    private func updateProgress(time: CMTime) {
        guard !isDraggingIndicator else { return }

        let progress = CMTimeGetSeconds(time) / CMTimeGetSeconds((player?.currentItem?.duration)!)
        let position = CGFloat(progress) * progressScrollView.contentSize.width
        dragIndicator.frame.origin.x = position
    }
}
