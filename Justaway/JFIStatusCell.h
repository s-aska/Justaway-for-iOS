#import <UIKit/UIKit.h>

@interface JFIStatusCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *sourceLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtRelativeLabel;
@property (nonatomic, weak) IBOutlet UILabel *createdAtLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIButton *replyButton;
@property (nonatomic, weak) IBOutlet UIButton *retweetButton;
@property (nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UILabel *retweetCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoriteCountLabel;
@property (nonatomic) NSDictionary *status;

- (void)setLabelTexts:(NSDictionary *)status;
- (void)loadImages:(BOOL)scrolling;

- (IBAction)replyAction:(id)sender;
- (IBAction)retweetAction:(id)sender;
- (IBAction)favoriteAction:(id)sender;

@end
