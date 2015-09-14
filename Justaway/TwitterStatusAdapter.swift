//
//  TwitterStatusAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import EventBox

class TwitterStatusAdapter: NSObject {
    
    // MARK: Types
    
    enum RenderMode {
        case HEADER
        case TOP
        case BOTTOM
        case OVER
    }
    
    struct Row {
        let status: TwitterStatus
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        let quotedTextHeight: CGFloat
        
        init(status: TwitterStatus, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat, quotedTextHeight: CGFloat) {
            self.status = status
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
            self.quotedTextHeight = quotedTextHeight
        }
    }
    
    // MARK: Properties
    
    var rows = [Row]()
    var layoutHeight = [TwitterStatusCellLayout: CGFloat]()
    var layoutHeightCell = [TwitterStatusCellLayout: TwitterStatusCell]()
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    var isTop: Bool = true
    var scrolling: Bool = false
    var didScrollToBottom: (Void -> Void)?
    var scrollCallback: ((scrollView: UIScrollView) -> Void)?
    var renderDataCallback: ((statuses: [TwitterStatus], mode: RenderMode) -> Void)?
    let loadDataQueue = NSOperationQueue().serial()
    let mainQueue = NSOperationQueue.mainQueue().serial()
    
    // MARK: Configuration
    
    func configureView(tableView: UITableView) {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValues {
            tableView.registerNib(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = tableView.dequeueReusableCellWithIdentifier(layout.rawValue) as? TwitterStatusCell
        }
    }
    
    // MARK: Private Methods
    
    func createRow(status: TwitterStatus, fontSize: CGFloat, tableView: UITableView) -> Row {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        if let height = layoutHeight[layout] {
            let textHeight = measure(status.text, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(status.text, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            cell.quotedStatusLabelHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        }
        fatalError("cellForHeight is missing.")
    }
    
    private func measure(text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSizeMake((self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
    
    private func measureQuoted(status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        if let quotedStatus = status.quotedStatus {
            return ceil(quotedStatus.text.boundingRectWithSize(
                CGSizeMake((self.layoutHeightCell[.Normal]?.quotedStatusLabel.frame.size.width)!, 0),
                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
                context: nil).size.height)
        } else {
            return 0
        }
    }
    
    // MARK: Public Methods
    
    func scrollBegin() {
        isTop = false
        scrolling = true
        loadDataQueue.suspended = true
        mainQueue.suspended = true
    }
    
    func scrollEnd(scrollView: UIScrollView) {
        scrolling = false
        loadDataQueue.suspended = false
        mainQueue.suspended = false
        Pinwheel.suspend = false
        if let tableView = scrollView as? UITableView {
            renderImages(tableView)
        }
        isTop = scrollView.contentOffset.y == 0 ? true : false
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let h = scrollView.contentSize.height
        let f = h - y
        if f < TIMELINE_FOOTER_HEIGHT {
            didScrollToBottom?()
        }
        if isTop {
            EventBox.post("timelineScrollToTop")
        }
    }
    
    func scrollToTop(scrollView: UIScrollView) {
        Pinwheel.suspend = true
        scrollView.setContentOffset(CGPointZero, animated: true)
    }
    
    func renderData(tableView: UITableView, statuses: [TwitterStatus], mode: RenderMode, handler: (() -> Void)?) {
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .OVER ? 0 : TIMELINE_ROWS_LIMIT
        let deleteCount = mode == .OVER ? self.rows.count : max((self.rows.count + statuses.count) - limit, 0)
        let deleteStart = mode == .TOP || mode == .HEADER ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { i in NSIndexPath(forRow: i, inSection: 0) }
        
        let insertStart = mode == .BOTTOM ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + statuses.count)).map { i in NSIndexPath(forRow: i, inSection: 0) }
        
        // println("renderData lastID: \(self.lastID ?? 0) insertIndexPaths: \(insertIndexPaths.count) deleteIndexPaths: \(deleteIndexPaths.count) oldRows:\(self.rows.count)")
        
        if let lastCell = tableView.visibleCells.last {
            let isTop = tableView.contentOffset.y == 0 && mode == .TOP
            let offset = lastCell.frame.origin.y - tableView.contentOffset.y
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            if deleteIndexPaths.count > 0 {
                tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .None)
                self.rows.removeRange(deleteRange)
            }
            if insertIndexPaths.count > 0 {
                var i = 0
                for insertIndexPath in insertIndexPaths {
                    let row = self.createRow(statuses[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, atIndex: insertIndexPath.row)
                    i++
                }
                tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPointMake(0, lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animateWithDuration(0.3, animations: { _ in
                    tableView.contentOffset = CGPointZero
                    }, completion: { _ in
                        self.scrollEnd(tableView)
                        self.renderDataCallback?(statuses: statuses, mode: mode)
                        handler?()
                })
            } else {
                self.renderDataCallback?(statuses: statuses, mode: mode)
                handler?()
            }
            
        } else {
            if deleteIndexPaths.count > 0 {
                self.rows.removeRange(deleteRange)
            }
            for status in statuses {
                self.rows.append(self.createRow(status, fontSize: fontSize, tableView: tableView))
            }
            tableView.setContentOffset(CGPointMake(0, -tableView.contentInset.top), animated: false)
            tableView.reloadData()
            self.renderImages(tableView)
            self.renderDataCallback?(statuses: statuses, mode: mode)
            handler?()
        }
    }
    
    func eraseData(tableView: UITableView, statusID: String, handler: (() -> Void)?) {
        var deleteIndexPaths = [NSIndexPath]()
        var i = 0
        var newRows = [Row]()
        for row in self.rows {
            if row.status.statusID == statusID {
                deleteIndexPaths.append(NSIndexPath(forRow: i, inSection: 0))
            } else {
                newRows.append(row)
            }
            i++
        }
        
        if deleteIndexPaths.count > 0 {
            CATransaction.begin()
            if let handler = handler {
                CATransaction.setCompletionBlock(handler)
            }
            tableView.beginUpdates()
            self.rows = newRows
            tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .Fade)
            tableView.endUpdates()
            CATransaction.commit()
        } else {
            handler?()
        }
    }
    
    func renderImages(tableView: UITableView) {
        for cell in tableView.visibleCells as! [TwitterStatusCell] {
            if let status = cell.status {
                cell.setImage(status)
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension TwitterStatusAdapter: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let status = row.status
        let layout = TwitterStatusCellLayout.fromStatus(status)
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as! TwitterStatusCell
        
        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }
        
        if cell.quotedStatusLabelHeightConstraint.constant != row.quotedTextHeight {
            cell.quotedStatusLabelHeightConstraint.constant = row.quotedTextHeight
        }
        
        if row.fontSize != cell.statusLabel.font.pointSize {
            cell.statusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        if row.fontSize != cell.quotedStatusLabel.font.pointSize {
            cell.quotedStatusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }
        
        if let s = cell.status {
            if s.uniqueID == status.uniqueID {
                return cell
            }
        }
        
        cell.status = status
        cell.setLayout(layout)
        cell.setText(status)
        
        if !Pinwheel.suspend {
            cell.setImage(status)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TwitterStatusAdapter: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            StatusAlert.show(cell, status: row.status)
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TIMELINE_FOOTER_HEIGHT
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, TIMELINE_FOOTER_HEIGHT))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: ThemeController.currentTheme.activityIndicatorStyle())
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
    }
}

// MARK: - UIScrollViewDelegate

extension TwitterStatusAdapter {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollCallback?(scrollView: scrollView)
        if loadDataQueue.suspended {
            return
        }
        scrollBegin() // now scrolling
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollBegin() // begin of flick scrolling
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        scrollEnd(scrollView) // end of flick scrolling no deceleration
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of deceleration of flick scrolling
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of setContentOffset
    }
}
