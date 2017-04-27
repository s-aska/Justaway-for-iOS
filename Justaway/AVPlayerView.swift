//
//  AVPlayerView.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/22/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {

    var indicatorView: UIActivityIndicatorView?
    var player: AVPlayer? {
        get {
            if let layer = self.layer as? AVPlayerLayer {
                return layer.player
            } else {
                return nil
            }
        }
        set(newValue) {
            if let layer = self.layer as? AVPlayerLayer {
                layer.player = newValue
            }
        }
    }

    override class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }

    func setVideoFillMode(_ mode: String) {
        if let layer = self.layer as? AVPlayerLayer {
            layer.videoGravity = mode
        }
    }
}
