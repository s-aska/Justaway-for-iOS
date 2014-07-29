#import "JFIAppDelegate.h"
#import "JFIActionStatus.h"
#import "JFIStatusActionSheet.h"
#import "JFIAccount.h"
#import "JFITwitter.h"
#import "JFIStatusMenuViewController.h"

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
            [self addButtonWithTitle:NSLocalizedString(@"retweet", nil) action:@selector(createRetweet)];
        }
        if ([sharedActionStatus isFavorite:entity.statusID]) {
            [self addButtonWithTitle:NSLocalizedString(@"destroy_favorite", nil) action:@selector(destroyFavorite)];
        } else {
            [self addButtonWithTitle:NSLocalizedString(@"favorite", nil) action:@selector(createFavorite)];
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
        [self addButtonWithTitle:NSLocalizedString(@"menu_settings", nil) action:@selector(settings)];
        [self addButtonWithTitle:NSLocalizedString(@"menu_settings", nil) action:NSSelectorFromString(@"")];
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
    [self createFavorite];
    [self createRetweet];
}

- (void)createRetweet
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

- (void)createFavorite
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
    [JFITwitter quote:self.entity];
}

- (void)reply
{
    [JFITwitter reply:self.entity];
}

- (void)settings
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIStatusMenu" bundle:nil];
    JFIStatusMenuViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIStatusMenuViewController"];
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    [delegate.window.rootViewController presentViewController:accountViewController animated:YES completion:nil];
}

- (void)openURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

@end
