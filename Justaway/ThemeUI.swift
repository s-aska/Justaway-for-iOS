//
//  ThemeUI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

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
class StatusLable: UILabel {
    var displayURLs = [String]()
    
    func setAttributes() {
        if let text = self.text {
            let attributedText = NSMutableAttributedString(string: text)
            for displayURL in displayURLs {
                let pattern = NSRegularExpression.escapedPatternForString(displayURL)
                let regexp = try! NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
                let results = regexp.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, text.utf16.count))
                for result in results {
                    attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.menuSelectedTextColor(), range: result.range)
                }
            }
            self.attributedText = attributedText
        }
    }
}
