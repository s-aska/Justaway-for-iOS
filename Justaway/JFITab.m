#import "JFITab.h"
#import "JFIHomeViewController.h"
#import "JFINotificationsViewController.h"
#import "JFIMessagesViewController.h"

@implementation JFITab

- (JFITab *)initWithType:(TabType)tabType
{
    self = [super init];
    if (self) {
        self.tabType = tabType;
    }
    return self;
}

- (JFITabViewController *)loadViewConroller
{
    JFITabViewController *viewController;
    switch (self.tabType) {
        case TabTypeHome:
            viewController = [[JFIHomeViewController alloc] initWithType:self.tabType];
            break;
        case TabTypeNotifications:
            viewController = [[JFINotificationsViewController alloc] initWithType:self.tabType];
            break;
        case TabTypeMessages:
            viewController = [[JFIMessagesViewController alloc] initWithType:self.tabType];
            break;
            
        default:
            break;
    }
    return viewController;
}

- (NSString *)title
{
    NSString *title;
    switch (self.tabType) {
        case TabTypeHome:
            title = @"Home";
            break;
        case TabTypeNotifications:
            title = @"Notifications";
            break;
        case TabTypeMessages:
            title = @"Messages";
            break;
        case TabTypeUserList:
            title = @"";
            break;
            
        default:
            title = @"unknown";
            break;
    }
    return title;
}

@end
