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
        fontSizeSlider.addTarget(self, action: Selector("fontSizeChanged"), forControlEvents: UIControlEvents.ValueChanged)
        fontSizeSlider.addTarget(self, action: Selector("fontSizeFixed"), forControlEvents: [UIControlEvents.TouchUpInside, UIControlEvents.TouchUpOutside])
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                self.actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        for size in Int(fontSizeSlider.minimumValue) ... Int(fontSizeSlider.maximumValue) {
            let fontSize = String(size)
            let title = fontSize + "pt"
            let style :UIAlertActionStyle = size == 12 ? .Destructive : .Default
            actionSheet.addAction(UIAlertAction(
                title: title,
                style: style,
                handler: { action in
                    self.fontSizeSlider.value = Float(size)
                    EventBox.post(EventFontSizeApplied, userInfo: ["fontSize": NSNumber(integer: size)])
                    KeyClip.save("fontSize", string: fontSize)
            }))
        }
        
        fontSizeSlider.value = GenericSettings.get().fontSize
    }
    
    @IBAction func menuAction(sender: UIButton) {
        
        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        
        AlertController.showViewController(actionSheet)
    }
    
    // MARK: - Event
    
    func fontSizeChanged() {
        EventBox.post(EventFontSizePreview, userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }
    
    func fontSizeFixed() {
        EventBox.post(EventFontSizeApplied, userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }
}
