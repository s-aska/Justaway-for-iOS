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

    var timer: Timer?
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1800, target: self, selector: #selector(PocketCoverViewController.timeout), userInfo: nil, repeats: false)

        self.state = 1
        self.button1.isHidden = false
        self.button2.isHidden = false
        self.button3.isHidden = false
        self.button4.isHidden = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.timer?.invalidate()

        UIApplication.shared.isIdleTimerDisabled = true
    }

    // MARK: - Configuration

    func configureView() {
        self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }

    func timeout() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @IBAction func button(_ sender: UIButton) {
        if sender.tag == state {
            switch state {
            case 1:
                button1.isHidden = true
            case 2:
                button2.isHidden = true
            case 3:
                button3.isHidden = true
            case 4:
                button4.isHidden = true
                hide()
            default:
                break
            }
            state += 1
        } else {
            state = 1
            button1.isHidden = false
            button2.isHidden = false
            button3.isHidden = false
            button4.isHidden = false
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
