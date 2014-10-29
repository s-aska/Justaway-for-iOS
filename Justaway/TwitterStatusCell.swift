import UIKit

class TwitterStatusCell: UITableViewCell {
    
    enum TwitterStatusCellLayout {
        case Normal
        case Actioned
    }
    
    // MARK: Properties
    var status: TwitterStatus?
    var layout: TwitterStatusCellLayout?
    
    @IBOutlet weak var createdAtBottom: NSLayoutConstraint!
    
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
            
            switch(layout) {
            case .Normal:
                self.createdAtBottom.constant = 5.0
                self.actionedContainerView.hidden = true
            case .Actioned:
                self.createdAtBottom.constant = 22.0
                self.actionedContainerView.hidden = false
            }
            
            self.layout = layout
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
        self.imagesContainerView.hidden = true
        self.iconImageView.image = nil
        if let actionedBy = status.actionedBy {
            self.actionedTextLabel.text = "@" + actionedBy.screenName
            self.actionedIconImageView.image = nil
        } else {
            
        }
    }
    
    // MARK: - Actions
    
    @IBAction func reply(sender: UIButton) {
        
    }
    
    @IBAction func retweet(sender: UIButton) {
        
    }
    
    @IBAction func favorite(sender: UIButton) {
        
    }
    
}
