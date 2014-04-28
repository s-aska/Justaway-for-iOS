#import "JFIActionSheet.h"
#import "JFIEntity.h"

@interface JFIRetweetActionSheet : JFIActionSheet <UIActionSheetDelegate>

@property (nonatomic) JFIEntity *entity;

- (instancetype)initWithEntity:(JFIEntity *)entity;

@end
