#import "JFIEntityMenu.h"
#import "JFIBlocksSheet.h"
#import "JFIAppDelegate.h"
#import "JFITwitter.h"
#import "JFIAccount.h"
#import "JFIActionStatus.h"
#import "JFIEntityMenuViewController.h"

@implementation JFIEntityMenu

static NSMutableDictionary *settings = nil;
static NSArray *menus = nil;

+ (void)initialize {
    if (self == [JFIEntityMenu class]) {
        settings = NSMutableDictionary.new;
        menus = @[[@{JFIEntityMenuIDKey      : @"reply",
                     JFIEntityMenuSelectorKey: @"menuReply:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"favorite_and_retweet",
                     JFIEntityMenuSelectorKey: @"menuFavoriteRetweet:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"favorite",
                     JFIEntityMenuSelectorKey: @"menuFavorite:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"retweet",
                     JFIEntityMenuSelectorKey: @"menuRetweet:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"quote",
                     JFIEntityMenuSelectorKey: @"menuQuote:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"open_url",
                     JFIEntityMenuSelectorKey: @"menuOpenURL:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"open_media_url",
                     JFIEntityMenuSelectorKey: @"menuOpenMediaURL:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy],
                  [@{JFIEntityMenuIDKey      : @"destroy_status",
                     JFIEntityMenuSelectorKey: @"menuDestroyStatus:entity:",
                     JFIEntityMenuEnableKey  :@YES} mutableCopy]];
    }
}

+ (NSArray *)loadSettings
{
    /*
    for (NSMutableDictionary *menu in menus) {
        [menu setValue:@(1) forKey:JFIEntityMenuEnableKey];
    }
     */
    return menus;
}

+ (void)saveSettings:(NSArray *)newMenus
{
    menus = newMenus;
}

+ (void)showMenu:(JFIEntity *)entity
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    JFIBlocksSheet *blocksSheet = JFIBlocksSheet.new;
    for (NSDictionary *menu in menus) {
        if ([menu[JFIEntityMenuEnableKey] boolValue] &&
            [self respondsToSelector:NSSelectorFromString(menu[JFIEntityMenuSelectorKey])]) {
            [self performSelector:NSSelectorFromString(menu[JFIEntityMenuSelectorKey]) withObject:blocksSheet withObject:entity];
        } else {
            NSLog(@"[%@] %s missing:%@", NSStringFromClass([self class]), sel_getName(_cmd), menu[JFIEntityMenuSelectorKey]);
        }
    }
#pragma clang diagnostic pop
    
    // メニュー設定
    [blocksSheet addButtonWithTitle:NSLocalizedString(@"settings_menu", nil) block:^{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIEntityMenu" bundle:nil];
        JFIEntityMenuViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIEntityMenuViewController"];
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
    for (NSDictionary *url in entity.urls) {
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
