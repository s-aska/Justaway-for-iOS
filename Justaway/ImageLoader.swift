import Foundation
import UIKit

enum ImageLoaderFrom {
    case Memory
    case Disk
    case Network
}

private class ImageLoaderHandler {
    var progress:((Double) -> Void)?
    var success:((NSData, ImageLoaderFrom) -> Void)?
    var failure:((NSError) -> Void)?
    
    init(progress: ((Double) -> Void)?, success: ((NSData, ImageLoaderFrom) -> Void)?, failure: ((NSError) -> Void)?) {
        self.progress = progress
        self.success = success
        self.failure = failure
    }
}

class ImageLoader {
    
    struct Static {
        private static let queue = NSOperationQueue()
        private static var handlers = Dictionary<String,Array<ImageLoaderHandler>>()
        private static let serial = dispatch_queue_create("ImageLoader.Static.instance.serial_queue", DISPATCH_QUEUE_SERIAL)
    }
    
    class func setup() {
        Static.queue.maxConcurrentOperationCount = 1
    }
    
    class func load(url: NSURL, imageView: UIImageView, success: ((data: NSData, from: ImageLoaderFrom) -> Void)) {
        let hash = url.absoluteString!
        
        dispatch_sync(Static.serial) {
            if let handlers = Static.handlers[hash] {
                Static.handlers[hash] = handlers + [ImageLoaderHandler(nil, success, nil)]
            } else {
                Static.handlers[hash] = [ImageLoaderHandler(nil, success, nil)]
                let task = ImageLoaderTask(url, imageView: imageView)
                if let operation = task.load() {
                    Static.queue.addOperation(operation)
                }
            }
        }
    }
    
    class func doSuccess(url: NSURL, data: NSData, from: ImageLoaderFrom) {
        let hash = url.absoluteString!
        NSLog("%@ success", hash)
        if let handlers = Static.handlers[hash] {
            for handler in handlers {
                if let success = handler.success {
                    success(data, from)
                }
            }
        }
        Static.handlers.removeValueForKey(hash)
    }
    
    class func doFailure(url: NSURL, error: NSError) {
        let hash = url.absoluteString!
        NSLog("%@ failure", hash)
        if let handlers = Static.handlers[hash] {
            for handler in handlers {
                if let failure = handler.failure {
                    failure(error)
                }
            }
        }
        Static.handlers.removeValueForKey(hash)
    }
}

class ImageLoaderMemoryCache {
    struct Static {
        static let instance = ImageLoaderMemoryCache()
    }
    var cache = [String:NSData]()
    
    class func get(key: String) -> NSData? {
        return Static.instance.cache[key]
    }
    
    class func set(key: String, data: NSData) {
        Static.instance.cache[key] = data
    }
}

class ImageLoaderOperation: NSOperation {
    
    let url: NSURL
    let task: NSURLSessionDownloadTask
    
    internal var running = false
    internal var stopped = false
    internal var done = false
    
    init(_ url: NSURL, task: NSURLSessionDownloadTask) {
        self.url = url
        self.task = task
    }
    
    override internal var asynchronous: Bool {
        return true
    }
    
    override internal var cancelled: Bool {
        return stopped
    }
    
    override internal var executing: Bool {
        get { return running }
        set {
            if running != newValue {
                willChangeValueForKey("isExecuting")
                running = newValue
                didChangeValueForKey("isExecuting")
            }
        }
    }
    
    override internal var finished: Bool {
        get { return done }
        set {
            if done != newValue {
                willChangeValueForKey("isFinished")
                done = newValue
                didChangeValueForKey("isFinished")
            }
        }
    }
    
    override internal var ready: Bool {
        return !running
    }
    
    override func start() {
        NSLog("%@ start", url.absoluteString!)
        super.start()
        stopped = false
        executing = true
        finished = false
        task.resume()
    }
    
    override func cancel() {
        NSLog("%@ cancel", url.absoluteString!)
        super.cancel()
        stopped = true
        executing = false
        finished = true
        task.cancel()
    }
    
    func finish() {
        NSLog("%@ finish", url.absoluteString!)
        executing = false
        finished = true
    }
    
}

class ImageLoaderTask: NSObject, NSURLSessionDownloadDelegate {
    
    let url: NSURL
    let imageView: UIImageView
    var operation: ImageLoaderOperation?
    
    init(_ url: NSURL, imageView: UIImageView) {
        self.url = url
        self.imageView = imageView
    }
    
    func load() -> ImageLoaderOperation? {
        NSLog("%@ load", url.absoluteString!)
        if let data = ImageLoaderMemoryCache.get(url.absoluteString!) {
            dispatch_async(dispatch_get_main_queue(), {
                ImageLoader.doSuccess(self.url, data: data, from: .Memory)
            })
            return nil
        }
        NSLog("%@ create", url.absoluteString!)
        let config  = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(url.absoluteString! + NSDate(timeIntervalSinceNow: 0).description)
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        operation = ImageLoaderOperation(url, task: session.downloadTaskWithURL(url))
        return operation
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let data = NSData(contentsOfURL: location)
        if data.length > 0 {
            ImageLoaderMemoryCache.set(url.absoluteString!, data: data)
            dispatch_async(dispatch_get_main_queue(), {
                ImageLoader.doSuccess(self.url, data: data, from: .Network)
            })
            operation?.finish()
        } else {
            operation?.cancel()
        }
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let e = error {
            ImageLoader.doFailure(self.url, error: e)
        }
    }
    
}
