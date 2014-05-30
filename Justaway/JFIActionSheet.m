#import "JFIActionSheet.h"

@implementation JFIActionSheet

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.actions = [@[] mutableCopy];
        self.objects = [@{} mutableCopy];
        self.delegate = self;
    }
    return self;
}

- (NSInteger)addButtonWithTitle:(NSString *)title action:(SEL)selector
{
    NSInteger index = [self addButtonWithTitle:title];
    [self.actions insertObject:[NSValue valueWithPointer:selector] atIndex:index];
    return index;
}

- (NSInteger)addButtonWithTitle:(NSString *)title action:(SEL)selector object:(id)object
{
    NSInteger index = [self addButtonWithTitle:title];
    [self.actions insertObject:[NSValue valueWithPointer:selector] atIndex:index];
    [self.objects setObject:object forKey:@(index)];
    return index;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)index
{
    if ([self.actions count] <= index) {
        return;
    }
    if (![self.actions objectAtIndex:index]) {
        return;
    }
    SEL selector = [[self.actions objectAtIndex:index] pointerValue];
    [self performSelector:selector withObject:[self.objects objectForKey:@(index)] afterDelay:0.0f];
}

@end
