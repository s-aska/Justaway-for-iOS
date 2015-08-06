//
//  PocketCoverViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/6/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class PocketCoverViewController: UIViewController {
    
    struct Static {
        static var instances = [PocketCoverViewController]()
    }
    
    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }
    
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
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1800, target: self, selector: "timeout", userInfo: nil, repeats: false)
        
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
            switch (state) {
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
            state++
        } else {
            state = 1
            button1.hidden = false
            button2.hidden = false
            button3.hidden = false
            button4.hidden = false
        }
    }
    
    func hide() {
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            self.view.frame = CGRectMake(
                self.view.frame.origin.x,
                -self.view.frame.size.height,
                self.view.frame.size.width,
                self.view.frame.size.height)
            }, completion: { finished in
                self.view.hidden = true
                self.view.removeFromSuperview()
                Static.instances.removeAtIndex(Static.instances.endIndex.predecessor()) // purge instance
        })
    }
    
    // MARK: - Class Methods
    
    class func show() {
        
        EditorViewController.hide() // TODO: think seriously about
        
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            let instance = PocketCoverViewController()
            instance.view.hidden = true
            vc.view.addSubview(instance.view)
            instance.view.frame = CGRectMake(0, -vc.view.frame.height, vc.view.frame.width, vc.view.frame.height)
            instance.view.hidden = false
            
            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                instance.view.frame = CGRectMake(vc.view.frame.origin.x,
                    vc.view.frame.origin.y,
                    vc.view.frame.size.width,
                    vc.view.frame.size.height)
                }) { (finished) -> Void in
            }
            Static.instances.append(instance) // keep instance
        }
    }
}
