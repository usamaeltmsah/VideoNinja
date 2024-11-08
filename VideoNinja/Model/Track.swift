//
//  Track.swift
//  VideoNinja
//
//  Created by Usama Fouad on 04/11/2024.
//

import AVFoundation

class VideoEditorModel {
    private var videoAsset: AVAsset
    
    init(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
    }
    
    func splitVideo(at times: [CMTime]) -> [AVAsset] {
        var segments = [AVAsset]()
        var lastTime = CMTime.zero

        for time in times {
            let range = CMTimeRange(start: lastTime, duration: time - lastTime)
            if let segment = extractSegment(timeRange: range) {
                segments.append(segment)
            }
            lastTime = time
        }
        
        let lastRange = CMTimeRange(start: lastTime, duration: videoAsset.duration - lastTime)
        if let lastSegment = extractSegment(timeRange: lastRange) {
            segments.append(lastSegment)
        }
        
        return segments
    }
    
    func mergeTracks(segments: [AVAsset]) -> AVAsset? {
        let composition = AVMutableComposition()
        var currentTime = CMTime.zero
        
        for segment in segments {
            guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
                  let assetTrack = segment.tracks(withMediaType: .video).first else { continue }
            do {
                try track.insertTimeRange(CMTimeRange(start: .zero, duration: segment.duration), of: assetTrack, at: currentTime)
                currentTime = CMTimeAdd(currentTime, segment.duration)
            } catch {
                print("Error merging tracks: \(error)")
                return nil
            }
        }
        return composition
    }
    
    private func extractSegment(timeRange: CMTimeRange) -> AVAsset? {
        let composition = AVMutableComposition()
        do {
            try composition.insertTimeRange(timeRange, of: videoAsset, at: .zero)
        } catch {
            print("Error extracting segment: \(error)")
            return nil
        }
        return composition
    }
}
