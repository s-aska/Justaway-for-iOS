#import "JFIEntityMenu.h"
#import "JFIBlocksSheet.h"
#import "JFIAppDelegate.h"
#import "JFITwitter.h"
#import "JFIAccount.h"
#import "JFIActionStatus.h"
#import "JFIStatusMenuViewController.h"

@implementation JFIEntityMenu

static NSMutableDictionary *settings = nil;
static NSArray *menus = nil;

+ (void)initialize {
    if (self == [JFIEntityMenu class]) {
        settings = NSMutableDictionary.new;
        menus = @[@"menuReply:entity:",
                  @"menuFavoriteRetweet:entity:",
                  @"menuFavorite:entity:",
                  @"menuRetweet:entity:",
                  @"menuQuote:entity:",
                  @"menuOpenURL:entity:",
                  @"menuOpenMediaURL:entity:",
                  @"menuDestroyStatus:entity:"];
    }
}

+ (void)loadSettings
{
    
}

+ (void)saveSettings
{
    
}

+ (void)showMenu:(JFIEntity *)entity
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    JFIBlocksSheet *blocksSheet = JFIBlocksSheet.new;
    for (NSString *menu in menus) {
        if ([self respondsToSelector:NSSelectorFromString(menu)]) {
            [self performSelector:NSSelectorFromString(menu) withObject:blocksSheet withObject:entity];
        } else {
            NSLog(@"[%@] %s missing:%@", NSStringFromClass([self class]), sel_getName(_cmd), menu);
        }
    }
    #pragma clang diagnostic pop
    
    // メニュー設定
    [blocksSheet addButtonWithTitle:NSLocalizedString(@"settings_menu", nil) block:^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIStatusMenu" bundle:nil];
        JFIStatusMenuViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIStatusMenuViewController"];
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        [delegate.window.rootViewController presentViewController:viewController animated:YES completion:nil];
    }];
    
    // キャンセル
    blocksSheet.cancelButtonIndex = [blocksSheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *navigationController = (UINavigationController *) delegate.window.rootViewController;
    [blocksSheet showInView:navigationController.topViewController.view];
}

+ (void)menuReply:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    [blocksSheet addButtonWithTitle:NSLocalizedString(@"reply", nil) block:^{
        [JFITwitter reply:entity];
    }];
}

+ (void)menuFavoriteRetweet:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    if (entity.isProtected) {
        return;
    }
    if (![[JFIActionStatus sharedActionStatus] isFavorite:entity.statusID] &&
        ![[JFIActionStatus sharedActionStatus] isRetweet:entity.statusID]) {
        [blocksSheet addButtonWithTitle:NSLocalizedString(@"favorite_and_retweet", nil) block:^{
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter createFavorite:twitter statusID:entity.statusID];
            [JFITwitter createRetweet:twitter statusID:entity.statusID];
        }];
    }
}

+ (void)menuFavorite:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    if ([[JFIActionStatus sharedActionStatus] isFavorite:entity.statusID]) {
        [blocksSheet addButtonWithTitle:NSLocalizedString(@"destroy_favorite", nil) block:^{
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter destroyFavorite:twitter statusID:entity.statusID];
        }];
    } else {
        [blocksSheet addButtonWithTitle:NSLocalizedString(@"favorite", nil) block:^{
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter createFavorite:twitter statusID:entity.statusID];
        }];
    }
}

+ (void)menuRetweet:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    if (entity.isProtected) {
        return;
    }
    if ([[JFIActionStatus sharedActionStatus] isRetweet:entity.statusID]) {
        [blocksSheet addButtonWithTitle:NSLocalizedString(@"destroy_retweet", nil) block:^{
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter destroyRetweet:twitter statusID:entity.statusID];
        }];
    } else {
        [blocksSheet addButtonWithTitle:NSLocalizedString(@"retweet", nil) block:^{
            JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter createRetweet:twitter statusID:entity.statusID];
        }];
    }
}

+ (void)menuQuote:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    if (entity.isProtected) {
        return;
    }
    [blocksSheet addButtonWithTitle:NSLocalizedString(@"quote", nil) block:^{
        [JFITwitter quote:entity];
    }];
}

+ (void)menuOpenURL:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    for (NSDictionary *url in entity.media) {
        [blocksSheet addButtonWithTitle:[url objectForKey:@"display_url"] block:^{
            [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:[url objectForKey:@"expanded_url"]]];
        }];
    }
}


+ (void)menuOpenMediaURL:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    for (NSDictionary *url in entity.media) {
        [blocksSheet addButtonWithTitle:[url objectForKey:@"display_url"] block:^{
            [[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:[url objectForKey:@"expanded_url"]]];
        }];
    }
}

+ (void)menuDestroyStatus:(JFIBlocksSheet *)blocksSheet entity:(JFIEntity *)entity
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    JFIAccount *account = [delegate getAccount];
    if ([account.userID isEqualToString:entity.userID]) {
        blocksSheet.destructiveButtonIndex = [blocksSheet addButtonWithTitle:NSLocalizedString(@"destroy_status", nil) block:^{
            STTwitterAPI *twitter = [delegate getTwitter];
            [JFITwitter destroyStatus:twitter statusID:entity.statusID];
        }];
    }
}

@end
