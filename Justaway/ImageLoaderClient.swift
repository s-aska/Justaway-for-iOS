import UIKit
import Pinwheel

class ImageLoaderClient {

    struct Static {
        static let defaultOptions = Pinwheel.DisplayOptions.Builder()
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let thumbnailOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(0, width: 80, height: 80), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let sideMenuUserIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(30, width: 60, height: 60), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let userIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(6, width: 42, height: 42), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()

        static let actionedUserIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, width: 20, height: 20), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()

        static let titleIconOptions = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, width: 30, height: 30), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
    }

    class CallbackDisplayer: PinwheelDisplayer {

        let callback: (() -> Void)

        init(callback: (() -> Void)) {
            self.callback = callback
        }

        func display(image: UIImage, imageView: UIImageView, loadedFrom: Pinwheel.LoadedFrom) {
            callback()
            imageView.image = image
        }
    }

    class func displayImage(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }

    class func displayImage(url: NSURL, imageView: UIImageView, callback: (() -> Void)) {
        let options = Pinwheel.DisplayOptions.Builder()
            .displayer(CallbackDisplayer(callback: callback))
            .build()
        Pinwheel.displayImage(url, imageView: imageView, options: options)
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

    class func displaySideMenuUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Static.sideMenuUserIconOptions)
    }
}
