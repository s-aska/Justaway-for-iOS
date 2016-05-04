import UIKit
import EventBox
import AVFoundation
import Async

enum TwitterStatusCellLayout: String {
    case Normal = "Normal"
    case Actioned = "Actioned"
    case NormalWithImage = "NormalWithImage"
    case ActionedWithImage = "ActionedWithImage"
    case NormalWithQuote = "NormalWithQuote"
    case ActionedWithQuote = "ActionedWithQuote"
    case NormalWithImageWithQuote = "NormalWithImageWithQuote"
    case ActionedWithImageWithQuote = "ActionedWithImageWithQuote"
    case NormalWithQuoteImage = "NormalWithQuoteImage"
    case ActionedWithQuoteImage = "ActionedWithQuoteImage"
    case NormalWithImageWithQuoteImage = "NormalWithImageWithQuoteImage"
    case ActionedWithImageWithQuoteImage = "ActionedWithImageWithQuoteImage"
    case Message = "Message"
    case MessageWithImage = "MessageWithImage"

    static func fromStatus(status: TwitterStatus) -> TwitterStatusCellLayout {
        if let quotedStatus = status.quotedStatus {
            if quotedStatus.media.count > 0 {
                if status.actionedBy != nil {
                    return status.media.count > 0 ? ActionedWithImageWithQuoteImage : ActionedWithQuoteImage
                } else {
                    return status.media.count > 0 ? NormalWithImageWithQuoteImage : NormalWithQuoteImage
                }
            } else {
                if status.actionedBy != nil {
                    return status.media.count > 0 ? ActionedWithImageWithQuote : ActionedWithQuote
                } else {
                    return status.media.count > 0 ? NormalWithImageWithQuote : NormalWithQuote
                }
            }
        } else {
            if status.actionedBy != nil {
                return status.media.count > 0 ? ActionedWithImage : Actioned
            } else {
                return status.media.count > 0 ? NormalWithImage : Normal
            }
        }
    }

    static var allValues: [TwitterStatusCellLayout] {
        return [
            Normal,
            Actioned,
            NormalWithImage,
            ActionedWithImage,
            NormalWithQuote,
            ActionedWithQuote,
            NormalWithImageWithQuote,
            ActionedWithImageWithQuote,
            NormalWithQuoteImage,
            ActionedWithQuoteImage,
            NormalWithImageWithQuoteImage,
            ActionedWithImageWithQuoteImage
        ]
    }

    static func fromMessage(message: TwitterMessage) -> TwitterStatusCellLayout {
        return message.media.count > 0 ? MessageWithImage : Message
    }

    static var allValuesForMessage: [TwitterStatusCellLayout] {
        return [
            Message,
            MessageWithImage
        ]
    }

    var hasAction: Bool {
        return self.rawValue.rangeOfString("Actioned") != nil
    }

    var hasQuote: Bool {
        return self.rawValue.rangeOfString("WithQuote") != nil
    }

    var hasQuoteImage: Bool {
        return self.rawValue.rangeOfString("WithQuoteImage") != nil
    }

    var hasImage: Bool {
        return self.rawValue.rangeOfString("WithImage") != nil
    }

    var isMessage: Bool {
        return self.rawValue.rangeOfString("Message") != nil
    }
}

// swiftlint:disable:next type_body_length
class TwitterStatusCell: BackgroundTableViewCell {

    // MARK: Properties
    var status: TwitterStatus?
    var message: TwitterMessage?
    var layout: TwitterStatusCellLayout?
    let playerView = AVPlayerView()
    let playerWrapperView = UIView()
    var threadMode = false

    @IBOutlet weak var sourceView: UIView!
    @IBOutlet weak var sourceViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sourceFavoriteButton: FavoritesButton!
    @IBOutlet weak var sourceRetweetButton: RetweetButton!
    @IBOutlet weak var sourceTextLabel: TextLable!
    @IBOutlet weak var sourceScreenNameLabel: TextLable!

