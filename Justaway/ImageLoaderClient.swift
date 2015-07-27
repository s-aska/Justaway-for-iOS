import UIKit
import Pinwheel

class ImageLoaderClient {
    
    struct Static {
        static let defaultOptions = Pinwheel.DisplayOptions.Builder()
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()
        
        static let thumbnailOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(0, w: 80, h: 80), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()
        
        static let userIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(6, w: 42, h: 42), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
        
        static let actionedUserIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, w: 20, h: 20), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
        
        static let titleIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, w: 20, h: 20), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }
    
    class func displayThumbnailImage(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.thumbnailOptions)
    }
    
    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }
    
    class func displayTitleIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.titleIconOptions)
    }
    
    class func displayActionedUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.actionedUserIconOptions)
    }
}
