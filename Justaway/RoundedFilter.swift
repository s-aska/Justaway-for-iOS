import UIKit
import Toucan
import Pinwheel

class RoundedFilter: Filter {

    let radius: CGFloat
    let size: CGSize

    init(_ radius: CGFloat, width: Int, height: Int) {
        self.radius = radius
        self.size = CGSize(width: width, height: height)
    }

    func filter(image: UIImage) -> UIImage {
        if radius > 0 {
            return Toucan(image: image).resizeByClipping(size).maskWithRoundedRect(cornerRadius: radius).image
        } else {
            return Toucan(image: image).resizeByClipping(size).image
        }
    }

    func cacheKey() -> String {
        return String(format: "?size=%@x%@&radius=%@",
                      size.width.description,
                      size.height.description,
                      radius.description)
    }
}
