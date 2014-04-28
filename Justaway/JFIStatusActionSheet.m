#import "JFIStatusActionSheet.h"

@implementation JFIStatusActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        [self addButtonWithTitle:@"公式RT" action:@selector(dummy)];
        [self addButtonWithTitle:@"引用" action:@selector(dummy)];
        [self addButtonWithTitle:@"リプ" action:@selector(reply)];
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
        NSLog(@"cancelButtonIndex:%i", self.cancelButtonIndex);
    }
    return self;
}

- (void)dummy
{
}

- (void)reply
{
    NSString *text = [NSString stringWithFormat:@"@%@ ", self.entity.screenName];
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": text,
                                                                 @"in_reply_to_status_id": self.entity.statusID}];
}

@end
