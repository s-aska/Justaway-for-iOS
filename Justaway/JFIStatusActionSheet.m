#import "JFIStatusActionSheet.h"

@implementation JFIStatusActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        [self addButtonWithTitle:@"公式RT" action:@selector(dummy)];
        [self addButtonWithTitle:@"引用" action:@selector(dummy)];
        [self addButtonWithTitle:@"リプ" action:@selector(reply)];
        for (NSDictionary *url in entity.urls) {
            [self addButtonWithTitle:[url objectForKey:@"display_url"]
                              action:@selector(openURL:)
                              object:[[NSURL alloc] initWithString:[url objectForKey:@"expanded_url"]]];
            
        }
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

- (void)openURL:(NSURL *)url
{
    NSLog(@"openURL:%@", url);
    [[UIApplication sharedApplication] openURL:url];
}

@end
