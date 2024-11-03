//
//  VideosListViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit
import Photos
import Combine

class VideosListViewController: UIViewController {
    @IBOutlet weak var videoCollectionView: UICollectionView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    private var viewModel = VideoEditorViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureVideoCollectionView()
        self.setupVideoCollectionViewLayout()
        self.bindViewModel()
    }
    
    // Configures the video collection view by registering the cell, setting the delegate and data source, and initially hiding it.
    private func configureVideoCollectionView() {
        videoCollectionView.register(UINib(nibName: "VideoThumbnailCVCell", bundle: nil), forCellWithReuseIdentifier: "VideoThumbnailCVCell")
        videoCollectionView.delegate = self
        videoCollectionView.dataSource = self
        videoCollectionView.isHidden = true
    }
    
    // Sets up the layout for the video collection view, configuring it with a vertical scroll direction, spacing, and item size.
    private func setupVideoCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width / 3 - 2, height: UIScreen.main.bounds.width / 3 - 2)
        videoCollectionView.collectionViewLayout = layout
    }
    
    // Binds the view model properties to the UI components, updating the UI in response to changes.
    private func bindViewModel() {
        // Observe the hasPermission property and update the visibility of placeholder and collection view accordingly
        viewModel.$hasPermission
            .sink { [weak self] hasPermission in
                guard let self else { return }
                self.placeholderLabel.isHidden = hasPermission
                self.videoCollectionView.isHidden = !hasPermission
            }
            .store(in: &cancellables)
        
        // Observe the permissionMessage property and update the placeholder label text when it changes
        viewModel.$permissionMessage
            .sink { [weak self] message in
                guard let self else { return }
                self.placeholderLabel.text = message
            }
            .store(in: &cancellables)
        
        // Observe the videoAssets property and reload the collection view when the assets change
        viewModel.$videoAssets
            .sink { [weak self] videos in
                guard let self else { return }
                self.videoCollectionView.reloadData()
                
                self.placeholderLabel.isHidden = !videos.isEmpty
                self.videoCollectionView.isHidden = videos.isEmpty
                
                if videos.isEmpty {
                    placeholderLabel.text = "No selected videos."
                }
            }
            .store(in: &cancellables)
    }
}
}
