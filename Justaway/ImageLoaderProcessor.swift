import Foundation
import UIKit

public protocol ImageLoaderProcessor {
    
    func transform(image: UIImage, imageView: UIImageView) -> UIImage
    
    func cacheKey(imageView: UIImageView) -> String
}

class SimpleProcessor: ImageLoaderProcessor {
    
    func transform(image: UIImage, imageView: UIImageView) -> UIImage {
        return image
    }
    
    func cacheKey(imageView: UIImageView) -> String {
        return ""
    }
}
