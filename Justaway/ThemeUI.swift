//
//  ThemeUI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import AVFoundation
import EventBox
import Async

// MARK: - ContainerView

class MenuView: UIView {}
class MenuShadowView: MenuView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class SideMenuShadowView: MenuShadowView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSize(width: 2.0, height: 0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class SideMenuSeparator: UIView {}
class NavigationShadowView: MenuView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundView: UIView {}
class BackgroundShadowView: BackgroundView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundTableView: UITableView {}
class BackgroundTableViewCell: UITableViewCell {}
class BackgroundScrollView: UIScrollView {}
class CurrentTabMaskView: UIView {}
class QuotedStatusContainerView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = ThemeController.currentTheme.cellSeparatorColor().CGColor
        layer.borderWidth = (1.0 / UIScreen.mainScreen().scale) / 1
    }
}
class ShowMoreTweetBackgroundView: UIView {}
class ShowMoreTweetLabel: UILabel {}
class ShowMoreTweetIndicatorView: UIActivityIndicatorView {}

// MARK: - Buttons

class StreamingButton: UIButton {
    var connectedColor = UIColor.greenColor()
    var normalColor = UIColor.grayColor()
    var errorColor = UIColor.redColor()

    override func awakeFromNib() {
        super.awakeFromNib()
        normalColor = ThemeController.currentTheme.bodyTextColor()
        connectedColor = ThemeController.currentTheme.streamingConnected()
        errorColor = ThemeController.currentTheme.streamingError()
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.rawValue) { _ in
            self.setTitleColor()
        }
        setTitleColor()
    }

    func setTitleColor() {
        switch Twitter.connectionStatus {
        case .CONNECTED:
            setTitleColor(connectedColor, forState: .Normal)
        case .CONNECTING:
            setTitleColor(normalColor, forState: .Normal)
        case .DISCONNECTED:
            if Twitter.enableStreaming {
                setTitleColor(errorColor, forState: .Normal)
            } else {
                setTitleColor(normalColor, forState: .Normal)
            }
        case .DISCONNECTING:
            setTitleColor(normalColor, forState: .Normal)
        }
    }

    deinit {
        EventBox.off(self)
    }
}
class MenuButton: BaseButton {}
class TabButton: BaseButton {
    var streaming = false {
        didSet {
            if streaming {
                setTitleColor(ThemeController.currentTheme.streamingConnected(), forState: .Normal)
            } else {
                setTitleColor(ThemeController.currentTheme.menuTextColor(), forState: .Normal)
            }
        }
    }
}
class FavoritesButton: BaseButton {}
class ReplyButton: BaseButton {}
class RetweetButton: BaseButton {}
class FollowButton: BaseButton {}
class UnfollowButton: BaseButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        layerColor = ThemeController.currentTheme.followButtonSelected()
        borderColor = ThemeController.currentTheme.followButtonSelected()
    }
}

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
    var message: TwitterMessage?
    var threadMode = false
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
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(StatusLable.touchesText(_:))))
    }

    // Disable text selection
    override func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
            gestureRecognizer.enabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
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

    func setMessage(message: TwitterMessage, threadMode: Bool) {
        self.threadMode = threadMode
        self.message = message
        self.text = message.text
        var newlinks = [Link]()
        for url in message.urls {
            for result in findString(url.displayURL) {
                let link = Link(entity: Entity.URL(url), range: result.range)
                newlinks.append(link)
            }
        }
        for media in message.media {
            for result in findString(media.displayURL) {
                let link = Link(entity: Entity.Media(media), range: result.range)
                newlinks.append(link)
            }
        }
        for hashtag in message.hashtags {
            for result in findString("#" + hashtag.text) {
                let link = Link(entity: Entity.Hashtag(hashtag), range: result.range)
                newlinks.append(link)
            }
        }
        for mention in message.mentions {
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
        attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.bodyTextColor(), range: NSRange.init(location: 0, length: text.utf16.count))
        if let font = font {
            attributedText.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(font.pointSize), range: NSRange.init(location: 0, length: text.utf16.count))
        }
        for link in links {
            attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.menuSelectedTextColor(), range: link.range)
        }
        self.attributedText = attributedText
    }

    private func findString(string: String) -> [NSTextCheckingResult] {
        let pattern = NSRegularExpression.escapedPatternForString(string)
        // swiftlint:disable:next force_try
        let regexp = try! NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
        return regexp.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSRange.init(location: 0, length: text.utf16.count))
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
            if !status.isRoot {
                TweetsViewController.show(status)
            }
        } else if let message = message, account = AccountSettingsStore.get()?.account() {
            if threadMode {
                if let messages = Twitter.messages[account.userID] {
                    let threadMessages = messages.filter({ $0.collocutor.userID == message.collocutor.userID })
                    Async.main {
                        MessagesViewController.show(message.collocutor, messages: threadMessages)
                    }
                }
            } else {
                Async.main {
                    DirectMessageAlert.show(account, message: message)
                }
            }
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
