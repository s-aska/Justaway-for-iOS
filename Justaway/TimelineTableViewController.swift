//
//  TimelineTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Pinwheel

class TimelineTableViewController: UITableViewController {
    
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    var isTop: Bool = true
    var scrolling: Bool = false
    var setup = false
    let loadDataQueue = NSOperationQueue().serial()
    let mainQueue = NSOperationQueue.mainQueue().serial()
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TIMELINE_FOOTER_HEIGHT
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRectMake(0, 0, view.frame.size.width, TIMELINE_FOOTER_HEIGHT))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: ThemeController.currentTheme.activityIndicatorStyle())
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if (loadDataQueue.suspended) {
            return
        }
        scrollBegin() // now scrolling
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollBegin() // begin of flick scrolling
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (decelerate) {
            return
        }
        scrollEnd() // end of flick scrolling no deceleration
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollEnd() // end of deceleration of flick scrolling
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollEnd() // end of setContentOffset
    }
    
    // MARK: -
    
    func scrollBegin() {
        isTop = false
        scrolling = true
        loadDataQueue.suspended = true
        mainQueue.suspended = true
    }
    
    func scrollEnd() {
        scrolling = false
        loadDataQueue.suspended = false
        mainQueue.suspended = false
        Pinwheel.suspend = false
        isTop = self.tableView.contentOffset.y == 0 ? true : false
        let y = self.tableView.contentOffset.y + self.tableView.bounds.size.height - self.tableView.contentInset.bottom
        let h = self.tableView.contentSize.height
        let f = h - y
        if f < TIMELINE_FOOTER_HEIGHT {
            didScrollToBottom()
        }
        renderImages()
        if isTop {
            EventBox.post("timelineScrollToTop")
        }
    }
    
    func didScrollToBottom() {
        
    }
    
    func scrollToTop() {
        Pinwheel.suspend = true
        self.tableView.setContentOffset(CGPointZero, animated: true)
    }
    
    func refresh() {
        assertionFailure("not implements.")
    }
    
    func renderImages() {
        assertionFailure("not implements.")
    }
}
