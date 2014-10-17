import Foundation
import UIKit

public enum ImageLoaderLoadedFrom {
    case Memory
    case Disk
    case Network
}

class ImageLoaderOptions {
    let displayer: ImageLoaderDisplayer
    let processor: ImageLoaderProcessor
    
    init(displayer: ImageLoaderDisplayer, processor: ImageLoaderProcessor) {
        self.displayer = displayer
        self.processor = processor
    }
}

class ImageLoaderRequest {
    let url: NSURL
    let imageView: UIImageView
    let options: ImageLoaderOptions?
    let cacheKey: String
    
    init(url: NSURL, imageView: UIImageView, options: ImageLoaderOptions?) {
        self.url = url
        self.imageView = imageView
        self.options = options
        if let o = options {
            self.cacheKey = url.absoluteString! + o.processor.cacheKey(imageView)
        } else {
            self.cacheKey = url.absoluteString!
        }
    }
    
    func display(image: UIImage, loadedFrom: ImageLoaderLoadedFrom) {
        let displayer = self.options?.displayer ?? DefaultDisplayer.sharedInstance
        
        dispatch_async(dispatch_get_main_queue(), {
            displayer.display(image, imageView: self.imageView, loadedFrom: loadedFrom)
        })
    }
}

class ImageLoader {
    
    struct Static {
        private static let queue = NSOperationQueue()
        private static var requests = Dictionary<String,Array<ImageLoaderRequest>>()
        private static let serial = dispatch_queue_create("ImageLoader.Static.instance.serial_queue", DISPATCH_QUEUE_SERIAL)
    }
    
    class func setup() {
        Static.queue.maxConcurrentOperationCount = 1
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView, options: ImageLoaderOptions?) {
        
        imageView.image = nil
        
        let request = ImageLoaderRequest(url: url, imageView: imageView, options: options)
        
        if let data = ImageLoaderMemoryCache.get(request.cacheKey) {
            ImageLoader.doSuccess(request, data: data, loadedFrom: .Memory)
            return
        }
        
        dispatch_sync(Static.serial) {
            if let requests = Static.requests[request.cacheKey] {
                Static.requests[request.cacheKey] = requests + [request]
            } else {
                Static.requests[request.cacheKey] = [request]
                let task = ImageLoaderTask(request)
                if let operation = task.create() {
                    Static.queue.addOperation(operation) // Download from Network
                }
            }
        }
    }
    
    class func doSuccess(request: ImageLoaderRequest, data: NSData, loadedFrom: ImageLoaderLoadedFrom) {
        NSLog("%@ success", request.cacheKey)
        
        let processor = request.options?.processor ?? DefaultProcessor.sharedInstance
        let image = processor.transform(data, imageView: request.imageView)
        
        switch (loadedFrom) {
        case .Network:
            ImageLoaderMemoryCache.set(request.cacheKey, data: UIImagePNGRepresentation(image))
        case .Disk:
            ImageLoaderMemoryCache.set(request.cacheKey, data: UIImagePNGRepresentation(image))
            request.display(UIImage(data: data), loadedFrom: .Disk)
        case .Memory:
            request.display(UIImage(data: data), loadedFrom: .Memory)
        }
        
        if let requests = Static.requests.removeValueForKey(request.cacheKey) {
            for request in requests.filter({ h in h.imageView.image == nil }) {
                request.display(image, loadedFrom: loadedFrom)
            }
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

class ImageLoaderDownloadOperation: AsyncOperation {
    
    let task: NSURLSessionDownloadTask
    
    init(_ task: NSURLSessionDownloadTask) {
        self.task = task
        super.init()
    }
    
    override func start() {
        super.start()
        state = .Executing
        task.resume()
    }
    
    override func cancel() {
        super.cancel()
        state = .Finished
        task.cancel()
    }
    
    func finish() {
        state = .Finished
    }
    
}

class ImageLoaderTask: NSObject, NSURLSessionDownloadDelegate {
    
    let request: ImageLoaderRequest
    var operation: ImageLoaderDownloadOperation?
    
    init(_ request: ImageLoaderRequest) {
        self.request = request
    }
    
    func create() -> ImageLoaderDownloadOperation? {
        NSLog("%@ create", request.cacheKey)
        
        let config  = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(request.cacheKey + String(NSDate().hashValue))
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithURL(request.url)
        operation = ImageLoaderDownloadOperation(task)
        operation?.name = request.cacheKey
        return operation
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        NSLog("%@ success", request.cacheKey)
        
        let data = NSData(contentsOfURL: location)
        if data.length > 0 {
            ImageLoader.doSuccess(request, data: data, loadedFrom: .Network)
            operation?.finish()
        } else {
            operation?.cancel()
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        NSLog("%@ failure", request.cacheKey)
        
        if let e = error {
//            ImageLoader.doFailure(self.url, error: e)
        }
    }
    
}
