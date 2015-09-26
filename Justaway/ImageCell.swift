//
//  ImageCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/12/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Photos

class ImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var asset: PHAsset?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureView()
    }
    
    func configureView() {
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "preview:"))
    }
    
    func preview(sender: UILongPressGestureRecognizer) {
        if (sender.state != .Began) {
            return
        }
        if let asset = asset {
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            options.synchronous = false
            options.networkAccessAllowed = true
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options, resultHandler: {
                (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                if let imageData = imageData {
                    if let window = UIApplication.sharedApplication().keyWindow {
                        let imageView = UIImageView(frame: window.frame)
                        imageView.contentMode = .ScaleAspectFit
                        imageView.image = UIImage(data: imageData)
                        imageView.userInteractionEnabled = true
                        imageView.addGestureRecognizer(UITapGestureRecognizer(target: imageView, action: "removeFromSuperview"))
                        window.addSubview(imageView)
                    }
                }
            })
        }
    }
}
