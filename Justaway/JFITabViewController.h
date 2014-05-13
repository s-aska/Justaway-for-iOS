#import <UIKit/UIKit.h>
#import "JFIConstants.h"
#import "JFIEntityCell.h"

@interface JFITabViewController : UITableViewController

@property (nonatomic) TabType tabType;
@property (nonatomic) NSMutableArray *entities;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) JFIEntityCell *cellForHeight;
@property (nonatomic) BOOL scrolling;

- (id)initWithType:(TabType)tabType;
- (void)finalizeWithDebounce:(CGFloat)delay;
- (void)receiveStatus:(NSNotification *)center;

@end