    @IBOutlet weak var iconImageView: UIImageView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var relativeCreatedAtLabel: UILabel!

    @IBOutlet weak var statusLabel: StatusLable!

    @IBOutlet weak var quotedStatusContainerView: QuotedStatusContainerView!
    @IBOutlet weak var quotedNameLabel: DisplayNameLable!
    @IBOutlet weak var quotedScreenNameLabel: ScreenNameLable!
    @IBOutlet weak var quotedProtectedLabel: UILabel!
    @IBOutlet weak var quotedStatusLabel: StatusLable?
    @IBOutlet weak var quotedStatusLabelHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var quotedImagesContainerView: UIView!
    @IBOutlet weak var quotedImageView1: UIImageView!
    @IBOutlet weak var quotedImageView2: UIImageView!
    @IBOutlet weak var quotedImageView3: UIImageView!
    @IBOutlet weak var quotedImageView4: UIImageView!
    @IBOutlet weak var quotedImagePlayLabel: MenuLable!

    @IBOutlet weak var quotedImageView1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView2WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView3WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView4HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var quotedImageView4WidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var imagesContainerView: UIView!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imagePlayLabel: MenuLable!

    @IBOutlet weak var imageView1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView4HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView4WidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var buttonsStatusTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var buttonsQuotedTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var buttonsImageTopConstraint: NSLayoutConstraint?

    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var retweetButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!

    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var viaLabel: UILabel!
    @IBOutlet weak var absoluteCreatedAtLabel: UILabel!
    @IBOutlet weak var talkButton: UIButton!

    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!

