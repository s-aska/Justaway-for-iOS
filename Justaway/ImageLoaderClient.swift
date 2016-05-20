import UIKit
import Pinwheel

class ImageLoaderClient {

    struct Static {
        static let defaultOptions = DisplayOptions.Builder()
            .requestBuilder(OAuthRequestBuilder())
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let thumbnailOptions = DisplayOptions.Builder()
            .addFilter(RoundedFilter(0, width: 80, height: 80), hook: .BeforeMemory)
            .requestBuilder(OAuthRequestBuilder())
            .displayer(FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let sideMenuUserIconOptions = DisplayOptions.Builder()
            .addFilter(RoundedFilter(30, width: 60, height: 60), hook: .BeforeMemory)
            .displayer(FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let userIconOptions = DisplayOptions.Builder()
            .addFilter(RoundedFilter(6, width: 42, height: 42), hook: .BeforeMemory)
            .displayer(FadeInDisplayer())
            .build()

        static let actionedUserIconOptions = DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, width: 20, height: 20), hook: .BeforeMemory)
            .displayer(FadeInDisplayer())
            .build()

        static let titleIconOptions = DisplayOptions.Builder()
            .addFilter(RoundedFilter(3, width: 30, height: 30), hook: .BeforeMemory)
            .displayer(FadeInDisplayer())
            .build()
    }

    class CallbackDisplayer: Displayer {

        let callback: (() -> Void)

        init(callback: (() -> Void)) {
            self.callback = callback
        }

        func display(image: UIImage, imageView: UIImageView, loadedFrom: LoadedFrom) {
            callback()
            imageView.image = image
        }
    }

    class DebugListener: ImageLoadingListener {
        func onLoadingCancelled(url: NSURL, imageView: UIImageView) {
            NSLog("onLoadingCancelled: url:\(url.absoluteString)")
        }
        func onLoadingComplete(url: NSURL, imageView: UIImageView, image: UIImage, loadedFrom: LoadedFrom) {
            NSLog("onLoadingComplete: url:\(url.absoluteString)")
        }
        func onLoadingFailed(url: NSURL, imageView: UIImageView, reason: FailureReason) {
            NSLog("onLoadingFailed: url:\(url.absoluteString)")
        }
        func onLoadingStarted(url: NSURL, imageView: UIImageView) {
            NSLog("onLoadingStarted: url:\(url.absoluteString)")
        }
    }

    class DebugProgressListener: ImageLoadingProgressListener {
        func onProgressUpdate(url: NSURL, imageView: UIImageView, current: Int64, total: Int64) {
            NSLog("onProgressUpdate: url:\(url.absoluteString) \(current)/\(total)")
        }
    }

    class func displayImage(url: NSURL, imageView: UIImageView) {
        #if DEBUG
            ImageLoader.displayImage(url, imageView: imageView, options: Static.defaultOptions)
//            ImageLoader.displayImage(url, imageView: imageView, options: Static.defaultOptions,
//                                     loadingListener: DebugListener(), loadingProgressListener: DebugProgressListener())
        #else
            ImageLoader.displayImage(url, imageView: imageView, options: Static.defaultOptions)
        #endif
    }

    class func displayImage(url: NSURL, imageView: UIImageView, callback: (() -> Void)) {
        let options = DisplayOptions.Builder()
            .displayer(CallbackDisplayer(callback: callback))
            .build()
        ImageLoader.displayImage(url, imageView: imageView, options: options)
    }

    class func displayThumbnailImage(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.thumbnailOptions)
    }

    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.userIconOptions)
    }

    class func displayTitleIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.titleIconOptions)
    }

    class func displayActionedUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.actionedUserIconOptions)
    }

    class func displaySideMenuUserIcon(url: NSURL, imageView: UIImageView) {
        ImageLoader.displayImage(url, imageView: imageView, options: Static.sideMenuUserIconOptions)
    }
}
