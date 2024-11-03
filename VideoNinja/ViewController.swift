//
//  ViewController.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var videoStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector (self.videoTapped)))
    }


    // MARK:- Handle action of Get started button
    @objc private func videoTapped(_ sender: UITapGestureRecognizer) {
        // Present all videos from photo library
        print("Clicked!")
    }
}

