//
//  ImageViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/19/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    
    // MARK: Properties
    
    override var nibName: String {
        return "ImageViewController"
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // configureEvent()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }
    
    
}

