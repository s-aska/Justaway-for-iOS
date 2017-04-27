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

    var imageURLs = [URL]()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showImage()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        scrollView.delegate = self

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(ImageViewController.swipeUp))
        swipeUp.numberOfTouchesRequired = 1
        swipeUp.direction = .up
        scrollView.panGestureRecognizer.require(toFail: swipeUp)
        scrollView.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(ImageViewController.swipeDown))
        swipeDown.numberOfTouchesRequired = 1
        swipeDown.direction = .down
        scrollView.panGestureRecognizer.require(toFail: swipeDown)
        scrollView.addGestureRecognizer(swipeDown)

        let tap = UITapGestureRecognizer(target: self, action: #selector(ImageViewController.hide))
        tap.numberOfTouchesRequired = 1
        scrollView.panGestureRecognizer.require(toFail: tap)
        scrollView.addGestureRecognizer(tap)

        scrollView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        pageControl.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }

    func configureEvent() {

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = Double(scrollView.contentOffset.x / pageWidth)
        let page = Int(lround(fractionalPage))
        if page != pageControl.currentPage {
            pageControl.currentPage = page
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return pageControl.currentPage < imageViews.count ? imageViews[pageControl.currentPage] : nil
    }

    // MARK: - Configuration

    func showImage() {
        let size = view.frame.size
        let contentView = UIView(frame: CGRect.init(x: 0, y: 0, width: size.width * CGFloat(imageURLs.count), height: size.height))
        contentView.backgroundColor = UIColor.clear
        var i = 0
        for imageURL in imageURLs {
            let imageView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .scaleAspectFit
            imageView.tag = i
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ImageViewController.menu(_:))))

            let indicatorView = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 80, height: 80))
            indicatorView.layer.cornerRadius = 10
            indicatorView.activityIndicatorViewStyle = .whiteLarge
            indicatorView.backgroundColor = UIColor(white: 0, alpha: 0.6)
            indicatorView.hidesWhenStopped = true
            indicatorView.center = imageView.center

            let zoomScrolliew = UIScrollView(frame: CGRect.init(x: size.width * CGFloat(i), y: 0, width: size.width, height: size.height))
            zoomScrolliew.delegate = self
            zoomScrolliew.isDirectionalLockEnabled = true
            zoomScrolliew.minimumZoomScale = 0.2
            zoomScrolliew.maximumZoomScale = 5
            zoomScrolliew.contentMode = .scaleAspectFit
            zoomScrolliew.contentSize = view.frame.size
            zoomScrolliew.backgroundColor = UIColor.clear
            zoomScrolliew.addSubview(imageView)
            zoomScrolliew.addSubview(indicatorView)
            contentView.addSubview(zoomScrolliew)
            imageViews.append(imageView)

            indicatorView.startAnimating()
            ImageLoaderClient.displayImage(imageURL, imageView: imageView) {
                indicatorView.stopAnimating()
            }

            i += 1
        }

        pageControl.isHidden = i == 1
        pageControl.numberOfPages = i
        pageControl.currentPage = initialPage

        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.setContentOffset(CGPoint.init(x: size.width * CGFloat(initialPage), y: 0), animated: false)
    }

    @IBAction func pageControlChange(_ sender: UIPageControl) {
        let size = view.frame.size
        scrollView.setContentOffset(CGPoint.init(x: size.width * CGFloat(sender.currentPage), y: 0), animated: false)
    }

    class func show(_ imageURLs: [URL], initialPage: Int) {
        Static.instance.imageURLs = imageURLs
        Static.instance.initialPage = initialPage

        if let vc = ViewTools.frontViewController() {
            Static.instance.view.frame = vc.view.frame
            vc.view.addSubview(Static.instance.view)
        }
    }

    func hide() {
        imageViews.removeAll(keepingCapacity: true)
        for view in scrollView.subviews as [UIView] {
            view.removeFromSuperview()
        }
        self.view.removeFromSuperview()
    }

    func swipeUp() {
        let imageView = imageViews[pageControl.currentPage]
        UIView.animate(withDuration: 0.3, animations: { _ in
            imageView.frame = imageView.frame.offsetBy(dx: 0, dy: -imageView.frame.size.height)
            }, completion: { _ in
                self.hide()
        })
    }

    func swipeDown() {
        let imageView = imageViews[pageControl.currentPage]
        UIView.animate(withDuration: 0.3, animations: { _ in
            imageView.frame = imageView.frame.offsetBy(dx: 0, dy: imageView.frame.size.height)
        }, completion: { _ in
            self.hide()
        })
    }

    func menu(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        let tag = sender.view?.tag ?? 0
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { action in
                actionSheet.dismiss(animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Save",
            style: .default,
            handler: { action in
                if let image = self.imageViews[tag].image {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(ImageViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
        }))
        AlertController.showViewController(actionSheet)
    }

    func image(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        if error != nil {
            ErrorAlert.show("Save failure", message: "\(error.localizedDescription)\n(code:\(error.code))")
        } else {
            ErrorAlert.show("Save success")
        }
    }
}
