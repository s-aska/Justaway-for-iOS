#import "JFIEntity.h"
#import "JFIButton.h"
#import <UIKit/UIKit.h>

@interface JFIEntityCell : UITableViewCell <UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *sourceLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtRelativeLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *createdAtLabelHeightConstraint;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet JFIButton *replyButton;
@property (nonatomic, weak) IBOutlet JFIButton *retweetButton;
@property (nonatomic, weak) IBOutlet JFIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UILabel *retweetCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoriteCountLabel;
@property (nonatomic, weak) IBOutlet UIView *actionedView;
@property (nonatomic, weak) IBOutlet UIImageView *actionedIconImageView;
@property (nonatomic, weak) IBOutlet UILabel *actionedLabel;
@property (nonatomic, weak) IBOutlet UIView *imagesView;
@property (nonatomic) JFIEntity *entity;
@property (nonatomic) NSString *themeName;
@property (nonatomic) BOOL resizing;

- (void)setFontSize;
- (void)setFontSize:(float)size;
- (void)setLabelTexts:(JFIEntity *)entity;
- (void)setButtonColor;
- (void)loadImages;

- (IBAction)replyAction:(id)sender;
- (IBAction)retweetAction:(id)sender;
- (IBAction)favoriteAction:(id)sender;

@end
