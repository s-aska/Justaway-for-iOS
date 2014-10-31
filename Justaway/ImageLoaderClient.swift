import Foundation
import UIKit

class ImageLoaderClient {
    
    struct Static {
        static let defaultOptions = ImageLoaderOptions(displayer: FadeInDisplayer(), processor: RoundedProcessor(0))
        static let userIconOptions = ImageLoaderOptions(displayer: FadeInDisplayer(), processor: RoundedProcessor(6))
        static let actionedUserIconOptions = ImageLoaderOptions(displayer: FadeInDisplayer(), processor: RoundedProcessor(2))
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }
    
    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }
    
    class func displayActionedUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.actionedUserIconOptions)
    }
}
