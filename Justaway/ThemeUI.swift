//
//  ThemeUI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - ContainerView

class MenuView: UIView {}
class MenuShadowView: MenuView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0, -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundView: UIView {}
class BackgroundShadowView: BackgroundView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0, -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundTableView: UITableView {}
class BackgroundTableViewCell: UITableViewCell {}
class BackgroundScrollView: UIScrollView {}
class CurrentTabMaskView: UIView {}
class CellSeparator: UIView {
    let borderLayer = CALayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let borderWidth: CGFloat = (1.0 / UIScreen.mainScreen().scale) / 1
        borderLayer.frame = CGRectMake(0, bounds.size.height - borderWidth, bounds.size.width, borderWidth);
        borderLayer.backgroundColor = ThemeController.currentTheme.cellSeparatorColor().CGColor
        layer.addSublayer(borderLayer)
    }
}
class QuotedStatusContainerView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = ThemeController.currentTheme.cellSeparatorColor().CGColor
        layer.borderWidth = (1.0 / UIScreen.mainScreen().scale) / 1
    }
}

// MARK: - Buttons

class StreamingButton: UIButton {}
class MenuButton: BaseButton {}
class FavoritesButton: BaseButton {}
class ReplyButton: BaseButton {}
class RetweetButton: BaseButton {}

// MARK: - Lable

class TextLable: UILabel {}
class MenuLable: UILabel {}
class DisplayNameLable: UILabel {}
class ScreenNameLable: UILabel {}
class RelativeDateLable: UILabel {}
class AbsoluteDateLable: UILabel {}
class ClientNameLable: UILabel {}
class StatusLable: UITextView {
    var status: TwitterStatus?
    var links = [Link]()
    let playerView = AVPlayerView()
    
    struct Link {
        let entity: Entity
        let range: NSRange
        init(entity: Entity, range: NSRange) {
            self.entity = entity
            self.range = range
        }
    }
    
    enum Entity {
        case URL(TwitterURL)
        case Media(TwitterMedia)
        case Hashtag(TwitterHashtag)
        case User(TwitterUser)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textContainer.lineFragmentPadding = 0
        textContainerInset = UIEdgeInsetsZero
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "touchesText:"))
    }
    
    func setStatus(status: TwitterStatus) {
        self.status = status
        self.text = status.text
        var newlinks = [Link]()
        for url in status.urls {
            for result in findString(url.displayURL) {
                let link = Link(entity: Entity.URL(url), range: result.range)
                newlinks.append(link)
            }
        }
        for media in status.media {
            for result in findString(media.displayURL) {
                let link = Link(entity: Entity.Media(media), range: result.range)
                newlinks.append(link)
            }
        }
        for hashtag in status.hashtags {
            for result in findString("#" + hashtag.text) {
                let link = Link(entity: Entity.Hashtag(hashtag), range: result.range)
                newlinks.append(link)
            }
        }
        for mention in status.mentions {
            for result in findString("@" + mention.screenName) {
                let link = Link(entity: Entity.User(mention), range: result.range)
                newlinks.append(link)
            }
        }
        links = newlinks
        setAttributes()
    }
    
    func setAttributes() {
        backgroundColor = ThemeController.currentTheme.mainBackgroundColor()
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.bodyTextColor(), range: NSMakeRange(0, text.utf16.count))
        for link in links {
            attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.menuSelectedTextColor(), range: link.range)
        }
        self.attributedText = attributedText
    }
    
    private func findString(string: String) -> [NSTextCheckingResult] {
        let pattern = NSRegularExpression.escapedPatternForString(string)
        let regexp = try! NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
        return regexp.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.utf16.count))
    }
    
    func touchesText(gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.locationInView(self)
        guard let position = closestPositionToPoint(location) else {
            return
        }
        let selectedPosition = offsetFromPosition(beginningOfDocument, toPosition: position)
        for link in links {
            if NSLocationInRange(selectedPosition, link.range) {
                touchesLink(link)
                return
            }
        }
        if let status = status {
            StatusAlert.show(self, status: status)
        }
    }
    
    func touchesLink(link: Link) {
        switch link.entity {
        case .URL(let url):
            Safari.openURL(NSURL(string: url.expandedURL)!)
        case .Media(let media):
            if !media.videoURL.isEmpty {
                if let videoURL = NSURL(string: media.videoURL) {
                    showVideo(videoURL)
                }
            } else {
                ImageViewController.show([media.mediaURL], initialPage: 0)
            }
        case .Hashtag(let hashtag):
            SearchViewController.show("#" + hashtag.text)
        case .User(let user):
            ProfileViewController.show(user)
        }
    }
    
    func showVideo(videoURL: NSURL) {
        guard let view = UIApplication.sharedApplication().keyWindow else {
            return
        }
        playerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        playerView.player = AVPlayer(URL: videoURL)
        playerView.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        playerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
        view.addSubview(playerView)
        playerView.player?.play()
    }
}
