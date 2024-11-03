//
//  VideosListViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit
import Photos

class VideosListViewController: UIViewController {
    @IBOutlet weak var videoCollectionView: UICollectionView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureVideoCollectionView()
        self.setupVideoCollectionViewLayout()
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
    
}
