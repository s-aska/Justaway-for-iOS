#import <UIKit/UIKit.h>
#import "JFIConstants.h"
#import "JFIEntityCell.h"

@interface JFITabViewController : UITableViewController

@property (nonatomic) TabType tabType;
@property (nonatomic) NSMutableArray *entities;
@property (nonatomic) NSMutableArray *stacks;
@property (nonatomic) JFIEntityCell *cellForHeight;
@property (nonatomic) BOOL isCurrent;
@property (nonatomic) BOOL scrolling;
@property (nonatomic) BOOL finalizing;
@property (nonatomic) float fontSize;

- (id)initWithType:(TabType)tabType;
- (CGFloat)heightForEntity:(JFIEntity *)entity;
- (void)scrollToTop;
- (void)receiveStatus:(NSNotification *)center;
- (void)setEntities:(NSMutableArray *)entities;
- (void)addStack:(JFIEntity *)entity;

@end
