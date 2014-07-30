#import <UIKit/UIKit.h>

@interface JFIBlocksSheet : UIActionSheet <UIActionSheetDelegate>

@property (nonatomic) NSMutableArray *blocks;

- (NSInteger)addButtonWithTitle:(NSString *)title block:(void(^)())block;

@end
