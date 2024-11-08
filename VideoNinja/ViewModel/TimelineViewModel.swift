//
//  TimelineViewModel.swift
//  VideoNinja
//
//  Created by Usama Fouad on 04/11/2024.
//

import Foundation
import AVFoundation

class TimelineViewModel: ObservableObject {
    private let model: VideoEditorModel
    @Published var segments: [AVAsset] = []
    @Published var mergedVideo: AVAsset?
    
    init(videoAsset: AVAsset) {
        self.model = VideoEditorModel(videoAsset: videoAsset)
    }
    
    func splitVideo(at times: [CMTime]) {
        self.segments = model.splitVideo(at: times)
    }
    
    func swapTracks(index1: Int, index2: Int) {
        guard index1 < segments.count, index2 < segments.count else { return }
        segments.swapAt(index1, index2)
    }
    
    func mergeSegments() {
        mergedVideo = model.mergeTracks(segments: segments)
    }
}
