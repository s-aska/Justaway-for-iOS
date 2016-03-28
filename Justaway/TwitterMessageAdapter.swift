//
//  TwitterMessageAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import EventBox
import Async

class TwitterMessageAdapter: TwitterAdapter {

    // MARK: Properties

    let threadMode: Bool
    var allMessage = [TwitterMessage]()

    var messages: [TwitterMessage] {
        return rows.filter({ $0.message != nil }).map({ $0.message! })
    }

    // MARK: Configuration

    override func configureView(tableView: UITableView) {
        super.configureView(tableView)
        setupLayout(tableView)
    }

    func setupLayout(tableView: UITableView) {
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValuesForMessage {
            tableView.registerNib(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = tableView.dequeueReusableCellWithIdentifier(layout.rawValue) as? TwitterStatusCell
        }
    }

    // MARK: Initializers

    init(threadMode: Bool) {
        self.threadMode = threadMode
    }

    // MARK: Private Methods

    func createRow(message: TwitterMessage, fontSize: CGFloat, tableView: UITableView) -> Row {
        let layout = TwitterStatusCellLayout.fromMessage(message)
        if let height = layoutHeight[layout] {
            let textHeight = measure(message.text, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(message: message, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(message.text, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            cell.quotedStatusLabelHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight)
            return Row(message: message, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        }
        fatalError("cellForHeight is missing.")
    }

    private func measure(text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSize.init(width: (self.layoutHeightCell[.Message]?.statusLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }

    // MARK: Public Methods

    func thread(messages: [TwitterMessage]) -> [TwitterMessage] {
        var thread = [TwitterMessage]()
        if let account = AccountSettingsStore.get()?.account() {
            var userMap = [String: Bool]()
            for message in messages {
                let userID = account.userID != message.sender.userID ? message.sender.userID : message.recipient.userID
                if userMap[userID] == nil {
                    userMap[userID] = true
                    thread.append(message)
                }
            }
        }
        return thread
    }

    func renderData(tableView: UITableView, messages: [TwitterMessage], mode: RenderMode, handler: (() -> Void)?) {
        var messages = messages
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .OVER ? 0 : timelineRowsLimit

        let deleteCount = mode == .OVER ? self.rows.count : max((self.rows.count + messages.count) - limit, 0)
        let deleteStart = mode == .TOP || mode == .HEADER ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { row in NSIndexPath(forRow: row, inSection: 0) }

        let insertStart = mode == .BOTTOM ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + messages.count)).map { row in NSIndexPath(forRow: row, inSection: 0) }

        if deleteIndexPaths.count == 0 && messages.count == 0 {
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
                    let row = self.createRow(messages[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, atIndex: insertIndexPath.row)
                    i += 1
                }
                tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPoint.init(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animateWithDuration(0.3, animations: { _ in
                    tableView.contentOffset = CGPoint.init(x: 0, y: -tableView.contentInset.top)
                    }, completion: { _ in
                        self.scrollEnd(tableView)
                        handler?()
                })
            } else {
                if mode == .OVER {
                    tableView.contentOffset = CGPoint.init(x: 0, y: -tableView.contentInset.top)
                }
                handler?()
            }

        } else {
            if deleteIndexPaths.count > 0 {
                self.rows.removeRange(deleteRange)
            }
            for message in messages {
                self.rows.append(self.createRow(message, fontSize: fontSize, tableView: tableView))
            }
            tableView.setContentOffset(CGPoint.init(x: 0, y: -tableView.contentInset.top), animated: false)
            tableView.reloadData()
            self.renderImages(tableView)
            handler?()
        }
    }

    func eraseData(tableView: UITableView, messageID: String, handler: (() -> Void)?) {
        let target = { (row: Row) -> Bool in
            return row.message?.id ?? "" == messageID
        }
        eraseData(tableView, target: target, handler: handler)
    }
}

// MARK: - UITableViewDelegate

extension TwitterMessageAdapter {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = rows[indexPath.row]
        if let message = row.message {
            if threadMode {
                let collocutorID = message.collocutor.userID
                let threadMessages = allMessage.filter({ $0.collocutor.userID == collocutorID })
                MessagesViewController.show(message.collocutor, messages: threadMessages)
            }
            // MessageAlert.show(cell, message: message)
        }
    }
}
