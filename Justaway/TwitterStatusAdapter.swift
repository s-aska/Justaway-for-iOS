//
//  TwitterStatusAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class TwitterStatusAdapter: TwitterAdapter {

    // MARK: Properties

    var renderDataCallback: ((_ statuses: [TwitterStatus], _ mode: RenderMode) -> Void)?
    var delegate: TwitterStatusAdapterDelegate?
    var activityMode = false

    var statuses: [TwitterStatus] {
        return rows.filter({ $0.status != nil }).map({ $0.status! })
    }

    // MARK: Configuration

    func configureView(_ delegate: TwitterStatusAdapterDelegate?, tableView: UITableView) {
        self.delegate = delegate
        self.configureView(tableView)
        tableView.register(UINib(nibName: "ShowMoreTweetsCell", bundle: nil), forCellReuseIdentifier: "ShowMoreTweetsCell")
        setupLayout(tableView)
    }

    func setupLayout(_ tableView: UITableView) {
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValues {
            tableView.register(nib, forCellReuseIdentifier: layout.rawValue)
            if let cell = tableView.dequeueReusableCell(withIdentifier: layout.rawValue) as? TwitterStatusCell {
                self.layoutHeightCell[layout] = cell
            }
        }
    }

    // MARK: Private Methods

    func createRow(_ status: TwitterStatus, fontSize: CGFloat, tableView: UITableView) -> Row {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        if let height = layoutHeight[layout] {
            let textHeight = measure(status.text as NSString, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(status.text as NSString, fontSize: fontSize)
            let quotedTextHeight = measureQuoted(status, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            if layout.hasQuote {
                cell.quotedStatusLabelHeightConstraint.constant = 0
            }
            let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight + quotedTextHeight)
            return Row(status: status, fontSize: fontSize, height: totalHeight, textHeight: textHeight, quotedTextHeight: quotedTextHeight)
        }
        fatalError("cellForHeight is missing.")
    }

    fileprivate func measure(_ text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRect(
            with: CGSize.init(width: (self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
            context: nil).size.height)
    }

    fileprivate func measureQuoted(_ status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        if let quotedStatus = status.quotedStatus {
            return ceil(quotedStatus.text.boundingRect(
                with: CGSize.init(width: (self.layoutHeightCell[.NormalWithQuote]?.quotedStatusLabel!.frame.size.width)!, height: 0),
                options: NSStringDrawingOptions.usesLineFragmentOrigin,
                attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
                context: nil).size.height)
        } else {
            return 0
        }
    }

    func fontSizeApplied(_ tableView: UITableView, fontSize: CGFloat) {
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

    func renderData(_ tableView: UITableView, statuses: [TwitterStatus], mode: RenderMode, handler: (() -> Void)?) {
        var statuses = statuses
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .over ? 0 : timelineRowsLimit

        var addShowMore = false
        if mode == .header {
            if let firstUniqueID = firstUniqueID() {
                if statuses.contains(where: { $0.uniqueID == firstUniqueID }) {
                    statuses.remove(at: statuses.count - 1)
                } else {
                    addShowMore = true
                }
            }
        } else if mode == .top {
            if let topRowStatus = rows.first?.status, let firstReceivedStatus = statuses.first {
                if !firstReceivedStatus.connectionID.isEmpty && firstReceivedStatus.connectionID != topRowStatus.connectionID {
                    addShowMore = true
                }
            }
        }

        if mode != .over {
            statuses = statuses.filter { status -> Bool in
                return !rows.contains { $0.status?.uniqueID ?? "" == status.uniqueID }
            }
        }

        let deleteCount = mode == .over ? self.rows.count : max((self.rows.count + statuses.count) - limit, 0)
        let deleteStart = mode == .top || mode == .header ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { row in IndexPath(row: row, section: 0) }

        let insertStart = mode == .bottom ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + statuses.count)).map { row in IndexPath(row: row, section: 0) }

        if deleteIndexPaths.count == 0 && statuses.count == 0 {
            handler?()
            return
        }
        // println("renderData lastID: \(self.lastID ?? 0) insertIndexPaths: \(insertIndexPaths.count) deleteIndexPaths: \(deleteIndexPaths.count) oldRows:\(self.rows.count)")

        if let lastCell = tableView.visibleCells.last {
            // NSLog("y:\(tableView.contentOffset.y) top:\(tableView.contentInset.top)")
            let isTop = tableView.contentOffset.y + tableView.contentInset.top <= 0 && mode == .top
            let offset = lastCell.frame.origin.y - tableView.contentOffset.y
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            if deleteIndexPaths.count > 0 {
                tableView.deleteRows(at: deleteIndexPaths, with: .none)
                self.rows.removeSubrange(deleteRange)
            }
            if insertIndexPaths.count > 0 {
                var i = 0
                for insertIndexPath in insertIndexPaths {
                    let row = self.createRow(statuses[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, at: insertIndexPath.row)
                    i += 1
                }
                if addShowMore {
                    let showMoreIndexPath = IndexPath(row: insertStart + statuses.count, section: 0)
                    self.rows.insert(Row(), at: showMoreIndexPath.row)
                    tableView.insertRows(at: insertIndexPaths + [showMoreIndexPath], with: .none)
                } else {
                    tableView.insertRows(at: insertIndexPaths, with: .none)
                }
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPoint(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animate(withDuration: 0.3, animations: { _ in
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                    }, completion: { _ in
                        self.scrollEnd(tableView)
                        self.renderDataCallback?(statuses, mode)
                        handler?()
                })
            } else {
                if mode == .over {
                    tableView.contentOffset = CGPoint(x: 0, y: -tableView.contentInset.top)
                    self.scrollEnd(tableView)
                }
                self.renderDataCallback?(statuses, mode)
                handler?()
            }

        } else {
            if deleteIndexPaths.count > 0 {
                self.rows.removeSubrange(deleteRange)
            }
            for status in statuses {
                self.rows.append(self.createRow(status, fontSize: fontSize, tableView: tableView))
            }
            tableView.setContentOffset(CGPoint(x: 0, y: -tableView.contentInset.top), animated: false)
            tableView.reloadData()
            self.renderImages(tableView)
            self.renderDataCallback?(statuses, mode)
            handler?()
        }
    }

    func showMoreTweets(_ tableView: UITableView, indexPath: IndexPath, handler: @escaping () -> Void) {

        let maxID: String? = {
            if indexPath.row < 1 {
                return nil
            }
            for i in 1 ... indexPath.row {
                if let status = self.rows[indexPath.row - i].status {
                    if activityMode {
                        return status.uniqueID
                    }
                    return String(status.referenceOrStatusID.longLongValue - 1)
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
                    return String(status.referenceOrStatusID.longLongValue - 1)
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
            if let iterator = tableView.indexPathsForVisibleRows?.enumerated() {
                for (i, visibleIndexPath) in iterator {
                    if indexPath.row == visibleIndexPath.row {
                        return i < 4
                    }
                }
            }
            return false
        }()

        NSLog("[TwitterStatusAdapter] maxID:\(maxID ?? "-") sinceID:\(sinceID ?? "-")")

        delegate?.loadData(sinceID: sinceID, maxID: maxID, success: { (statuses) -> Void in

            let findLast: Bool = {
                guard let lastUniqueID = statuses.last?.uniqueID else {
                    return true
                }
                if self.statuses.contains(where: { $0.uniqueID == lastUniqueID }) {
                    return true
                }
                if statuses.count == 0 {
                    #if DEBGU
                        ErrorAlert.show("maxID:\(maxID ?? "-") sinceID:\(sinceID ?? "-")")
                    #endif
                    return true
                }
                return false
            }()

            NSLog("[TwitterStatusAdapter] maxID:\(maxID ?? "-") sinceID:\(sinceID ?? "-") count:\(statuses.count) findLast:\(findLast)")

            var statuses = statuses
            statuses = statuses.filter { status -> Bool in
                return !self.rows.contains { $0.status?.uniqueID ?? "" == status.uniqueID }
            }

            let fontSize = CGFloat(GenericSettings.get().fontSize)

            let deleteCount = findLast ? 1 : 0
            let deleteStart = indexPath.row
            let deleteRange = deleteStart ..< (deleteStart + deleteCount)
            let deleteIndexPaths = findLast ? [indexPath] : [IndexPath]()

            let insertStart = indexPath.row
            let insertIndexPaths = statuses.count == 0 ? [] : (insertStart ..< (insertStart + statuses.count)).map { i in IndexPath(row: i, section: 0) }

            let lastCell = tableView.visibleCells.last
            let offset = (lastCell?.frame.origin.y ?? 0) - tableView.contentOffset.y

            if keep {
                UIView.setAnimationsEnabled(false)
            }

            tableView.beginUpdates()
            if deleteIndexPaths.count > 0 {
                tableView.deleteRows(at: deleteIndexPaths, with: .none)
                self.rows.removeSubrange(deleteRange)
            }
            if insertIndexPaths.count > 0 {
                var i = 0
                for insertIndexPath in insertIndexPaths {
                    let row = self.createRow(statuses[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, at: insertIndexPath.row)
                    i += 1
                }
                tableView.insertRows(at: insertIndexPaths, with: .none)
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

    func eraseData(_ tableView: UITableView, statusID: String, handler: (() -> Void)?) {
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
            if status.type == .normal {
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
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard let _ = tableView.cellForRow(at: indexPath) else {
            return
        }
        let row = rows[indexPath.row]
        if let status = row.status {
            if !status.isRoot {
                TweetsViewController.show(status)
            }
        } else if let cell = tableView.cellForRow(at: indexPath) as? ShowMoreTweetsCell {

            Async.main {
                cell.showMoreLabel.isHidden = true
                cell.indicator.isHidden = false
                cell.indicator.startAnimating()
            }

            let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
                let always: ((Void) -> Void) = {
                    op.finish()
                    Async.main {
                        cell.showMoreLabel.isHidden = false
                        cell.indicator.isHidden = true
                        cell.indicator.stopAnimating()
                    }
                }
                self.showMoreTweets(tableView, indexPath: indexPath, handler: always)
            })
            NSLog("didSelectRowAtIndexPath loadDataQueue operationCount:\(self.loadDataQueue.operationCount) suspended:\(self.loadDataQueue.isSuspended)")
            self.loadDataQueue.addOperation(op)
        }
    }
}

protocol TwitterStatusAdapterDelegate {
    func loadData(sinceID: String?, maxID: String?, success: @escaping  ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void))
}
