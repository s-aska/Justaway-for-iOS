#import <UIKit/UIKit.h>

@interface JFIActionSheet : UIActionSheet <UIActionSheetDelegate>

@property (nonatomic) NSMutableArray *actions;
@property (nonatomic) NSMutableDictionary *objects;

- (void)addButtonWithTitle:(NSString *)title action:(SEL)selector;
- (void)addButtonWithTitle:(NSString *)title action:(SEL)selector object:(id)object;

@end
