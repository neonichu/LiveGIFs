//
//  GIFViewController.swift
//  LiveGIFs
//
//  Created by Boris Bügling on 13/10/15.
//  Copyright © 2015 Boris Bügling. All rights reserved.
//

import FLAnimatedImage
import ImgurAnonymousAPIClient
import Keys
import MRProgress
import UIKit

class GIFViewController: UIViewController {
    let fileURL: NSURL
    let imageView = FLAnimatedImageView()

    init(fileURL: NSURL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)

        imageView.animatedImage = FLAnimatedImage(animatedGIFData: NSData(contentsOfURL: fileURL))
        imageView.userInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    dynamic func shareGIF() {
        MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)

        let client = ImgurAnonymousAPIClient(clientID: LivegifsKeys().imgurClientId())
        client.uploadImageFile(fileURL, withFilename:nil) { (url, error) in
             MRProgressOverlayView.dismissOverlayForView(self.view, animated: true)

            if let url = url {
                self.navigationController?.presentViewController(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true, completion: nil)
            }

            if let error = error {
                print("Could not upload to imgur: \(error)")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.frame = view.bounds
        view.addSubview(imageView)

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "shareGIF")
        imageView.addGestureRecognizer(gestureRecognizer)
    }
}
