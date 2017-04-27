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
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ImageCell.preview(_:))))
    }

    func preview(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        if let asset = asset {
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: {
                (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) -> Void in
                if let imageData = imageData {
                    if let window = UIApplication.shared.keyWindow {
                        let imageView = UIImageView(frame: window.frame)
                        imageView.contentMode = .scaleAspectFit
                        imageView.image = UIImage(data: imageData)
                        imageView.isUserInteractionEnabled = true
                        imageView.addGestureRecognizer(UITapGestureRecognizer(target: imageView, action: #selector(UIView.removeFromSuperview)))
                        window.addSubview(imageView)
                    }
                }
            })
        }
    }
}
