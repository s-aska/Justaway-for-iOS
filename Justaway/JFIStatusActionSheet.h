#import "JFIActionSheet.h"
#import "JFIEntity.h"

@interface JFIStatusActionSheet : JFIActionSheet

@property (nonatomic) JFIEntity *entity;

- (instancetype)initWithEntity:(JFIEntity *)entity;

@end
