//
//  ViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit

enum OperationType {
    case trimming // For video trimming operations
    case montage // For video montage/editing operations
}

class ViewController: UIViewController {
    @IBOutlet weak var videoStackView: UIStackView!
    @IBOutlet weak var videoMontageStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector (self.videoTapped)))
        videoMontageStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.videoMontageTapped)))
    }
    
    private func navigateToVideosListViewController(type: OperationType) {
        // Instantiate VideosListViewController from the Storyboard
        guard let videosListViewController = UIStoryboard(name: "VideosListScreen", bundle: nil).instantiateViewController(identifier: "VideosListViewController") as? VideosListViewController else { return }
        
        // Set the operation type (OperationType) for VideosListViewController
        videosListViewController.operationType = type
        
        // Navigate to VideosListViewController using the NavigationController
        self.navigationController?.pushViewController(videosListViewController, animated: true)
    }


    // MARK:- Handle action of Get started button
    @objc private func videoTapped(_ sender: UITapGestureRecognizer) {
        // Present all videos from photo library
        self.navigateToVideosListViewController(type: .trimming)
    }
    
    @objc func videoMontageTapped(_ sender: UITapGestureRecognizer) {
        self.navigateToVideosListViewController(type: .montage)
    }
}

