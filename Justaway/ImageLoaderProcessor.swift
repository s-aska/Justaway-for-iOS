import Foundation
import UIKit

public protocol ImageLoaderProcessor {
    
    func transform(data: NSData, imageView: UIImageView) -> UIImage
    
    func cacheKey(imageView: UIImageView) -> String
}

class DefaultProcessor {
    
    struct Static {
        static var instance: ImageLoaderProcessor = SimpleProcessor()
    }
    
    class var sharedInstance: ImageLoaderProcessor { return Static.instance }
}

class SimpleProcessor: ImageLoaderProcessor {
    
    func transform(data: NSData, imageView: UIImageView) -> UIImage {
        return UIImage(data: data)
    }
    
    func cacheKey(imageView: UIImageView) -> String {
        return ""
    }
}
