//
//  MessagesViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/28/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import EventBox

class MessagesViewController: UIViewController {

    // MARK: Properties

    let adapter = TwitterMessageAdapter(threadMode: false)
    var loadData = false
    var messages = [TwitterMessage]()
    var collocutor: TwitterUser?

    @IBOutlet weak var tableView: UITableView!

    override var nibName: String {
        return "MessagesViewController"
    }

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
        configureEvent()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !loadData {
            loadData = true
            adapter.setupLayout(tableView)
            adapter.renderData(tableView, messages: messages, mode: .OVER, handler: nil)
        }
    }

    // MARK: - Configuration

    func configureView() {
        adapter.configureView(tableView)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            self.adapter.scrollToTop(self.tableView)
        }
        EventBox.onMainThread(self, name: Twitter.Event.CreateMessage.rawValue) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            guard let message = n.object as? TwitterMessage else {
                return
            }
            if let collocutorID = self.collocutor?.userID where message.collocutor.userID == collocutorID {
                self.adapter.renderData(self.tableView, messages: [message], mode: .TOP, handler: nil)
            }
        }
        EventBox.onMainThread(self, name: Twitter.Event.DestroyMessage.rawValue) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            guard let messageID = n.object as? String else {
                return
            }
            self.adapter.eraseData(self.tableView, messageID: messageID, handler: nil)
        }
    }

    // MARK: -

    // MARK: - Actions

    @IBAction func left(sender: UIButton) {
        hide()
    }

    @IBAction func reply(sender: UIButton) {
        EditorViewController.show(nil, range: nil, inReplyToStatus: nil, messageTo: collocutor)
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show(collocutor: TwitterUser, messages: [TwitterMessage]) {
        let instance = MessagesViewController()
        instance.collocutor = collocutor
        instance.messages = messages
        ViewTools.slideIn(instance)
    }
}

