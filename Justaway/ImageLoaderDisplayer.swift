import Foundation
import UIKit

public protocol ImageLoaderDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: ImageLoaderLoadedFrom)
}

class SimpleDisplayer: ImageLoaderDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: ImageLoaderLoadedFrom) {
        imageView.image = image
    }
}
