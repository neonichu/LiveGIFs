//
//  GIFication.swift
//  LiveGIFs
//
//  Created by Boris Bügling on 13/10/15.
//  Copyright © 2015 Boris Bügling. All rights reserved.
//

import MobileCoreServices
import Photos

public struct BBUAsset {
    let asset: PHAsset
    let manager = PHImageManager.defaultManager()

    public var isLivePhoto: Bool { return resources.count >= 2 }
    public var photo: PHAssetResource? { return resource(.Photo) }
    public var video: PHAssetResource? { return resource(.PairedVideo) }

    var resources: [PHAssetResource] { return PHAssetResource.assetResourcesForAsset(asset) }

    func resource(type: PHAssetResourceType) -> PHAssetResource? {
        for resource in resources {
            if resource.type == type {
                return resource
            }
        }

        return nil
    }

    public func requestThumbnail(size: CGSize, completionHandler: (UIImage?, [NSObject : AnyObject]?) -> ()) {
        manager.requestImageForAsset(asset, targetSize: size, contentMode: .AspectFill, options: nil, resultHandler: completionHandler)
    }

    public func exportLivePhotoAsGIF(completionHandler: (fileURL: NSURL) -> ()) {
        // PHImageManager.defaultManager().requestAVAssetForVideo(asset, options: nil) {} doesn't work :(

        if let video = video {
            let fileName = String(format: "%@_file.mov", NSProcessInfo.processInfo().globallyUniqueString)
            let fileURL = NSURL(fileURLWithPath: (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName))
            defer { let _ = try? NSFileManager.defaultManager().removeItemAtURL(fileURL) }

            PHAssetResourceManager.defaultManager().writeDataForAssetResource(video, toFile: fileURL, options: nil) { (error) in
                if let error = error {
                    NSLog("Could not write file: \(error)")
                } else {
                    let avAsset = AVURLAsset(URL: fileURL)
                    let duration = Int64(CMTimeGetSeconds(avAsset.duration) + 0.5)

                    let track = avAsset.tracksWithMediaType(AVMediaTypeVideo).first!
                    let frameRate = track.nominalFrameRate

                    let imageGenerator = AVAssetImageGenerator(asset: avAsset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    imageGenerator.maximumSize = CGSize(width: 720, height: 540)

                    let times = self.times(Int32(frameRate), duration)
                    //times = times + times.reverse()

                    let fileProperties = [ String(kCGImagePropertyGIFLoopCount): 0 ]
                    let frameProperties = [ String(kCGImagePropertyGIFDictionary): [ String(kCGImagePropertyGIFDelayTime): Float(1.0 / frameRate) ] ]

                    let documentsDirectoryURL = try? NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
                    let fileURL = documentsDirectoryURL!.URLByAppendingPathComponent("animated.gif")

                    if let destination = CGImageDestinationCreateWithURL(fileURL, kUTTypeGIF, times.count, nil) {
                        CGImageDestinationSetProperties(destination, fileProperties)

                        var currentImage = 0
                        imageGenerator.generateCGImagesAsynchronouslyForTimes(times) { (requestedTime, imageRef, actualTime, result, error) in
                            if let imageRef = imageRef {
                                CGImageDestinationAddImage(destination, imageRef, frameProperties)
                            }

                            if currentImage == times.count - 1 {
                                if (!CGImageDestinationFinalize(destination)) {
                                    NSLog("failed to finalize image destination")
                                }

                                completionHandler(fileURL: fileURL)
                            }

                            currentImage++
                        }
                    }
                }
            }
        }
    }

    func times(times: Int32, _ duration: Int64) -> [NSValue] {
        var cmtimes = [NSValue]()

        for second in 0..<duration {
            for time in 0..<times {
                let cmtime = CMTimeMake(Int64(time) + second * Int64(times), times)
                cmtimes.append(NSValue(CMTime: cmtime))
            }
        }

        return cmtimes
    }
}
