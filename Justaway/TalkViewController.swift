//
//  TalkViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/28/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel

class TalkViewController: UIViewController {

    // MARK: Properties

    let adapter = TwitterStatusAdapter()
    var lastID: Int64?
    var rootStatus: TwitterStatus?

    @IBOutlet weak var tableView: UITableView!

    override var nibName: String {
        return "TalkViewController"
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
        if let status = rootStatus {
            adapter.renderData(tableView, statuses: [status], mode: .BOTTOM, handler: nil)
            if let inReplyToStatusID = status.inReplyToStatusID {
                loadStatus(inReplyToStatusID)
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        adapter.configureView(nil, tableView: tableView)
    }

    func configureEvent() {

    }

    // MARK: -

    func loadStatus(statusID: String) {
        let success = { (statuses: [TwitterStatus]) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: .BOTTOM, handler: nil)
            for status in statuses {
                if let inReplyToStatusID = status.inReplyToStatusID {
                    self.loadStatus(inReplyToStatusID)
                }
            }
        }
        let failure = { (error: NSError) -> Void in
            ErrorAlert.show("Error", message: error.localizedDescription)
        }
        Twitter.getStatuses([statusID], success: success, failure: failure)
    }

    // MARK: - Actions

    @IBAction func left(sender: UIButton) {
        hide()
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show(status: TwitterStatus) {
        let instance = TalkViewController()
        instance.rootStatus = status
        ViewTools.slideIn(instance)
    }
}
