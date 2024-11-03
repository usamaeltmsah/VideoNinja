//
//  VideoEditingViewModel.swift
//  VideoNinja
//
//  Created by Usama Fouad on 03/11/2024.
//

import AVFoundation
import CoreImage

class VideoEditingViewModel {
    var videoAsset: AVAsset?
    private var ciContext: CIContext?
    var currentFilter: CIFilter?
    
    init(videoAsset: AVAsset) {
        self.videoAsset = videoAsset
        self.ciContext = CIContext()
    }
    
    func applyFilter(to composition: AVMutableComposition, completion: @escaping (AVMutableVideoComposition?) -> Void) {
        guard let currentFilter = currentFilter else {
            completion(nil) // No filter to apply
            return
        }
        
        let videoComposition = AVMutableVideoComposition(asset: composition) { request in
            var outputImage = request.sourceImage.clampedToExtent()
            currentFilter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = currentFilter.outputImage!.cropped(to: request.sourceImage.extent)
            request.finish(with: outputImage, context: nil)
        }
        completion(videoComposition)
    }
    
    func getTrimTimeRange(startX: CGFloat, endX: CGFloat, totalWidth: CGFloat) -> CMTimeRange? {
        let startTime = (videoAsset?.duration.seconds ?? 0) * Double(startX / totalWidth)
        let endTime = (videoAsset?.duration.seconds ?? 0) * Double(endX / totalWidth)
        
        guard endTime > startTime else { return nil }
        
        return CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: 600),
                           duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600))
    }
}
