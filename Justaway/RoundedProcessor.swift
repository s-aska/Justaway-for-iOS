import Foundation
import UIKit
import Toucan
import Iguazu

class RoundedProcessor: IguazuFilter {
    
    let radius: CGFloat
    let size: CGSize
    
    init(_ radius: CGFloat, size: CGSize) {
        self.radius = radius
        self.size = size
    }
    
    func filter(image: UIImage) -> UIImage {
        if radius > 0 {
            return Toucan(image: image).resizeByClipping(size).maskWithRoundedRect(cornerRadius: radius).image
        } else {
            return Toucan(image: image).resizeByClipping(size).image
        }
    }
    
    func cacheKey() -> String {
        return String(format: "?size=%@x%@&radius=%@", size.width, size.height, radius)
    }
}
