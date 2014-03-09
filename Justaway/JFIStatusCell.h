#import <UIKit/UIKit.h>

@interface JFIStatusCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

- (void) setLabelTexts:(NSDictionary *)status;

@end
