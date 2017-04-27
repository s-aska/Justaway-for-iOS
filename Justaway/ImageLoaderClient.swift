import UIKit
import TwitterAPI
import OAuthSwift
import Kingfisher

class ImageLoaderClient {

    struct Static {
        static let modifier = AnyModifier { request in
            var r = request
            if let url = r.url {
                if url.absoluteString.hasPrefix("https://ton.twitter.com/1.1/ton/data/dm/") {
                    if let client = Twitter.client() as? OAuthClient {
                        let authorization = client.oAuthCredential.authorizationHeader(method: .GET, url: url, parameters: [:])
                        r.setValue(authorization, forHTTPHeaderField: "Authorization")
                    }
                }
            }
            return r
        }
        static let optionInfo: KingfisherOptionsInfo = [.transition(ImageTransition.fade(0.5)), .requestModifier(modifier)]
    }

    class func displayImage(_ url: URL, imageView: UIImageView) {
        imageView.kf.setImage(with: url, placeholder: nil, options: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displayImage(_ url: URL, imageView: UIImageView, callback: @escaping (() -> Void)) {
        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
            callback()
        })
    }

    class func displayThumbnailImage(_ url: URL, imageView: UIImageView) {
        imageView.kf.setImage(with: url, placeholder: nil, options: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displayUserIcon(_ url: URL, imageView: UIImageView) {
        imageView.kf.setImage(with: url, placeholder: nil, options: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }

    class func displaySideMenuUserIcon(_ url: URL, imageView: UIImageView) {
        imageView.kf.setImage(with: url, placeholder: nil, options: Static.optionInfo, progressBlock: nil, completionHandler: nil)
    }
}
