import Foundation
import UIKit

class ImageLoader {
    
    struct Static {
        static let queue = NSOperationQueue()
    }
    
    class func setup() {
        Static.queue.maxConcurrentOperationCount = 1
    }
    
    class func load(url: NSURL, imageView: UIImageView, success: ((inMemory: Bool) -> Void)) {
        let task = ImageLoaderTask(url, imageView: imageView, success)
        if let operation = task.load() {
            Static.queue.addOperation(operation)
        }
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
    
    let task: NSURLSessionDownloadTask
    
    internal var running = false
    internal var stopped = false
    internal var done = false
    
    init(_ task: NSURLSessionDownloadTask) {
        self.task = task
    }
    
    override internal var cancelled: Bool {
        return stopped
    }
    
    override internal var executing: Bool {
        return running
    }
    
    override internal var finished: Bool {
        return done
    }
    
    override internal var ready: Bool {
        return !running
    }
    
    override func start() {
        super.start()
        stopped = false
        running = true
        done = false
        task.resume()
    }
    
    override func cancel() {
        super.cancel()
        stopped = true
        running = false
        done = true
        task.cancel()
    }
    
    func finish() {
        running = false
        done = true
    }
    
}

class ImageLoaderTask: NSObject, NSURLSessionDownloadDelegate {
    
    let url: NSURL
    let imageView: UIImageView
    var operation: ImageLoaderOperation?
    let success: ((inMemory: Bool) -> Void)
    
    init(_ url: NSURL, imageView: UIImageView, success: ((inMemory: Bool) -> Void)) {
        self.url = url
        self.imageView = imageView
        self.success = success
    }
    
    func load() -> ImageLoaderOperation? {
        if let data = ImageLoaderMemoryCache.get(url.absoluteString!) {
            dispatch_async(dispatch_get_main_queue(), {
                self.imageView.image = UIImage(data: data)
                self.success(inMemory: false)
            })
            return nil
        }
        let config  = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(url.absoluteString! + NSDate(timeIntervalSinceNow: 0).description)
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        operation = ImageLoaderOperation(session.downloadTaskWithURL(url))
        return operation
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        println("didFinishDownloadingToURL.")
        let data = NSData(contentsOfURL: location)
        if data.length > 0 {
            ImageLoaderMemoryCache.set(url.absoluteString!, data: data)
            dispatch_async(dispatch_get_main_queue(), {
                self.imageView.image = UIImage(data: data)
                self.success(inMemory: false)
            })
            operation?.finish()
        } else {
            operation?.cancel()
        }
        
    }
    
}
