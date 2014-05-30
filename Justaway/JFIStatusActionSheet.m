#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIStatusActionSheet.h"
#import "JFIAccount.h"
#import "JFITwitter.h"

@implementation JFIStatusActionSheet

- (instancetype)initWithEntity:(JFIEntity *)entity
{
    self = [super init];
    if (self) {
        JFIActionStatus *sharedActionStatus = [JFIActionStatus sharedActionStatus];
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        JFIAccount *account = [delegate.accounts objectAtIndex:delegate.currentAccountIndex];
        if ([account.userID isEqualToString:entity.userID]) {
            [self addButtonWithTitle:@"ツイ消し" action:@selector(destroyStatus)];
        }
        if ([sharedActionStatus isRetweet:entity.statusID]) {
            [self addButtonWithTitle:@"公式RT取り消し" action:@selector(destroyRetweet)];
        } else {
            [self addButtonWithTitle:@"公式RT" action:@selector(retweet)];
        }
        if ([sharedActionStatus isFavorite:entity.statusID]) {
            [self addButtonWithTitle:@"あんふぁぼ" action:@selector(destroyFavorite)];
        } else {
            [self addButtonWithTitle:@"ふぁぼ" action:@selector(favorite)];
        }
        if (![sharedActionStatus isRetweet:entity.statusID] && ![sharedActionStatus isFavorite:entity.statusID]) {
            [self addButtonWithTitle:@"ふぁぼ＆公式RT" action:@selector(favoriteRetweet)];
        }
        [self addButtonWithTitle:@"引用" action:@selector(quote)];
        [self addButtonWithTitle:@"リプ" action:@selector(reply)];
        for (NSDictionary *url in entity.urls) {
            [self addButtonWithTitle:[url objectForKey:@"display_url"]
                              action:@selector(openURL:)
                              object:[[NSURL alloc] initWithString:[url objectForKey:@"expanded_url"]]];
        }
        for (NSDictionary *url in entity.media) {
            [self addButtonWithTitle:[url objectForKey:@"display_url"]
                              action:@selector(openURL:)
                              object:[[NSURL alloc] initWithString:[url objectForKey:@"media_url"]]];
        }
        self.entity = entity;
        self.cancelButtonIndex = [self addButtonWithTitle:@"キャンセル"];
    }
    return self;
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFICloseStatusNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)favoriteRetweet
{
    [self favorite];
    [self retweet];
}

- (void)retweet
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter createRetweet:twitter statusID:self.entity.statusID];
}

- (void)destroyRetweet
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter destroyRetweet:twitter statusID:self.entity.statusID];
}

- (void)favorite
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter createFavorite:twitter statusID:self.entity.statusID];
}

- (void)destroyFavorite
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter destroyFavorite:twitter statusID:self.entity.statusID];
}

- (void)destroyStatus
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    STTwitterAPI *twitter = [delegate getTwitter];
    [JFITwitter destroyStatus:twitter statusID:self.entity.statusID];
}

- (void)quote
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIEditorNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:@{@"text": self.entity.statusURL,
                                                                 @"range_location": @0,
                                                                 @"range_length": @0}];
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
    [[UIApplication sharedApplication] openURL:url];
}

@end
