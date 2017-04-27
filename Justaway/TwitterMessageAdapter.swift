//
//  TwitterMessageAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class TwitterMessageAdapter: TwitterAdapter {

    // MARK: Properties

    let threadMode: Bool

    var messages: [TwitterMessage] {
        return rows.filter({ $0.message != nil }).map({ $0.message! })
    }

    // MARK: Configuration

    override func configureView(_ tableView: UITableView) {
        super.configureView(tableView)
        setupLayout(tableView)
    }

    func setupLayout(_ tableView: UITableView) {
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValuesForMessage {
            tableView.register(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = tableView.dequeueReusableCell(withIdentifier: layout.rawValue) as? TwitterStatusCell
        }
    }

    // MARK: Initializers

    init(threadMode: Bool) {
        self.threadMode = threadMode
    }

    // MARK: Private Methods

    func createRow(_ message: TwitterMessage, fontSize: CGFloat, tableView: UITableView) -> Row {
        let layout = TwitterStatusCellLayout.fromMessage(message)
        if let height = layoutHeight[layout] {
            let textHeight = measure(message.text as NSString, fontSize: fontSize)
            let totalHeight = ceil(height + textHeight)
            return Row(message: message, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = tableView.bounds
            cell.setLayout(layout)
            let textHeight = measure(message.text as NSString, fontSize: fontSize)
            cell.textHeightConstraint.constant = 0
            cell.quotedStatusLabelHeightConstraint.constant = 0
            let height = cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
            layoutHeight[layout] = height
            let totalHeight = ceil(height + textHeight)
            return Row(message: message, fontSize: fontSize, height: totalHeight, textHeight: textHeight)
        }
        fatalError("cellForHeight is missing.")
    }

    fileprivate func measure(_ text: NSString, fontSize: CGFloat) -> CGFloat {
        return ceil(text.boundingRect(
            with: CGSize.init(width: (self.layoutHeightCell[.Message]?.statusLabel.frame.size.width)!, height: 0),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
            context: nil).size.height)
    }

    func fontSizeApplied(_ tableView: UITableView, fontSize: CGFloat) {
        let newRows = self.rows.map({ (row) -> TwitterStatusAdapter.Row in
            if let message = row.message {
                return self.createRow(message, fontSize: fontSize, tableView: tableView)
            } else {
                return row
            }
        })
        fontSizeApplied(tableView, fontSize: fontSize, rows: newRows)
    }

    // MARK: Public Methods

    func thread(_ messages: [TwitterMessage]) -> [TwitterMessage] {
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

    func renderData(_ tableView: UITableView, messages: [TwitterMessage], mode: RenderMode, handler: (() -> Void)?) {
        var messages = messages
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let limit = mode == .over ? 0 : timelineRowsLimit

        let deleteCount = mode == .over ? self.rows.count : max((self.rows.count + messages.count) - limit, 0)
        let deleteStart = mode == .top || mode == .header ? self.rows.count - deleteCount : 0
        let deleteRange = deleteStart ..< (deleteStart + deleteCount)
        let deleteIndexPaths = deleteRange.map { row in IndexPath(row: row, section: 0) }

        let insertStart = mode == .bottom ? self.rows.count - deleteCount : 0
        let insertIndexPaths = (insertStart ..< (insertStart + messages.count)).map { row in IndexPath(row: row, section: 0) }

        if deleteIndexPaths.count == 0 && messages.count == 0 {
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
                    let row = self.createRow(messages[i], fontSize: fontSize, tableView: tableView)
                    self.rows.insert(row, at: insertIndexPath.row)
                    i += 1
                }
                tableView.insertRows(at: insertIndexPaths, with: .none)
            }
            tableView.endUpdates()
            tableView.setContentOffset(CGPoint.init(x: 0, y: lastCell.frame.origin.y - offset), animated: false)
            UIView.setAnimationsEnabled(true)
            if isTop {
                UIView.animate(withDuration: 0.3, animations: { _ in
                    tableView.contentOffset = CGPoint.init(x: 0, y: -tableView.contentInset.top)
                    }, completion: { _ in
                        self.scrollEnd(tableView)
                        handler?()
                })
            } else {
                if mode == .over {
                    tableView.contentOffset = CGPoint.init(x: 0, y: -tableView.contentInset.top)
                }
                handler?()
            }

        } else {
            if deleteIndexPaths.count > 0 {
                self.rows.removeSubrange(deleteRange)
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

    func eraseData(_ tableView: UITableView, messageID: String, handler: (() -> Void)?) {
        let target = { (row: Row) -> Bool in
            return row.message?.id ?? "" == messageID
        }
        eraseData(tableView, target: target, handler: handler)
    }
}

// MARK: - UITableViewDelegate

extension TwitterMessageAdapter {
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        NSLog("TwitterMessageAdapter didSelectRowAtIndexPath")
        let row = rows[indexPath.row]
        if let message = row.message {
            if let account = AccountSettingsStore.get()?.account(), let messages = Twitter.messages[account.userID], threadMode {
                let collocutorID = message.collocutor.userID
                let threadMessages = messages.filter({ $0.collocutor.userID == collocutorID })
                Async.main {
                    MessagesViewController.show(message.collocutor, messages: threadMessages)
                }
            } else if let account = AccountSettingsStore.get()?.account() {
                DirectMessageAlert.show(account, message: message)
            }
        }
    }
}
