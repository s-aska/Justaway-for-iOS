import Foundation
import UIKit

class ImageLoaderClient {
    
    struct Static {
        static let userIconOptions = ImageLoaderOptions(displayer: FadeInDisplayer(), processor: RoundedProcessor(6))
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: nil)
    }
    
    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }
}
