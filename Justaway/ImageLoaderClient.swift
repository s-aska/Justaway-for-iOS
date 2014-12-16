import UIKit
import Pinwheel

class ImageLoaderClient {
    
    struct Static {
        static let defaultOptions = Pinwheel.DisplayOptions.Builder()
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()
        
        static let userIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(6, w: 42, h: 42), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
        
        static let actionedUserIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(2, w: 16, h: 16), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }
    
    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }
    
    class func displayActionedUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.actionedUserIconOptions)
    }
}
