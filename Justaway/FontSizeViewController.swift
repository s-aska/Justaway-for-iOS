import UIKit
import EventBox
import KeyClip

class FontSizeViewController: UIViewController {

    @IBOutlet weak var fontSizeSlider: UISlider!
    let actionSheet = UIAlertController()

    // MARK: Properties

    override var nibName: String {
        return "FontSizeViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    // MARK: - Configuration

    func configureView() {
        fontSizeSlider.addTarget(self, action: #selector(FontSizeViewController.fontSizeChanged), for: UIControlEvents.valueChanged)
        fontSizeSlider.addTarget(self, action: #selector(FontSizeViewController.fontSizeFixed), for: [UIControlEvents.touchUpInside, UIControlEvents.touchUpOutside])

        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { action in
                self.actionSheet.dismiss(animated: true, completion: nil)
        }))

        for size in Int(fontSizeSlider.minimumValue) ... Int(fontSizeSlider.maximumValue) {
            let fontSize = String(size)
            let title = fontSize + "pt"
            let style: UIAlertActionStyle = size == 12 ? .destructive : .default
            actionSheet.addAction(UIAlertAction(
                title: title,
                style: style,
                handler: { action in
                    self.fontSizeSlider.value = Float(size)
                    EventBox.post(eventFontSizeApplied, userInfo: ["fontSize": NSNumber(value: size as Int)])
                    KeyClip.save("fontSize", string: fontSize)
            }))
        }

        fontSizeSlider.value = GenericSettings.get().fontSize
    }

    @IBAction func menuAction(_ sender: UIButton) {

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }

    // MARK: - Event

    func fontSizeChanged() {
        EventBox.post(eventFontSizePreview, userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }

    func fontSizeFixed() {
        EventBox.post(eventFontSizeApplied, userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }
}
