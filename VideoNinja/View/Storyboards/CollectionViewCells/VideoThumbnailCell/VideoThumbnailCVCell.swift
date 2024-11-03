//
//  VideoThumbnailCVCell.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit
import Photos

class VideoThumbnailCVCell: UICollectionViewCell {
    @IBOutlet weak var videoThumbnailImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // Configure the cell with a video asset
    func configure(with asset: PHAsset) {
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: contentView.bounds.width, height: contentView.bounds.height)
        
        // Request an image for the asset
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { [weak self] image, _ in
            self?.videoThumbnailImageView.image = image
        }
    }
}
