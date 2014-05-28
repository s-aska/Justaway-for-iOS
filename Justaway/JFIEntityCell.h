#import "JFIEntity.h"
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
@property (nonatomic, weak) IBOutlet UIButton *replyButton;
@property (nonatomic, weak) IBOutlet UIButton *retweetButton;
@property (nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UILabel *retweetCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoriteCountLabel;
@property (nonatomic, weak) IBOutlet UIView *actionedView;
@property (nonatomic, weak) IBOutlet UIImageView *actionedIconImageView;
@property (nonatomic, weak) IBOutlet UILabel *actionedLabel;
@property (nonatomic, weak) IBOutlet UIView *imagesView;
@property (nonatomic) JFIEntity *entity;

- (void)setLabelTexts:(JFIEntity *)entity;
- (void)loadImages:(BOOL)scrolling;

- (IBAction)replyAction:(id)sender;
- (IBAction)retweetAction:(id)sender;
- (IBAction)favoriteAction:(id)sender;

@end
