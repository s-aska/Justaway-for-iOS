import UIKit
import EventBox
import Photos
import Async
import MediaPlayer

class EditorViewController: UIViewController {

    struct Static {
        static let instance = EditorViewController()
    }

    struct UploadImage {
        let data: Data
        let asset: PHAsset
    }

    // MARK: Properties

    @IBOutlet weak var replyToContainerView: BackgroundView!
    @IBOutlet weak var replyToIconImageView: UIImageView!
    @IBOutlet weak var replyToNameLabel: DisplayNameLable!
    @IBOutlet weak var replyToScreenNameLabel: ScreenNameLable!
    @IBOutlet weak var replyToStatusLabel: StatusLable!
    @IBOutlet weak var replyToStatusLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyCancelButton: MenuButton!

    @IBOutlet weak var countLabel: MenuLable!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewButtomConstraint: NSLayoutConstraint! // Used to adjust the height when the keyboard hides and shows.

    @IBOutlet weak var textView: AutoExpandTextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint! // Used to AutoExpandTextView

    @IBOutlet weak var imageContainerView: UIScrollView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageContentView: UIView!
    @IBOutlet weak var collectionView: ImagePickerCollectionView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionMenuView: MenuView!

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var halfButton: MenuButton!

    let refreshControl = UIRefreshControl()
    var images: [UploadImage] = []
    var imageViews: [UIImageView] = []
    var picking = false
    let imageContainerHeightConstraintDefault: CGFloat = 100

    override var nibName: String {
        return "EditorViewController"
    }

