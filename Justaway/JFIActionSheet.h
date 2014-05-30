#import <UIKit/UIKit.h>

@interface JFIActionSheet : UIActionSheet <UIActionSheetDelegate>

@property (nonatomic) NSMutableArray *actions;
@property (nonatomic) NSMutableDictionary *objects;

- (NSInteger)addButtonWithTitle:(NSString *)title action:(SEL)selector;
- (NSInteger)addButtonWithTitle:(NSString *)title action:(SEL)selector object:(id)object;

@end