    // MARK: - View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
        configureEvent()
    }

    deinit {
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        selectionStyle = .None
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false

        for imageView in [imageView1, imageView2, imageView3, imageView4] {
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TwitterStatusCell.showImage(_:))))
        }

        for imageView in [quotedImageView1, quotedImageView2, quotedImageView3, quotedImageView4] {
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TwitterStatusCell.showQuotedImage(_:))))
        }

        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TwitterStatusCell.openProfile(_:))))

        playerWrapperView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TwitterStatusCell.hideVideo)))
        playerWrapperView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(TwitterStatusCell.videoSwipeUp))
        swipeUp.numberOfTouchesRequired = 1
        swipeUp.direction = .Up
        playerWrapperView.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(TwitterStatusCell.videoSwipeDown))
        swipeDown.numberOfTouchesRequired = 1
        swipeDown.direction = .Down
        playerWrapperView.addGestureRecognizer(swipeDown)

        playerWrapperView.addSubview(playerView)
    }

    func configureEvent() {

        configureFavoritesEvent()

        configureRetweetEvent()

        EventBox.onMainThread(self, name: eventFontSizePreview) { (n) -> Void in
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                let font = UIFont.systemFontOfSize(CGFloat(fontSize.floatValue))
                self.statusLabel.font = font
                self.quotedStatusLabel?.font = font
            }
        }

        EventBox.onMainThread(self, name: "applicationWillEnterForeground") { (n) -> Void in
            if let status = self.status {
                self.relativeCreatedAtLabel.text = status.createdAt.relativeString
            }
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TwitterStatusCell.endVideo), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }

    func configureFavoritesEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateFavorites.rawValue) { (n) -> Void in
            guard let statusID = n.object as? String else {
                return
            }
            if self.status?.statusID == statusID {
                self.favoriteButton.selected = true
                self.favoriteButton.transform = CGAffineTransformMakeScale(1, 1)
                let zoomOut = {
                    self.favoriteButton.transform = CGAffineTransformMakeScale(1, 1)
                }
                let zoomIn: (() -> Void) = {
                    self.favoriteButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
                }
                let zoomInCompletion: ((Bool) -> Void) = { _ in
                    UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomOut, completion: { _ in })
                }
                UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomIn, completion: zoomInCompletion)
            }
        }

        EventBox.onMainThread(self, name: Twitter.Event.DestroyFavorites.rawValue) { (n) -> Void in
            guard let statusID = n.object as? String else {
                return
            }
            if self.status?.statusID == statusID {
                self.favoriteButton.selected = false
            }
        }
    }

    func configureRetweetEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateRetweet.rawValue) { (n) -> Void in
            guard let statusID = n.object as? String else {
                return
            }
            if self.status?.statusID == statusID {
                self.retweetButton.selected = true
                self.retweetButton.transform = CGAffineTransformMakeScale(1, 1)
                let zoomOut = {
                    self.retweetButton.transform = CGAffineTransformMakeScale(1, 1)
                }
                let zoomIn: (() -> Void) = {
                    self.retweetButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
                }
                let zoomInCompletion: ((Bool) -> Void) = { _ in
                    UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomOut, completion: { _ in })
                }
                UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomIn, completion: zoomInCompletion)
            }
        }

        EventBox.onMainThread(self, name: Twitter.Event.DestroyRetweet.rawValue) { (n) -> Void in
            guard let statusID = n.object as? String else {
                return
            }
            if self.status?.statusID == statusID {
                self.retweetButton.selected = false
            }
        }
    }

    // MARK: - UITableViewCell



    // MARK: - Public Mehtods

    func setLayout(layout: TwitterStatusCellLayout) {
        if self.layout == nil || self.layout != layout {
            self.layout = layout
            if !layout.hasAction {
                sourceView.hidden = true
                sourceViewHeightConstraint.constant = 0
            }
            if !layout.hasImage {
                imagesContainerView.removeFromSuperview()
            }
            if !layout.hasQuote {
                quotedStatusContainerView.removeFromSuperview()
            }
            if !layout.hasQuoteImage {
                quotedImagesContainerView.removeFromSuperview()
            }
            if layout.hasImage {
                buttonsImageTopConstraint?.priority = UILayoutPriorityDefaultHigh
                buttonsQuotedTopConstraint?.priority = UILayoutPriorityDefaultLow
                buttonsStatusTopConstraint?.priority = UILayoutPriorityDefaultLow
            } else if layout.hasQuote {
                buttonsImageTopConstraint?.priority = UILayoutPriorityDefaultLow
                buttonsQuotedTopConstraint?.priority = UILayoutPriorityDefaultHigh
                buttonsStatusTopConstraint?.priority = UILayoutPriorityDefaultLow
            } else {
                buttonsImageTopConstraint?.priority = UILayoutPriorityDefaultLow
                buttonsQuotedTopConstraint?.priority = UILayoutPriorityDefaultLow
                buttonsStatusTopConstraint?.priority = UILayoutPriorityDefaultHigh
            }
            if layout.isMessage {
                retweetButton.hidden = true
                retweetCountLabel.hidden = true
                favoriteButton.hidden = true
                favoriteCountLabel.hidden = true
                talkButton.hidden = true
                viaLabel.hidden = true
                replyButton.hidden = true
            }
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    func setText(message: TwitterMessage) {
        iconImageView.image = nil
        statusLabel.setMessage(message, threadMode: threadMode)
        relativeCreatedAtLabel.text = message.createdAt.relativeString
        absoluteCreatedAtLabel.text = message.createdAt.absoluteString

        let user = threadMode ? message.collocutor : message.sender
        nameLabel.text = user.name
        screenNameLabel.text = "@" + user.screenName
        protectedLabel.hidden = user.isProtected ? false : true

        if message.media.count > 0 {
            imagePlayLabel.hidden = message.media.filter({ !$0.videoURL.isEmpty }).count > 0 ? false : true
            imagesContainerView.hidden = true
            imageView1.image = nil
            imageView2.image = nil
            imageView3.image = nil
            imageView4.image = nil
        }
    }

    func setImage(message: TwitterMessage) {
        if iconImageView.image == nil {
            let user = threadMode ? message.collocutor : message.sender
            ImageLoaderClient.displayUserIcon(user.profileImageURL, imageView: iconImageView)
        }
        setImage(message.media, possiblySensitive: false)
    }

    // swiftlint:disable:next function_body_length
    func setText(status: TwitterStatus) {
        Twitter.isFavorite(status.statusID) { isFavorite in
            if self.favoriteButton.selected != isFavorite {
                Async.main { self.favoriteButton.selected = isFavorite }
            }
        }

        Twitter.isRetweet(status.statusID) { retweetedStatusID in
            let isRetweet = retweetedStatusID != nil ? true : false
            if self.retweetButton.selected != isRetweet {
                Async.main { self.retweetButton.selected = isRetweet }
            }
        }

        iconImageView.image = nil
        nameLabel.text = status.user.name
        screenNameLabel.text = "@" + status.user.screenName
        protectedLabel.hidden = status.user.isProtected ? false : true
        statusLabel.setStatus(status)
        retweetCountLabel.text = status.retweetCount > 0 ? String(status.retweetCount) : ""
        favoriteCountLabel.text = status.favoriteCount > 0 ? String(status.favoriteCount) : ""
        relativeCreatedAtLabel.text = status.createdAt.relativeString
        absoluteCreatedAtLabel.text = status.createdAt.absoluteString
        viaLabel.text = status.via.name
        talkButton.hidden = status.inReplyToStatusID == nil

        if let actionedBy = status.actionedBy {
            sourceTextLabel.text = actionedBy.name
            sourceScreenNameLabel.text = "@" + actionedBy.screenName
            if status.type == .Favorite {
                sourceRetweetButton.hidden = true
                sourceFavoriteButton.hidden = false
                sourceFavoriteButton.selected = AccountSettingsStore.get()?.isMe(status.user.userID) ?? false
            } else {
                sourceFavoriteButton.hidden = true
                sourceRetweetButton.hidden = false
                sourceRetweetButton.selected = AccountSettingsStore.get()?.isMe(status.user.userID) ?? false
            }
        }

        if status.media.count > 0 {
            imagePlayLabel.hidden = status.media.filter({ !$0.videoURL.isEmpty }).count > 0 ? false : true
            imagesContainerView.hidden = true
            imageView1.image = nil
            imageView2.image = nil
            imageView3.image = nil
            imageView4.image = nil
        }

        if let quotedStatus = status.quotedStatus {

            quotedNameLabel.text = quotedStatus.user.name
            quotedScreenNameLabel.text = "@" + quotedStatus.user.screenName
            quotedStatusLabel?.setStatus(quotedStatus)
            quotedProtectedLabel.hidden = quotedStatus.user.isProtected ? false : true

            if quotedStatus.media.count > 0 {
                quotedImagePlayLabel.hidden = quotedStatus.media.filter({ !$0.videoURL.isEmpty }).count > 0 ? false : true
                quotedImagesContainerView.hidden = true
                quotedImageView1.image = nil
                quotedImageView2.image = nil
                quotedImageView3.image = nil
                quotedImageView4.image = nil
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func setImage(status: TwitterStatus) {

        if iconImageView.image == nil {
            ImageLoaderClient.displayUserIcon(status.user.profileImageURL, imageView: iconImageView)
        }

        setImage(status.media, possiblySensitive: status.possiblySensitive)

        setQuotedImage(status)
    }

    func setImage(mediaList: [TwitterMedia], possiblySensitive: Bool) {
        if mediaList.count > 0 && imagesContainerView.hidden == true {
            imagesContainerView.hidden = false

            let fullHeight = imagesContainerView.frame.height
            let fullWidth = imagesContainerView.frame.width
            let harfHeight = (fullHeight - 5) / 2
            let halfWidth = (fullWidth - 5) / 2
            switch mediaList.count {
            case 1:
                imageView1HeightConstraint.constant = fullHeight
                imageView1WidthConstraint.constant = fullWidth
                if possiblySensitive {
                    drawAttention([imageView1])
                } else {
                    ImageLoaderClient.displayImage(mediaList[0].mediaURL, imageView: imageView1)
                }
                imageView1.hidden = false
                imageView2.hidden = true
                imageView3.hidden = true
                imageView4.hidden = true
            case 2:
                imageView1HeightConstraint.constant = fullHeight
                imageView1WidthConstraint.constant = halfWidth
                imageView2HeightConstraint.constant = fullHeight
                imageView2WidthConstraint.constant = halfWidth
                if possiblySensitive {
                    drawAttention([imageView1, imageView2])
                } else {
                    ImageLoaderClient.displayThumbnailImage(mediaList[0].mediaThumbURL, imageView: imageView1)
                    ImageLoaderClient.displayThumbnailImage(mediaList[1].mediaThumbURL, imageView: imageView2)
                }
                imageView1.hidden = false
                imageView2.hidden = false
                imageView3.hidden = true
                imageView4.hidden = true
            case 3:
                imageView1HeightConstraint.constant = fullHeight
                imageView1WidthConstraint.constant = halfWidth
                imageView2HeightConstraint.constant = harfHeight
                imageView2WidthConstraint.constant = halfWidth
                imageView3HeightConstraint.constant = harfHeight
                imageView3WidthConstraint.constant = halfWidth
                if possiblySensitive {
                    drawAttention([imageView1, imageView2, imageView3])
                } else {
                    ImageLoaderClient.displayThumbnailImage(mediaList[0].mediaThumbURL, imageView: imageView1)
                    ImageLoaderClient.displayThumbnailImage(mediaList[1].mediaThumbURL, imageView: imageView2)
                    ImageLoaderClient.displayThumbnailImage(mediaList[2].mediaThumbURL, imageView: imageView3)
                }
                imageView1.hidden = false
                imageView2.hidden = false
                imageView3.hidden = false
                imageView4.hidden = true
            case 4:
                imageView1HeightConstraint.constant = harfHeight
                imageView1WidthConstraint.constant = halfWidth
                imageView2HeightConstraint.constant = harfHeight
                imageView2WidthConstraint.constant = halfWidth
                imageView3HeightConstraint.constant = harfHeight
                imageView3WidthConstraint.constant = halfWidth
                imageView4HeightConstraint.constant = harfHeight
                imageView4WidthConstraint.constant = halfWidth
                if possiblySensitive {
                    drawAttention([imageView1, imageView2, imageView3, imageView4])
                } else {
                    ImageLoaderClient.displayThumbnailImage(mediaList[0].mediaThumbURL, imageView: imageView1)
                    ImageLoaderClient.displayThumbnailImage(mediaList[1].mediaThumbURL, imageView: imageView2)
                    ImageLoaderClient.displayThumbnailImage(mediaList[3].mediaThumbURL, imageView: imageView3)
                    ImageLoaderClient.displayThumbnailImage(mediaList[2].mediaThumbURL, imageView: imageView4)
                }
                imageView1.hidden = false
                imageView2.hidden = false
                imageView3.hidden = false
                imageView4.hidden = false
            default:
                break
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func setQuotedImage(status: TwitterStatus) {
        if let quotedStatus = status.quotedStatus {
            if quotedStatus.media.count > 0 && quotedImagesContainerView.hidden == true {
                quotedImagesContainerView.hidden = false

                let fullHeight = quotedImagesContainerView.frame.height
                let fullWidth = quotedImagesContainerView.frame.width
                let harfHeight = (fullHeight - 5) / 2
                let halfWidth = (fullWidth - 5) / 2
                switch quotedStatus.media.count {
                case 1:
                    quotedImageView1HeightConstraint.constant = fullHeight
                    quotedImageView1WidthConstraint.constant = fullWidth
                    if quotedStatus.possiblySensitive {
                        drawAttention([quotedImageView1])
                    } else {
                        ImageLoaderClient.displayImage(quotedStatus.media[0].mediaURL, imageView: quotedImageView1)
                    }
                    quotedImageView1.hidden = false
                    quotedImageView2.hidden = true
                    quotedImageView3.hidden = true
                    quotedImageView4.hidden = true
                case 2:
                    quotedImageView1HeightConstraint.constant = fullHeight
                    quotedImageView1WidthConstraint.constant = halfWidth
                    quotedImageView2HeightConstraint.constant = fullHeight
                    quotedImageView2WidthConstraint.constant = halfWidth
                    if quotedStatus.possiblySensitive {
                        drawAttention([quotedImageView1, quotedImageView2])
                    } else {
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[0].mediaThumbURL, imageView: quotedImageView1)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[1].mediaThumbURL, imageView: quotedImageView2)
                    }
                    quotedImageView1.hidden = false
                    quotedImageView2.hidden = false
                    quotedImageView3.hidden = true
                    quotedImageView4.hidden = true
                case 3:
                    quotedImageView1HeightConstraint.constant = fullHeight
                    quotedImageView1WidthConstraint.constant = halfWidth
                    quotedImageView2HeightConstraint.constant = harfHeight
                    quotedImageView2WidthConstraint.constant = halfWidth
                    quotedImageView3HeightConstraint.constant = harfHeight
                    quotedImageView3WidthConstraint.constant = halfWidth
                    if quotedStatus.possiblySensitive {
                        drawAttention([quotedImageView1, quotedImageView2, quotedImageView3])
                    } else {
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[0].mediaThumbURL, imageView: quotedImageView1)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[1].mediaThumbURL, imageView: quotedImageView2)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[2].mediaThumbURL, imageView: quotedImageView3)
                    }
                    quotedImageView1.hidden = false
                    quotedImageView2.hidden = false
                    quotedImageView3.hidden = false
                    quotedImageView4.hidden = true
                case 4:
                    quotedImageView1HeightConstraint.constant = harfHeight
                    quotedImageView1WidthConstraint.constant = halfWidth
                    quotedImageView2HeightConstraint.constant = harfHeight
                    quotedImageView2WidthConstraint.constant = halfWidth
                    quotedImageView3HeightConstraint.constant = harfHeight
                    quotedImageView3WidthConstraint.constant = halfWidth
                    quotedImageView4HeightConstraint.constant = harfHeight
                    quotedImageView4WidthConstraint.constant = halfWidth
                    if quotedStatus.possiblySensitive {
                        drawAttention([quotedImageView1, quotedImageView2, quotedImageView3, quotedImageView4])
                    } else {
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[0].mediaThumbURL, imageView: quotedImageView1)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[1].mediaThumbURL, imageView: quotedImageView2)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[3].mediaThumbURL, imageView: quotedImageView3)
                        ImageLoaderClient.displayThumbnailImage(quotedStatus.media[2].mediaThumbURL, imageView: quotedImageView4)
                    }
                    quotedImageView1.hidden = false
                    quotedImageView2.hidden = false
                    quotedImageView3.hidden = false
                    quotedImageView4.hidden = false
                default:
                    break
                }
            }
        }
    }

    func drawAttention(imageViews: [UIImageView]) {
        Async.main {
            let font = UIFont(name: "fontello", size: imageViews[0].frame.height * 0.8)!
            let rect = imageViews[0].frame.offsetBy(dx: (imageViews[0].frame.width - imageViews[0].frame.height) / 2, dy: imageViews[0].frame.height * 0.1)
            UIGraphicsBeginImageContext(imageViews[0].frame.size)
            // swiftlint:disable:next force_cast
            let textStyle = NSMutableParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            let textFontAttributes: [String: AnyObject] = [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: ThemeController.currentTheme.bodyTextColor(),
                NSBackgroundColorAttributeName: UIColor.clearColor(),
                NSParagraphStyleAttributeName: textStyle
            ]
            "!".drawInRect(rect, withAttributes: textFontAttributes)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            for imageView in imageViews {
                imageView.image = image
            }
        }
    }

    // MARK: - Actions

    func openProfile(sender: UIGestureRecognizer) {
        if let user = status?.user {
            ProfileViewController.show(user)
        } else if let user = message?.sender {
            ProfileViewController.show(user)
        }
    }

    // 1 ... left top (tag:0, page:0)
    // 2 ... left top (tag:0, page:0) => right top (tag:1, page:1)
    // 3 ... left top (tag:0, page:0) => right top (tag:1, page:1) => right bottom (tag:2, page:2)
    // 4 ... left top (tag:0, page:0) => right top (tag:1, page:1) => left  bottom (tag:3, page:2) => right bottom (tag:2, page:3)
    let tagToPage = [
        1: [0:0],
        2: [0:0, 1:1],
        3: [0:0, 1:1, 2:2],
        4: [0:0, 1:1, 3:2, 2:3],
    ]

    func showImage(sender: UIGestureRecognizer) {
        let tag = sender.view?.tag ?? 0
        if let mediaList = self.status?.media ?? self.message?.media {
            if let page = tagToPage[mediaList.count]?[tag] {
                let media = mediaList[page]
                if !media.videoURL.isEmpty {
                    guard let videoURL = NSURL(string: media.videoURL) else {
                        return
                    }
                    self.showVideo(videoURL)
                } else {
                    ImageViewController.show(mediaList.map({ $0.mediaURL }), initialPage: page)
                }
            }
        }
    }

    func showVideo(videoURL: NSURL) {
        guard let view = UIApplication.sharedApplication().keyWindow else {
            return
        }
        playerWrapperView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        playerView.frame = playerWrapperView.frame
        playerView.player = AVPlayer(URL: videoURL)
        playerView.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        playerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
        view.addSubview(playerWrapperView)
        playerView.player?.play()
    }

    func hideVideo() {
        playerView.player?.pause()
        playerWrapperView.removeFromSuperview()
        do {
            try AVAudioSession.sharedInstance().setActive(false, withOptions:
                AVAudioSessionSetActiveOptions.NotifyOthersOnDeactivation)
        } catch {
            print("AVAudioSession setActive failure.")
        }
    }

    func endVideo() {
        playerView.player?.currentItem?.seekToTime(kCMTimeZero)
    }

    func videoSwipeUp() {
        UIView.animateWithDuration(0.3, animations: { _ in
            self.playerView.frame = self.playerView.frame.offsetBy(dx: 0, dy: -self.playerView.frame.size.height)
            }, completion: { _ in
                self.hideVideo()
        })
    }

    func videoSwipeDown() {
        UIView.animateWithDuration(0.3, animations: { _ in
            self.playerView.frame = self.playerView.frame.offsetBy(dx: 0, dy: self.playerView.frame.size.height)
        }, completion: { _ in
            self.hideVideo()
        })
    }

    func showQuotedImage(sender: UIGestureRecognizer) {
        let tag = sender.view?.tag ?? 0
        if let status = self.status?.quotedStatus {
            if let page = tagToPage[status.media.count]?[tag] {
                let media = status.media[page]
                if !media.videoURL.isEmpty {
                    if let videoURL = NSURL(string: media.videoURL) {
                        self.showVideo(videoURL)
                    }
                } else {
                    ImageViewController.show(status.media.map({ $0.mediaURL }), initialPage: page)
                }
            }
        }
    }

    @IBAction func reply(sender: UIButton) {
        if let status = self.status {
            Twitter.reply(status)
        }
    }

    @IBAction func retweet(sender: BaseButton) {
        if sender.lock() {
            if let status = self.status {
                RetweetAlert.show(sender, status: status)
            }
        }
    }

    @IBAction func favorite(sender: BaseButton) {
        if sender.lock() {
            if let statusID = self.status?.statusID {
                Twitter.toggleFavorite(statusID)
            }
        }
    }

    @IBAction func talk(sender: UIButton) {
        if let status = status {
            TalkViewController.show(status)
        }
    }
}