    var inReplyToStatusId: String?
    var messageTo: TwitterUser?

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
        configureEvent()
        Async.main {
            self.view.isHidden = false
            self.show()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        view.isHidden = true
        textView.configure(heightConstraint: textViewHeightConstraint)

        imageViews = [imageView1, imageView2, imageView3, imageView4]
        for imageView in imageViews {
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EditorViewController.removeImage(_:))))
        }

        replyToIconImageView.layer.cornerRadius = 3
        replyToIconImageView.clipsToBounds = true

        resetPickerController()

        configureTextView()

        configureCollectionView()
    }

    func configureTextView() {
        // swiftlint:disable:next force_try
        let isKatakana = try! NSRegularExpression(pattern: "[\\u30A0-\\u30FF]", options: .caseInsensitive)
        textView.callback = { [weak self] in
            guard let `self` = self else {
                return
            }
            let count = TwitterText.count(self.textView.text, hasImage: self.images.count > 0)
            self.countLabel.text = String(140 - count)
            self.halfButton.isHidden = isKatakana.firstMatch(
                in: self.textView.text,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSRange(location: 0, length: self.textView.text.utf16.count)
                ) == nil
        }
    }

    func configureCollectionView() {
        collectionView.callback = { (asset: PHAsset) in
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: {
                (imageData: Data?, dataUTI: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) -> Void in
                if let imageData = imageData {
                    if self.images.count > 0 {
                        var i = 0
                        for image in self.images {
                            if imageData == image.data {
                                self.removeImageIndex(i)
                                return
                            }
                            i += 1
                        }
                    }
                    let i = self.images.count
                    if i >= 4 {
                        return
                    }
                    self.images.append(UploadImage(data: imageData, asset: asset))
                    self.imageViews[i].image = UIImage(data: imageData)
                    self.collectionView.highlightRows = self.images.map({ $0.asset })
                    self.collectionView.reloadHighlight()
                    if self.imageContainerHeightConstraint.constant == 0 {
                        self.imageContainerHeightConstraint.constant = self.imageContainerHeightConstraintDefault
                        UIView.animate(withDuration: 0.2, animations: { () -> Void in
                            self.view.layoutIfNeeded()
                        })
                    }
                }
            })
        }
        refreshControl.addTarget(self, action: #selector(loadImages), for: UIControlEvents.valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    func loadImages() {
        Async.background { () -> Void in
            let options = PHFetchOptions()
            options.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            var rows = [PHAsset]()
            let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
            assets.enumerateObjects({ (asset, index, stop) -> Void in
                rows.append(asset as PHAsset)
            })
            self.collectionView.rows = rows
            Async.main { () -> Void in
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: NSNotification.Name.UIKeyboardWillShow) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: true)
        }

        EventBox.onMainThread(self, name: NSNotification.Name.UIKeyboardWillHide) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: false)
        }
    }

    func resetPickerController() {
        images = []
        for imageView in imageViews {
            imageView.image = nil
        }
        collectionView.rows = []
        collectionView.highlightRows = []
        collectionHeightConstraint.constant = 0
        imageContainerHeightConstraint.constant = 0
        collectionMenuView.isHidden = true
    }

    // MARK: - Keyboard Event Notifications

    func keyboardWillChangeFrame(_ notification: Notification, showsKeyboard: Bool) {
        let userInfo = notification.userInfo!
        // swiftlint:disable force_cast
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey]as! NSValue).cgRectValue
        // swiftlint:enable force_cast

        if showsKeyboard {
            let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            if orientation.isLandscape {
                containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.width
            } else {
                containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.height
            }
            collectionHeightConstraint.constant = 0
            collectionMenuView.isHidden = true
        } else {

            // en: UIKeyboardWillHideNotification occurs when you scroll through the conversion candidates in iOS9
            // ja: iOS9 では変換候補をスクロールする際 UIKeyboardWillHideNotification が発生する
            if !textView.text.isEmpty && !picking {
                return
            }
            containerViewButtomConstraint.constant = 0
        }

        self.view.setNeedsUpdateConstraints()

        UIView.animate(withDuration: animationDuration, delay: 0, options: .beginFromCurrentState, animations: {
            self.containerView.alpha = showsKeyboard || self.picking ? 1 : 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            if !showsKeyboard && !self.picking {
                self.view.removeFromSuperview()
            }
        })
    }

    // MARK: - Actions

    @IBAction func hide(_ sender: UIButton) {
        if picking {
            picking = false
            textView.becomeFirstResponder()
        } else {
            hide()
        }
    }

    @IBAction func image(_ sender: UIButton) {
        image()
    }

    @IBAction func music(_ sender: UIButton) {
        guard let item = MPMusicPlayerController.systemMusicPlayer().nowPlayingItem else {
            if let url = URL.init(string: "googleplaymusic://") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                    return
                }
            }
            ErrorAlert.show("Missing music", message: "Sorry, support the apple music only")
            return
        }
        var text = ""
        if let title = item.title {
            text += title
        }
        if let artist = item.artist {
            text += " - " + artist
        }
        if !text.isEmpty {
            textView.text = "#NowPlaying " + text
            textView.selectedRange = NSRange.init(location: 0, length: 0)
        }
        if let artwork = item.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
            if let image = artwork.image(at: artwork.bounds.size), let imageData = UIImagePNGRepresentation(image) {
                let i = self.images.count
                if i >= 4 {
                    return
                }
                self.images.append(UploadImage(data: imageData, asset: PHAsset()))
                self.imageViews[i].image = image
                if self.imageContainerHeightConstraint.constant == 0 {
                    self.imageContainerHeightConstraint.constant = self.imageContainerHeightConstraintDefault
                    UIView.animate(withDuration: 0.2, animations: { () -> Void in
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }

    @IBAction func half(_ sender: AnyObject) {
        let text = NSMutableString(string: textView.text) as CFMutableString
        CFStringTransform(text, nil, kCFStringTransformFullwidthHalfwidth, false)
        textView.text = text as String
    }

    @IBAction func send(_ sender: UIButton) {
        let text = textView.text
        if (text?.isEmpty)! && images.count == 0 {
            hide()
        } else {
            if let messageTo = messageTo {
                Twitter.postDirectMessage(text!, userID: messageTo.userID)
            } else {
                Twitter.statusUpdate(text!, inReplyToStatusID: self.inReplyToStatusId, images: self.images.map({ $0.data }), mediaIds: [])
            }
            hide()
        }
    }

    func removeImage(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else {
            return
        }
        if images.count <= index {
            return
        }
        removeImageIndex(index)
    }

    func removeImageIndex(_ index: Int) {
        images.remove(at: index)
        var i = 0
        for imageView in imageViews {
            if images.count > i {
                imageView.image = UIImage(data: images[i].data)
            } else {
                imageView.image = nil
            }
            i += 1
        }
        if images.count == 0 {
            imageContainerHeightConstraint.constant = 0
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
        collectionView.highlightRows = images.map({ $0.asset })
        collectionView.reloadHighlight()
    }

    @IBAction func replyCancel(_ sender: UIButton) {
        if let inReplyToStatusId = inReplyToStatusId {
            let pattern = " ?https?://twitter\\.com/[0-9a-zA-Z_]+/status/\(inReplyToStatusId)"
            textView.text = textView.text.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
        }
        inReplyToStatusId = nil
        replyToContainerView.isHidden = true
        textView.text = textView.text.replacingOccurrences(of: "^.*@[0-9a-zA-Z_]+ *", with: "", options: .regularExpression, range: nil)
    }

    func image() {
        if messageTo != nil {
            ErrorAlert.show("Not supported image with DirectMessage")
            return
        }

        picking = true
        let height = UIApplication.shared.keyWindow?.frame.height ?? 480
        collectionHeightConstraint.constant = height - imageContainerHeightConstraintDefault - 10
        collectionMenuView.isHidden = false
        textView.resignFirstResponder()
        if collectionView.rows.count == 0 {
            loadImages()
        }
    }

    func show() {
        textView.becomeFirstResponder()
        textView.callback?()
    }

    func hide() {
        picking = false
        inReplyToStatusId = nil
        messageTo = nil
        replyToContainerView.isHidden = true
        textView.reset()
        resetPickerController()

        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            view.removeFromSuperview()
        }
    }

    class func show(_ text: String? = nil, range: NSRange? = nil, inReplyToStatus: TwitterStatus? = nil, messageTo: TwitterUser? = nil) {
        if let vc = ViewTools.frontViewController() {
            Static.instance.view.frame = vc.view.frame
            Static.instance.resetPickerController()
            Static.instance.textView.text = text ?? ""
            Static.instance.countLabel.isHidden = messageTo != nil
            Static.instance.replyCancelButton.isHidden = messageTo != nil
            Static.instance.messageTo = messageTo
            if let inReplyToStatus = inReplyToStatus {
                Static.instance.inReplyToStatusId = inReplyToStatus.statusID
                Static.instance.replyToNameLabel.text = inReplyToStatus.user.name
                Static.instance.replyToScreenNameLabel.text = "@" + inReplyToStatus.user.screenName
                Static.instance.replyToStatusLabel.text = inReplyToStatus.text
                Static.instance.replyToStatusLabelHeightConstraint.constant =
                    measure(inReplyToStatus.text as NSString,
                        fontSize: Static.instance.replyToStatusLabel.font?.pointSize ?? 12,
                        wdith: Static.instance.replyToStatusLabel.frame.size.width)
                Static.instance.replyToContainerView.isHidden = false
                if let url = inReplyToStatus.user.profileImageURL {
                    ImageLoaderClient.displayUserIcon(url, imageView: Static.instance.replyToIconImageView)
                }
            } else if let messageTo = messageTo {
                Static.instance.inReplyToStatusId = nil
                Static.instance.replyToNameLabel.text = messageTo.name
                Static.instance.replyToScreenNameLabel.text = "@" + messageTo.screenName
                Static.instance.replyToStatusLabel.text = ""
                Static.instance.replyToStatusLabelHeightConstraint.constant = 0
                Static.instance.replyToContainerView.isHidden = false
                if let url = messageTo.profileImageURL {
                    ImageLoaderClient.displayUserIcon(url, imageView: Static.instance.replyToIconImageView)
                }
            } else {
                Static.instance.inReplyToStatusId = nil
                Static.instance.replyToContainerView.isHidden = true
            }
            if let selectedRange = range {
                Static.instance.textView.selectedRange = selectedRange
            }
            vc.view.addSubview(Static.instance.view)
        }
    }

    class func hide() {
        if Static.instance.textView == nil {
            return
        }
        Static.instance.hide()
    }

    class func measure(_ text: NSString, fontSize: CGFloat, wdith: CGFloat) -> CGFloat {
        return ceil(text.boundingRect(
            with: CGSize.init(width: wdith, height: 0),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: fontSize)],
            context: nil).size.height)
    }
}
