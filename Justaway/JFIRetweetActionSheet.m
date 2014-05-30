#import "JFIEntity.h"
#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIRetweetActionSheet.h"
#import "JFITwitter.h"

@implementation JFIRetweetActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
        if ([sharedActionStatus isRetweet:entity.statusID]) {
            [self addButtonWithTitle:@"公式RT取り消し" action:@selector(destroyRetweet)];
        } else {
            [self addButtonWithTitle:@"公式RT" action:@selector(retweet)];
        }
        [self addButtonWithTitle:@"引用" action:@selector(quote)];
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
    }
    return self;
}

- (void)destroyRetweet
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter destroyRetweet:twitter statusID:self.entity.statusID];
}

- (void)retweet
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter createRetweet:twitter statusID:self.entity.statusID];
}

- (void)quote
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": self.entity.statusURL,
                                                                 @"range_location": @0,
                                                                 @"range_length": @0}];
}

@end
