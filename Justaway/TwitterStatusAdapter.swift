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
import Async

class TwitterStatusAdapter: TwitterAdapter {

    // MARK: Properties

    var renderDataCallback: ((statuses: [TwitterStatus], mode: RenderMode) -> Void)?
    var delegate: TwitterStatusAdapterDelegate?
    var activityMode = false

    var statuses: [TwitterStatus] {
        return rows.filter({ $0.status != nil }).map({ $0.status! })
    }

    // MARK: Configuration

    func configureView(delegate: TwitterStatusAdapterDelegate?, tableView: UITableView) {
        self.delegate = delegate
        self.configureView(tableView)
        tableView.registerNib(UINib(nibName: "ShowMoreTweetsCell", bundle: nil), forCellReuseIdentifier: "ShowMoreTweetsCell")
        setupLayout(tableView)
    }

    func setupLayout(tableView: UITableView) {
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
            CGSize.init(width: (self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }

    private func measureQuoted(status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        if let quotedStatus = status.quotedStatus {
            return ceil(quotedStatus.text.boundingRectWithSize(
                CGSize.init(width: (self.layoutHeightCell[.NormalWithQuote]?.quotedStatusLabel!.frame.size.width)!, height: 0),
                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
                context: nil).size.height)
        } else {
            return 0
        }
    }

    func fontSizeApplied(tableView: UITableView, fontSize: CGFloat) {
        let newRows = self.rows.map({ (row) -> TwitterStatusAdapter.Row in
            if let status = row.status {
                return self.createRow(status, fontSize: fontSize, tableView: tableView)
            } else {
                return row
            }
        })
        fontSizeApplied(tableView, fontSize: fontSize, rows: newRows)
    }

    // MARK: Public Methods

    func renderData(tableView: UITableView, statuses: [TwitterStatus], mode: RenderMode, handler: (() -> Void)?) {
        var statuses = statuses
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .OVER ? 0 : timelineRowsLimit

        var addShowMore = false
        if mode == .HEADER {
            if let firstUniqueID = firstUniqueID() {
                if statuses.contains({ $0.uniqueID == firstUniqueID }) {
                    statuses.removeAtIndex(statuses.count - 1)
                } else {
                    addShowMore = true
                }
            }
        } else if mode == .TOP {
            if let topRowStatus = rows.first?.status, firstReceivedStatus = statuses.first {
                if !firstReceivedStatus.connectionID.isEmpty && firstReceivedStatus.connectionID != topRowStatus.connectionID {
                    addShowMore = true
                }
            }
        }

        if mode != .OVER {
            statuses = statuses.filter { status -> Bool in
                return !rows.contains { $0.status?.uniqueID ?? "" == status.uniqueID }
            }
        }

        let deleteCount = mode == .OVER ? self.rows.count : max((self.rows.count + statuses.count) - limit, 0)
        let deleteStart = mode == .TOP || mode == .HEADER ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { row in NSIndexPath(forRow: row, inSection: 0) }

        let insertStart = mode == .BOTTOM ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + statuses.count)).map { row in NSIndexPath(forRow: row, inSection: 0) }

        if deleteIndexPaths.count == 0 && statuses.count == 0 {
            handler?()
            return
        }
        // println("renderData lastID: \(self.lastID ?? 0) insertIndexPaths: \(insertIndexPaths.count) deleteIndexPaths: \(deleteIndexPaths.count) oldRows:\(self.rows.count)")

        if let lastCell = tableView.visibleCells.last {
            // NSLog("y:\(tableView.contentOffset.y) top:\(tableView.contentInset.top)")
            let isTop = tableView.contentOffset.y + tableView.contentInset.top <= 0 && mode == .TOP
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
                    i += 1
                }
                if addShowMore {
                    let showMoreIndexPath = NSIndexPath(forRow: insertStart + statuses.count, inSection: 0)
                    self.rows.insert(Row(), atIndex: showMoreIndexPath.row)
                    tableView.insertRowsAtIndexPaths(insertIndexPaths + [showMoreIndexPath], withRowAnimation: .None)
                } else {
                    tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
                }
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPoint(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animateWithDuration(0.3, animations: { _ in
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                    }, completion: { _ in
                        self.scrollEnd(tableView)
                        self.renderDataCallback?(statuses: statuses, mode: mode)
                        handler?()
                })
            } else {
                if mode == .OVER {
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                }
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
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: false)
            tableView.reloadData()
            self.renderImages(tableView)
            self.renderDataCallback?(statuses: statuses, mode: mode)
            handler?()
        }
    }

    func showMoreTweets(tableView: UITableView, indexPath: NSIndexPath, handler: () -> Void) {

        let maxID: String? = {
            if indexPath.row < 1 {
                return nil
            }
            for i in 1 ... indexPath.row {
                if let status = self.rows[indexPath.row - i].status {
                    if activityMode {
                        return status.uniqueID
                    }
                    return String((status.referenceOrStatusID as NSString).longLongValue - 1)
                }
            }
            return nil
        }()

        let sinceID: String? = {
            for i in indexPath.row ..< rows.count {
                if let status = self.rows[i].status {
                    if activityMode {
                        return status.uniqueID
                    }
                    return String((status.referenceOrStatusID as NSString).longLongValue - 1)
                }
            }
            return nil
        }()

        let keep: Bool = {
            if maxID == nil {
                return true
            }
            if sinceID == nil {
                return false
            }
            if let iterator = tableView.indexPathsForVisibleRows?.enumerate() {
                for (i, visibleIndexPath) in iterator {
                    if indexPath.row == visibleIndexPath.row {
                        return i < 4
                    }
                }
            }
            return false
        }()

        delegate?.loadData(sinceID: sinceID, maxID: maxID, success: { (statuses) -> Void in

            let findLast: Bool = {
                guard let lastUniqueID = statuses.last?.uniqueID else {
                    return true
                }
                if self.statuses.contains({ $0.uniqueID == lastUniqueID }) {
                    return true
                }
                if statuses.count == 0 {
                    return true
                }
                return false
            }()

            var statuses = statuses
            statuses = statuses.filter { status -> Bool in
                return !self.rows.contains { $0.status?.uniqueID ?? "" == status.uniqueID }
            }

            let fontSize = CGFloat(GenericSettings.get().fontSize)

            let deleteCount = findLast ? 1 : 0
            let deleteStart = indexPath.row
            let deleteRange = deleteStart ..< (deleteStart + deleteCount)
            let deleteIndexPaths = findLast ? [indexPath] : [NSIndexPath]()

            let insertStart = indexPath.row
            let insertIndexPaths = statuses.count == 0 ? [] : (insertStart ..< (insertStart + statuses.count)).map { i in NSIndexPath(forRow: i, inSection: 0) }

            let lastCell = tableView.visibleCells.last
            let offset = (lastCell?.frame.origin.y ?? 0) - tableView.contentOffset.y

            if keep {
                UIView.setAnimationsEnabled(false)
            }

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
                    i += 1
                }
                tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
            }
            tableView.endUpdates()
            if keep {
                if let lastCell = lastCell {
                    tableView.setContentOffset(CGPoint(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
                    UIView.setAnimationsEnabled(true)
                    if insertIndexPaths.count > 0 && !findLast && indexPath.row == 0 {
                        tableView.setContentOffset(CGPoint(x: 0, y: lastCell.frame.origin.y - offset - 50), animated: true)
                    } else {
                        self.scrollEnd(tableView)
                    }
                } else {
                    UIView.setAnimationsEnabled(true)
                }
            }
            handler()
        }, failure: { (error) -> Void in
            ErrorAlert.show(error)
            handler()
        })
    }

    func eraseData(tableView: UITableView, statusID: String, handler: (() -> Void)?) {
        let target = { (row: Row) -> Bool in
            return row.status?.statusID ?? "" == statusID
        }
        eraseData(tableView, target: target, handler: handler)
    }

    func sinceID() -> String? {
        if activityMode {
            return firstUniqueID()
        }
        for status in statuses {
            if status.type == .Normal {
                return status.referenceOrStatusID
            }
        }
        return nil
    }

    func firstUniqueID() -> String? {
        for status in statuses {
            return status.uniqueID
        }
        return nil
    }
}

// MARK: - UITableViewDelegate

extension TwitterStatusAdapter {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let _ = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        let row = rows[indexPath.row]
        if let status = row.status {
            TalkViewController.show(status)
        } else if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ShowMoreTweetsCell {

            Async.main {
                cell.showMoreLabel.hidden = true
                cell.indicator.hidden = false
                cell.indicator.startAnimating()
            }

            let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
                let always: (Void -> Void) = {
                    op.finish()
                    Async.main {
                        cell.showMoreLabel.hidden = false
                        cell.indicator.hidden = true
                        cell.indicator.stopAnimating()
                    }
                }
                self.showMoreTweets(tableView, indexPath: indexPath, handler: always)
            })
            NSLog("didSelectRowAtIndexPath loadDataQueue operationCount:\(self.loadDataQueue.operationCount) suspended:\(self.loadDataQueue.suspended)")
            self.loadDataQueue.addOperation(op)
        }
    }
}

protocol TwitterStatusAdapterDelegate {
    func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void))
}
