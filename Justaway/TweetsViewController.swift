//
//  TweetsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/28/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Pinwheel
import SwiftyJSON
import EventBox

class TweetsViewController: UIViewController {

    // MARK: Properties

    let adapter = TwitterStatusAdapter()
    var loaded = false

    @IBOutlet weak var tableView: UITableView!

    override var nibName: String {
        return "TweetsViewController"
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
        if !loaded {
            loaded = true
            adapter.setupLayout(tableView)
            loadData()
        }
    }

    // MARK: - Configuration

    func configureView() {
        adapter.configureView(nil, tableView: tableView)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tableView)
        })
    }

    // MARK: -

    func loadData() {
    }

    // MARK: - Actions

    @IBAction func left(sender: UIButton) {
        hide()
    }

    func hide() {
        ViewTools.slideOut(self)
    }
}
