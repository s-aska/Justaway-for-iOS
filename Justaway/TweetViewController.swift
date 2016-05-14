//
//  TweetViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/14/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async

class TweetViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!

    var sourceStatus: TwitterStatus?

    override var nibName: String {
        return "TweetViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    // MARK: - Configuration

    func configureView() {

    }

    // MARK: - Private

//    private func measure(text: NSString) -> CGFloat {
//        return ceil(text.boundingRectWithSize(
//            CGSize.init(width: self.messageLabel.frame.size.width, height: 0),
//            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
//            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(CGFloat(GenericSettings.get().fontSize))],
//            context: nil).size.height)
//    }

    // MARK: - Action

    @IBAction func left(sender: UIButton) {
        hide()
    }

    @IBAction func menu(sender: UIButton) {
        if let status = sourceStatus {
            StatusAlert.show(sender, status: status)
        }
    }

    // MARK: - Public

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Public

    class func show(sourceStatus: TwitterStatus) {
        let instance = TweetViewController()
        instance.sourceStatus = sourceStatus
        Async.main {
            ViewTools.slideIn(instance, keepEditor: true)
        }
    }
}

