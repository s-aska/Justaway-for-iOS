//
//  PocketCoverViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/6/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class PocketCoverViewController: UIViewController {

    override var nibName: String {
        return "PocketCoverViewController"
    }

    var timer: NSTimer?
    var state = 1

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!

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

        self.timer?.invalidate()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1800, target: self, selector: #selector(PocketCoverViewController.timeout), userInfo: nil, repeats: false)

        self.state = 1
        self.button1.hidden = false
        self.button2.hidden = false
        self.button3.hidden = false
        self.button4.hidden = false
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.timer?.invalidate()

        UIApplication.sharedApplication().idleTimerDisabled = true
    }

    // MARK: - Configuration

    func configureView() {
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }

    func timeout() {
        UIApplication.sharedApplication().idleTimerDisabled = false
    }

    @IBAction func button(sender: UIButton) {
        if sender.tag == state {
            switch state {
            case 1:
                button1.hidden = true
            case 2:
                button2.hidden = true
            case 3:
                button3.hidden = true
            case 4:
                button4.hidden = true
                hide()
            default:
                break
            }
            state += 1
        } else {
            state = 1
            button1.hidden = false
            button2.hidden = false
            button3.hidden = false
            button4.hidden = false
        }
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show() {
        ViewTools.slideIn(PocketCoverViewController())
    }
}
