import UIKit
import Kingfisher

class ImageLoaderClient {

    struct Static {
        static let optionInfo: KingfisherOptionsInfo = [.Transition(ImageTransition.Fade(0.5))]
    }

    class func displayImage(url: NSURL, imageView: UIImageView) {
        imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displayImage(url: NSURL, imageView: UIImageView, callback: (() -> Void)) {
        imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
            callback()
        })
    }

    class func displayThumbnailImage(url: NSURL, imageView: UIImageView) {
        imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displaySideMenuUserIcon(url: NSURL, imageView: UIImageView) {
        imageView.kf_setImageWithURL(url, placeholderImage: nil, optionsInfo: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }
}
