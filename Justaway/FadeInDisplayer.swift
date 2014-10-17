import Foundation
import UIKit

class FadeInDisplayer: ImageLoaderDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: ImageLoaderLoadedFrom) {
        
        if loadedFrom == ImageLoaderLoadedFrom.Network {
            imageView.alpha = 0
            imageView.image = image
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { imageView.alpha = 1 }, completion: nil)
        } else {
            imageView.image = image
        }
    }
}
