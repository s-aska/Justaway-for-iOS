#import "JFIBlocksSheet.h"
#import "JFIConstants.h"

@implementation JFIBlocksSheet

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.blocks = [@[] mutableCopy];
        self.delegate = self;
    }
    return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(void(^)())block
{
    NSInteger index = [self addButtonWithTitle:title];
    [self.blocks insertObject:block atIndex:index];
    return index;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)index
{
    if ([self.blocks count] <= index) {
        return;
    }
    if (![self.blocks objectAtIndex:index]) {
        return;
    }
    void((^block)()) = self.blocks[index];
    block();
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFICloseStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
    
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end
