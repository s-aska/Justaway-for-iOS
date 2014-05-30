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
        if ([sharedActionStatus isRetweet:entity.statusID]) {
            [self addButtonWithTitle:NSLocalizedString(@"destroy_retweet", nil) action:@selector(destroyRetweet)];
        } else {
            [self addButtonWithTitle:NSLocalizedString(@"retweet", nil) action:@selector(retweet)];
        }
        if ([sharedActionStatus isFavorite:entity.statusID]) {
            [self addButtonWithTitle:NSLocalizedString(@"destroy_favorite", nil) action:@selector(destroyFavorite)];
        } else {
            [self addButtonWithTitle:NSLocalizedString(@"favorite", nil) action:@selector(favorite)];
        }
        if (![sharedActionStatus isRetweet:entity.statusID] && ![sharedActionStatus isFavorite:entity.statusID]) {
            [self addButtonWithTitle:NSLocalizedString(@"favorite_and_retweet", nil) action:@selector(favoriteRetweet)];
        }
        [self addButtonWithTitle:NSLocalizedString(@"quote", nil) action:@selector(quote)];
        [self addButtonWithTitle:NSLocalizedString(@"reply", nil) action:@selector(reply)];
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
        if ([account.userID isEqualToString:entity.userID]) {
            self.destructiveButtonIndex = [self addButtonWithTitle:NSLocalizedString(@"destroy_status", nil) action:@selector(destroyStatus)];
        }
        self.cancelButtonIndex = [self addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
        self.entity = entity;
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
