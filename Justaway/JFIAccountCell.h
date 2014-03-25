#import <UIKit/UIKit.h>

@interface JFIAccountCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;

- (void)setLabelTexts:(NSDictionary *)account;

@end
