import UIKit

class ThemeViewController: UIViewController {

    // MARK: Properties

    override var nibName: String {
        return "ThemeViewController"
    }

    @IBOutlet weak var themeLight: UILabel!
    @IBOutlet weak var themeDark: UILabel!
    @IBOutlet weak var themeSolarizedLight: UILabel!
    @IBOutlet weak var themeSolarizedDark: UILabel!
    @IBOutlet weak var themeMonokai: UILabel!

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        for touch in touches {
            switch touch.view!.tag {
            case self.themeLight.tag:
                ThemeController.apply(ThemeLight())
            case self.themeDark.tag:
                ThemeController.apply(ThemeDark())
            case self.themeSolarizedLight.tag:
                ThemeController.apply(ThemeSolarizedLight())
            case self.themeSolarizedDark.tag:
                ThemeController.apply(ThemeSolarizedDark())
            case self.themeMonokai.tag:
                ThemeController.apply(ThemeMonokai())
            default:
                break
            }
        }
    }
}
