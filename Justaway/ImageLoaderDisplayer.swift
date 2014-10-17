import Foundation
import UIKit

public protocol ImageLoaderDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: ImageLoaderLoadedFrom)
}

class DefaultDisplayer {
    
    struct Static {
        static var instance: ImageLoaderDisplayer = SimpleDisplayer()
    }
    
    class var sharedInstance: ImageLoaderDisplayer { return Static.instance }
}

class SimpleDisplayer: ImageLoaderDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: ImageLoaderLoadedFrom) {
        imageView.image = image
    }
}
