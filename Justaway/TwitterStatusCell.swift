import UIKit

let TwitterStatusCellImagePreviewHeight :CGFloat = 80

enum TwitterStatusCellLayout: String {
    case Normal = "Normal"
    case Actioned = "Actioned"
    
    static func fromStatus(status: TwitterStatus) -> TwitterStatusCellLayout {
        return status.isActioned ? Actioned : Normal
    }
    
    static var allValues: [TwitterStatusCellLayout] {
        return [Normal, Actioned]
    }
}

class TwitterStatusCell: UITableViewCell {
    
    // MARK: Properties
    var status: TwitterStatus?
    var layout: TwitterStatusCellLayout?
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var relativeCreatedAtLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var imagesContainerView: UIView!
    
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var retweetButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var viaLabel: UILabel!
    @IBOutlet weak var absoluteCreatedAtLabel: UILabel!
    
    @IBOutlet weak var actionedContainerView: UIView!
    @IBOutlet weak var actionedIconImageView: UIImageView!
    @IBOutlet weak var actionedTextLabel: UILabel!
    @IBOutlet weak var createdAtBottomConstraintWhenActioned: NSLayoutConstraint!
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .None
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
    }
    
    deinit {
        // NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - UITableViewCell
    
    
    
    // MARK: - Public Mehtods
    
    func setLayout(layout: TwitterStatusCellLayout) {
        if self.layout == nil || self.layout != layout {
            self.layout = layout
            
            if layout == .Normal {
                self.actionedContainerView.hidden = true
                self.createdAtBottomConstraintWhenActioned.constant = 5 // UILayoutPriorityDefaultHight + 1
            } else {
//                self.createdAtBottomConstraintWhenActioned.priority = 751 // UILayoutPriorityDefaultHight + 1
            }
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    func setText(status: TwitterStatus) {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        self.nameLabel.text = status.user.name
        self.screenNameLabel.text = "@" + status.user.screenName
        self.protectedLabel.hidden = status.isProtected ? false : true
        self.statusLabel.text = status.text
        self.retweetCountLabel.text = status.retweetCount > 0 ? numberFormatter.stringFromNumber(status.retweetCount) : ""
        self.favoriteCountLabel.text = status.favoriteCount > 0 ? numberFormatter.stringFromNumber(status.favoriteCount) : ""
        self.relativeCreatedAtLabel.text = status.createdAt.relativeString
        self.absoluteCreatedAtLabel.text = status.createdAt.absoluteString
        self.viaLabel.text = status.via.name
        self.iconImageView.image = nil
        if let actionedBy = status.actionedBy {
            self.actionedTextLabel.text = "@" + actionedBy.screenName
            self.actionedIconImageView.image = nil
        }
        self.imagesContainerView.hidden = true
    }
    
    func setImage(status: TwitterStatus) {
        if status.media.count == 0 {
            return
        }
        
        for subview in self.imagesContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        self.imagesContainerView.hidden = false
        
        var tag = 0
        for media in status.media {
            let imageView = UIImageView(frame: CGRectMake(
                0,
                CGFloat(tag) * TwitterStatusCellImagePreviewHeight + CGFloat(5),
                CGFloat(240),
                TwitterStatusCellImagePreviewHeight - CGFloat(5)))
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.tag = tag
//            imageView.userInteractionEnabled = true
//            let gesture = UITapGestureRecognizer(target: self, action: Selector("showImage:"))
//            gesture.numberOfTapsRequired = 1
//            imageView.addGestureRecognizer(gesture)
            self.imagesContainerView.addSubview(imageView)
            ImageLoaderClient.displayImage(media.mediaThumbURL, imageView: imageView)
            tag++
//            println("load imageView.frame:\(imageView.frame) \(media.mediaThumbURL)")
        }
        self.imagesContainerView.frame = CGRectMake(
            self.imagesContainerView.frame.origin.x,
            self.imagesContainerView.frame.origin.y,
            CGFloat(240),
            TwitterStatusCellImagePreviewHeight * CGFloat(status.media.count))
//        println("load imagesContainerView.frame:\(self.imagesContainerView.frame)")
//        self.contentView.setNeedsLayout()
//        self.contentView.layoutIfNeeded()
        
    }
    
    // MARK: - Actions
    
    func showImage(sender: AnyObject) {
        
    }
    
    @IBAction func reply(sender: UIButton) {
        
    }
    
    @IBAction func retweet(sender: UIButton) {
        
    }
    
    @IBAction func favorite(sender: UIButton) {
        
    }
    
}
