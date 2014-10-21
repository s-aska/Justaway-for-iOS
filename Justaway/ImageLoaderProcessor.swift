import Foundation
import UIKit

public protocol ImageLoaderProcessor {
    
    func transform(data: NSData, imageView: UIImageView) -> UIImage
    
    func cacheKey(imageView: UIImageView) -> String
}

class SimpleProcessor: ImageLoaderProcessor {
    
    func transform(data: NSData, imageView: UIImageView) -> UIImage {
        return UIImage(data: data)!
    }
    
    func cacheKey(imageView: UIImageView) -> String {
        return ""
    }
}
