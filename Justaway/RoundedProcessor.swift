import Foundation
import UIKit
import Toucan

class RoundedProcessor: ImageLoaderProcessor {
    
    let radius: CGFloat
    
    init(_ radius: CGFloat) {
        self.radius = radius
    }
    
    func transform(data: NSData, imageView: UIImageView) -> UIImage {
        if radius > 0 {
            return Toucan(image: UIImage(data: data)!).resizeByClipping(imageView.bounds.size).maskWithRoundedRect(cornerRadius: radius).image
        } else {
            return Toucan(image: UIImage(data: data)!).resizeByClipping(imageView.bounds.size).image
        }
    }
    
    func cacheKey(imageView: UIImageView) -> String {
        let size = imageView.frame.size
        return String(format: "?size=%@x%@&radius=%@", size.width, size.height, radius)
    }
}
