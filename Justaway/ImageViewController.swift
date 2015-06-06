//
//  ImageViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/19/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    struct Static {
        static let instance = ImageViewController()
    }
    
    // MARK: Properties
    
    override var nibName: String {
        return "ImageViewController"
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var imageURLs = [NSURL]()
    var imageViews = [UIImageView]()
    var initialPage = 0
    var currentPage = 0
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        showImage()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: "hide:")
        tapGesture.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tapGesture)
        scrollView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    }
    
    func configureEvent() {
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var pageWidth = self.scrollView.frame.size.width
        var fractionalPage = Double(self.scrollView.contentOffset.x / pageWidth)
        var page = Int(lround(fractionalPage))
        if page != currentPage {
            currentPage = page
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return currentPage < imageViews.count ? imageViews[currentPage] : nil
    }
    
    // MARK: - Configuration
    
    func showImage() {
        var size = view.frame.size
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * CGFloat(imageURLs.count), size.height))
        contentView.backgroundColor = UIColor.clearColor()
        var i = 0
        for imageURL in imageURLs {
            let imageView = UIImageView(frame: CGRectMake(0, 0, size.width, size.height))
            imageView.contentMode = .ScaleAspectFit
            imageView.tag = i
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "menu:"))
            let zoomScrolliew = UIScrollView(frame: CGRectMake(size.width * CGFloat(i), 0, size.width, size.height))
            zoomScrolliew.delegate = self
            zoomScrolliew.directionalLockEnabled = true
            zoomScrolliew.minimumZoomScale = 0.2
            zoomScrolliew.maximumZoomScale = 5
            zoomScrolliew.contentMode = .ScaleAspectFit
            zoomScrolliew.contentSize = view.frame.size
            zoomScrolliew.backgroundColor = UIColor.clearColor()
            zoomScrolliew.addSubview(imageView)
            contentView.addSubview(zoomScrolliew)
            imageViews.append(imageView)
            ImageLoaderClient.displayImage(imageURL, imageView: imageView)
            i++
        }
        
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.setContentOffset(CGPointMake(size.width * CGFloat(initialPage), 0), animated: false)
    }
    
    class func show(imageURLs: [NSURL], initialPage: Int) {
        Static.instance.imageURLs = imageURLs
        Static.instance.initialPage = initialPage
        
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            Static.instance.view.frame = CGRectMake(0, 0, vc.view.frame.width, vc.view.frame.height)
            vc.view.addSubview(Static.instance.view)
        }
    }
    
    func hide(sender: AnyObject) {
        imageViews.removeAll(keepCapacity: true)
        for view in scrollView.subviews as! [UIView] {
            view.removeFromSuperview()
        }
        self.view.removeFromSuperview()
    }
    
    func menu(sender: UILongPressGestureRecognizer) {
        if (sender.state != .Began) {
            return
        }
        let tag = sender.view?.tag ?? 0
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Save",
            style: .Default,
            handler: { action in
                if let image = self.imageViews[tag].image {
                    UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
                }
        }))
        AlertController.showViewController(actionSheet)
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutablePointer<Void>) {
        if error != nil {
            ErrorAlert.show("Save failure", message: "\(error.localizedDescription)\n(code:\(error.code))")
        } else {
            ErrorAlert.show("Save success")
        }
    }
}

