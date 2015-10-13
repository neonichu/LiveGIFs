//
//  ViewController.swift
//  LiveGIFs
//
//  Created by Boris Bügling on 13/10/15.
//  Copyright © 2015 Boris Bügling. All rights reserved.
//

import MRProgress
import Photos
import UIKit

class ViewController: UICollectionViewController {
    static let cellId = NSStringFromClass(ImageCell.self)

    var livePhotos = [BBUAsset]()

    init() {
        let size = UIScreen.mainScreen().bounds.size.width / 3.5
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        super.init(collectionViewLayout: layout)
        title = "LiveGIFs"

        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.registerClass(ImageCell.self, forCellWithReuseIdentifier:ViewController.cellId)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let assetCollectionsResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .SmartAlbumRecentlyAdded, options: nil)

        if let recentlyAddedCollection = assetCollectionsResult.firstObject as? PHAssetCollection {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            let recentlyAddedFetchResult = PHAsset.fetchAssetsInAssetCollection(recentlyAddedCollection, options: fetchOptions)

            for i in 0..<recentlyAddedFetchResult.count {
                if let asset = recentlyAddedFetchResult.objectAtIndex(i) as? PHAsset {
                    let assetWrapper = BBUAsset(asset: asset)
                    if assetWrapper.isLivePhoto {
                        livePhotos.append(assetWrapper)
                    }
                }
            }
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ViewController.cellId, forIndexPath: indexPath)

        if cell.tag != 0 {
            PHImageManager.defaultManager().cancelImageRequest(PHImageRequestID(cell.tag))
        }

        let livePhoto = livePhotos[indexPath.row]
        cell.tag = Int(livePhoto.requestThumbnail(cell.bounds.size) { (result, _) in
            (cell as? ImageCell)?.imageView.image = result
        })

        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let livePhoto = livePhotos[indexPath.row]

        MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
        livePhoto.exportLivePhotoAsGIF() { (fileURL) in
            dispatch_sync(dispatch_get_main_queue()) {
                MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)

                let viewController = GIFViewController(fileURL: fileURL)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return livePhotos.count
    }
}
