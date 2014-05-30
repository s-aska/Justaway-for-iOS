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
            [self addButtonWithTitle:NSLocalizedString(@"destroy_retweet", nil) action:@selector(destroyRetweet)];
        } else {
            [self addButtonWithTitle:NSLocalizedString(@"retweet", nil) action:@selector(retweet)];
        }
        [self addButtonWithTitle:NSLocalizedString(@"quote", nil) action:@selector(quote)];
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
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
