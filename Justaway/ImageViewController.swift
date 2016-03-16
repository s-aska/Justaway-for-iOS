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
    @IBOutlet weak var pageControl: UIPageControl!

    var imageURLs = [NSURL]()
    var imageViews = [UIImageView]()
    var initialPage = 0

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
        scrollView.delegate = self

        let swipeUp = UISwipeGestureRecognizer(target: self, action: "swipeUp")
        swipeUp.numberOfTouchesRequired = 1
        swipeUp.direction = .Up
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(swipeUp)
        scrollView.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: "swipeDown")
        swipeDown.numberOfTouchesRequired = 1
        swipeDown.direction = .Down
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(swipeDown)
        scrollView.addGestureRecognizer(swipeDown)

        let tap = UITapGestureRecognizer(target: self, action: "hide")
        tap.numberOfTouchesRequired = 1
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(tap)
        scrollView.addGestureRecognizer(tap)

        scrollView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        pageControl.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }

    func configureEvent() {

    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = Double(scrollView.contentOffset.x / pageWidth)
        let page = Int(lround(fractionalPage))
        if page != pageControl.currentPage {
            pageControl.currentPage = page
        }
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return pageControl.currentPage < imageViews.count ? imageViews[pageControl.currentPage] : nil
    }

    // MARK: - Configuration

    func showImage() {
        let size = view.frame.size
        let contentView = UIView(frame: CGRect.init(x: 0, y: 0, width: size.width * CGFloat(imageURLs.count), height: size.height))
        contentView.backgroundColor = UIColor.clearColor()
        var i = 0
        for imageURL in imageURLs {
            let imageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .ScaleAspectFit
            imageView.tag = i
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "menu:"))

            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            indicatorView.hidesWhenStopped = true
            indicatorView.center = imageView.center

            let zoomScrolliew = UIScrollView(frame: CGRect.init(x: size.width * CGFloat(i), y: 0, width: size.width, height: size.height))
            zoomScrolliew.delegate = self
            zoomScrolliew.directionalLockEnabled = true
            zoomScrolliew.minimumZoomScale = 0.2
            zoomScrolliew.maximumZoomScale = 5
            zoomScrolliew.contentMode = .ScaleAspectFit
            zoomScrolliew.contentSize = view.frame.size
            zoomScrolliew.backgroundColor = UIColor.clearColor()
            zoomScrolliew.addSubview(imageView)
            zoomScrolliew.addSubview(indicatorView)
            contentView.addSubview(zoomScrolliew)
            imageViews.append(imageView)

            indicatorView.startAnimating()
            ImageLoaderClient.displayImage(imageURL, imageView: imageView) {
                indicatorView.stopAnimating()
            }

            i++
        }

        pageControl.hidden = i == 1
        pageControl.numberOfPages = i
        pageControl.currentPage = initialPage

        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.setContentOffset(CGPoint.init(x: size.width * CGFloat(initialPage), y: 0), animated: false)
    }

    @IBAction func pageControlChange(sender: UIPageControl) {
        let size = view.frame.size
        scrollView.setContentOffset(CGPoint.init(x: size.width * CGFloat(sender.currentPage), y: 0), animated: false)
    }

    class func show(imageURLs: [NSURL], initialPage: Int) {
        Static.instance.imageURLs = imageURLs
        Static.instance.initialPage = initialPage

        if let vc = ViewTools.frontViewController() {
            Static.instance.view.frame = CGRect.init(x: 0, y: 0, width: vc.view.frame.width, height: vc.view.frame.height)
            vc.view.addSubview(Static.instance.view)
        }
    }

    func hide() {
        imageViews.removeAll(keepCapacity: true)
        for view in scrollView.subviews as [UIView] {
            view.removeFromSuperview()
        }
        self.view.removeFromSuperview()
    }

    func swipeUp() {
        let imageView = imageViews[pageControl.currentPage]
        UIView.animateWithDuration(0.3, animations: { _ in
            imageView.frame = CGRect.init(x: imageView.frame.origin.x, y: -imageView.frame.size.height, width: imageView.frame.size.width, height: imageView.frame.size.height)
            }, completion: { _ in
                self.hide()
        })
    }

    func swipeDown() {
        let imageView = imageViews[pageControl.currentPage]
        UIView.animateWithDuration(0.3, animations: { _ in
            imageView.frame = CGRect.init(x: imageView.frame.origin.x, y: imageView.frame.size.height, width: imageView.frame.size.width, height: imageView.frame.size.height)
        }, completion: { _ in
            self.hide()
        })
    }

    func menu(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began {
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
