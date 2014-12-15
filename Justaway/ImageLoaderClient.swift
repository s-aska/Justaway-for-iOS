import UIKit
import Iguazu

class ImageLoaderClient {
    
    struct Static {
        static let defaultOptions = Iguazu.DisplayOptions.Builder()
            .displayer(Iguazu.FadeInDisplayer())
            .build()
        
        static let userIconOptions = Iguazu.DisplayOptions.Builder()
            .addFilter(RoundedProcessor(6, size: CGSize(width: 42, height: 42)),
                hook: .PreMemoryCache)
            .displayer(Iguazu.FadeInDisplayer())
            .build()
        
        static let actionedUserIconOptions = Iguazu.DisplayOptions.Builder()
            .addFilter(RoundedProcessor(2, size: CGSize(width: 16, height: 16)),
                hook: .PreMemoryCache)
            .displayer(Iguazu.FadeInDisplayer())
            .build()
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        Iguazu.displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }
    
    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        Iguazu.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }
    
    class func displayActionedUserIcon(url: NSURL, imageView: UIImageView) {
        Iguazu.displayImage(url, imageView: imageView, options: Static.actionedUserIconOptions)
    }
}
